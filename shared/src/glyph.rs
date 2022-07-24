use crate::util::{char_map, char_write};
use deku::prelude::*;

const X: usize = 0;
const Y: usize = 1;

#[derive(DekuRead, DekuWrite, Clone, PartialEq, Eq)]
#[deku(endian = "big")]
pub struct Glyph {
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
    pub char: char,
    #[deku(bits_read = "deku::rest.len()")]
    paths: Vec<Path>,
}

#[derive(DekuRead, DekuWrite, Clone, PartialEq, Eq)]
#[deku(endian = "endian", ctx = "endian: deku::ctx::Endian")]
pub struct Path {
    #[deku(update = "self.points.len()")]
    count: u16,
    #[deku(count = "count")]
    points: Vec<Point>,
}

#[derive(DekuRead, DekuWrite, Clone, PartialEq)]
#[deku(endian = "endian", ctx = "endian: deku::ctx::Endian")]
pub struct Point {
    /// This stores coordinates as `[x, y]`. Both numbers go from 0 (top left) to 32767. Use the `X` and `Y` constants for indexing.
    pub position: [i16; 2],
    /// In the curve from this point to the next point, `radians` is the angle from this point (P0) to P1.
    ///
    /// In the curve from the previous point to this point, `radians` is the angle from P2 to this point (P3).
    ///
    /// https://upload.wikimedia.org/wikipedia/commons/d/d0/Bezier_curve.svg
    ///
    /// 0 radians points to the right, and it turns clockwise when increasing.
    pub radians: f32,
    pub curviness: i16,
}

// `Glyph` must implement `Eq` to be used with `sycamore::flow::Keyed` because of lukechu10
// https://github.com/sycamore-rs/sycamore/issues/452
impl Eq for Point {}

impl Glyph {
    pub fn new(char: char) -> Self {
        Glyph {
            char: char,
            paths: vec![Path::new()],
        }
    }

    pub fn paths(&self) -> &[Path] {
        &self.paths
    }

    pub fn mutate(&mut self) {
        for path in &mut self.paths {
            path.mutate();
        }
    }

    pub fn add_path(&mut self) {
        self.paths.push(Path::new());
    }

    pub fn add_point(&mut self, path_id: usize) {
        if let Some(path) = self.paths.get_mut(path_id) {
            if path.count < u16::MAX {
                path.points.push(Point::new());
                DekuUpdate::update(path).unwrap();
            }
        }
    }

    pub fn update_point(
        &mut self,
        path_id: usize,
        point_id: usize,
        f: impl Fn(&mut Point),
    ) {
        if let Some(path) = self.paths.get_mut(path_id) {
            path.update_point(point_id, f);
        }
    }

    pub fn generate_variants<'a, Iter>(old_glyphs: Iter) -> Vec<Glyph>
    where
        Iter: Iterator<Item = &'a Glyph>,
    {
        let mut variants = Vec::<Glyph>::new();
        for old_glyph in old_glyphs {
            let mut glyph = old_glyph.clone();
            glyph.mutate();
            variants.push(glyph);
        }
        fastrand::shuffle(&mut variants);
        variants
    }

    /// Converts the glyph to a string for the `d` attribute in an SVG `path` element
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
    pub fn to_svg_path_d(&self) -> String {
        fn push_coordinates(string: &mut String, pair: [i16; 2]) {
            // 5 digits prefixed with + or -
            for num in pair {
                string.push_str(&format!("{:+06}", num));
            }
        }

        fn points_to_commands(string: &mut String, points: &[Point]) {
            let first_point = match points.first() {
                Some(point) => point,
                None => return,
            };

            // Convert [0, 1, 2, .., n] in `points` to [(0, 1), (1, 2), .., (n, 0)] in `pairs`
            let pairs = {
                let mut iter = points.iter().peekable();
                std::iter::from_fn(move || {
                    let next = iter.next()?;
                    Some((next, *iter.peek().unwrap_or(&first_point)))
                })
            };

            string.push('M');
            push_coordinates(string, first_point.position);
            for (p0, p1) in pairs {
                // Cubic bezier curve
                string.push('C');
                for (factor, point) in [(1, p0), (-1, p1)] {
                    let distance = factor * point.curviness;
                    push_coordinates(string, point.curve_point(distance));
                }
                push_coordinates(string, p1.position);
            }
            string.push('Z');
        }

        let mut string = String::with_capacity(1024);
        for path in &self.paths {
            points_to_commands(&mut string, &path.points);
        }

        string
    }
}

impl Path {
    fn new() -> Self {
        let points: Vec<Point> =
            [
                (2, 1, 0.0),
                (3, 2, 90.0),
                (1, 2, 270.0),
            ]
            .iter()
            .map(|(x, y, degrees): &(i16, i16, f32)| Point {
                position: [x * 8192, y * 8192],
                radians: degrees.to_radians(),
                curviness: 4096,
            })
            .collect();

        Path {
            count: points.len() as u16,
            points: points,
        }
    }

    fn mutate(&mut self) {
        for point in &mut self.points {
            point.mutate();
        }
    }

    fn update_point(
        &mut self,
        point_id: usize,
        f: impl Fn(&mut Point),
    ) {
        if let Some(point) = self.points.get_mut(point_id) {
            f(point);
        }
    }
}

impl Point {
    fn new() -> Self {
        Point {
            position: [0, 0],
            radians: 0.0,
            curviness: 4096,
        }
    }

    fn curve_point(&self, distance: i16) -> [i16; 2] {
        let transform_component = |component, ratio| {
            let transform_amount = ratio * f32::from(distance);
            self.position[component] + (transform_amount as i16)
        };
        [
            transform_component(X, self.radians.cos()),
            transform_component(Y, self.radians.sin()),
        ]
    }

    fn mutate(&mut self) {
        fn rand_between(min: f32, max: f32) -> f32 {
            min + (fastrand::f32() * (max - min))
        }

        /// Adds a random number between `-scale` and `scale`
        fn mutate_float(num: &mut f32, scale: f32) {
            *num += rand_between(-scale, scale).powi(3);
        }

        /// Adds a random integer between `-scale` and `scale`
        fn mutate_int(num: &mut i16, scale: i16) {
            let change_amount = fastrand::i16(-scale..=scale);
            *num = std::cmp::max(0, num.saturating_add(change_amount));
        }

        mutate_int(&mut self.position[X], 10);
        mutate_int(&mut self.position[Y], 10);
        mutate_float(&mut self.radians, 0.1);
        mutate_int(&mut self.curviness, 10);
    }
}
