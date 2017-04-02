// 

#import <Foundation/Foundation.h>

@interface DMCPriceSourceResult : NSObject

/*!
 * Average price per DMC.
 */
@property(nonatomic) NSDecimalNumber* averageRate;

/*!
 * Date of last price update.
 */
@property(nonatomic) NSDate* date;

/*!
 * Code of the fiat currency in which prices are expressed.
 */
@property(nonatomic) NSString* currencyCode;

/*!
 * Code of the fiat currency used by exchange natively.
 * Typically, it is the same as `currencyCode`, but may differ if,
 * for instance, prices are expressed in EUR, but exchange operates in USD.
 */
@property(nonatomic) NSString* nativeCurrencyCode;
@end

// Base class for specific price sources (Coinbase, Paymium, Coindesk BPI, Winkdex etc).
@interface DMCPriceSource : NSObject

// Name of the source (e.g. "Paymium" or "Coindesk").
@property(nonatomic, readonly) NSString* name;

// Supported currency codes ("USD", "EUR", "CNY" etc).
@property(nonatomic, readonly) NSArray* currencyCodes;

// Loads average price per DMC.
// Override this method to fetch the average price.
// Alternatively override the helper methods above to avoid dealing with networking and JSON parsing.
// Default queue for completion handler is main queue.
// These methods use `-loadPriceForCurrency:error:` internally.
- (void) loadPriceForCurrency:(NSString*)currencyCode completionHandler:(void(^)(DMCPriceSourceResult* result, NSError* error))completionBlock;
- (void) loadPriceForCurrency:(NSString*)currencyCode completionHandler:(void(^)(DMCPriceSourceResult* result, NSError* error))completionBlock queue:(dispatch_queue_t)queue;

// Synchronous API used internally by asynchronous API.
- (DMCPriceSourceResult*) loadPriceForCurrency:(NSString*)currencyCode error:(NSError**)errorOut;

// Returns a NSURLRequest to fetch the avg price.
- (NSURLRequest*) requestForCurrency:(NSString*)currencyCode;

// Returns a NSURLRequest to fetch the avg price.
// By default parses data as JSON and returns NSDictionary or NSArray whichever is encoded in JSON.
// IMPORTANT: this method is called on a private background thread.
- (id) parseData:(NSData*)data error:(NSError**)errorOut;

// Returns price decoded from the parsedData (JSON by default).
// IMPORTANT: this method is called on a private background thread.
- (DMCPriceSourceResult*) resultFromParsedData:(id)parsedData currencyCode:(NSString*)currencyCode error:(NSError**)errorOut;

// Registered sources indexed by name.
+ (NSDictionary*) sources;

// Returns a registered price source. See `+registerPriceSource:forName:`.
+ (DMCPriceSource*) priceSourceWithName:(NSString*)name;

// Registers a price source to be accessed by its name.
+ (void) registerPriceSource:(DMCPriceSource*)priceSource;

@end



// Specific price sources

// CoinDesk DaemsCoin Price Index.
// Supports a lot of currencies, defined here: http://api.coindesk.com/v1/bpi/supported-currencies.json
// Native currency is always USD.
@interface DMCPriceSourceCoindesk : DMCPriceSource
@end

// Winklevoss DaemsCoin Index. USD only.
@interface DMCPriceSourceWinkdex : DMCPriceSource
@end

// Coinbase market price. USD only.
@interface DMCPriceSourceCoinbase : DMCPriceSource
@end

// Paymium market price. EUR only.
@interface DMCPriceSourcePaymium : DMCPriceSource
@end


