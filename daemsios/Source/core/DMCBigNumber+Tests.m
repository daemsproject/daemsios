// Oleg Andreev <oleganza@gmail.com>

#import "DMCBigNumber+Tests.h"
#import "DMCData.h"

@implementation DMCBigNumber (Tests)

+ (void) runAllTests {
    NSAssert([[[DMCBigNumber alloc] init] isEqual:[DMCBigNumber zero]], @"default bignum should be zero");
    NSAssert(![[[DMCBigNumber alloc] init] isEqual:[DMCBigNumber one]], @"default bignum should not be one");
    NSAssert([@"0" isEqualToString:[[[DMCBigNumber alloc] init] stringInBase:10]], @"default bignum should be zero");
    NSAssert([[[DMCBigNumber alloc] initWithInt32:0] isEqual:[DMCBigNumber zero]], @"0 should be equal to itself");
    
    NSAssert([[DMCBigNumber one] isEqual:[DMCBigNumber one]], @"1 should be equal to itself");
    NSAssert([[DMCBigNumber one] isEqual:[[DMCBigNumber alloc] initWithUInt32:1]], @"1 should be equal to itself");
    
    NSAssert([[[DMCBigNumber one] stringInBase:16] isEqual:@"1"], @"1 should be correctly printed out");
    NSAssert([[[[DMCBigNumber alloc] initWithUInt32:1] stringInBase:16] isEqual:@"1"], @"1 should be correctly printed out");
    NSAssert([[[[DMCBigNumber alloc] initWithUInt32:0xdeadf00d] stringInBase:16] isEqual:@"deadf00d"], @"0xdeadf00d should be correctly printed out");
    
    NSAssert([[[[DMCBigNumber alloc] initWithUInt64:0xdeadf00ddeadf00d] stringInBase:16] isEqual:@"deadf00ddeadf00d"], @"0xdeadf00ddeadf00d should be correctly printed out");

    NSAssert([[[[DMCBigNumber alloc] initWithString:@"0b1010111" base:2] stringInBase:2] isEqual:@"1010111"], @"0b1010111 should be correctly parsed");
    NSAssert([[[[DMCBigNumber alloc] initWithString:@"0x12346789abcdef" base:16] stringInBase:16] isEqual:@"12346789abcdef"], @"0x12346789abcdef should be correctly parsed");
    
    {
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUInt64:0xdeadf00ddeadbeef];
        NSData* data = bn.signedLittleEndian;
        NSAssert([@"efbeadde0df0adde00" isEqualToString:DMCHexFromData(data)], @"littleEndianData should be little-endian with trailing zero byte");
        DMCBigNumber* bn2 = [[DMCBigNumber alloc] initWithSignedLittleEndian:data];
        NSAssert([@"deadf00ddeadbeef" isEqualToString:bn2.hexString], @"converting to and from data should give the same result");
    }
    
    
    // Negative zero
    {
        DMCBigNumber* zeroBN = [DMCBigNumber zero];
        DMCBigNumber* negativeZeroBN = [[DMCBigNumber alloc] initWithSignedLittleEndian:DMCDataFromHex(@"80")];
        DMCBigNumber* zeroWithEmptyDataBN = [[DMCBigNumber alloc] initWithSignedLittleEndian:[NSData data]];
        
        //NSLog(@"negativeZeroBN.data = %@", negativeZeroBN.data);
        
        NSAssert(zeroBN, @"must exist");
        NSAssert(negativeZeroBN, @"must exist");
        NSAssert(zeroWithEmptyDataBN, @"must exist");
        
        //NSLog(@"negative zero: %lld", [negativeZeroBN int64value]);
        
        NSAssert([[[zeroBN mutableCopy] add:[[DMCBigNumber alloc] initWithInt32:1]] isEqual:[DMCBigNumber one]], @"0 + 1 == 1");
        NSAssert([[[negativeZeroBN mutableCopy] add:[[DMCBigNumber alloc] initWithInt32:1]] isEqual:[DMCBigNumber one]], @"0 + 1 == 1");
        NSAssert([[[zeroWithEmptyDataBN mutableCopy] add:[[DMCBigNumber alloc] initWithInt32:1]] isEqual:[DMCBigNumber one]], @"0 + 1 == 1");
        
        // In BitcoinQT script.cpp, there is check (bn != bnZero).
        // It covers negative zero alright because "bn" is created in a way that discards the sign.
        NSAssert(![zeroBN isEqual:negativeZeroBN], @"zero should != negative zero");
    }
    
    // Experiments:

    return;

    {
        //DMCBigNumber* bn = [DMCBigNumber zero];
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCDataFromHex(@"00")];
        NSLog(@"bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }

    {
        //DMCBigNumber* bn = [DMCBigNumber one];
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCDataFromHex(@"01")];
        NSLog(@"bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }

    {
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUInt32:0xdeadf00dL];
        NSLog(@"bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }
    {
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithInt32:-16];
        NSLog(@"bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }
    
    {
        int base = 17;
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithString:@"123" base:base];
        NSLog(@"bn = %@", [bn stringInBase:base]);
    }
    {
        int base = 2;
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithString:@"0b123" base:base];
        NSLog(@"bn = %@", [bn stringInBase:base]);
    }

    {
        DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUInt64:0xdeadf00ddeadbeef];
        NSData* data = bn.signedLittleEndian;
        DMCBigNumber* bn2 = [[DMCBigNumber alloc] initWithSignedLittleEndian:data];
        NSLog(@"bn = %@", [bn2 hexString]);
    }
}

@end
