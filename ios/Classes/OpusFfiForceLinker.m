#import <Foundation/Foundation.h>

/// Declared in `opus_ffi.c`.
extern void opus_ffi_force_link(void);

@interface OpusFfiForceLinker : NSObject
@end

@implementation OpusFfiForceLinker

+ (void)load {
  opus_ffi_force_link();
}

@end

