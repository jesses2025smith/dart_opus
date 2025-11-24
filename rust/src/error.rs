use opus_rs::Error;
use std::ffi::{c_char, c_int, CString};

use crate::utils::free_c_string;

/// Opus 错误结构体，用于在 C 和 Rust 之间传递错误信息
///
/// # 内存管理
///
/// **重要**：`message` 字段是由 Rust 分配的 C 字符串，需要手动释放。
///
/// - **在 Rust 代码中**：如果 `OpusError` 在 Rust 栈上分配，`Drop` trait 会自动释放 `message`
/// - **在 C 代码中**：如果 `OpusError` 在 C 栈上分配，必须手动调用 `free_c_string(&error.message)` 来释放 `message`
///
/// # 示例（C 代码）
///
/// ```c
/// OpusError error = {0, NULL};
/// int res = new_decoder(1, 16000, &decoder, &error);
/// if (res < 0 && error.message != NULL) {
///     printf("Error: %s\n", error.message);
///     free_c_string(&error.message);  // 必须手动释放
/// }
/// ```
#[repr(C)]
pub struct OpusError {
    pub code: c_int,
    pub message: *mut c_char,
}

impl Drop for OpusError {
    /// 自动释放 `message` 字段（仅对 Rust 代码中分配的 `OpusError` 有效）
    ///
    /// 注意：对于 C 代码中在栈上分配的 `OpusError`，此 `Drop` 不会被调用，
    /// C 代码必须手动调用 `free_c_string(&error.message)` 来释放内存。
    fn drop(&mut self) {
        if !self.message.is_null() {
            free_c_string(&mut self.message);
        }
    }
}

impl OpusError {
    pub fn fill(out: *mut OpusError, origin: Error) -> c_int {
        let mut err: OpusError = origin.into();
        unsafe {
            if !out.is_null() {
                (*out).code = err.code;
                (*out).message = err.message;
                err.message = std::ptr::null_mut();
            }
        }

        err.code
    }
}

impl From<Error> for OpusError {
    fn from(e: Error) -> Self {
        let message = CString::new(e.description()).unwrap();
        Self {
            code: e.code() as c_int,
            message: message.into_raw(),
        }
    }
}
