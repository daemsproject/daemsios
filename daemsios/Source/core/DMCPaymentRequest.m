// 

#import "DMCPaymentRequest.h"
#import "DMCProtocolBuffers.h"
#import "DMCErrors.h"
#import "DMCAssetType.h"
#import "DMCAssetID.h"
#import "DMCData.h"
#import "DMCNetwork.h"
#import "DMCScript.h"
#import "DMCTransaction.h"
#import "DMCTransactionOutput.h"
#import "DMCTransactionInput.h"
#import <Security/Security.h>

NSInteger const DMCPaymentRequestVersion1 = 1;
NSInteger const DMCPaymentRequestVersionOpenAssets1 = 0x4f41;

NSString* const DMCPaymentRequestPKITypeNone = @"none";
NSString* const DMCPaymentRequestPKITypeX509SHA1 = @"x509+sha1";
NSString* const DMCPaymentRequestPKITypeX509SHA256 = @"x509+sha256";

DMCAmount const DMCUnspecifiedPaymentAmount = -1;

typedef NS_ENUM(NSInteger, DMCOutputKey) {
    DMCOutputKeyAmount = 1,
    DMCOutputKeyScript = 2,
    DMCOutputKeyAssetID = 4001, // only for Open Assets PRs.
    DMCOutputKeyAssetAmount = 4002 // only for Open Assets PRs.
};

typedef NS_ENUM(NSInteger, DMCInputKey) {
    DMCInputKeyTxhash = 1,
    DMCInputKeyIndex = 2
};

typedef NS_ENUM(NSInteger, DMCRequestKey) {
    DMCRequestKeyVersion        = 1,
    DMCRequestKeyPkiType        = 2,
    DMCRequestKeyPkiData        = 3,
    DMCRequestKeyPaymentDetails = 4,
    DMCRequestKeySignature      = 5
};

typedef NS_ENUM(NSInteger, DMCDetailsKey) {
    DMCDetailsKeyNetwork      = 1,
    DMCDetailsKeyOutputs      = 2,
    DMCDetailsKeyTime         = 3,
    DMCDetailsKeyExpires      = 4,
    DMCDetailsKeyMemo         = 5,
    DMCDetailsKeyPaymentURL   = 6,
    DMCDetailsKeyMerchantData = 7,
    DMCDetailsKeyInputs       = 8
};

typedef NS_ENUM(NSInteger, DMCCertificatesKey) {
    DMCCertificatesKeyCertificate = 1
};

typedef NS_ENUM(NSInteger, DMCPaymentKey) {
    DMCPaymentKeyMerchantData = 1,
    DMCPaymentKeyTransactions = 2,
    DMCPaymentKeyRefundTo     = 3,
    DMCPaymentKeyMemo         = 4
};

typedef NS_ENUM(NSInteger, DMCPaymentAckKey) {
    DMCPaymentAckKeyPayment = 1,
    DMCPaymentAckKeyMemo    = 2
};


@interface DMCPaymentRequest ()
// If you make these publicly writable, make sure to set _data to nil and _isValidated to NO.
@property(nonatomic, readwrite) NSInteger version;
@property(nonatomic, readwrite) NSString* pkiType;
@property(nonatomic, readwrite) NSData* pkiData;
@property(nonatomic, readwrite) DMCPaymentDetails* details;
@property(nonatomic, readwrite) NSData* signature;
@property(nonatomic, readwrite) NSArray* certificates;
@property(nonatomic, readwrite) NSData* data;

@property(nonatomic) BOOL isValidated;
@property(nonatomic, readwrite) BOOL isValid;
@property(nonatomic, readwrite) NSString* signerName;
@property(nonatomic, readwrite) DMCPaymentRequestStatus status;
@end


@interface DMCPaymentDetails ()
@property(nonatomic, readwrite) DMCNetwork* network;
@property(nonatomic, readwrite) NSArray* /*[DMCTransactionOutput]*/ outputs;
@property(nonatomic, readwrite) NSArray* /*[DMCTransactionInput]*/ inputs;
@property(nonatomic, readwrite) NSDate* date;
@property(nonatomic, readwrite) NSDate* expirationDate;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSURL* paymentURL;
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSData* data;
@end


@interface DMCPayment ()
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSArray* /*[DMCTransaction]*/ transactions;
@property(nonatomic, readwrite) NSArray* /*[DMCTransactionOutput]*/ refundOutputs;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* data;
@end


@interface DMCPaymentACK ()
@property(nonatomic, readwrite) DMCPayment* payment;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* data;
@end







@implementation DMCPaymentRequest

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        // Note: we are not assigning default values here because we need to
        // reconstruct exact data (without the signature) for signature verification.

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t i = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&i data:&d fromData:data]) {
                case DMCRequestKeyVersion:
                    if (i) _version = (uint32_t)i;
                    break;
                case DMCRequestKeyPkiType:
                    if (d) _pkiType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCRequestKeyPkiData:
                    if (d) _pkiData = d;
                    break;
                case DMCRequestKeyPaymentDetails:
                    if (d) _details = [[DMCPaymentDetails alloc] initWithData:d];
                    break;
                case DMCRequestKeySignature:
                    if (d) _signature = d;
                    break;
                default: break;
            }
        }

        // Payment details are required.
        if (!_details) return nil;
    }
    return self;
}

- (NSData*) data {
    if (!_data) {
        _data = [self dataWithSignature:_signature];
    }
    return _data;
}

- (NSData*) dataForSigning {
    return [self dataWithSignature:[NSData data]];
}

- (NSData*) dataWithSignature:(NSData*)signature {
    NSMutableData* data = [NSMutableData data];

    // Note: we should reconstruct the data exactly as it was on the input.
    if (_version > 0) {
        [DMCProtocolBuffers writeInt:_version withKey:DMCRequestKeyVersion toData:data];
    }
    if (_pkiType) {
        [DMCProtocolBuffers writeString:_pkiType withKey:DMCRequestKeyPkiType toData:data];
    }
    if (_pkiData) {
        [DMCProtocolBuffers writeData:_pkiData withKey:DMCRequestKeyPkiData toData:data];
    }

    [DMCProtocolBuffers writeData:self.details.data withKey:DMCRequestKeyPaymentDetails toData:data];

    if (signature) {
        [DMCProtocolBuffers writeData:signature withKey:DMCRequestKeySignature toData:data];
    }
    return data;
}

- (NSInteger) version
{
    return (_version > 0) ? _version : DMCPaymentRequestVersion1;
}

- (NSString*) pkiType
{
    return _pkiType ?: DMCPaymentRequestPKITypeNone;
}

- (NSArray*) certificates {
    if (!_certificates) {
        _certificates = DMCParseCertificatesFromPaymentRequestPKIData(self.pkiData);
    }
    return _certificates;
}

- (BOOL) isValid {
    if (!_isValidated) [self validatePaymentRequest];
    return _isValid;
}

- (NSString*) signerName {
    if (!_isValidated) [self validatePaymentRequest];
    return _signerName;
}

- (DMCPaymentRequestStatus) status {
    if (!_isValidated) [self validatePaymentRequest];
    return _status;
}

- (void) validatePaymentRequest {
    _isValidated = YES;
    _isValid = NO;

    // Make sure we do not accidentally send funds to a payment request that we do not support.
    if (self.version != DMCPaymentRequestVersion1 &&
        self.version != DMCPaymentRequestVersionOpenAssets1) {
        _status = DMCPaymentRequestStatusNotCompatible;
        return;
    }

    __typeof(_status) status = _status;
    __typeof(_signerName) signer = _signerName;
    _isValid = DMCPaymentRequestVerifySignature(self.pkiType,
                                                [self dataForSigning],
                                                self.certificates,
                                                _signature,
                                                &status,
                                                &signer);
    _status = status;
    _signerName = signer;
    if (!_isValid) {
        return;
    }

    // Signatures are valid, but PR has expired.
    if (self.details.expirationDate && [self.currentDate ?: [NSDate date] timeIntervalSinceDate:self.details.expirationDate] > 0.0) {
        _status = DMCPaymentRequestStatusExpired;
        _isValid = NO;
        return;
    }
}

- (DMCPayment*) paymentWithTransaction:(DMCTransaction*)tx {
    NSParameterAssert(tx);
    return [self paymentWithTransactions:@[ tx ] memo:nil];
}

- (DMCPayment*) paymentWithTransactions:(NSArray*)txs memo:(NSString*)memo {
    if (!txs || txs.count == 0) return nil;
    DMCPayment* payment = [[DMCPayment alloc] init];
    payment.merchantData = self.details.merchantData;
    payment.transactions = txs;
    payment.memo = memo;
    return payment;
}

@end


NSArray* __nullable DMCParseCertificatesFromPaymentRequestPKIData(NSData* __nullable pkiData) {
    if (!pkiData) return nil;
    NSMutableArray* certs = [NSMutableArray array];
    NSInteger offset = 0;
    while (offset < pkiData.length) {
        NSData* d = nil;
        NSInteger key = [DMCProtocolBuffers fieldAtOffset:&offset int:NULL data:&d fromData:pkiData];
        if (key == DMCCertificatesKeyCertificate && d) {
            [certs addObject:d];
        }
    }
    return certs;
}


BOOL DMCPaymentRequestVerifySignature(NSString* __nullable pkiType,
                                      NSData* __nullable dataToVerify,
                                      NSArray* __nullable certificates,
                                      NSData* __nullable signature,
                                      DMCPaymentRequestStatus* __nullable statusOut,
                                      NSString* __autoreleasing __nullable *  __nullable signerOut) {

    if ([pkiType isEqual:DMCPaymentRequestPKITypeX509SHA1] ||
        [pkiType isEqual:DMCPaymentRequestPKITypeX509SHA256]) {

        if (!signature || !certificates || certificates.count == 0 || !dataToVerify) {
            if (statusOut) *statusOut = DMCPaymentRequestStatusInvalidSignature;
            return NO;
        }

        // 1. Verify chain of trust

        NSMutableArray *certs = [NSMutableArray array];
        NSArray *policies = @[CFBridgingRelease(SecPolicyCreateBasicX509())];
        SecTrustRef trust = NULL;
        SecTrustResultType trustResult = kSecTrustResultInvalid;

        for (NSData *certData in certificates) {
            SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
            if (cert) [certs addObject:CFBridgingRelease(cert)];
        }

        if (certs.count > 0) {
            if (signerOut) *signerOut = CFBridgingRelease(SecCertificateCopySubjectSummary((__bridge SecCertificateRef)certs[0]));
        }

        SecTrustCreateWithCertificates((__bridge CFArrayRef)certs, (__bridge CFArrayRef)policies, &trust);
        SecTrustEvaluate(trust, &trustResult); // verify certificate chain

        // kSecTrustResultUnspecified indicates the evaluation succeeded
        // and the certificate is implicitly trusted, but user intent was not
        // explicitly specified.
        if (trustResult != kSecTrustResultUnspecified && trustResult != kSecTrustResultProceed) {
            if (certs.count > 0) {
                if (statusOut) *statusOut = DMCPaymentRequestStatusUntrustedCertificate;
            } else {
                if (statusOut) *statusOut = DMCPaymentRequestStatusMissingCertificate;
            }
            return NO;
        }

        // 2. Verify signature

    #if TARGET_OS_IPHONE
        SecKeyRef pubKey = SecTrustCopyPublicKey(trust);
        SecPadding padding = kSecPaddingPKCS1;
        NSData* hash = nil;

        if ([pkiType isEqual:DMCPaymentRequestPKITypeX509SHA256]) {
            hash = DMCSHA256(dataToVerify);
            padding = kSecPaddingPKCS1SHA256;
        }
        else if ([pkiType isEqual:DMCPaymentRequestPKITypeX509SHA1]) {
            hash = DMCSHA1(dataToVerify);
            padding = kSecPaddingPKCS1SHA1;
        }

        OSStatus status = SecKeyRawVerify(pubKey, padding, hash.bytes, hash.length, signature.bytes, signature.length);

        CFRelease(pubKey);

        if (status != errSecSuccess) {
            if (statusOut) *statusOut = DMCPaymentRequestStatusInvalidSignature;
            return NO;
        }

        if (statusOut) *statusOut = DMCPaymentRequestStatusValid;
        return YES;

    #else
        // On OS X 10.10 we don't have kSecPaddingPKCS1SHA256 and SecKeyRawVerify.
        // So we have to verify the signature using Security Transforms API.

        //  Here's a draft of what needs to be done here.
        /*
         CFErrorRef* error = NULL;
         verifier = SecVerifyTransformCreate(publickey, signature, &error);
         if (!verifier) { CFShow(error); exit(-1); }
         if (!SecTransformSetAttribute(verifier, kSecTransformInputAttributeName, dataForSigning, &error) {
         CFShow(error);
         exit(-1);
         }
         // if it's sha256, then set SHA2 digest type and 32 bytes length.
         if (!SecTransformSetAttribute(verifier, kSecDigestTypeAttribute, kSecDigestSHA2, &error) {
         CFShow(error);
         exit(-1);
         }
         // Not sure if the length is in bytes or bits. Quinn The Eskimo says it's in bits:
         // https://devforums.apple.com/message/1119092#1119092
         if (!SecTransformSetAttribute(verifier, kSecDigestLengthAttribute, @(256), &error) {
         CFShow(error);
         exit(-1);
         }

         result = SecTransformExecute(verifier, &error);
         if (error) {
         CFShow(error);
         exit(-1);
         }
         if (result == kCFBooleanTrue) {
         // signature is valid
         if (statusOut) *statusOut = DMCPaymentRequestStatusValid;
         _isValid = YES;
         } else {
         // signature is invalid.
         if (statusOut) *statusOut = DMCPaymentRequestStatusInvalidSignature;
         _isValid = NO;
         return NO;
         }

         // -----------------------------------------------------------------------

         // From CryptoCompatibility sample code (QCCRSASHA1VerifyT.m):

         BOOL                success;
         SecTransformRef     transform;
         CFBooleanRef        result;
         CFErrorRef          errorCF;

         result = NULL;
         errorCF = NULL;

         // Set up the transform.

         transform = SecVerifyTransformCreate(self.publicKey, (__bridge CFDataRef) self.signatureData, &errorCF);
         success = (transform != NULL);

         // Note: kSecInputIsAttributeName defaults to kSecInputIsPlainText, which is what we want.

         if (success) {
         success = SecTransformSetAttribute(transform, kSecDigestTypeAttribute, kSecDigestSHA1, &errorCF) != false;
         }

         if (success) {
         success = SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFDataRef) self.inputData, &errorCF) != false;
         }

         // Run it.

         if (success) {
         result = SecTransformExecute(transform, &errorCF);
         success = (result != NULL);
         }

         // Process the results.

         if (success) {
         assert(CFGetTypeID(result) == CFBooleanGetTypeID());
         self.verified = (CFBooleanGetValue(result) != false);
         } else {
         assert(errorCF != NULL);
         self.error = (__bridge NSError *) errorCF;
         }

         // Clean up.

         if (result != NULL) {
         CFRelease(result);
         }
         if (errorCF != NULL) {
         CFRelease(errorCF);
         }
         if (transform != NULL) {
         CFRelease(transform);
         }
         */

        if (statusOut) *statusOut = DMCPaymentRequestStatusUnknown;
        return NO;
    #endif

    } else {
        // Either "none" PKI type or some new and unsupported PKI.

        if (certificates.count > 0) {
            // Non-standard extension to include a signer's name without actually signing request.
            if (signerOut) *signerOut = [[NSString alloc] initWithData:certificates[0] encoding:NSUTF8StringEncoding];
        }

        if ([pkiType isEqual:DMCPaymentRequestPKITypeNone]) {
            if (statusOut) *statusOut = DMCPaymentRequestStatusUnsigned;
            return YES;
        } else {
            if (statusOut) *statusOut = DMCPaymentRequestStatusUnknown;
            return NO;
        }
    }
    return NO;
}



















@implementation DMCPaymentDetails

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* outputs = [NSMutableArray array];
        NSMutableArray* inputs = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCDetailsKeyNetwork:
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
                case DMCDetailsKeyOutputs: {
                    NSInteger offset2 = 0;
                    DMCAmount amount = DMCUnspecifiedPaymentAmount;
                    NSData* scriptData = nil;
                    DMCAssetID* assetID = nil;
                    DMCAmount assetAmount = DMCUnspecifiedPaymentAmount;

                    uint64_t integer2 = 0;
                    NSData* d2 = nil;
                    while (offset2 < d.length) {
                        switch ([DMCProtocolBuffers fieldAtOffset:&offset2 int:&integer2 data:&d2 fromData:d]) {
                            case DMCOutputKeyAmount:
                                amount = integer2;
                                break;
                            case DMCOutputKeyScript:
                                scriptData = d2;
                                break;
                            case DMCOutputKeyAssetID:
                                if (d2.length != 20) {
                                    NSLog(@"DaemsCoin ERROR: Received invalid asset id in Payment Request Details (must be 20 bytes long): %@", d2);
                                    return nil;
                                }
                                assetID = [DMCAssetID assetIDWithHash:d2];
                                break;
                            case DMCOutputKeyAssetAmount:
                                assetAmount = integer2;
                                break;
                            default:
                                break;
                        }
                    }
                    if (scriptData) {
                        DMCScript* script = [[DMCScript alloc] initWithData:scriptData];
                        if (!script) {
                            NSLog(@"DaemsCoin ERROR: Received invalid script data in Payment Request Details: %@", scriptData);
                            return nil;
                        }
                        if (assetID) {
                            if (amount != DMCUnspecifiedPaymentAmount) {
                                NSLog(@"DaemsCoin ERROR: Received invalid amount specification in Payment Request Details: amount must not be specified.");
                                return nil;
                            }
                        } else {
                            if (assetAmount != DMCUnspecifiedPaymentAmount) {
                                NSLog(@"DaemsCoin ERROR: Received invalid amount specification in Payment Request Details: asset_amount must not specified without asset_id.");
                                return nil;
                            }
                        }
                        DMCTransactionOutput* txout = [[DMCTransactionOutput alloc] initWithValue:amount script:script];
                        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];

                        if (assetID) {
                            userInfo[@"assetID"] = assetID;
                        }
                        if (assetAmount != DMCUnspecifiedPaymentAmount) {
                            userInfo[@"assetAmount"] = @(assetAmount);
                        }
                        txout.userInfo = userInfo;
                        txout.index = (uint32_t)outputs.count;
                        [outputs addObject:txout];
                    }
                    break;
                }
                case DMCDetailsKeyInputs: {
                    NSInteger offset2 = 0;
                    uint64_t index = DMCUnspecifiedPaymentAmount;
                    NSData* txhash = nil;
                    // both amount and scriptData are optional, so we try to read any of them
                    while (offset2 < d.length) {
                        [DMCProtocolBuffers fieldAtOffset:&offset2 int:(uint64_t*)&index data:&txhash fromData:d];
                    }
                    if (txhash) {
                        if (txhash.length != 32) {
                            NSLog(@"DaemsCoin ERROR: Received invalid txhash in Payment Request Input: %@", txhash);
                            return nil;
                        }
                        if (index > 0xffffffffLL) {
                            NSLog(@"DaemsCoin ERROR: Received invalid prev index in Payment Request Input: %@", @(index));
                            return nil;
                        }
                        DMCTransactionInput* txin = [[DMCTransactionInput alloc] init];
                        txin.previousHash = txhash;
                        txin.previousIndex = (uint32_t)index;
                        [inputs addObject:txin];
                    }
                    break;
                }
                case DMCDetailsKeyTime:
                    if (integer) _date = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case DMCDetailsKeyExpires:
                    if (integer) _expirationDate = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case DMCDetailsKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case DMCDetailsKeyPaymentURL:
                    if (d) _paymentURL = [NSURL URLWithString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
                    break;
                case DMCDetailsKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                default: break;
            }
        }

        // PR must have at least one output
        if (outputs.count == 0) return nil;

        // PR requires a creation time.
        if (!_date) return nil;

        _outputs = outputs;
        _inputs = inputs;
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

        // Note: we should reconstruct the data exactly as it was on the input.

        if (_network) {
            [DMCProtocolBuffers writeString:_network.paymentProtocolName withKey:DMCDetailsKeyNetwork toData:dst];
        }

        for (DMCTransactionOutput* txout in _outputs) {
            NSMutableData* outputData = [NSMutableData data];

            if (txout.value != DMCUnspecifiedPaymentAmount) {
                [DMCProtocolBuffers writeInt:txout.value withKey:DMCOutputKeyAmount toData:outputData];
            }
            [DMCProtocolBuffers writeData:txout.script.data withKey:DMCOutputKeyScript toData:outputData];

            if (txout.userInfo[@"assetID"]) {
                DMCAssetID* aid = txout.userInfo[@"assetID"];
                [DMCProtocolBuffers writeData:aid.data withKey:DMCOutputKeyAssetID toData:outputData];
            }
            if (txout.userInfo[@"assetAmount"]) {
                DMCAmount assetAmount = [txout.userInfo[@"assetAmount"] longLongValue];
                [DMCProtocolBuffers writeInt:assetAmount withKey:DMCOutputKeyAssetAmount toData:outputData];
            }
            [DMCProtocolBuffers writeData:outputData withKey:DMCDetailsKeyOutputs toData:dst];
        }

        for (DMCTransactionInput* txin in _inputs) {
            NSMutableData* inputsData = [NSMutableData data];

            [DMCProtocolBuffers writeData:txin.previousHash withKey:DMCInputKeyTxhash toData:inputsData];
            [DMCProtocolBuffers writeInt:txin.previousIndex withKey:DMCInputKeyIndex toData:inputsData];
            [DMCProtocolBuffers writeData:inputsData withKey:DMCDetailsKeyInputs toData:dst];
        }

        if (_date) {
            [DMCProtocolBuffers writeInt:(uint64_t)[_date timeIntervalSince1970] withKey:DMCDetailsKeyTime toData:dst];
        }
        if (_expirationDate) {
            [DMCProtocolBuffers writeInt:(uint64_t)[_expirationDate timeIntervalSince1970] withKey:DMCDetailsKeyExpires toData:dst];
        }
        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCDetailsKeyMemo toData:dst];
        }
        if (_paymentURL) {
            [DMCProtocolBuffers writeString:_paymentURL.absoluteString withKey:DMCDetailsKeyPaymentURL toData:dst];
        }
        if (_merchantData) {
            [DMCProtocolBuffers writeData:_merchantData withKey:DMCDetailsKeyMerchantData toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end




















@implementation DMCPayment

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSInteger offset = 0;
        NSMutableArray* txs = [NSMutableArray array];
        NSMutableArray* outputs = [NSMutableArray array];

        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;
            DMCTransaction* tx = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                case DMCPaymentKeyTransactions:
                    if (d) tx = [[DMCTransaction alloc] initWithData:d];
                    if (tx) [txs addObject:tx];
                    break;
                case DMCPaymentKeyRefundTo: {
                    NSInteger offset2 = 0;
                    DMCAmount amount = DMCUnspecifiedPaymentAmount;
                    NSData* scriptData = nil;
                    // both amount and scriptData are optional, so we try to read any of them
                    while (offset2 < d.length) {
                        [DMCProtocolBuffers fieldAtOffset:&offset2 int:(uint64_t*)&amount data:&scriptData fromData:d];
                    }
                    if (scriptData) {
                        DMCScript* script = [[DMCScript alloc] initWithData:scriptData];
                        if (!script) {
                            NSLog(@"DaemsCoin ERROR: Received invalid script data in Payment Request Details: %@", scriptData);
                            return nil;
                        }
                        DMCTransactionOutput* txout = [[DMCTransactionOutput alloc] initWithValue:amount script:script];
                        [outputs addObject:txout];
                    }
                    break;
                }
                case DMCPaymentKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }

        }

        _transactions = txs;
        _refundOutputs = outputs;
    }
    return self;
}

- (NSData*) data {

    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_merchantData) {
            [DMCProtocolBuffers writeData:_merchantData withKey:DMCPaymentKeyMerchantData toData:dst];
        }

        for (DMCTransaction* tx in _transactions) {
            [DMCProtocolBuffers writeData:tx.data withKey:DMCPaymentKeyTransactions toData:dst];
        }

        for (DMCTransactionOutput* txout in _refundOutputs) {
            NSMutableData* outputData = [NSMutableData data];

            if (txout.value != DMCUnspecifiedPaymentAmount) {
                [DMCProtocolBuffers writeInt:txout.value withKey:DMCOutputKeyAmount toData:outputData];
            }
            [DMCProtocolBuffers writeData:txout.script.data withKey:DMCOutputKeyScript toData:outputData];
            [DMCProtocolBuffers writeData:outputData withKey:DMCPaymentKeyRefundTo toData:dst];
        }

        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCPaymentKeyMemo toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end






















@implementation DMCPaymentACK

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([DMCProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case DMCPaymentAckKeyPayment:
                    if (d) _payment = [[DMCPayment alloc] initWithData:d];
                    break;
                case DMCPaymentAckKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }
        }
        
        // payment object is required.
        if (! _payment) return nil;
    }
    return self;
}


- (NSData*) data {
    
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];
        
        [DMCProtocolBuffers writeData:_payment.data withKey:DMCPaymentAckKeyPayment toData:dst];
        
        if (_memo) {
            [DMCProtocolBuffers writeString:_memo withKey:DMCPaymentAckKeyMemo toData:dst];
        }
        
        _data = dst;
    }
    return _data;
}


@end
