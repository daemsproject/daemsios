// 

#import <Foundation/Foundation.h>
#import "DMCUnitsAndLimits.h"

@class DMCNetwork;
@class DMCAssetID;
@class DMCPaymentMethodDetailsItem;
@class DMCPaymentMethodAcceptedAsset;
@interface DMCPaymentMethodDetails : NSObject

// Mainnet or testnet. Default is mainnet.
@property(nonatomic, readonly, nonnull) DMCNetwork* network;

// Payment items for the customer.
@property(nonatomic, readonly, nonnull)  NSArray* /* [DMCPaymentMethodDetailsItem] */ items;

// Secure location (usually https) where a PaymentMethod message (see below) may be sent to obtain a PaymentRequest.
// The payment_url specified in the PaymentMethodDetails should remain valid at least until the PaymentMethodDetails expires
// (or as long as possible if the PaymentMethodDetails does not expire).
@property(nonatomic, readonly, nullable) NSURL* paymentMethodURL;

// Date when the PaymentRequest was created.
@property(nonatomic, readonly, nonnull) NSDate* date;

// Date after which the PaymentRequest should be considered invalid.
@property(nonatomic, readonly, nullable) NSDate* expirationDate;

// Plain-text (no formatting) note that should be displayed to the customer, explaining what this PaymentRequest is for.
@property(nonatomic, readonly, nullable) NSString* memo;

// Arbitrary data that may be used by the merchant to identify the PaymentRequest.
// May be omitted if the merchant does not need to associate Payments with PaymentRequest or
// if they associate each PaymentRequest with a separate payment address.
@property(nonatomic, readonly, nullable) NSData* merchantData;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

@end



@interface  DMCPaymentMethodDetailsItem : NSObject

@property(nonatomic, readonly, nullable) NSString* itemType;
@property(nonatomic, readonly) BOOL optional;
@property(nonatomic, readonly, nullable) NSData* itemIdentifier;
@property(nonatomic, readonly) DMCAmount amount;
@property(nonatomic, readonly, nonnull) NSArray* /* [DMCPaymentMethodAcceptedAsset] */ acceptedAssets;
@property(nonatomic, readonly, nullable) NSString* memo;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end



@interface  DMCPaymentMethodAcceptedAsset : NSObject

@property(nonatomic, readonly, nullable) NSString* assetType; // DMCAssetTypeDaemsCoin or DMCAssetTypeOpenAssets
@property(nonatomic, readonly, nullable) DMCAssetID* assetID; // nil if type is "daemsCoin".
@property(nonatomic, readonly, nullable) NSString* assetGroup;
@property(nonatomic, readonly) double multiplier;
@property(nonatomic, readonly) DMCAmount minAmount;
@property(nonatomic, readonly) DMCAmount maxAmount;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end


