// Oleg Andreev <oleganza@gmail.com>

#import "NS+DMCBase58.h"

// TODO.

@implementation NSString (DMCBase58)

- (NSMutableData*) dataFromBase58 { return DMCDataFromBase58(self); }
- (NSMutableData*) dataFromBase58Check { return DMCDataFromBase58Check(self); }
@end


@implementation NSMutableData (DMCBase58)

+ (NSMutableData*) dataFromBase58CString:(const char*)cstring {
    return DMCDataFromBase58CString(cstring);
}

+ (NSMutableData*) dataFromBase58CheckCString:(const char*)cstring {
    return DMCDataFromBase58CheckCString(cstring);
}

@end


@implementation NSData (DMCBase58)

- (char*) base58CString {
    return DMCBase58CStringWithData(self);
}

- (char*) base58CheckCString {
    return DMCBase58CheckCStringWithData(self);
}

- (NSString*) base58String {
    return DMCBase58StringWithData(self);
}

- (NSString*) base58CheckString {
    return DMCBase58CheckStringWithData(self);
}


@end
