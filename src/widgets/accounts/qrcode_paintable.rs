use gtk::{gdk, glib, graphene, gsk, prelude::*, subclass::prelude::*};

#[allow(clippy::upper_case_acronyms)]
pub struct QRCodeData {
    pub size: i32,
    pub items: Vec<bool>,
}

impl<B: AsRef<[u8]>> From<B> for QRCodeData {
    fn from(data: B) -> Self {
        let code = qrencode::QrCode::new(data).unwrap();
        let items = code
            .to_colors()
            .iter()
            .map(|color| matches!(color, qrencode::types::Color::Dark))
            .collect::<Vec<bool>>();

        let size = code.width() as i32;
        Self { size, items }
    }
}

mod imp {
    use std::cell::RefCell;

    use super::*;

    #[allow(clippy::upper_case_acronyms)]
    #[derive(Default)]
    pub struct QRCodePaintable {
        pub qrcode: RefCell<Option<QRCodeData>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for QRCodePaintable {
        const NAME: &'static str = "QRCodePaintable";
        type Type = super::QRCodePaintable;
        type Interfaces = (gdk::Paintable,);
    }

    impl ObjectImpl for QRCodePaintable {}
    impl PaintableImpl for QRCodePaintable {
        fn snapshot(&self, snapshot: &gdk::Snapshot, width: f64, height: f64) {
            if let Some(ref qrcode) = *self.qrcode.borrow() {
                let padding_squares = 3.max(qrcode.size / 10);
                let square_height = height as f32 / (qrcode.size + 2 * padding_squares) as f32;
                let square_width = width as f32 / (qrcode.size + 2 * padding_squares) as f32;
                let padding = square_height * padding_squares as f32;

                let rect = graphene::Rect::new(0.0, 0.0, width as f32, height as f32);
                snapshot.append_color(&gdk::RGBA::WHITE, &rect);

                let inner_rect = graphene::Rect::new(
                    padding,
                    padding,
                    square_width * qrcode.size as f32,
                    square_height * qrcode.size as f32,
                );

                let texture = texture(qrcode);
                snapshot.append_scaled_texture(&texture, gsk::ScalingFilter::Nearest, &inner_rect);
            }
        }
    }
}

glib::wrapper! {
    pub struct QRCodePaintable(ObjectSubclass<imp::QRCodePaintable>)
        @implements gdk::Paintable;
}

impl QRCodePaintable {
    pub fn set_qrcode(&self, qrcode: QRCodeData) {
        self.imp().qrcode.replace(Some(qrcode));
        self.invalidate_contents();
    }
}

impl Default for QRCodePaintable {
    fn default() -> Self {
        glib::Object::new()
    }
}

fn texture(qrcode: &QRCodeData) -> gdk::Texture {
    let size = qrcode.size;

    const G8_SIZE: usize = 1;
    const WHITE: u8 = 0xff; // #ffffff
    const BLACK: u8 = 0x24; // #242424

    let bytes: Vec<u8> = qrcode
        .items
        .iter()
        .map(|is_black| if *is_black { BLACK } else { WHITE })
        .collect();
    let bytes = glib::Bytes::from_owned(bytes);
    let stride = G8_SIZE * size as usize;

    gdk::MemoryTexture::new(size, size, gdk::MemoryFormat::G8, &bytes, stride).upcast()
}
