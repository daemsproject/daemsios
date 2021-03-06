// 

#import <Foundation/Foundation.h>
#import "DMCUnitsAndLimits.h"

// Interface to BIP70 payment protocol.
// Spec: https://github.com/daemsCoin/bips/blob/master/bip-0070.mediawiki
//
// * DMCPaymentProtocol implements high-level request and response API.
// * DMCPaymentRequest object that represents "PaymentRequest" as described in BIP70.
// * DMCPaymentDetails object that represents "PaymentDetails" as described in BIP70.
// * DMCPayment object that represents "Payment" as described in BIP70.
// * DMCPaymentACK object that represents "PaymentACK" as described in BIP70.

extern NSInteger const DMCPaymentRequestVersion1;
extern NSInteger const DMCPaymentRequestVersionOpenAssets1;

extern NSString* __nonnull const DMCPaymentRequestPKITypeNone;
extern NSString* __nonnull const DMCPaymentRequestPKITypeX509SHA1;
extern NSString* __nonnull const DMCPaymentRequestPKITypeX509SHA256;

// Special value indicating that amount on the output is not specified.
extern DMCAmount const DMCUnspecifiedPaymentAmount;

// Status allows to correctly display information about security of the request to the user.
typedef NS_ENUM(NSInteger, DMCPaymentRequestStatus) {
    // Payment request is valid and the user can trust it.
    DMCPaymentRequestStatusValid                 = 0, // signed with a valid and known certificate.

    DMCPaymentRequestStatusNotCompatible         = 100, // version is not supported (currently only v1 is supported)

    // These allow Payment Request to be accepted with a warning to the user.
    DMCPaymentRequestStatusUnsigned              = 101, // PKI type is "none"
    DMCPaymentRequestStatusUnknown               = 102, // PKI type is unknown (for forward compatibility may allow sending or warn to upgrade).

    // These generally mean we should decline the Payment Request.
    DMCPaymentRequestStatusExpired               = 201,
    DMCPaymentRequestStatusInvalidSignature      = 202,
    DMCPaymentRequestStatusMissingCertificate    = 203,
    DMCPaymentRequestStatusUntrustedCertificate  = 204,
};

@class DMCNetwork;
@class DMCPayment;
@class DMCPaymentACK;
@class DMCPaymentRequest;
@class DMCPaymentDetails;
@class DMCTransaction;

NSArray* __nullable DMCParseCertificatesFromPaymentRequestPKIData(NSData* __nullable pkiData);

BOOL DMCPaymentRequestVerifySignature(NSString* __nullable pkiType,
                                             NSData* __nullable dataToVerify,
                                             NSArray* __nullable certificates,
                                             NSData* __nullable signature,
                                             DMCPaymentRequestStatus* __nullable statusOut,
                                             NSString* __autoreleasing __nullable *  __nullable signerOut);

// Payment requests are split into two messages to support future extensibility.
// The bulk of the information is contained in the PaymentDetails message.
// It is wrapped inside a PaymentRequest message, which contains meta-information
// about the merchant and a digital signature.
// message PaymentRequest {
//     optional uint32 payment_details_version = 1 [default = 1];
//     optional string pki_type = 2 [default = "none"];
//     optional bytes pki_data = 3;
//     required bytes serialized_payment_details = 4;
//     optional bytes signature = 5;
// }
@interface DMCPaymentRequest : NSObject

// Version of the payment request and payment details.
// Default is DMCPaymentRequestVersion1.
@property(nonatomic, readonly) NSInteger version;

// Public-key infrastructure (PKI) system being used to identify the merchant.
// All implementation should support "none", "x509+sha256" and "x509+sha1".
// See DMCPaymentRequestPKIType* constants.
@property(nonatomic, readonly, nonnull) NSString* pkiType;

// PKI-system data that identifies the merchant and can be used to create a digital signature.
// In the case of X.509 certificates, pki_data contains one or more X.509 certificates.
// Depends on pkiType. Optional.
@property(nonatomic, readonly, nullable) NSData* pkiData;

// A DMCPaymentDetails object.
@property(nonatomic, readonly, nonnull) DMCPaymentDetails* details;

// Digital signature over a hash of the protocol buffer serialized variation of
// the PaymentRequest message, with all serialized fields serialized in numerical order
// (all current protocol buffer implementations serialize fields in numerical order) and
// signed using the private key that corresponds to the public key in pki_data.
// Optional fields that are not set are not serialized (however, setting a field to its default value will cause it to be serialized and will affect the signature).
// Before serialization, the signature field must be set to an empty value so that
// the field is included in the signed PaymentRequest hash but contains no data.
@property(nonatomic, readonly, nullable) NSData* signature;

// Array of DER encoded certificates or nil if pkiType does offer certificates.
// This list is extracted from raw `pkiData`.
// If set, certificates are cerialized in X509Certificates object and set to pkiData.
@property(nonatomic, readonly, nonnull) NSArray* certificates;

// A date against which the payment request is being validated.
// If nil, system date at the moment of validation is used.
@property(nonatomic, nullable) NSDate* currentDate;

// Returns YES if payment request is correctly signed by a trusted certificate if needed
// and expiration date is valid.
// Accessing this property also updates `status` and `signerName`.
@property(nonatomic, readonly) BOOL isValid;

// Human-readable name of the signer or nil if it's unsigned.
// You should display this to the user as a name of the merchant.
// Accessing this property also updates `status` and `isValid`.
@property(nonatomic, readonly, nullable) NSString* signerName;

// Validation status.
// Accessing this property also updates `commonName` and `isValid`.
@property(nonatomic, readonly) DMCPaymentRequestStatus status;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

- (nullable DMCPayment*) paymentWithTransaction:(nullable DMCTransaction*)tx;

- (nullable DMCPayment*) paymentWithTransactions:(nullable  NSArray*)txs memo:(nullable NSString*)memo;

@end

@interface DMCPaymentDetails : NSObject

// Mainnet or testnet. Default is mainnet.
@property(nonatomic, readonly, nonnull) DMCNetwork* network;

// Array of transaction outputs storing `value` in satoshis and `script` where payment should be sent.
// Unspecified amounts are set to DMC_MAX_MONEY so you can know if zero amount was actually specified (e.g. for OP_RETURN or proof-of-burn etc).
@property(nonatomic, readonly, nonnull) NSArray* /*[DMCTransactionOutput]*/ outputs;

// Array of transaction inputs storing `previousHash` and `previousIndex`.
// Client should include these inputs in the transaction as they constitute product offered by the merchant.
@property(nonatomic, readonly, nonnull) NSArray* /*[DMCTransactionInput]*/ inputs;

// Date when the PaymentRequest was created.
@property(nonatomic, readonly, nonnull) NSDate* date;

// Date after which the PaymentRequest should be considered invalid.
@property(nonatomic, readonly, nullable) NSDate* expirationDate;

// Plain-text (no formatting) note that should be displayed to the customer, explaining what this PaymentRequest is for.
@property(nonatomic, readonly, nullable) NSString* memo;

// Secure location (usually https) where a Payment message (see below) may be sent to obtain a PaymentACK.
// The payment_url specified in the PaymentDetails should remain valid at least until the PaymentDetails expires
// (or as long as possible if the PaymentDetails does not expire).
// Note that this is irrespective of any state change in the underlying payment request;
// for example cancellation of an order should not invalidate the payment_url,
// as it is important that the merchant's server can record mis-payments in order to refund the payment.
@property(nonatomic, readonly, nullable) NSURL* paymentURL;

// Arbitrary data that may be used by the merchant to identify the PaymentRequest.
// May be omitted if the merchant does not need to associate Payments with PaymentRequest or
// if they associate each PaymentRequest with a separate payment address.
@property(nonatomic, readonly, nullable) NSData* merchantData;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

@end

// Payment messages are sent after the customer has authorized payment.
@interface DMCPayment : NSObject

// Should be copied from PaymentDetails.merchant_data.
// Merchants may use invoice numbers or any other data they require
// to match Payments to PaymentRequests.
@property(nonatomic, readonly, nullable) NSData* merchantData;

// One or more valid, signed DaemsCoin transactions that fully pay the PaymentRequest
@property(nonatomic, readonly, nonnull) NSArray* /*[DMCTransaction]*/ transactions;

// Output scripts and amounts. Amounts are optional and can be zero.
@property(nonatomic, readonly, nonnull) NSArray* /*[DMCTransactionOutput]*/ refundOutputs;

// Plain-text note from the customer to the merchant.
@property(nonatomic, readonly, nullable) NSString* memo;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

@end

// PaymentACK is the final message in the payment protocol;
// it is sent from the merchant's server to the daemsCoin wallet in response to a Payment message.
@interface DMCPaymentACK : NSObject

// Copy of the Payment message that triggered this PaymentACK.
// Clients may ignore this if they implement another way of associating Payments with PaymentACKs.
@property(nonatomic, readonly, nonnull) DMCPayment* payment;

// Note that should be displayed to the customer giving the status of the transaction
// (e.g. "Payment of 1 DMC for eleven tribbles accepted for processing.")
@property(nonatomic, readonly, nullable) NSString* memo;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

@end
