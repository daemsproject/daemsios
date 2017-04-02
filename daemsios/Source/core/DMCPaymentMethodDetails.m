// 

#import "DMCPaymentMethodDetails.h"
#import "DMCPaymentProtocol.h"
#import "DMCProtocolBuffers.h"
#import "DMCNetwork.h"
#import "DMCAssetType.h"
#import "DMCAssetID.h"

//message PaymentMethodDetails {
//    optional string        network            = 1 [default = "main"];
//    required string        payment_method_url = 2;
//    repeated PaymentItem   items              = 3;
//    required uint64        time               = 4;
//    optional uint64        expires            = 5;
//    optional string        memo               = 6;
//    optional bytes         merchant_data      = 7;
//}
typedef NS_ENUM(NSInteger, DMCPMDetailsKey) {
    DMCPMDetailsKeyNetwork            = 1,
    DMCPMDetailsKeyPaymentMethodURL   = 2,
    DMCPMDetailsKeyItems              = 3,
    DMCPMDetailsKeyTime               = 4,
    DMCPMDetailsKeyExpires            = 5,
    DMCPMDetailsKeyMemo               = 6,
    DMCPMDetailsKeyMerchantData       = 7,
};

@interface DMCPaymentMethodDetails ()
@property(nonatomic, readwrite) DMCNetwork* network;
@property(nonatomic, readwrite) NSArray* /* [DMCPaymentMethodRequestItem] */ items;
@property(nonatomic, readwrite) NSURL* paymentMethodURL;
@property(nonatomic, readwrite) NSDate* date;
@property(nonatomic, readwrite) NSDate* expirationDate;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSData* data;
@end

@implementation DMCPaymentMethodDetails

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* items = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPMDetailsKeyNetwork:
                    if (d) {
                        NSString* networkName = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                        if ([networkName isEqual:@"main"]) {
                            _network = [DMCNetwork mainnet];
                        } else if ([networkName isEqual:@"test"]) {
                            _network = [DMCNetwork testnet];
                        } else {
                            _network = [[DMCNetwork alloc] initWithName:networkName];
                        }
                    }
                    break;
                case DMCPMDetailsKeyPaymentMethodURL:
                    if (d) _paymentMethodURL = [NSURL URLWithString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
                    break;
                case DMCPMDetailsKeyItems: {
                    if (d) {
                        DMCPaymentMethodDetailsItem* item = [[DMCPaymentMethodDetailsItem alloc] initWithData:d];
                        [items addObject:item];
                    }
                    break;
                }
                case DMCPMDetailsKeyTime:
                    if (integer) _date = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case DMCPMDetailsKeyExpires:
                    if (integer) _expirationDate = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case DMCPMDetailsKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPMDetailsKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                default: break;
            }
        }

        // PMR must have at least one item
        if (items.count == 0) return nil;

        // PMR requires a creation time.
        if (!_date) return nil;

        _items = items;
        _data = data;
    }
    return self;
}

- (DMCNetwork*) network {
    return _network ?: [DMCNetwork mainnet];
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_network) {
            [DMCProtocolBuffers writeString:_network.paymentProtocolName withKey:DMCPMDetailsKeyNetwork toData:dst];
        }
        if (_paymentMethodURL) {
            [DMCProtocolBuffers writeString:_paymentMethodURL.absoluteString withKey:DMCPMDetailsKeyPaymentMethodURL toData:dst];
        }
        for (DMCPaymentMethodDetailsItem* item in _items) {
            [DMCProtocolBuffers writeData:item.data withKey:DMCPMDetailsKeyItems toData:dst];
        }
        if (_date) {
            [DMCProtocolBuffers writeInt:(uint64_t)[_date timeIntervalSince1970] withKey:DMCPMDetailsKeyTime toData:dst];
        }
        if (_expirationDate) {
            [DMCProtocolBuffers writeInt:(uint64_t)[_expirationDate timeIntervalSince1970] withKey:DMCPMDetailsKeyExpires toData:dst];
        }
        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCPMDetailsKeyMemo toData:dst];
        }
        if (_merchantData) {
            [DMCProtocolBuffers writeData:_merchantData withKey:DMCPMDetailsKeyMerchantData toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end





//message PaymentItem {
//    optional string type                   = 1 [default = "default"];
//    optional bool   optional               = 2 [default = false];
//    optional bytes  item_identifier        = 3;
//    optional uint64 amount                 = 4 [default = 0];
//    repeated AcceptedAsset accepted_assets = 5;
//    optional string memo                   = 6;
//}
typedef NS_ENUM(NSInteger, DMCPMItemKey) {
    DMCPMRItemKeyItemType           = 1,
    DMCPMRItemKeyItemOptional       = 2,
    DMCPMRItemKeyItemIdentifier     = 3,
    DMCPMRItemKeyAmount             = 4,
    DMCPMRItemKeyAcceptedAssets     = 5,
    DMCPMRItemKeyMemo               = 6,
};

@interface DMCPaymentMethodDetailsItem ()
@property(nonatomic, readwrite, nullable) NSString* itemType;
@property(nonatomic, readwrite) BOOL optional;
@property(nonatomic, readwrite, nullable) NSData* itemIdentifier;
@property(nonatomic, readwrite) DMCAmount amount;
@property(nonatomic, readwrite, nonnull) NSArray* /* [DMCPaymentMethodAcceptedAsset] */ acceptedAssets;
@property(nonatomic, readwrite, nullable) NSString* memo;
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodDetailsItem

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* assets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPMRItemKeyItemType:
                    if (d) _itemType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPMRItemKeyItemOptional:
                    _optional = (integer != 0);
                    break;
                case DMCPMRItemKeyItemIdentifier:
                    if (d) _itemIdentifier = d;
                    break;

                case DMCPMRItemKeyAmount: {
                    _amount = integer;
                    break;
                }
                case DMCPMRItemKeyAcceptedAssets: {
                    if (d) {
                        DMCPaymentMethodAcceptedAsset* asset = [[DMCPaymentMethodAcceptedAsset alloc] initWithData:d];
                        [assets addObject:asset];
                    }
                    break;
                }
                case DMCPMRItemKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }
        }
        _acceptedAssets = assets;
        _data = data;
    }
    return self;
}


- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_itemType) {
            [DMCProtocolBuffers writeString:_itemType withKey:DMCPMRItemKeyItemType toData:dst];
        }
        [DMCProtocolBuffers writeInt:_optional ? 1 : 0 withKey:DMCPMRItemKeyItemOptional toData:dst];
        if (_itemIdentifier) {
            [DMCProtocolBuffers writeData:_itemIdentifier withKey:DMCPMRItemKeyItemIdentifier toData:dst];
        }
        if (_amount > 0) {
             [DMCProtocolBuffers writeInt:(uint64_t)_amount withKey:DMCPMRItemKeyAmount toData:dst];
        }
        for (DMCPaymentMethodAcceptedAsset* asset in _acceptedAssets) {
            [DMCProtocolBuffers writeData:asset.data withKey:DMCPMRItemKeyAcceptedAssets toData:dst];
        }
        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCPMRItemKeyMemo toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end





//message AcceptedAsset {
//    optional string asset_id = 1 [default = "default"];
//    optional string asset_group = 2;
//    optional double multiplier = 3 [default = 1.0];
//    optional uint64 min_amount = 4 [default = 0];
//    optional uint64 max_amount = 5;
//}
typedef NS_ENUM(NSInteger, DMCPMAcceptedAssetKey) {
    DMCPMRAcceptedAssetKeyAssetID    = 1,
    DMCPMRAcceptedAssetKeyAssetGroup = 2,
    DMCPMRAcceptedAssetKeyMultiplier = 3,
    DMCPMRAcceptedAssetKeyMinAmount  = 4,
    DMCPMRAcceptedAssetKeyMaxAmount  = 5,
};


@interface DMCPaymentMethodAcceptedAsset ()
@property(nonatomic, readwrite, nullable) NSString* assetType; // DMCAssetTypeDaemsCoin or DMCAssetTypeOpenAssets
@property(nonatomic, readwrite, nullable) DMCAssetID* assetID;
@property(nonatomic, readwrite, nullable) NSString* assetGroup;
@property(nonatomic, readwrite) double multiplier; // to use as a multiplier need to multiply by that amount and divide by 1e8.
@property(nonatomic, readwrite) DMCAmount minAmount;
@property(nonatomic, readwrite) DMCAmount maxAmount;
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodAcceptedAsset


- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        _multiplier = 1.0;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            uint64_t fixed64 = 0;
            NSData* d = nil;
            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer fixed32:NULL fixed64:&fixed64 data:&d fromData:data]) {
                case DMCPMRAcceptedAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;

                case DMCPMRAcceptedAssetKeyAssetGroup: {
                    if (d) _assetGroup = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                }
                case DMCPMRAcceptedAssetKeyMultiplier: {
                    _multiplier = (double)fixed64;
                    break;
                }
                case DMCPMRAcceptedAssetKeyMinAmount: {
                    _minAmount = integer;
                    break;
                }
                case DMCPMRAcceptedAssetKeyMaxAmount: {
                    _maxAmount = integer;
                    break;
                }
                default: break;
            }
        }

        if (!assetIDString || [assetIDString isEqual:@"default"]) {
            _assetType = DMCAssetTypeDaemsCoin;
            _assetID = nil;
        } else {
            _assetID = [DMCAssetID assetIDWithString:assetIDString];
            if (_assetID) {
                _assetType = DMCAssetTypeOpenAssets;
            }
        }
        _data = data;
    }
    return self;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:DMCAssetTypeDaemsCoin]) {
            [DMCProtocolBuffers writeString:@"default" withKey:DMCPMRAcceptedAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:DMCAssetTypeOpenAssets] && _assetID) {
            [DMCProtocolBuffers writeString:_assetID.string withKey:DMCPMRAcceptedAssetKeyAssetID toData:dst];
        }
        if (_assetGroup) {
            [DMCProtocolBuffers writeString:_assetGroup withKey:DMCPMRAcceptedAssetKeyAssetGroup toData:dst];
        }

        [DMCProtocolBuffers writeFixed64:(uint64_t)_multiplier withKey:DMCPMRAcceptedAssetKeyMultiplier toData:dst];
        [DMCProtocolBuffers writeInt:(uint64_t)_minAmount withKey:DMCPMRAcceptedAssetKeyMinAmount toData:dst];
        [DMCProtocolBuffers writeInt:(uint64_t)_maxAmount withKey:DMCPMRAcceptedAssetKeyMaxAmount toData:dst];
        _data = dst;
    }
    return _data;
}

@end

