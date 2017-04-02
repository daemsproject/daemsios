// 

#import "DMCAddress.h"

@interface DMCAssetAddress : DMCAddress
@property(nonatomic, readonly, nonnull) DMCAddress* daemsCoinAddress;
+ (nonnull instancetype) addressWithDaemsCoinAddress:(nonnull DMCAddress*)DMCAddress;
@end
