use crate::util::{char_map, char_write};
use deku::prelude::*;

#[derive(DekuRead, DekuWrite, Clone, PartialEq, Eq)]
#[deku(endian = "big")]
pub struct Glyph {
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
    char: char,
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
    /// 0 to 32767 from left to right
    x: i16,
    /// 0 to 32767 from up to down
    y: i16,
    /// In the curve from this point to the next point, `radians` is the angle from this point (P0) to P1.
    ///
    /// In the curve from the previous point to this point, `radians` is the angle from P2 to this point (P3).
    ///
    /// https://upload.wikimedia.org/wikipedia/commons/d/d0/Bezier_curve.svg
    ///
    /// 0 radians points to the right, and it turns clockwise when increasing.
    radians: f32,
    curviness: i16,
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

    pub fn char(&self) -> char {
        self.char
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
            path.points.push(Point::new());
            let _ = DekuUpdate::update(path);
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
        fn push_num(string: &mut String, num: i16) {
            // 5 digits prefixed with + or -
            string.push_str(&format!("{:+06}", num));
        }

        fn points_to_commands(points: &[Point]) -> Option<String> {
            let first_point = points.first()?;

            // Convert [0, 1, 2, .., n] in `points` to [(0, 1), (1, 2), .., (n, 0)] in `pairs`
            let pairs = {
                let mut iter = points.iter().peekable();
                std::iter::from_fn(move || {
                    let next = iter.next()?;
                    Some((next, *iter.peek().unwrap_or(&first_point)))
                })
            };

            let mut result = String::with_capacity(1024);
            result.push('M');
            push_num(&mut result, first_point.x);
            push_num(&mut result, first_point.y);
            for (p0, p1) in pairs {
                // Cubic bezier curve
                result.push('C');
                for (factor, point) in [(1, p0), (-1, p1)] {
                    let distance = point.curviness * factor;
                    let (x, y) = point.curve_point(distance);
                    push_num(&mut result, x);
                    push_num(&mut result, y);
                }
                push_num(&mut result, p1.x);
                push_num(&mut result, p1.y);
            }
            result.push('Z');

            Some(result)
        }

        self
            .paths
            .iter()
            .filter_map(|path| points_to_commands(&path.points))
            .collect()
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
                x: x * 8192,
                y: y * 8192,
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
            x: 0,
            y: 0,
            radians: 0.0,
            curviness: 4096,
        }
    }

    fn curve_point(&self, distance: i16) -> (i16, i16) {
        (
            self.x + (distance * (self.radians.cos() as i16)),
            self.y + (distance * (self.radians.sin() as i16)),
        )
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

        mutate_int(&mut self.x, 10);
        mutate_int(&mut self.y, 10);
        mutate_float(&mut self.radians, 0.1);
        mutate_int(&mut self.curviness, 10);
    }
}
