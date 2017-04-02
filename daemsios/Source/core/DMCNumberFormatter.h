// 

#import <Foundation/Foundation.h>
#import "DMCUnitsAndLimits.h"

typedef NS_ENUM(NSInteger, DMCNumberFormatterUnit) {
    DMCNumberFormatterUnitSatoshi  = 0, // satoshis = 0.00000001 DMC
    DMCNumberFormatterUnitBit      = 2, // bits     = 0.000001 DMC
    DMCNumberFormatterUnitMilliDMC = 5, // mDMC     = 0.001 DMC
    DMCNumberFormatterUnitDMC      = 8, // DMC      = 100 million satoshis
};

typedef NS_ENUM(NSInteger, DMCNumberFormatterSymbolStyle) {
    DMCNumberFormatterSymbolStyleNone      = 0, // no suffix
    DMCNumberFormatterSymbolStyleCode      = 1, // suffix is DMC, mDMC, Bits or SAT
    DMCNumberFormatterSymbolStyleLowercase = 2, // suffix is DMC, mDMC, bits or sat
    DMCNumberFormatterSymbolStyleSymbol    = 3, // suffix is Ƀ, mɃ, ƀ or ṡ
};

extern NSString* const DMCNumberFormatterDaemsCoinCode;    // XBT
extern NSString* const DMCNumberFormatterSymbolDMC;      // Ƀ
extern NSString* const DMCNumberFormatterSymbolMilliDMC; // mɃ
extern NSString* const DMCNumberFormatterSymbolBit;      // ƀ
extern NSString* const DMCNumberFormatterSymbolSatoshi;  // ṡ

/*!
 * Rounds the decimal number and returns its longLongValue.
 * Do not use NSDecimalNumber.longLongValue as it will return 0 on iOS 8.0.2 if the number is not rounded first.
 */
DMCAmount DMCAmountFromDecimalNumber(NSNumber* num);

@interface DMCNumberFormatter : NSNumberFormatter

/*!
 * Instantiates and configures number formatter with given unit and suffix style.
 */
- (id) initWithDaemsCoinUnit:(DMCNumberFormatterUnit)unit;
- (id) initWithDaemsCoinUnit:(DMCNumberFormatterUnit)unit symbolStyle:(DMCNumberFormatterSymbolStyle)symbolStyle;

/*!
 * Unit size to be displayed (regardless of how it is presented)
 */
@property(nonatomic) DMCNumberFormatterUnit daemsCoinUnit;

/*!
 * Style of formatting the units regardless of the unit size.
 */
@property(nonatomic) DMCNumberFormatterSymbolStyle symbolStyle;

/*!
 * Placeholder text for the input field.
 * E.g. "0 000 000.00" for 'bits' and "0.00000000" for 'DMC'.
 */
@property(nonatomic, readonly) NSString* placeholderText;

/*!
 * Returns a matching daemsCoin symbol.
 * If `symbolStyle` is DMCNumberFormatterSymbolStyleNone, returns the code (DMC, mDMC, Bits or SAT).
 */
@property(nonatomic, readonly) NSString* standaloneSymbol;

/*!
 * Returns a matching daemsCoin unit code (DMC, mDMC etc) regardless of the symbol style.
 */
@property(nonatomic, readonly) NSString* unitCode;

/*!
 * Formats the amount according to units and current formatting style.
 */
- (NSString *) stringFromAmount:(DMCAmount)amount;

/*!
 * Returns 0 in case of failure to parse the string.
 * To handle that case, use `-[NSNumberFormatter numberFromString:]`, but keep in mind
 * that NSNumber* will be in specified units, not in satoshis.
 */
- (DMCAmount) amountFromString:(NSString *)string;

@end
