// 

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DMCSecretSharingVersion) {
    // Identifies configuration for compact 128-bit secrets with up to 16 shares.
    DMCSecretSharingVersionCompact96  = 96,
    DMCSecretSharingVersionCompact104 = 104,
    DMCSecretSharingVersionCompact128 = 128,
};

@class DMCBigNumber;
@interface DMCSecretSharing : NSObject

@property(nonatomic, readonly) DMCSecretSharingVersion version;
@property(nonatomic, readonly, nonnull) DMCBigNumber* order;
@property(nonatomic, readonly) NSInteger bitlength;

- (id __nonnull) initWithVersion:(DMCSecretSharingVersion)version;

- (NSArray<NSData*>* __nullable) splitSecret:(NSData* __nonnull)secret threshold:(NSInteger)m shares:(NSInteger)n error:(NSError* __nullable * __nullable)errorOut;

- (NSData* __nullable) joinShares:(NSArray<NSData*>* __nonnull)shares error:(NSError* __nullable * __nullable)errorOut;

@end
