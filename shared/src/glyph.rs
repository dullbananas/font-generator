use crate::util::{char_map, char_write};
use deku::prelude::*;

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "big")]
pub struct Glyph {
    #[deku(map = "char_map", writer = "char_write(deku::output, char)")]
        /*map = "|c: u32|
            char::from_u32(c)
                .ok_or(DekuError::Parse(\"invalid char\".to_owned()))
        ",
        writer = "u32::from(*char).write(deku::output, ())"*/
    char: char,
    #[deku(bits_read = "deku::rest.len()")]
    paths: Vec<Path>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "endian", ctx = "endian: deku::ctx::Endian")]
pub struct Path {
    #[deku(update = "self.points.len()")]
    count: u16,
    #[deku(count = "count")]
    points: Vec<Point>,
}

#[derive(DekuRead, DekuWrite)]
#[deku(endian = "endian", ctx = "endian: deku::ctx::Endian")]
pub struct Point {
    x: f64,
    y: f64,
    radians: f64,
    curviness: f64,
}

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
