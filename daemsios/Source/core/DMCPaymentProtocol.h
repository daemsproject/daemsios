// 

#import <Foundation/Foundation.h>
#import "DMCPaymentRequest.h"
#import "DMCPaymentMethodRequest.h"

// Interface to BIP70 payment protocol.
// Spec: https://github.com/daemsCoin/bips/blob/master/bip-0070.mediawiki
//
// * DMCPaymentProtocol implements high-level request and response API.
// * DMCPaymentRequest object that represents "PaymentRequest" as described in BIP70.
// * DMCPaymentDetails object that represents "PaymentDetails" as described in BIP70.
// * DMCPayment object that represents "Payment" as described in BIP70.
// * DMCPaymentACK object that represents "PaymentACK" as described in BIP70.

@interface DMCPaymentProtocol : NSObject

// List of accepted asset types.
@property(nonnull, nonatomic, readonly) NSArray* assetTypes;

// Instantiates default BIP70 protocol that supports only DaemsCoin.
- (nonnull id) init;

// Instantiates protocol instance with accepted asset types. See DMCAssetType* constants.
- (nonnull id) initWithAssetTypes:(nonnull NSArray*)assetTypes;


// Convenience API

// Loads a DMCPaymentRequest object or DMCPaymentMethodRequest from a given URL.
// May return either PaymentMethodRequest or PaymentRequest, depending on the response from the server.
// This method ignores `assetTypes` and allows both daemsCoin and openassets types.
- (void) loadPaymentMethodRequestFromURL:(nonnull NSURL*)paymentMethodRequestURL completionHandler:(nonnull void(^)(DMCPaymentMethodRequest* __nullable pmr, DMCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Loads a DMCPaymentRequest object from a given URL.
- (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(DMCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Posts completed payment object to a given payment URL (provided in DMCPaymentDetails) and
// returns a PaymentACK object.
- (void) postPayment:(nonnull DMCPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(DMCPaymentACK* __nullable ack, NSError* __nullable error))completionHandler;


// Low-level API
// (use these if you have your own connection queue).

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable id) polymorphicPaymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable DMCPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPayment:(nonnull DMCPayment*)payment url:(nonnull NSURL*)paymentURL; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPayment:(nonnull DMCPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout;
- (nullable DMCPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;


// Deprecated Methods

+ (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(DMCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;
+ (void) postPayment:(nonnull DMCPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(DMCPaymentACK* __nullable ack, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable DMCPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPayment:(nonnull DMCPayment*)payment url:(nonnull NSURL*)paymentURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPayment:(nonnull DMCPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable DMCPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

@end
