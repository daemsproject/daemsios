//
//  DMCCurrencyConverter+Tests.m
//  DaemsCoin
//
//  Created by Andrew Ogden on 5/4/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

#import "DMCCurrencyConverter+Tests.h"


@implementation DMCCurrencyConverter (Tests)

+ (void) runAllTests {
    [self testRateUpdates];
    [self testAsksAndBids];
    [self testFiatConversions];
}

+ (void) testRateUpdates {
    DMCCurrencyConverter* converter = [[DMCCurrencyConverter alloc] init];
    [converter setBuyRate:[NSDecimalNumber decimalNumberWithString:@"210.0"]];
    [converter setSellRate:[NSDecimalNumber decimalNumberWithString:@"200.0"]];
    
    NSAssert(converter.averageRate.doubleValue == 205.0, @"Average should be from buy and sell rates");
    
    [converter setAverageRate:[NSDecimalNumber decimalNumberWithString:@"300.0"]];
    
    NSAssert(converter.sellRate.doubleValue == 300.0, @"Setting average should reassign sell rate");
    NSAssert(converter.buyRate.doubleValue == 300.0, @"Setting average should reassign buy rate");
}

+ (void) testAsksAndBids {
    DMCCurrencyConverter* converter = [[DMCCurrencyConverter alloc] init];
    [converter setBuyRate:[NSDecimalNumber decimalNumberWithString:@"210.0"]];
    [converter setSellRate:[NSDecimalNumber decimalNumberWithString:@"200.0"]];
    
    NSArray* asks = @[@[[NSNumber numberWithDouble:209.0],[NSNumber numberWithDouble:1.0]]];
    
    [converter setAsks:asks];
    NSAssert(converter.asks,@"Should be valid ask array");
//    NSAssert([converter.buyRate isEqualTo:[NSDecimalNumber decimalNumberWithString:@"209.0"]], @"Buy rate should equal minimum of asks array");
    
    NSArray* bids = @[@[[NSNumber numberWithDouble:201.0],[NSNumber numberWithDouble:1.0]]];
    
    [converter setBids:bids];
    NSAssert(converter.bids,@"Should be valid bids array");
//    NSAssert([converter.sellRate isEqualTo:[NSDecimalNumber decimalNumberWithString:@"201.0"]], @"Sell rate should equal maximum of bids array");
}

+ (void) testFiatConversions {
    DMCCurrencyConverter* converter = [[DMCCurrencyConverter alloc] init];
    [converter setBuyRate:[NSDecimalNumber decimalNumberWithString:@"205.0"]];
    [converter setSellRate:[NSDecimalNumber decimalNumberWithString:@"195.0"]];
    
    converter.mode = DMCCurrencyConverterModeAverage;
    DMCAmount averageDMCAmout = [converter daemsCoinFromFiat:[NSDecimalNumber decimalNumberWithString:@"10.0"]];
    
    NSAssert(averageDMCAmout == 5000000, @"10.0 fiat with average DMC price of 200 should buy 5 million satoshis");
    
    converter.mode = DMCCurrencyConverterModeBuy;
    DMCAmount buyDMCAmount = [converter daemsCoinFromFiat:[NSDecimalNumber decimalNumberWithString:@"10.0"]];
    
    NSAssert(buyDMCAmount == 4878049, @"10.0 fiat with buy rate of 205 should buy 4878049 satoshis");
    
    converter.mode = DMCCurrencyConverterModeSell;
    DMCAmount sellDMCAmount = [converter daemsCoinFromFiat:[NSDecimalNumber decimalNumberWithString:@"10.0"]];
    
    NSAssert(sellDMCAmount == 5128205, @"10.0 fiat with sell rate of 195 should convert to 5128205 satoshis");
}


@end
