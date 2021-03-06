// Oleg Andreev <oleganza@gmail.com>

#import "NSData+DMCData.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (DMC)



#pragma mark - Hash Functions


- (NSData*) SHA1 { return DMCSHA1(self); }
- (NSData*) SHA256 { return DMCSHA256(self); }
- (NSData*) DMCHash256 { return DMCHash256(self); }

#if DMCDataRequiresOpenSSL
- (NSData*) RIPEMD160 { return DMCRIPEMD160(self); }
- (NSData*) DMCHash160 { return DMCHash160(self); }
#endif




#pragma mark - Formatting


- (NSString*) hex {
    return DMCHexFromData(self);
}

- (NSString*) uppercaseHex {
    return DMCUppercaseHexFromData(self);
}

- (NSString*) hexString {
    return DMCHexFromData(self);
}

- (NSString*) hexUppercaseString {
    return DMCUppercaseHexFromData(self);
}





#pragma mark - Encryption / Decryption




+ (NSMutableData*) encryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector {
    return [self cryptData:data key:key iv:initializationVector operation:kCCEncrypt];
}

+ (NSMutableData*) decryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector {
    return [self cryptData:data key:key iv:initializationVector operation:kCCDecrypt];
}


+ (NSMutableData*) cryptData:(NSData*)data key:(NSData*)key iv:(NSData*)iv operation:(CCOperation)operation {
    if (!data || !key) return nil;
    
    int blockSize = kCCBlockSizeAES128;
    int encryptedDataCapacity = (int)(data.length / blockSize + 1) * blockSize;
    NSMutableData* encryptedData = [[NSMutableData alloc] initWithLength:encryptedDataCapacity];
    
    // Treat empty IV as nil
    if (iv.length == 0) {
        iv = nil;
    }
    
    // If IV is supplied, validate it.
    if (iv) {
        if (iv.length == blockSize) {
            // perfect.
        } else if (iv.length > blockSize) {
            // IV is bigger than the block size. CCCrypt will take only the first 16 bytes.
        } else {
            // IV is smaller than needed. This should not happen. It's better to crash than to leak something.
            @throw [NSException exceptionWithName:@"NSData+DMC IV is invalid"
                                           reason:[NSString stringWithFormat:@"Invalid size of IV: %d", (int)iv.length]
                                         userInfo:nil];
        }
    }
    
    size_t dataOutMoved = 0;
    CCCryptorStatus cryptstatus = CCCrypt(
                                          operation,                   // CCOperation op,         /* kCCEncrypt, kCCDecrypt */
                                          kCCAlgorithmAES,             // CCAlgorithm alg,        /* kCCAlgorithmAES128, etc. */
                                          kCCOptionPKCS7Padding,       // CCOptions options,      /* kCCOptionPKCS7Padding, etc. */
                                          key.bytes,                   // const void *key,
                                          key.length,                  // size_t keyLength,
                                          iv ? iv.bytes : NULL,        // const void *iv,         /* optional initialization vector */
                                          data.bytes,                  // const void *dataIn,     /* optional per op and alg */
                                          data.length,                 // size_t dataInLength,
                                          encryptedData.mutableBytes,  // void *dataOut,          /* data RETURNED here */
                                          encryptedData.length,        // size_t dataOutAvailable,
                                          &dataOutMoved                // size_t *dataOutMoved
                                          );
    
    if (cryptstatus == kCCSuccess) {
        // Resize the result key to the correct size.
        encryptedData.length = dataOutMoved;
        return encryptedData;
    } else {
        //kCCSuccess          = 0,
        //kCCParamError       = -4300,
        //kCCBufferTooSmall   = -4301,
        //kCCMemoryFailure    = -4302,
        //kCCAlignmentError   = -4303,
        //kCCDecodeError      = -4304,
        //kCCUnimplemented    = -4305,
        //kCCOverflow         = -4306
        @throw [NSException exceptionWithName:@"NSData+DMC CCCrypt failed"
                                       reason:[NSString stringWithFormat:@"error: %d", cryptstatus] userInfo:nil];
        return nil;
    }
}


@end
