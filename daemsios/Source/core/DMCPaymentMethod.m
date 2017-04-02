// 

#import "DMCPaymentMethod.h"
#import "DMCProtocolBuffers.h"
#import "DMCAssetID.h"
#import "DMCAssetType.h"

//message PaymentMethod {
//    optional bytes             merchant_data = 1;
//    repeated PaymentMethodItem items         = 2;
//}
typedef NS_ENUM(NSInteger, DMCPaymentMethodKey) {
    DMCPaymentMethodKeyMerchantData = 1,
    DMCPaymentMethodKeyItem         = 2,
};


@interface DMCPaymentMethod ()
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethod

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* items = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentMethodKeyMerchantData:
                    if (d) _merchantData = d;
                    break;

                case DMCPaymentMethodKeyItem: {
                    if (d) {
                        DMCPaymentMethodItem* item = [[DMCPaymentMethodItem alloc] initWithData:d];
                        [items addObject:item];
                    }
                    break;
                }
                default: break;
            }
        }

        _items = items;
        _data = data;
    }
    return self;
}

- (void) setMerchantData:(NSData * __nullable)merchantData {
    _merchantData = merchantData;
    _data = nil;
}

- (void) setItems:(NSArray * __nullable)items {
    _items = items;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_merchantData) {
            [DMCProtocolBuffers writeData:_merchantData withKey:DMCPaymentMethodKeyMerchantData toData:dst];
        }
        for (DMCPaymentMethodItem* item in _items) {
            [DMCProtocolBuffers writeData:item.data withKey:DMCPaymentMethodKeyItem toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end




//message PaymentMethodItem {
//    optional string             type                = 1 [default = "default"];
//    optional bytes              item_identifier     = 2;
//    repeated PaymentMethodAsset payment_item_assets = 3;
//}
typedef NS_ENUM(NSInteger, DMCPaymentMethodItemKey) {
    DMCPaymentMethodItemKeyItemType          = 1, // default = "default"
    DMCPaymentMethodItemKeyItemIdentifier    = 2,
    DMCPaymentMethodItemKeyAssets            = 3,
};


@interface DMCPaymentMethodItem ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodItem

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSMutableArray* assets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentMethodItemKeyItemType:
                    if (d) _itemType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPaymentMethodItemKeyItemIdentifier:
                    if (d) _itemIdentifier = d;
                    break;
                case DMCPaymentMethodItemKeyAssets: {
                    if (d) {
                        DMCPaymentMethodAsset* asset = [[DMCPaymentMethodAsset alloc] initWithData:d];
                        [assets addObject:asset];
                    }
                    break;
                }
                default: break;
            }
        }

        _assets = assets;
        _data = data;
    }
    return self;
}

- (void) setItemType:(NSString * __nonnull)itemType {
    _itemType = itemType;
    _data = nil;
}

- (void) setItemIdentifier:(NSData * __nullable)itemIdentifier {
    _itemIdentifier = itemIdentifier;
    _data = nil;
}

- (void) setAssets:(NSArray * __nullable)assets {
    _assets = assets;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_itemType) {
            [DMCProtocolBuffers writeString:_itemType withKey:DMCPaymentMethodItemKeyItemType toData:dst];
        }
        if (_itemIdentifier) {
            [DMCProtocolBuffers writeData:_itemIdentifier withKey:DMCPaymentMethodItemKeyItemIdentifier toData:dst];
        }
        for (DMCPaymentMethodItem* item in _assets) {
            [DMCProtocolBuffers writeData:item.data withKey:DMCPaymentMethodItemKeyAssets toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end






//message PaymentMethodAsset {
//    optional string            asset_id = 1 [default = "default"];
//    optional uint64            amount = 2;
//}
typedef NS_ENUM(NSInteger, DMCPaymentMethodAssetKey) {
    DMCPaymentMethodAssetKeyAssetID = 1,
    DMCPaymentMethodAssetKeyAmount  = 2,
};


@interface DMCPaymentMethodAsset ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodAsset

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentMethodAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPaymentMethodAssetKeyAmount: {
                    _amount = integer;
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

- (void) setAssetType:(NSString * __nullable)assetType {
    _assetType = assetType;
    _data = nil;
}

- (void) setAssetID:(DMCAssetID * __nullable)assetID {
    _assetID = assetID;
    _data = nil;
}

- (void) setAmount:(DMCAmount)amount {
    _amount = amount;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:DMCAssetTypeDaemsCoin]) {
            [DMCProtocolBuffers writeString:@"default" withKey:DMCPaymentMethodAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:DMCAssetTypeOpenAssets] && _assetID) {
            [DMCProtocolBuffers writeString:_assetID.string withKey:DMCPaymentMethodAssetKeyAssetID toData:dst];
        }

        [DMCProtocolBuffers writeInt:(uint64_t)_amount withKey:DMCPaymentMethodAssetKeyAmount toData:dst];
        _data = dst;
    }
    return _data;
}

@end




//message PaymentMethodRejection {
//    optional string memo = 1;
//    repeated PaymentMethodRejectedAsset rejected_assets = 2;
//}
typedef NS_ENUM(NSInteger, DMCPaymentMethodRejectionKey) {
    DMCPaymentMethodRejectionKeyMemo   = 1,
    DMCPaymentMethodRejectionKeyCode   = 2,
    DMCPaymentMethodRejectionKeyAssets = 3,
};


@interface DMCPaymentMethodRejection ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodRejection

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSMutableArray* rejectedAssets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentMethodRejectionKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPaymentMethodRejectionKeyCode:
                    _code = integer;
                    break;
                case DMCPaymentMethodRejectionKeyAssets: {
                    if (d) {
                        DMCPaymentMethodRejectedAsset* rejasset = [[DMCPaymentMethodRejectedAsset alloc] initWithData:d];
                        [rejectedAssets addObject:rejasset];
                    }
                    break;
                }
                default: break;
            }
        }

        _rejectedAssets = rejectedAssets;
        _data = data;
    }
    return self;
}

- (void) setMemo:(NSString * __nullable)memo {
    _memo = [memo copy];
    _data = nil;
}

- (void) setCode:(uint64_t)code {
    _code = code;
    _data = nil;
}

- (void) setRejectedAssets:(NSArray * __nullable)rejectedAssets {
    _rejectedAssets = rejectedAssets;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCPaymentMethodRejectionKeyMemo toData:dst];
        }

        [DMCProtocolBuffers writeInt:_code withKey:DMCPaymentMethodRejectionKeyCode toData:dst];

        for (DMCPaymentMethodRejectedAsset* rejectedAsset in _rejectedAssets) {
            [DMCProtocolBuffers writeData:rejectedAsset.data withKey:DMCPaymentMethodRejectionKeyAssets toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end


//message PaymentMethodRejectedAsset {
//    required string asset_id = 1;
//    optional uint64 code     = 2;
//    optional string reason   = 3;
//}
typedef NS_ENUM(NSInteger, DMCPaymentMethodRejectedAssetKey) {
    DMCPaymentMethodRejectedAssetKeyAssetID = 1,
    DMCPaymentMethodRejectedAssetKeyCode    = 2,
    DMCPaymentMethodRejectedAssetKeyReason  = 3,
};


@interface DMCPaymentMethodRejectedAsset ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation DMCPaymentMethodRejectedAsset

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentMethodRejectedAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCPaymentMethodRejectionKeyCode:
                    _code = integer;
                    break;
                case DMCPaymentMethodRejectedAssetKeyReason: {
                    if (d) _reason = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
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

- (void) setAssetType:(NSString * __nonnull)assetType {
    _assetType = assetType;
    _data = nil;
}

- (void) setAssetID:(DMCAssetID * __nullable)assetID {
    _assetID = assetID;
    _data = nil;
}

- (void) setCode:(uint64_t)code {
    _code = code;
    _data = nil;
}

- (void) setReason:(NSString * __nullable)reason {
    _reason = reason;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:DMCAssetTypeDaemsCoin]) {
            [DMCProtocolBuffers writeString:@"default" withKey:DMCPaymentMethodRejectedAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:DMCAssetTypeOpenAssets] && _assetID) {
            [DMCProtocolBuffers writeString:_assetID.string withKey:DMCPaymentMethodRejectedAssetKeyAssetID toData:dst];
        }

        [DMCProtocolBuffers writeInt:_code withKey:DMCPaymentMethodRejectedAssetKeyCode toData:dst];

        if (_reason) {
            [DMCProtocolBuffers writeString:_reason withKey:DMCPaymentMethodRejectedAssetKeyReason toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end
