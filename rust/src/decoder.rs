use std::ffi::c_int;

use opus_rs::{Channels, Decoder};

use crate::{
    error::OpusError,
    utils::{ffi_exec, invalid_input},
};

/// 创建新的 Opus 解码器
///
/// # 参数
///
/// * `channels` - 声道数：1 表示单声道（Mono），2 表示立体声（Stereo），其他值默认为单声道
/// * `sample_rate` - 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
/// * `result` - 输出参数，用于接收创建的解码器指针。如果函数成功返回，此指针将被设置为有效的解码器实例
/// * `error` - 可选的错误输出参数。如果函数失败，错误信息将被填充到此结构中
///
/// # 返回值
///
/// * `0` - 成功
/// * 负数 - 错误代码（错误详情在 `error` 参数中）
///
/// # 安全性
///
/// 调用者负责在不再需要时调用 `free_decoder` 释放返回的解码器。
///
/// # 示例
///
/// ```c
/// Decoder *decoder = NULL;
/// OpusError error = {0, NULL};
/// int res = new_decoder(1, 16000, &decoder, &error);
/// if (res == 0) {
///     // 使用解码器...
///     free_decoder(decoder);
/// }
/// ```
#[no_mangle]
pub extern "C" fn new_decoder(
    channels: u32,
    sample_rate: u32,
    result: *mut *mut Decoder,
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

    ffi_exec(error, || {
        let decoder = Decoder::new(sample_rate, channels)?;
        unsafe {
            *result = Box::into_raw(Box::new(decoder));
        }

        Ok(())
    })
}

/// 解码 Opus 音频数据包为 PCM 样本（16 位整数）
///
/// # 参数
///
/// * `decoder` - 之前通过 `new_decoder` 创建的解码器实例
/// * `input` - 指向 Opus 编码数据包的指针
/// * `input_size` - 输入数据包的大小（字节数）
/// * `output` - 输出缓冲区，用于存储解码后的 PCM 样本
/// * `output_size` - 输出缓冲区的容量（样本数，不是字节数）
/// * `fec` - 前向纠错（Forward Error Correction）标志。如果为 `true`，解码器将尝试使用前一个数据包来恢复丢失的数据
/// * `decoded_size` - 输出参数，解码后实际产生的样本数
/// * `error` - 可选的错误输出参数
///
/// # 返回值
///
/// * `0` - 成功
/// * 负数 - 错误代码（错误详情在 `error` 参数中）
///
/// # 注意事项
///
/// * `output_size` 应该足够大以容纳解码后的数据。对于 16kHz 采样率，20ms 的帧需要至少 320 个样本
/// * 解码后的样本格式为 16 位有符号整数（i16），小端序
/// * 如果 `fec` 为 `true` 且前一个数据包丢失，解码器将尝试使用前向纠错来恢复数据
///
/// # 示例
///
/// ```c
/// uint8_t opus_packet[4000];
/// int16_t pcm_buffer[320];
/// size_t decoded_samples = 0;
/// OpusError error = {0, NULL};
///
/// int res = decode(decoder, opus_packet, packet_size, pcm_buffer, 320, false, &decoded_samples, &error);
/// if (res == 0) {
///     // 使用解码后的 PCM 数据...
/// }
/// ```
#[no_mangle]
pub extern "C" fn decode(
    decoder: *mut Decoder,
    input: *const u8,
    input_size: u32,
    output: *mut i16,
    output_size: u32,
    fec: bool,
    decoded_size: *mut usize,
    error: *mut OpusError,
) -> c_int {
    if decoder.is_null() || input.is_null() || output.is_null() || decoded_size.is_null() {
        return invalid_input(error);
    }

    ffi_exec(error, || {
        let decoder = unsafe { &mut *decoder };
        let input = unsafe { std::slice::from_raw_parts(input, input_size as usize) };
        let output = unsafe { std::slice::from_raw_parts_mut(output, output_size as usize) };
        let size = decoder.decode(input, output, fec)?;
        unsafe {
            (*decoded_size) = size;
        }

        Ok(())
    })
}

/// 解码 Opus 音频数据包为 PCM 样本（32 位浮点数）
///
/// # 参数
///
/// * `decoder` - 之前通过 `new_decoder` 创建的解码器实例
/// * `input` - 指向 Opus 编码数据包的指针
/// * `input_size` - 输入数据包的大小（字节数）
/// * `output` - 输出缓冲区，用于存储解码后的浮点 PCM 样本
/// * `output_size` - 输出缓冲区的容量（样本数，不是字节数）
/// * `fec` - 前向纠错（Forward Error Correction）标志
/// * `result` - 输出参数，解码后实际产生的样本数
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
/// * 此函数与 `decode` 功能相同，但输出格式为浮点数，适合需要高精度处理的场景
///
/// # 示例
///
/// ```c
/// uint8_t opus_packet[4000];
/// float pcm_buffer[320];
/// size_t decoded_samples = 0;
/// OpusError error = {0, NULL};
///
/// int res = decode_float(decoder, opus_packet, packet_size, pcm_buffer, 320, false, &decoded_samples, &error);
/// ```
#[no_mangle]
pub extern "C" fn decode_float(
    decoder: *mut Decoder,
    input: *const u8,
    input_size: u32,
    output: *mut f32,
    output_size: u32,
    fec: bool,
    result: *mut usize,
    error: *mut OpusError,
) -> c_int {
    if decoder.is_null() || input.is_null() || output.is_null() || result.is_null() {
        return invalid_input(error);
    }

    ffi_exec(error, || {
        let decoder = unsafe { &mut *decoder };
        let input = unsafe { std::slice::from_raw_parts(input, input_size as usize) };
        let output = unsafe { std::slice::from_raw_parts_mut(output, output_size as usize) };
        let size = decoder.decode_float(input, output, fec)?;
        unsafe {
            (*result) = size;
        }

        Ok(())
    })
}

/// 释放 Opus 解码器实例
///
/// # 参数
///
/// * `decoder` - 通过 `new_decoder` 创建的解码器指针
///
/// # 安全性
///
/// * 如果 `decoder` 为 `NULL`，函数不会执行任何操作
/// * 释放后，`decoder` 指针将不再有效，不应再次使用
/// * 每个通过 `new_decoder` 创建的解码器必须且只能调用一次此函数
///
/// # 示例
///
/// ```c
/// Decoder *decoder = NULL;
/// // ... 创建和使用解码器 ...
/// free_decoder(decoder);
/// decoder = NULL; // 防止重复释放
/// ```
#[no_mangle]
pub extern "C" fn free_decoder(decoder: *mut Decoder) {
    unsafe {
        if !decoder.is_null() {
            let _ = Box::from_raw(decoder);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ptr;

    #[test]
    fn test_null_checks_decoder() {
        let expected_error = invalid_input(ptr::null_mut());
        let res = new_decoder(1, 48000, ptr::null_mut(), ptr::null_mut());
        assert_eq!(res, expected_error);

        let res = decode(
            ptr::null_mut(),
            ptr::null(),
            0,
            ptr::null_mut(),
            0,
            false,
            ptr::null_mut(),
            ptr::null_mut(),
        );
        assert_eq!(res, expected_error);
    }
}
