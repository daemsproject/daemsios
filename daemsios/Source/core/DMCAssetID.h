// 

#import "DMCAddress.h"

@interface DMCAssetID : DMCAddress

+ (nullable instancetype) assetIDWithHash:(nullable NSData*)data;

+ (nullable instancetype) assetIDWithString:(nullable NSString*)string;

@end
