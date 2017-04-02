// 

#import "DMCBlockchainInfo+Tests.h"
#import "DMCAddress.h"
#import "DMCTransactionOutput.h"

@implementation DMCBlockchainInfo (Tests)

+ (void) runAllTests {
    [self testUnspentOutputs];
}

+ (void) testUnspentOutputs {
    // our donations address with some outputs: 1CDMCGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG
    // some temp address without outputs: 1LKF45kfvHAaP7C4cF91pVb3bkAsmQ8nBr

    {
        NSError* error = nil;
        NSArray* outputs = [[[DMCBlockchainInfo alloc] init] unspentOutputsWithAddresses:@[ [DMCAddress addressWithString:@"1LKF45kfvHAaP7C4cF91pVb3bkAsmQ8nBr"] ] error:&error];
        
        NSAssert([outputs isEqual:@[]], @"should return an empty array");
        NSAssert(!error, @"should have no error");
    }

    
    {
        NSError* error = nil;
        NSArray* outputs = [[[DMCBlockchainInfo alloc] init] unspentOutputsWithAddresses:@[ [DMCAddress addressWithString:@"1CDMCGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG"] ] error:&error];
        
        NSAssert(outputs.count > 0, @"should return non-empty array");
        NSAssert([outputs.firstObject isKindOfClass:[DMCTransactionOutput class]], @"should contain DMCTransactionOutput objects");
        NSAssert(!error, @"should have no error");
    }
}

@end
