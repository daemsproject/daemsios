// 

#import <Foundation/Foundation.h>
#import "DMCUnitsAndLimits.h"

@class DMCAssetID;
@class DMCPaymentMethodItem;
@class DMCPaymentMethodAsset;
@class DMCPaymentMethodRejection;
@class DMCPaymentMethodRejectedAsset;

// Reply by the user: payment_method, methods per item, assets per method.
@interface  DMCPaymentMethod : NSObject

@property(nonatomic, nullable) NSData* merchantData;
@property(nonatomic, nullable) NSArray* /* [DMCPaymentMethodItem] */ items;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed method to pay for a given item
@interface  DMCPaymentMethodItem : NSObject

@property(nonatomic, nonnull) NSString* itemType;
@property(nonatomic, nullable) NSData* itemIdentifier;
@property(nonatomic, nullable) NSArray* /* [DMCPaymentMethodAsset] */ assets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed asset and amount within DMCPaymentMethodItem.
@interface  DMCPaymentMethodAsset : NSObject

@property(nonatomic, nullable) NSString* assetType; // DMCAssetTypeDaemsCoin or DMCAssetTypeOpenAssets
@property(nonatomic, nullable) DMCAssetID* assetID; // nil if type is "daemsCoin".
@property(nonatomic) DMCAmount amount;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end






// Rejection reply by the server: rejection summary and per-asset rejection info.


@interface  DMCPaymentMethodRejection : NSObject

@property(nonatomic, nullable) NSString* memo;
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSArray* /* [DMCPaymentMethodRejectedAsset] */ rejectedAssets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end


@interface  DMCPaymentMethodRejectedAsset : NSObject

@property(nonatomic, nonnull) NSString* assetType;  // DMCAssetTypeDaemsCoin or DMCAssetTypeOpenAssets
@property(nonatomic, nullable) DMCAssetID* assetID; // nil if type is "daemsCoin".
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSString* reason;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end

