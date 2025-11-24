/* Opus FFI Bindings for Rust */

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Opus 错误结构体，用于在 C 和 Rust 之间传递错误信息
 *
 * # 内存管理
 *
 * **重要**：`message` 字段是由 Rust 分配的 C 字符串，需要手动释放。
 *
 * - **在 Rust 代码中**：如果 `OpusError` 在 Rust 栈上分配，`Drop` trait 会自动释放 `message`
 * - **在 C 代码中**：如果 `OpusError` 在 C 栈上分配，必须手动调用 `free_c_string(&error.message)` 来释放 `message`
 *
 * # 示例（C 代码）
 *
 * ```c
 * OpusError error = {0, NULL};
 * int res = new_decoder(1, 16000, &decoder, &error);
 * if (res < 0 && error.message != NULL) {
 *     printf("Error: %s\n", error.message);
 *     free_c_string(&error.message);  // 必须手动释放
 * }
 * ```
 */
typedef struct OpusError {
  int code;
  char *message;
} OpusError;

/**
 * Opus 解码器不透明指针类型
 */
typedef struct Decoder Decoder;

/**
 * Opus 编码器不透明指针类型
 */
typedef struct Encoder Encoder;

/**
 * 创建新的 Opus 解码器
 *
 * # 参数
 *
 * * `channels` - 声道数：1 表示单声道（Mono），2 表示立体声（Stereo），其他值默认为单声道
 * * `sample_rate` - 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
 * * `result` - 输出参数，用于接收创建的解码器指针。如果函数成功返回，此指针将被设置为有效的解码器实例
 * * `error` - 可选的错误输出参数。如果函数失败，错误信息将被填充到此结构中
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 安全性
 *
 * 调用者负责在不再需要时调用 `free_decoder` 释放返回的解码器。
 *
 * # 示例
 *
 * ```c
 * Decoder *decoder = NULL;
 * OpusError error = {0, NULL};
 * int res = new_decoder(1, 16000, &decoder, &error);
 * if (res == 0) {
 *     // 使用解码器...
 *     free_decoder(decoder);
 * }
 * ```
 */
int new_decoder(uint32_t channels,
                uint32_t sample_rate,
                Decoder **result,
                struct OpusError *error);

/**
 * 解码 Opus 音频数据包为 PCM 样本（16 位整数）
 *
 * # 参数
 *
 * * `decoder` - 之前通过 `new_decoder` 创建的解码器实例
 * * `input` - 指向 Opus 编码数据包的指针
 * * `input_size` - 输入数据包的大小（字节数）
 * * `output` - 输出缓冲区，用于存储解码后的 PCM 样本
 * * `output_size` - 输出缓冲区的容量（样本数，不是字节数）
 * * `fec` - 前向纠错（Forward Error Correction）标志。如果为 `true`，解码器将尝试使用前一个数据包来恢复丢失的数据
 * * `decoded_size` - 输出参数，解码后实际产生的样本数
 * * `error` - 可选的错误输出参数
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 注意事项
 *
 * * `output_size` 应该足够大以容纳解码后的数据。对于 16kHz 采样率，20ms 的帧需要至少 320 个样本
 * * 解码后的样本格式为 16 位有符号整数（i16），小端序
 * * 如果 `fec` 为 `true` 且前一个数据包丢失，解码器将尝试使用前向纠错来恢复数据
 *
 * # 示例
 *
 * ```c
 * uint8_t opus_packet[4000];
 * int16_t pcm_buffer[320];
 * size_t decoded_samples = 0;
 * OpusError error = {0, NULL};
 *
 * int res = decode(decoder, opus_packet, packet_size, pcm_buffer, 320, false, &decoded_samples, &error);
 * if (res == 0) {
 *     // 使用解码后的 PCM 数据...
 * }
 * ```
 */
int decode(Decoder *decoder,
           const uint8_t *input,
           uint32_t input_size,
           int16_t *output,
           uint32_t output_size,
           bool fec,
           uintptr_t *decoded_size,
           struct OpusError *error);

/**
 * 解码 Opus 音频数据包为 PCM 样本（32 位浮点数）
 *
 * # 参数
 *
 * * `decoder` - 之前通过 `new_decoder` 创建的解码器实例
 * * `input` - 指向 Opus 编码数据包的指针
 * * `input_size` - 输入数据包的大小（字节数）
 * * `output` - 输出缓冲区，用于存储解码后的浮点 PCM 样本
 * * `output_size` - 输出缓冲区的容量（样本数，不是字节数）
 * * `fec` - 前向纠错（Forward Error Correction）标志
 * * `result` - 输出参数，解码后实际产生的样本数
 * * `error` - 可选的错误输出参数
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 注意事项
 *
 * * 浮点样本的范围通常在 [-1.0, 1.0] 之间
 * * 此函数与 `decode` 功能相同，但输出格式为浮点数，适合需要高精度处理的场景
 *
 * # 示例
 *
 * ```c
 * uint8_t opus_packet[4000];
 * float pcm_buffer[320];
 * size_t decoded_samples = 0;
 * OpusError error = {0, NULL};
 *
 * int res = decode_float(decoder, opus_packet, packet_size, pcm_buffer, 320, false, &decoded_samples, &error);
 * ```
 */
int decode_float(Decoder *decoder,
                 const uint8_t *input,
                 uint32_t input_size,
                 float *output,
                 uint32_t output_size,
                 bool fec,
                 uintptr_t *result,
                 struct OpusError *error);

/**
 * 释放 Opus 解码器实例
 *
 * # 参数
 *
 * * `decoder` - 通过 `new_decoder` 创建的解码器指针
 *
 * # 安全性
 *
 * * 如果 `decoder` 为 `NULL`，函数不会执行任何操作
 * * 释放后，`decoder` 指针将不再有效，不应再次使用
 * * 每个通过 `new_decoder` 创建的解码器必须且只能调用一次此函数
 *
 * # 示例
 *
 * ```c
 * Decoder *decoder = NULL;
 * // ... 创建和使用解码器 ...
 * free_decoder(decoder);
 * decoder = NULL; // 防止重复释放
 * ```
 */
void free_decoder(Decoder *decoder);

/**
 * 创建新的 Opus 编码器
 *
 * # 参数
 *
 * * `channels` - 声道数：1 表示单声道（Mono），2 表示立体声（Stereo），其他值默认为单声道
 * * `sample_rate` - 采样率（Hz），支持的采样率：8000, 12000, 16000, 24000, 48000
 * * `application` - 应用模式：
 *   - `1` = Voip（语音通话，低延迟优化）
 *   - `2` = Audio（音频流，高质量优化）
 *   - `3` = LowDelay（低延迟模式）
 *   - 其他值默认为 Voip
 * * `result` - 输出参数，用于接收创建的编码器指针
 * * `error` - 可选的错误输出参数
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 安全性
 *
 * 调用者负责在不再需要时调用 `free_encoder` 释放返回的编码器。
 *
 * # 示例
 *
 * ```c
 * Encoder *encoder = NULL;
 * OpusError error = {0, NULL};
 * int res = new_encoder(1, 16000, 1, &encoder, &error);
 * if (res == 0) {
 *     // 使用编码器...
 *     free_encoder(encoder);
 * }
 * ```
 */
int new_encoder(uint32_t channels,
                uint32_t sample_rate,
                uint32_t application,
                Encoder **result,
                struct OpusError *error);

/**
 * 将 PCM 样本编码为 Opus 数据包（16 位整数输入）
 *
 * # 参数
 *
 * * `encoder` - 之前通过 `new_encoder` 创建的编码器实例
 * * `input` - 指向 PCM 样本数据的指针（16 位有符号整数）
 * * `input_size` - 输入样本的数量（不是字节数）。对于单声道，这是样本数；对于立体声，这是样本对的数量
 * * `output` - 输出缓冲区，用于存储编码后的 Opus 数据包
 * * `output_size` - 输出缓冲区的容量（字节数）。建议至少 4000 字节
 * * `encoded_size` - 输出参数，编码后实际产生的字节数
 * * `error` - 可选的错误输出参数
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 注意事项
 *
 * * `input_size` 是样本数，不是字节数。对于 16 位 PCM，每个样本占 2 字节
 * * 输入样本格式为 16 位有符号整数（i16），小端序
 * * 典型的帧大小：20ms 在 16kHz 采样率下 = 320 个样本
 * * 输出缓冲区应该足够大，Opus 数据包最大约为 4000 字节
 *
 * # 示例
 *
 * ```c
 * int16_t pcm_samples[320]; // 20ms @ 16kHz, 单声道
 * uint8_t opus_packet[4000];
 * size_t encoded_size = 0;
 * OpusError error = {0, NULL};
 *
 * int res = encode(encoder, pcm_samples, 320, opus_packet, 4000, &encoded_size, &error);
 * if (res == 0) {
 *     // 使用编码后的数据包...
 * }
 * ```
 */
int encode(Encoder *encoder,
           const int16_t *input,
           uint32_t input_size,
           uint8_t *output,
           uint32_t output_size,
           uintptr_t *encoded_size,
           struct OpusError *error);

/**
 * 将 PCM 样本编码为 Opus 数据包（32 位浮点数输入）
 *
 * # 参数
 *
 * * `encoder` - 之前通过 `new_encoder` 创建的编码器实例
 * * `input` - 指向 PCM 样本数据的指针（32 位浮点数）
 * * `input_size` - 输入样本的数量（不是字节数）
 * * `output` - 输出缓冲区，用于存储编码后的 Opus 数据包
 * * `output_size` - 输出缓冲区的容量（字节数）
 * * `result` - 输出参数，编码后实际产生的字节数
 * * `error` - 可选的错误输出参数
 *
 * # 返回值
 *
 * * `0` - 成功
 * * 负数 - 错误代码（错误详情在 `error` 参数中）
 *
 * # 注意事项
 *
 * * 浮点样本的范围通常在 [-1.0, 1.0] 之间
 * * 此函数与 `encode` 功能相同，但输入格式为浮点数，适合需要高精度处理的场景
 * * `input_size` 是样本数，不是字节数
 *
 * # 示例
 *
 * ```c
 * float pcm_samples[320]; // 20ms @ 16kHz, 单声道
 * uint8_t opus_packet[4000];
 * size_t encoded_size = 0;
 * OpusError error = {0, NULL};
 *
 * int res = encode_float(encoder, pcm_samples, 320, opus_packet, 4000, &encoded_size, &error);
 * ```
 */
int encode_float(Encoder *encoder,
                 const float *input,
                 uint32_t input_size,
                 uint8_t *output,
                 uint32_t output_size,
                 uintptr_t *result,
                 struct OpusError *error);

/**
 * 释放 Opus 编码器实例
 *
 * # 参数
 *
 * * `encoder` - 通过 `new_encoder` 创建的编码器指针
 *
 * # 安全性
 *
 * * 如果 `encoder` 为 `NULL`，函数不会执行任何操作
 * * 释放后，`encoder` 指针将不再有效，不应再次使用
 * * 每个通过 `new_encoder` 创建的编码器必须且只能调用一次此函数
 *
 * # 示例
 *
 * ```c
 * Encoder *encoder = NULL;
 * // ... 创建和使用编码器 ...
 * free_encoder(encoder);
 * encoder = NULL; // 防止重复释放
 * ```
 */
void free_encoder(Encoder *encoder);

/**
 * 释放由 Rust 分配的 C 字符串
 *
 * # 参数
 *
 * * `p` - 指向 C 字符串指针的指针（`char**`）。函数会释放字符串并将指针设置为 `NULL`
 *
 * # 安全性
 *
 * * 如果 `p` 为 `NULL` 或 `*p` 为 `NULL`，函数不会执行任何操作
 * * 只能释放由 Rust 代码分配的 C 字符串（通过 `CString::into_raw()` 创建）
 * * 释放后，字符串指针将被设置为 `NULL`，防止重复释放
 *
 * # 示例
 *
 * ```c
 * char *message = NULL;
 * // ... 从 Rust 函数获取字符串 ...
 * free_c_string(&message);
 * // message 现在为 NULL
 * ```
 */
void free_c_string(char **p);

/**
 * 释放堆上分配的 OpusError 结构
 *
 * # 参数
 *
 * * `e` - 指向堆上分配的 `OpusError` 结构的指针
 *
 * # 安全性
 *
 * * 如果 `e` 为 `NULL`，函数不会执行任何操作
 * * 只能释放通过 `Box` 在堆上分配的 `OpusError`
 * * 栈上分配的 `OpusError` 不需要调用此函数，它们会自动释放
 * * 释放后，指针将不再有效，不应再次使用
 *
 * # 注意事项
 *
 * 大多数情况下，`OpusError` 是在栈上分配的，不需要调用此函数。
 * 只有在特殊情况下（如在堆上分配）才需要调用此函数。
 *
 * # 示例
 *
 * ```c
 * OpusError *error = malloc(sizeof(OpusError));
 * // ... 使用 error ...
 * free_opus_error(error);
 * ```
 */
void free_opus_error(struct OpusError *e);
