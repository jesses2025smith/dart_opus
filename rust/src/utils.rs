use opus_rs::{Error, ErrorCode};

use crate::error::OpusError;
use std::ffi::{c_char, c_int, CString};

/// 释放由 Rust 分配的 C 字符串
///
/// # 参数
///
/// * `p` - 指向 C 字符串指针的指针（`char**`）。函数会释放字符串并将指针设置为 `NULL`
///
/// # 安全性
///
/// * 如果 `p` 为 `NULL` 或 `*p` 为 `NULL`，函数不会执行任何操作
/// * 只能释放由 Rust 代码分配的 C 字符串（通过 `CString::into_raw()` 创建）
/// * 释放后，字符串指针将被设置为 `NULL`，防止重复释放
///
/// # 示例
///
/// ```c
/// char *message = NULL;
/// // ... 从 Rust 函数获取字符串 ...
/// free_c_string(&message);
/// // message 现在为 NULL
/// ```
#[no_mangle]
pub extern "C" fn free_c_string(p: *mut *mut c_char) {
    unsafe {
        if !p.is_null() {
            if !(*p).is_null() {
                let _ = CString::from_raw(*p);
                *p = std::ptr::null_mut();
            }
        }
    }
}

/// 释放堆上分配的 OpusError 结构
///
/// # 参数
///
/// * `e` - 指向堆上分配的 `OpusError` 结构的指针
///
/// # 安全性
///
/// * 如果 `e` 为 `NULL`，函数不会执行任何操作
/// * 只能释放通过 `Box` 在堆上分配的 `OpusError`
/// * 栈上分配的 `OpusError` 不需要调用此函数，它们会自动释放
/// * 释放后，指针将不再有效，不应再次使用
///
/// # 注意事项
///
/// 大多数情况下，`OpusError` 是在栈上分配的，不需要调用此函数。
/// 只有在特殊情况下（如在堆上分配）才需要调用此函数。
///
/// # 示例
///
/// ```c
/// OpusError *error = malloc(sizeof(OpusError));
/// // ... 使用 error ...
/// free_opus_error(error);
/// ```
#[no_mangle]
pub extern "C" fn free_opus_error(e: *mut OpusError) {
    if !e.is_null() {
        unsafe {
            // if !(*e).message.is_null() {
            //     free_c_string(&mut (*e).message);
            // }
            let _ = Box::from_raw(e);
        }
    }
}

pub(crate) fn invalid_input(error: *mut OpusError) -> c_int {
    let code = ErrorCode::Unknown as c_int - 1;
    if !error.is_null() {
        unsafe {
            (*error).code = code;
            (*error).message = CString::new("Invalid input").unwrap().into_raw();
        }
    }

    code
}

pub(crate) fn ffi_exec<F: FnOnce() -> Result<(), Error> + std::panic::UnwindSafe>(
    error: *mut OpusError,
    f: F,
) -> c_int {
    let result = std::panic::catch_unwind(f);
    match result {
        Ok(Ok(())) => 0,
        Ok(Err(e)) => OpusError::fill(error, e),
        Err(_) => {
            // Panic occurred
            // We can't easily get the panic message here safely across FFI without more work,
            // so we just return a generic error code for now.
            // In a real app we might want to log this or try to set the error message.
            let code = ErrorCode::Unknown as c_int - 2;
            if !error.is_null() {
                unsafe {
                    (*error).code = code; // Generic error
                    let msg = CString::new("Rust panic occurred").unwrap();
                    (*error).message = msg.into_raw();
                }
            }

            code
        }
    }
}
