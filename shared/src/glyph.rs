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
    x: f64,
    y: f64,
    radians: f64,
    curviness: f64,
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
        fn push_num(string: &mut String, num: f64) {
            // Format looks like +222.222
            string.push_str(&format!("{:+08.3}", num));
        }

        fn path_to_commands(path: &Path) -> Option<String> {
            let points = &path.points;
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
                for (factor, point) in [(1.0, p0), (-1.0, p1)] {
                    let scaled_factor = factor * point.curviness;
                    push_num(
                        &mut result,
                        point.x + (scaled_factor * f64::sin(point.radians)),
                    );
                    push_num(
                        &mut result,
                        point.y - (scaled_factor * f64::cos(point.radians)),
                    );
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
            .filter_map(path_to_commands)
            .collect()
    }
}

impl Path {
    fn new() -> Self {
        let points: Vec<Point> =
            [
                (16.0, 8.0, 90.0, 4.0),
                (24.0, 16.0, 180.0, 4.0),
                (8.0, 16.0, 0.0, 4.0),
            ]
            .iter()
            .map(|(x, y, degrees, curviness)| Point {
                x: *x,
                y: *y,
                radians: degrees * (std::f64::consts::PI / 180.0),
                curviness: *curviness,
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
            x: 0.0,
            y: 0.0,
            radians: 0.0,
            curviness: 1.0,
        }
    }

    fn mutate(&mut self) {
        fn rand_between(min: f64, max: f64) -> f64 {
            min + (fastrand::f64() * (max - min))
        }

        /// Adds a random number between `-scale` and `scale`
        fn mutate_float(num: &mut f64, scale: f64) {
            *num += rand_between(-scale, scale).powi(3);
        }

        mutate_float(&mut self.x, 0.5);
        mutate_float(&mut self.y, 0.5);
        mutate_float(&mut self.radians, 0.1);
        mutate_float(&mut self.curviness, 1.0);
    }
}
