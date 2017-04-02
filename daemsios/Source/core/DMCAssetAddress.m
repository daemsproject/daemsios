// 

#import "DMCAssetAddress.h"
#import "DMCData.h"
#import "DMCBase58.h"

@interface DMCAssetAddress ()
@property(nonatomic, readwrite) DMCAddress* daemsCoinAddress;
@end

// OpenAssets Address, e.g. akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy (corresponds to 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM)
@implementation DMCAssetAddress

#define DMCAssetAddressNamespace 0x13

+ (void) load {
    [DMCAddress registerAddressClass:self version:DMCAssetAddressNamespace];
}

+ (instancetype) addressWithDaemsCoinAddress:(DMCAddress*)DMCAddress {
    if (!DMCAddress) return nil;
    DMCAssetAddress* addr = [[self alloc] init];
    addr.daemsCoinAddress = DMCAddress;
    return addr;
}

+ (instancetype) addressWithString:(NSString*)string {
    NSMutableData* composedData = DMCDataFromBase58Check(string);
    uint8_t version = ((unsigned char*)composedData.bytes)[0];
    return [self addressWithComposedData:composedData cstring:[string cStringUsingEncoding:NSUTF8StringEncoding] version:version];
}

+ (instancetype) addressWithComposedData:(NSData*)composedData cstring:(const char*)cstring version:(uint8_t)version {
    if (!composedData) return nil;
    if (composedData.length < 2) return nil;

    if (version == DMCAssetAddressNamespace) { // same for testnet and mainnet
        DMCAddress* DMCAddr = [DMCAddress addressWithString:DMCBase58CheckStringWithData([composedData subdataWithRange:NSMakeRange(1, composedData.length - 1)])];
        return [self addressWithDaemsCoinAddress:DMCAddr];
    } else {
        return nil;
    }
}

- (NSMutableData*) dataForBase58Encoding {
    NSMutableData* data = [NSMutableData dataWithLength:1];
    char* buf = data.mutableBytes;
    buf[0] = DMCAssetAddressNamespace;
    [data appendData:[(DMCAssetAddress* /* cast only to expose the method that is defined in DMCAddress anyway */)self.daemsCoinAddress dataForBase58Encoding]];
    return data;
}

- (unsigned char) versionByte {
    return DMCAssetAddressNamespace;
}

- (BOOL) isTestnet {
    return self.daemsCoinAddress.isTestnet;
}

@end
