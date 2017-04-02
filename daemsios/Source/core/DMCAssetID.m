// 

#import "DMCAssetID.h"
#import "DMCAddressSubclass.h"

static const uint8_t DMCAssetIDVersionMainnet = 23; // "A" prefix
static const uint8_t DMCAssetIDVersionTestnet = 115;

@implementation DMCAssetID

+ (void) load {
    [DMCAddress registerAddressClass:self version:DMCAssetIDVersionMainnet];
    [DMCAddress registerAddressClass:self version:DMCAssetIDVersionTestnet];
}

#define DMCAssetIDLength 20

+ (instancetype) assetIDWithString:(NSString*)string {
    return [self addressWithString:string];
}

+ (instancetype) assetIDWithHash:(NSData*)data {
    if (!data) return nil;
    if (data.length != DMCAssetIDLength) {
        NSLog(@"+[DMCAssetID addressWithData] cannot init with hash %d bytes long", (int)data.length);
        return nil;
    }
    DMCAssetID* addr = [[self alloc] init];
    addr.data = [NSMutableData dataWithData:data];
    return addr;
}

+ (instancetype) addressWithComposedData:(NSData*)composedData cstring:(const char*)cstring version:(uint8_t)version {
    if (composedData.length != (1 + DMCAssetIDLength)) {
        NSLog(@"DMCAssetID: cannot init with %d bytes (need 20+1 bytes)", (int)composedData.length);
        return nil;
    }
    DMCAssetID* addr = [[self alloc] init];
    addr.data = [[NSMutableData alloc] initWithBytes:((const char*)composedData.bytes) + 1 length:composedData.length - 1];
    return addr;
}

- (NSMutableData*) dataForBase58Encoding {
    NSMutableData* data = [NSMutableData dataWithLength:1 + DMCAssetIDLength];
    char* buf = data.mutableBytes;
    buf[0] = [self versionByte];
    memcpy(buf + 1, self.data.bytes, DMCAssetIDLength);
    return data;
}

- (uint8_t) versionByte {
// TODO: support testnet
    return DMCAssetIDVersionMainnet;
}


@end
