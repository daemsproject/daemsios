#import "DMCDaemsCoinURL.h"
#import "DMCAddress.h"
#import "DMCAssetAddress.h"
#import "DMCAssetID.h"
#import "DMCNumberFormatter.h"

NSString* const DMCDaemsCoinURLSchemeDaemsCoin = @"daemsCoin";
NSString* const DMCDaemsCoinURLSchemeOpenAssets = @"openassets";

@interface DMCDaemsCoinURL ()
@property NSMutableDictionary* mutableQueryParameters;
@property NSString* scheme;
@end

@implementation DMCDaemsCoinURL

@synthesize amount = _amount;
@synthesize label = _label;
@synthesize assetID = _assetID;
@synthesize message = _message;
@synthesize paymentRequestURL = _paymentRequestURL;
@synthesize queryParameters = _queryParameters;

+ (NSURL*) URLWithAddress:(DMCAddress*)address amount:(DMCAmount)amount label:(NSString*)label {
    DMCDaemsCoinURL* DMCurl = [[self alloc] init];
    DMCurl.scheme = @"daemsCoin";
    DMCurl.address = address;
    DMCurl.amount = amount;
    DMCurl.label = label;
    return DMCurl.URL;
}

- (id) init {
    if (self = [super init]) {
        self.mutableQueryParameters = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) initWithURL:(NSURL*)url {
    if (!url) return nil;

    NSURLComponents* comps = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];

    if (!comps) {
        return nil;
    }

    NSString* scheme = [comps.scheme lowercaseString];

    // We only support daemsCoin: and openassets: schemes.
    if (![scheme isEqual:DMCDaemsCoinURLSchemeDaemsCoin] &&
        ![scheme isEqual:DMCDaemsCoinURLSchemeOpenAssets]) {
        return nil;
    }

    // We allow empty address, but if it's not empty, it must be a valid address.
    DMCAddress* address = nil;
    if (comps.path.length > 0) {
        address = [DMCAddress addressWithString:comps.path];
        if (!address) {
            return nil;
        }
    }

    if (self = [self init]) {
        self.address = address;
        for (NSURLQueryItem* item in comps.queryItems) {
            [self.mutableQueryParameters setObject:item.value forKey:item.name];
        }
    }

    self.scheme = scheme;

    return self;
}

- (BOOL) isValid {
    return [self isValidDaemsCoinURL] || [self isValidOpenAssetsURL];
}

- (BOOL) isDaemsCoinAddress {
    return [self.address isKindOfClass:[DMCPublicKeyAddress class]] ||
           [self.address isKindOfClass:[DMCScriptHashAddress class]];
}

- (BOOL) isValidDaemsCoinURL {
    if ([self.scheme isEqualToString:DMCDaemsCoinURLSchemeDaemsCoin]) {
        return [self isDaemsCoinAddress] || (!self.address && self.paymentRequestURL);
    }
    return NO;
}

- (BOOL) isValidOpenAssetsURL {
    if ([self.scheme isEqualToString:DMCDaemsCoinURLSchemeDaemsCoin] ||
        [self.scheme isEqualToString:DMCDaemsCoinURLSchemeOpenAssets]) {

        // We should either have an asset address with asset ID, or no address and payment request URL.
        return ([self.address isKindOfClass:[DMCAssetAddress class]] && self.assetID) || (!self.address && !self.assetID && self.paymentRequestURL);
    }
    return NO;
}

- (NSURL*) URL {
    NSMutableString* string = [NSMutableString stringWithFormat:@"%@:%@", self.scheme, self.address ? self.address.string : @""];
    NSMutableArray* queryItems = [NSMutableArray array];

    if(self.queryParameters) {
        NSArray* keys = self.queryParameters.allKeys;
        for (NSString* key in keys) {
            NSString* encodedKey = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)key, NULL, CFSTR("&="),
                                                                                             kCFStringEncodingUTF8));
            NSString* encodedValue = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[self.queryParameters objectForKey:key], NULL, CFSTR("&="),
                                                                                               kCFStringEncodingUTF8));
            [queryItems addObject:[NSString stringWithFormat:@"%@=%@",encodedKey,encodedValue]];
             
        }
    }

    if (queryItems.count > 0) {
        [string appendString:@"?"];
        [string appendString:[queryItems componentsJoinedByString:@"&"]];
    }

    return [NSURL URLWithString:string];
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key {
    return self.mutableQueryParameters[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    self.mutableQueryParameters[key] = obj;
}

- (NSDictionary*) queryParameters {
    return self.mutableQueryParameters;
}

- (void) setQueryParameters:(NSDictionary *)queryParameters {
    self.mutableQueryParameters = [NSMutableDictionary dictionaryWithDictionary:queryParameters ?: @{}];
    //Reset cached standard query parameters
    _amount = 0;
    _paymentRequestURL = nil;
    _message = nil;
    _label = nil;
    _assetID = nil;
}




#pragma mark - Standard query parameters


- (void) setAddress:(DMCAddress *)address {
    // Make sure to reformat amount according to the address.
    DMCAmount amount = self.amount;
    _address = address;
    self.amount = amount;
}

- (DMCAmount) amount {
    if(_amount == 0){
        NSString* amountString = self.mutableQueryParameters[@"amount"];
        if (amountString) _amount = [DMCDaemsCoinURL parseAmount:amountString address:self.address];
    }
    return _amount;
}

- (void) setAmount:(DMCAmount)amount {
    _amount = amount;
    if (amount > 0) {
        NSString* amountString = [DMCDaemsCoinURL formatAmount:amount address:self.address];
        self.mutableQueryParameters[@"amount"] = amountString;
    } else {
        [self.mutableQueryParameters removeObjectForKey:@"amount"];
    }
}

- (DMCAssetID*) assetID {
    return [DMCAssetID assetIDWithString:self.mutableQueryParameters[@"asset"]];
}

- (void) setAssetID:(DMCAssetID *)assetID {
    if (assetID) {
        self.mutableQueryParameters[@"asset"] = assetID.string;
    } else {
        [self.mutableQueryParameters removeObjectForKey:@"asset"];
    }
}

- (NSURL*) paymentRequestURL {
    if (!_paymentRequestURL) {
        NSString* r = self.mutableQueryParameters[@"r"];
        if (r) _paymentRequestURL = [NSURL URLWithString:r];
    }
    return _paymentRequestURL;
}

- (void) setPaymentRequestURL:(NSURL *)paymentRequestURL {
    _paymentRequestURL = paymentRequestURL;
    if(paymentRequestURL != nil) {
        self.mutableQueryParameters[@"r"] = paymentRequestURL.absoluteString;
    } else {
        [self.mutableQueryParameters removeObjectForKey:@"r"];
    }
}

- (NSString*) label {
    if(!_label) {
        _label = self.mutableQueryParameters[@"label"];
    }
    return _label;
}

- (void) setLabel:(NSString *)label {
    _label = label;
    if(label != nil) {
        self.mutableQueryParameters[@"label"] = label;
    } else {
        [self.mutableQueryParameters removeObjectForKey:@"label"];
    }
}

- (NSString*) message {
    if(!_message) {
        _message = self.mutableQueryParameters[@"message"];
    }
    return _message;
}

- (void) setMessage:(NSString *)message {
    _message = message;
    if(message != nil) {
        self.mutableQueryParameters[@"message"] = message;
    } else {
        [self.mutableQueryParameters removeObjectForKey:@"message"];
    }
}

#pragma mark - Helpers

+ (NSString*) formatAmount:(DMCAmount)amount address:(DMCAddress*)address {
    // Open Assets urls should have amount formatted as integer
    if (address && [address isKindOfClass:[DMCAssetAddress class]]) {
        return @(amount).stringValue;
    }
    return [NSString stringWithFormat:@"%d.%08d", (int)(amount / DMCCoin), (int)(amount % DMCCoin)];
}

+ (DMCAmount) parseAmount:(NSString*)string address:(DMCAddress*)address {

    // Open Assets urls should have amount formatted as integer
    if (address && [address isKindOfClass:[DMCAssetAddress class]]) {
        return [string longLongValue];
    }

    NSLocale* locale = [[NSLocale localeWithLocaleIdentifier:@"en_US"] copy]; // uses period (".") as a decimal point.
    NSAssert([[locale objectForKey:NSLocaleDecimalSeparator] isEqual:@"."], @"must be point as a decimal separator");
    NSDecimalNumber* dn = [NSDecimalNumber decimalNumberWithString:string locale:locale];
    // Fixes crash on URL like "daemsCoin:1shaYanre36PBhspFL9zG7nt6tfDhxQ4u?amount=#" (https://twitter.com/sbetamc/status/581974120440700929)
    if ([dn isEqual:[NSDecimalNumber notANumber]]) {
        return 0;
    }
    if (DMCAmountFromDecimalNumber(dn) > 21000000) { // prevent overflow when multiplying by 8.
        return 0;
    }
    dn = [dn decimalNumberByMultiplyingByPowerOf10:8];
    return DMCAmountFromDecimalNumber(dn);
}

@end
