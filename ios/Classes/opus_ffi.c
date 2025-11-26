// Placeholder translation unit to ensure the target builds correctly.
// Actual implementation lives in the Rust static library built during
// the CocoaPods script phase. We reference each exported symbol here so
// the linker keeps them when the pod is compiled into the host app.
#include "../../src/opus_ffi.h"

static const void *const kOpusFfiSymbols[] __attribute__((used)) = {
    (const void *)&new_decoder,
    (const void *)&decode,
    (const void *)&decode_float,
    (const void *)&free_decoder,
    (const void *)&new_encoder,
    (const void *)&encode,
    (const void *)&encode_float,
    (const void *)&free_encoder,
    (const void *)&free_c_string,
    (const void *)&free_opus_error,
};

void opus_ffi_force_link(void) {
  (void)kOpusFfiSymbols;
}
