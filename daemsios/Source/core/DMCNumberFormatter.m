#import "DMCNumberFormatter.h"

#define NarrowNbsp @"\xE2\x80\xAF"
//#define PunctSpace @" "
//#define ThinSpace  @" "

NSString* const DMCNumberFormatterDaemsCoinCode    = @"XBT";

NSString* const DMCNumberFormatterSymbolDMC      = @"Ƀ" @"";
NSString* const DMCNumberFormatterSymbolMilliDMC = @"mɃ";
NSString* const DMCNumberFormatterSymbolBit      = @"ƀ";
NSString* const DMCNumberFormatterSymbolSatoshi  = @"ṡ";

DMCAmount DMCAmountFromDecimalNumber(NSNumber* num) {
    if ([num isKindOfClass:[NSDecimalNumber class]]) {
        NSDecimalNumber* dnum = (id)num;
        // Starting iOS 8.0.2, the longLongValue method returns 0 for some non rounded values.
        // Rounding the number looks like a work around.
        NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                          scale:0
                                                                                               raiseOnExactness:NO
                                                                                                raiseOnOverflow:YES
                                                                                               raiseOnUnderflow:NO
                                                                                            raiseOnDivideByZero:YES];
        num = [dnum decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    }
    DMCAmount sat = [num longLongValue];
    return sat;
}

@implementation DMCNumberFormatter {
    NSDecimalNumber* _myMultiplier; // because standard multiplier when below 1e-6 leads to a rounding no matter what the settings.
}

- (id) initWithDaemsCoinUnit:(DMCNumberFormatterUnit)unit {
    return [self initWithDaemsCoinUnit:unit symbolStyle:DMCNumberFormatterSymbolStyleNone];
}

- (id) initWithDaemsCoinUnit:(DMCNumberFormatterUnit)unit symbolStyle:(DMCNumberFormatterSymbolStyle)symbolStyle {
    if (self = [super init]) {
        _daemsCoinUnit = unit;
        _symbolStyle = symbolStyle;

        [self updateFormatterProperties];
    }
    return self;
}

- (void) setDaemsCoinUnit:(DMCNumberFormatterUnit)daemsCoinUnit {
    if (_daemsCoinUnit == daemsCoinUnit) return;
    _daemsCoinUnit = daemsCoinUnit;
    [self updateFormatterProperties];
}

- (void) setSymbolStyle:(DMCNumberFormatterSymbolStyle)suffixStyle {
    if (_symbolStyle == suffixStyle) return;
    _symbolStyle = suffixStyle;
    [self updateFormatterProperties];
}

- (void) updateFormatterProperties {
    // Reset formats so they are recomputed after we change properties.
    self.positiveFormat = nil;
    self.negativeFormat = nil;

    self.lenient = YES;
    self.generatesDecimalNumbers = YES;
    self.numberStyle = NSNumberFormatterCurrencyStyle;
    self.currencyCode = @"XBT";
    self.groupingSize = 3;

    self.currencySymbol = [self daemsCoinUnitSymbol] ?: @"";

    self.internationalCurrencySymbol = self.currencySymbol;

    // On iOS 8 we have to set these *after* setting the currency symbol.
    switch (_daemsCoinUnit) {
        case DMCNumberFormatterUnitSatoshi:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:NO];
            self.minimumFractionDigits = 0;
            self.maximumFractionDigits = 0;
            break;
        case DMCNumberFormatterUnitBit:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-2 isNegative:NO];
            self.minimumFractionDigits = 0;
            self.maximumFractionDigits = 2;
            break;
        case DMCNumberFormatterUnitMilliDMC:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-5 isNegative:NO];
            self.minimumFractionDigits = 2;
            self.maximumFractionDigits = 5;
            break;
        case DMCNumberFormatterUnitDMC:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-8 isNegative:NO];
            self.minimumFractionDigits = 2;
            self.maximumFractionDigits = 8;
            break;
        default:
            [[NSException exceptionWithName:@"DMCNumberFormatter: not supported daemsCoin unit" reason:@"" userInfo:nil] raise];
    }

    switch (_symbolStyle) {
        case DMCNumberFormatterSymbolStyleNone:
            self.minimumFractionDigits = 0;
            self.positivePrefix = @"";
            self.positiveSuffix = @"";
            self.negativePrefix = @"–";
            self.negativeSuffix = @"";
            break;
        case DMCNumberFormatterSymbolStyleCode:
        case DMCNumberFormatterSymbolStyleLowercase:
            self.positivePrefix = @"";
            self.positiveSuffix = [NSString stringWithFormat:@" %@", self.currencySymbol]; // nobreaking space here.
            self.negativePrefix = @"-";
            self.negativeSuffix = self.positiveSuffix;
            break;

        case DMCNumberFormatterSymbolStyleSymbol:
            // Leave positioning of the currency symbol to locale (in English it'll be prefix, in French it'll be suffix).
            break;
    }
    self.maximum = @(DMC_MAX_MONEY);

    // Fixup prefix symbol with a no-breaking space. When it's postfix, Foundation puts nobr space already.
    self.positiveFormat = [self.positiveFormat stringByReplacingOccurrencesOfString:@"¤" withString:@"¤" NarrowNbsp "#"];

    // Fixup negative format to have the same format as positive format and a minus sign in front of the first digit.
    self.negativeFormat = [self.positiveFormat stringByReplacingCharactersInRange:[self.positiveFormat rangeOfString:@"#"] withString:@"–#"];
}

- (NSString *) standaloneSymbol {
    NSString* sym = [self daemsCoinUnitSymbol];
    if (!sym) {
        sym = [self daemsCoinUnitSymbolForUnit:_daemsCoinUnit];
    }
    return sym;
}

- (NSString*) daemsCoinUnitSymbol {
    return [self daemsCoinUnitSymbolForStyle:_symbolStyle unit:_daemsCoinUnit];
}

- (NSString*) unitCode {
    return [self daemsCoinUnitCodeForUnit:_daemsCoinUnit];
}

- (NSString*) daemsCoinUnitCodeForUnit:(DMCNumberFormatterUnit)unit {
    switch (unit) {
        case DMCNumberFormatterUnitSatoshi:
            return NSLocalizedStringFromTable(@"SAT", @"DaemsCoin", @"");
        case DMCNumberFormatterUnitBit:
            return NSLocalizedStringFromTable(@"Bits", @"DaemsCoin", @"");
        case DMCNumberFormatterUnitMilliDMC:
            return NSLocalizedStringFromTable(@"mDMC", @"DaemsCoin", @"");
        case DMCNumberFormatterUnitDMC:
            return NSLocalizedStringFromTable(@"DMC", @"DaemsCoin", @"");
        default:
            [[NSException exceptionWithName:@"DMCNumberFormatter: not supported daemsCoin unit" reason:@"" userInfo:nil] raise];
    }
}

- (NSString*) daemsCoinUnitSymbolForUnit:(DMCNumberFormatterUnit)unit {
    switch (unit) {
        case DMCNumberFormatterUnitSatoshi:
            return DMCNumberFormatterSymbolSatoshi;
        case DMCNumberFormatterUnitBit:
            return DMCNumberFormatterSymbolBit;
        case DMCNumberFormatterUnitMilliDMC:
            return DMCNumberFormatterSymbolMilliDMC;
        case DMCNumberFormatterUnitDMC:
            return DMCNumberFormatterSymbolDMC;
        default:
            [[NSException exceptionWithName:@"DMCNumberFormatter: not supported daemsCoin unit" reason:@"" userInfo:nil] raise];
    }
}

- (NSString*) daemsCoinUnitSymbolForStyle:(DMCNumberFormatterSymbolStyle)symbolStyle unit:(DMCNumberFormatterUnit)daemsCoinUnit {
    switch (symbolStyle) {
        case DMCNumberFormatterSymbolStyleNone:
            return nil;
        case DMCNumberFormatterSymbolStyleCode:
            return [self daemsCoinUnitCodeForUnit:daemsCoinUnit];
        case DMCNumberFormatterSymbolStyleLowercase:
            return [[self daemsCoinUnitCodeForUnit:daemsCoinUnit] lowercaseString];
        case DMCNumberFormatterSymbolStyleSymbol:
            return [self daemsCoinUnitSymbolForUnit:daemsCoinUnit];
        default:
            [[NSException exceptionWithName:@"DMCNumberFormatter: not supported symbol style" reason:@"" userInfo:nil] raise];
    }
    return nil;
}

- (NSString *) placeholderText {
    //NSString* groupSeparator = self.currencyGroupingSeparator ?: @"";
    NSString* decimalPoint = self.currencyDecimalSeparator ?: @".";
    switch (_daemsCoinUnit) {
        case DMCNumberFormatterUnitSatoshi:
            return @"0";
        case DMCNumberFormatterUnitBit:
            return [NSString stringWithFormat:@"0%@00", decimalPoint];
        case DMCNumberFormatterUnitMilliDMC:
            return [NSString stringWithFormat:@"0%@00000", decimalPoint];
        case DMCNumberFormatterUnitDMC:
            return [NSString stringWithFormat:@"0%@00000000", decimalPoint];
        default:
            [[NSException exceptionWithName:@"DMCNumberFormatter: not supported daemsCoin unit" reason:@"" userInfo:nil] raise];
            return nil;
    }
}

- (NSString*) stringFromNumber:(NSNumber *)number {
    if (![number isKindOfClass:[NSDecimalNumber class]]) {
        number = [NSDecimalNumber decimalNumberWithDecimal:number.decimalValue];
    }
    return [super stringFromNumber:[(NSDecimalNumber*)number decimalNumberByMultiplyingBy:_myMultiplier]];
}

- (NSNumber*) numberFromString:(NSString *)string {
    // self.generatesDecimalNumbers guarantees NSDecimalNumber here.
    NSDecimalNumber* number = (NSDecimalNumber*)[super numberFromString:string];
    return [number decimalNumberByDividingBy:_myMultiplier];
}

- (NSString *) stringFromAmount:(DMCAmount)amount {
    return [self stringFromNumber:@(amount)];
}

- (DMCAmount) amountFromString:(NSString *)string {
    return DMCAmountFromDecimalNumber([self numberFromString:string]);
}

- (id) copyWithZone:(NSZone *)zone {
    return [[DMCNumberFormatter alloc] initWithDaemsCoinUnit:self.daemsCoinUnit symbolStyle:self.symbolStyle];
}


@end
