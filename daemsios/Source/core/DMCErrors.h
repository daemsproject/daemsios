// 

#import <Foundation/Foundation.h>

extern NSString* const DMCErrorDomain;

typedef NS_ENUM(NSUInteger, DMCErrorCode) {
    
    // Canonical pubkey/signature check errors
    DMCErrorNonCanonicalPublicKey            = 4001,
    DMCErrorNonCanonicalScriptSignature      = 4002,
    
    // Script verification errors
    DMCErrorScriptError                      = 5001,
    
    // DMCPriceSource errors
    DMCErrorUnsupportedCurrencyCode          = 6001,

    // BIP70 Payment Protocol errors
    DMCErrorPaymentRequestInvalidResponse    = 7001,
    DMCErrorPaymentRequestTooBig             = 7002,

    // Secret Sharing errors
    DMCErrorIncompatibleSecret               = 10001,
    DMCErrorInsufficientShares               = 10002,
    DMCErrorMalformedShare                   = 10003,
};
