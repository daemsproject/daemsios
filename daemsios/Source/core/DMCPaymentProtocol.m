// 

#import "DMCPaymentProtocol.h"
#import "DMCPaymentRequest.h"
#import "DMCErrors.h"
#import "DMCAssetType.h"
#import <Security/Security.h>

static NSString* const DMCDaemsCoinPaymentRequestMimeType = @"application/daemsCoin-paymentrequest";
static NSString* const DMCOpenAssetsPaymentRequestMimeType = @"application/oa-paymentrequest";
static NSString* const DMCOpenAssetsPaymentMethodRequestMimeType = @"application/oa-paymentmethodrequest";

@interface DMCPaymentProtocol ()
@property(nonnull, nonatomic, readwrite) NSArray* assetTypes;
@property(nonnull, nonatomic) NSArray* paymentRequestMediaTypes;
@end

@implementation DMCPaymentProtocol

// Instantiates default BIP70 protocol that supports only DaemsCoin.
- (nonnull id) init {
    return [self initWithAssetTypes:@[ DMCAssetTypeDaemsCoin ]];
}

// Instantiates protocol instance with accepted asset types.
- (nonnull id) initWithAssetTypes:(nonnull NSArray*)assetTypes {
    NSParameterAssert(assetTypes);
    NSParameterAssert(assetTypes.count > 0);
    if (self = [super init]) {
        self.assetTypes = assetTypes;
    }
    return self;
}

- (NSArray*) paymentRequestMediaTypes {
    if (!_paymentRequestMediaTypes && self.assetTypes) {
        NSMutableArray* arr = [NSMutableArray array];
        for (NSString* assetType in self.assetTypes) {
            if ([assetType isEqual:DMCAssetTypeDaemsCoin]) {
                [arr addObject:DMCDaemsCoinPaymentRequestMimeType];
            } else if ([assetType isEqual:DMCAssetTypeOpenAssets]) {
                [arr addObject:DMCOpenAssetsPaymentRequestMimeType];
            }
        }
        _paymentRequestMediaTypes = arr;
    }
    return _paymentRequestMediaTypes;
}

- (NSInteger) maxDataLength {
    return 50000;
}


// Convenience API


- (void) loadPaymentMethodRequestFromURL:(nonnull NSURL*)paymentMethodRequestURL
                       completionHandler:(nonnull void(^)(DMCPaymentMethodRequest* __nullable pmr, DMCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler {

    NSParameterAssert(paymentMethodRequestURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPaymentMethodRequestWithURL:paymentMethodRequestURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, nil, error);
            });
            return;
        }
        id prOrPmr = [self polymorphicPaymentRequestFromData:data response:response error:&error];
        DMCPaymentRequest* pr = ([prOrPmr isKindOfClass:[DMCPaymentRequest class]] ? prOrPmr : nil);
        DMCPaymentMethodRequest* pmr = ([prOrPmr isKindOfClass:[DMCPaymentMethodRequest class]] ? prOrPmr : nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(pmr, pr, prOrPmr ? nil : error);
        });
    });
}


- (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(DMCPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler {
    NSParameterAssert(paymentRequestURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPaymentRequestWithURL:paymentRequestURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        DMCPaymentRequest* pr = [self paymentRequestFromData:data response:response error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(pr, pr ? nil : error);
        });
    });
}

- (void) postPayment:(nonnull DMCPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(DMCPaymentACK* __nullable ack, NSError* __nullable error))completionHandler {
    NSParameterAssert(payment);
    NSParameterAssert(paymentURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPayment:payment url:paymentURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        DMCPaymentACK* ack = [self paymentACKFromData:data response:response error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(ack, ack ? nil : error);
        });
    });
}


// Low-level API
// (use this if you have your own connection queue).

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url {
    return [self requestForPaymentMethodRequestWithURL:url timeout:10];
}

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout {
    if (!url) return nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    [request addValue:DMCDaemsCoinPaymentRequestMimeType forHTTPHeaderField:@"Accept"];
    [request addValue:DMCOpenAssetsPaymentRequestMimeType forHTTPHeaderField:@"Accept"];
    [request addValue:DMCOpenAssetsPaymentMethodRequestMimeType forHTTPHeaderField:@"Accept"];
    return request;
}

- (nullable id) polymorphicPaymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut {
    NSString* mime = response.MIMEType.lowercaseString;
    BOOL isPaymentRequest = [mime isEqual:DMCDaemsCoinPaymentRequestMimeType] ||
                            [mime isEqual:DMCOpenAssetsPaymentRequestMimeType];
    BOOL isPaymentMethodRequest = [mime isEqual:DMCOpenAssetsPaymentMethodRequestMimeType];

    if (!isPaymentRequest && !isPaymentMethodRequest) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }
    if (isPaymentRequest) {
        DMCPaymentRequest* pr = [[DMCPaymentRequest alloc] initWithData:data];
        if (!pr) {
            if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
            return nil;
        }
        return pr;
    } else if (isPaymentMethodRequest) {
        DMCPaymentMethodRequest* pmr = [[DMCPaymentMethodRequest alloc] initWithData:data];
        if (!pmr) {
            if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
            return nil;
        }
        return pmr;
    }
    return nil;

}

- (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL {
    return [self requestForPaymentRequestWithURL:paymentRequestURL timeout:10];
}

- (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout {
    if (!paymentRequestURL) return nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:paymentRequestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    for (NSString* mimeType in self.paymentRequestMediaTypes) {
        [request addValue:mimeType forHTTPHeaderField:@"Accept"];
    }
    return request;
}

- (DMCPaymentRequest*) paymentRequestFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {

    NSArray* mimes = self.paymentRequestMediaTypes;
    NSString* mime = response.MIMEType.lowercaseString;
    if (![mimes containsObject:mime]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }
    DMCPaymentRequest* pr = [[DMCPaymentRequest alloc] initWithData:data];
    if (!pr) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (pr.version == DMCPaymentRequestVersion1 && ![self.assetTypes containsObject:DMCAssetTypeDaemsCoin]) {
        // Client did not want daemsCoin, but received daemsCoin.
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (pr.version == DMCPaymentRequestVersionOpenAssets1 && ![self.assetTypes containsObject:DMCAssetTypeOpenAssets]) {
        // Client did not want open assets, but received open assets.
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    return pr;
}

- (NSURLRequest*) requestForPayment:(DMCPayment*)payment url:(NSURL*)paymentURL {
    return [self requestForPayment:payment url:paymentURL timeout:10];
}

- (NSURLRequest*) requestForPayment:(DMCPayment*)payment url:(NSURL*)paymentURL timeout:(NSTimeInterval)timeout {
    if (!payment) return nil;
    if (!paymentURL) return nil;

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:paymentURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];

    [request addValue:@"application/daemsCoin-payment" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/daemsCoin-paymentack" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payment.data];
    return request;
}

- (DMCPaymentACK*) paymentACKFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {

    if (![response.MIMEType.lowercaseString isEqual:@"application/daemsCoin-paymentack"]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }

    DMCPaymentACK* ack = [[DMCPaymentACK alloc] initWithData:data];

    if (!ack) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain code:DMCErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    
    return ack;
}




// DEPRECATED METHODS

+ (void) loadPaymentRequestFromURL:(NSURL*)paymentRequestURL completionHandler:(void(^)(DMCPaymentRequest* pr, NSError* error))completionHandler {
    [[[self alloc] init] loadPaymentRequestFromURL:paymentRequestURL completionHandler:completionHandler];
}
+ (void) postPayment:(DMCPayment*)payment URL:(NSURL*)paymentURL completionHandler:(void(^)(DMCPaymentACK* ack, NSError* error))completionHandler {
    [[[self alloc] init] postPayment:payment URL:paymentURL completionHandler:completionHandler];
}

+ (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL {
    return [self requestForPaymentRequestWithURL:paymentRequestURL timeout:10];
}

+ (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout {
    return [[[self alloc] init] requestForPaymentRequestWithURL:paymentRequestURL timeout:timeout];
}

+ (DMCPaymentRequest*) paymentRequestFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {
    return [[[self alloc] init] paymentRequestFromData:data response:response error:errorOut];
}

+ (NSURLRequest*) requestForPayment:(DMCPayment*)payment url:(NSURL*)paymentURL {
    return [self requestForPayment:payment url:paymentURL timeout:10];
}

+ (NSURLRequest*) requestForPayment:(DMCPayment*)payment url:(NSURL*)paymentURL timeout:(NSTimeInterval)timeout {
    return [[[self alloc] init] requestForPayment:payment url:paymentURL timeout:timeout];
}

+ (DMCPaymentACK*) paymentACKFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {
    return [[[self alloc] init] paymentACKFromData:data response:response error:errorOut];
}

@end


