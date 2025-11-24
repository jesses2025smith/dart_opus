use std::env;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_language(cbindgen::Language::C)
        .with_header("/* Opus FFI Bindings for Rust */")
        .with_include_guard("OPUS_FFI_H")
        .with_after_include(    r#"
/**
 * Opus 解码器不透明指针类型
 */
typedef struct Decoder Decoder;
/**
 * Opus 编码器不透明指针类型
 */
typedef struct Encoder Encoder;"#)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file("include/opus_ffi.h");
}
