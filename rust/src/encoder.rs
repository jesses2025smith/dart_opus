use std::ffi::c_int;

use opus_rs::{Application, Channels, Encoder};

use crate::{
    error::OpusError,
    utils::{ffi_exec, invalid_input},
};

/// 创建新的 Opus 编码器
///
/// # 参数
///
/// * `channels` - 声道数：1 表示单声道（Mono），2 表示立体声（Stereo），其他值默认为单声道
/// * `sample_rate` - 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
/// * `application` - 应用模式：
///   - `1` = Voip（语音通话，低延迟优化）
///   - `2` = Audio（音频流，高质量优化）
///   - `3` = LowDelay（低延迟模式）
///   - 其他值默认为 Voip
/// * `result` - 输出参数，用于接收创建的编码器指针
/// * `error` - 可选的错误输出参数
///
/// # 返回值
///
/// * `0` - 成功
/// * 负数 - 错误代码（错误详情在 `error` 参数中）
///
/// # 安全性
///
/// 调用者负责在不再需要时调用 `free_encoder` 释放返回的编码器。
///
/// # 示例
///
/// ```c
/// Encoder *encoder = NULL;
/// OpusError error = {0, NULL};
/// int res = new_encoder(1, 16000, 1, &encoder, &error);
/// if (res == 0) {
///     // 使用编码器...
///     free_encoder(encoder);
/// }
/// ```
#[no_mangle]
pub extern "C" fn new_encoder(
    channels: u32,
    sample_rate: u32,
    application: u32,
    result: *mut *mut Encoder,
    error: *mut OpusError,
) -> c_int {
    if result.is_null() {
        return invalid_input(error);
    }

    let channels = match channels {
        1 => Channels::Mono,
        2 => Channels::Stereo,
        _ => Channels::Mono,
    };
    let mode = match application {
        1 => Application::Voip,
        2 => Application::Audio,
        3 => Application::LowDelay,
        _ => Application::Voip,
    };

    ffi_exec(error, || {
        let encoder = Encoder::new(sample_rate, channels, mode)?;
        unsafe {
            *result = Box::into_raw(Box::new(encoder));
        }

        Ok(())
    })
}

/// 将 PCM 样本编码为 Opus 数据包（16 位整数输入）
///
/// # 参数
///
/// * `encoder` - 之前通过 `new_encoder` 创建的编码器实例
/// * `input` - 指向 PCM 样本数据的指针（16 位有符号整数）
/// * `input_size` - 输入样本的数量（不是字节数）。对于单声道，这是样本数；对于立体声，这是样本对的数量
/// * `output` - 输出缓冲区，用于存储编码后的 Opus 数据包
/// * `output_size` - 输出缓冲区的容量（字节数）。建议至少 4000 字节
/// * `encoded_size` - 输出参数，编码后实际产生的字节数
/// * `error` - 可选的错误输出参数
///
/// # 返回值
///
/// * `0` - 成功
/// * 负数 - 错误代码（错误详情在 `error` 参数中）
///
/// # 注意事项
///
/// * `input_size` 是样本数，不是字节数。对于 16 位 PCM，每个样本占 2 字节
/// * 输入样本格式为 16 位有符号整数（i16），小端序
/// * 典型的帧大小：20ms 在 16kHz 采样率下 = 320 个样本
/// * 输出缓冲区应该足够大，Opus 数据包最大约为 4000 字节
///
/// # 示例
///
/// ```c
/// int16_t pcm_samples[320]; // 20ms @ 16kHz, 单声道
/// uint8_t opus_packet[4000];
/// size_t encoded_size = 0;
/// OpusError error = {0, NULL};
///
/// int res = encode(encoder, pcm_samples, 320, opus_packet, 4000, &encoded_size, &error);
/// if (res == 0) {
///     // 使用编码后的数据包...
/// }
/// ```
#[no_mangle]
pub extern "C" fn encode(
    encoder: *mut Encoder,
    input: *const i16,
    input_size: u32,
    output: *mut u8,
    output_size: u32,
    encoded_size: *mut usize,
    error: *mut OpusError,
) -> c_int {
    if encoder.is_null() || input.is_null() || output.is_null() || encoded_size.is_null() {
        return invalid_input(error);
    }

    ffi_exec(error, || {
        let encoder = unsafe { &mut *encoder };
        let input = unsafe { std::slice::from_raw_parts(input, input_size as usize) };
        let output = unsafe { std::slice::from_raw_parts_mut(output, output_size as usize) };
        let size = encoder.encode(input, output)?;
        unsafe {
            (*encoded_size) = size;
        }

        Ok(())
    })
}

/// 将 PCM 样本编码为 Opus 数据包（32 位浮点数输入）
///
/// # 参数
///
/// * `encoder` - 之前通过 `new_encoder` 创建的编码器实例
/// * `input` - 指向 PCM 样本数据的指针（32 位浮点数）
/// * `input_size` - 输入样本的数量（不是字节数）
/// * `output` - 输出缓冲区，用于存储编码后的 Opus 数据包
/// * `output_size` - 输出缓冲区的容量（字节数）
/// * `result` - 输出参数，编码后实际产生的字节数
/// * `error` - 可选的错误输出参数
///
/// # 返回值
///
/// * `0` - 成功
/// * 负数 - 错误代码（错误详情在 `error` 参数中）
///
/// # 注意事项
///
/// * 浮点样本的范围通常在 [-1.0, 1.0] 之间
/// * 此函数与 `encode` 功能相同，但输入格式为浮点数，适合需要高精度处理的场景
/// * `input_size` 是样本数，不是字节数
///
/// # 示例
///
/// ```c
/// float pcm_samples[320]; // 20ms @ 16kHz, 单声道
/// uint8_t opus_packet[4000];
/// size_t encoded_size = 0;
/// OpusError error = {0, NULL};
///
/// int res = encode_float(encoder, pcm_samples, 320, opus_packet, 4000, &encoded_size, &error);
/// ```
#[no_mangle]
pub extern "C" fn encode_float(
    encoder: *mut Encoder,
    input: *const f32,
    input_size: u32,
    output: *mut u8,
    output_size: u32,
    result: *mut usize,
    error: *mut OpusError,
) -> c_int {
    if encoder.is_null() || input.is_null() || output.is_null() || result.is_null() {
        return invalid_input(error);
    }

    ffi_exec(error, || {
        let encoder = unsafe { &mut *encoder };
        let input = unsafe { std::slice::from_raw_parts(input, input_size as usize) };
        let output = unsafe { std::slice::from_raw_parts_mut(output, output_size as usize) };
        let size = encoder.encode_float(input, output)?;
        unsafe {
            (*result) = size;
        }

        Ok(())
    })
}

/// 释放 Opus 编码器实例
///
/// # 参数
///
/// * `encoder` - 通过 `new_encoder` 创建的编码器指针
///
/// # 安全性
///
/// * 如果 `encoder` 为 `NULL`，函数不会执行任何操作
/// * 释放后，`encoder` 指针将不再有效，不应再次使用
/// * 每个通过 `new_encoder` 创建的编码器必须且只能调用一次此函数
///
/// # 示例
///
/// ```c
/// Encoder *encoder = NULL;
/// // ... 创建和使用编码器 ...
/// free_encoder(encoder);
/// encoder = NULL; // 防止重复释放
/// ```
#[no_mangle]
pub extern "C" fn free_encoder(encoder: *mut Encoder) {
    unsafe {
        if !encoder.is_null() {
            let _ = Box::from_raw(encoder);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::utils::invalid_input;
    use std::ptr;

    #[test]
    fn test_null_checks_encoder() {
        let expected_error = invalid_input(ptr::null_mut());
        let res = new_encoder(1, 48000, 1, ptr::null_mut(), ptr::null_mut());
        assert_eq!(res, expected_error);

        let res = encode(
            ptr::null_mut(),
            ptr::null(),
            0,
            ptr::null_mut(),
            0,
            ptr::null_mut(),
            ptr::null_mut(),
        );
        assert_eq!(res, expected_error);
    }
}
