// 
// Implementation of blind signatures for DaemsCoin transactions:
// http://oleganza.com/blind-ecdsa-draft-v2.pdf

#import "DMCBlindSignature+Tests.h"

#import "DMCKey.h"
#import "DMCKeychain.h"
#import "DMCData.h"
#import "DMCBigNumber.h"
#import "DMCCurvePoint.h"


@implementation DMCBlindSignature (Tests)

+ (void) runAllTests {
    [self testCoreAlgorithm];
    [self testConvenienceAPI];
}

+ (void) testCoreAlgorithm {
    DMCBlindSignature* api = [[DMCBlindSignature alloc] init];
    
    DMCBigNumber* a = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"a" dataUsingEncoding:NSUTF8StringEncoding])];
    DMCBigNumber* b = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"b" dataUsingEncoding:NSUTF8StringEncoding])];
    DMCBigNumber* c = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"c" dataUsingEncoding:NSUTF8StringEncoding])];
    DMCBigNumber* d = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"d" dataUsingEncoding:NSUTF8StringEncoding])];
    DMCBigNumber* p = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"p" dataUsingEncoding:NSUTF8StringEncoding])];
    DMCBigNumber* q = [[DMCBigNumber alloc] initWithUnsignedBigEndian:DMCHash256([@"q" dataUsingEncoding:NSUTF8StringEncoding])];
    
    NSArray* PQ = [api bob_P_and_Q_for_p:p q:q];
    DMCCurvePoint* P = PQ.firstObject;
    DMCCurvePoint* Q = PQ.lastObject;

    NSAssert(P, @"sanity check");
    NSAssert(Q, @"sanity check");

    NSArray* KT = [api alice_K_and_T_for_a:a b:b c:c d:d P:P Q:Q];
    DMCCurvePoint* K = KT.firstObject;
    DMCCurvePoint* T = KT.lastObject;
    
    NSAssert(K, @"sanity check");
    NSAssert(T, @"sanity check");
    
    // In real life we'd use T in a destination script and keep K.x around for redeeming it later.
    // ...
    // It's time to redeem funds! Lets do it by asking Bob to sign stuff for Alice.
    
    NSData* hash = DMCHash256([@"some transaction" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // Alice computes and sends to Bob.
    DMCBigNumber* blindedHash = [api aliceBlindedHashForHash:[[DMCBigNumber alloc] initWithUnsignedBigEndian:hash] a:a b:b];
    
    NSAssert(blindedHash, @"sanity check");
    
    // Bob computes and sends to Alice.
    DMCBigNumber* blindedSig = [api bobBlindedSignatureForHash:blindedHash p:p q:q];
    
    NSAssert(blindedSig, @"sanity check");
    
    // Alice unblinds and uses in the final signature.
    DMCBigNumber* unblindedSignature = [api aliceUnblindedSignatureForSignature:blindedSig c:c d:d];
    
    NSAssert(unblindedSignature, @"sanity check");
    
    NSData* finalSignature = [api aliceCompleteSignatureForKx:K.x unblindedSignature:unblindedSignature];
    
    NSAssert(finalSignature, @"sanity check");
    
    DMCKey* pubkey = [[DMCKey alloc] initWithCurvePoint:T];
    
    NSAssert([pubkey isValidSignature:finalSignature hash:hash], @"should have created a valid signature after all that trouble");
}



+ (void) testConvenienceAPI {
    DMCKeychain* aliceKeychain = [[DMCKeychain alloc] initWithSeed:[@"Alice" dataUsingEncoding:NSUTF8StringEncoding]];
    DMCKeychain* bobKeychain = [[DMCKeychain alloc] initWithSeed:[@"Bob" dataUsingEncoding:NSUTF8StringEncoding]];
    DMCKeychain* bobPublicKeychain = [[DMCKeychain alloc] initWithExtendedKey:bobKeychain.extendedPublicKey];

    NSAssert(aliceKeychain, @"sanity check");
    NSAssert(bobKeychain, @"sanity check");
    NSAssert(bobPublicKeychain, @"sanity check");

    DMCBlindSignature* alice = [[DMCBlindSignature alloc] initWithClientKeychain:aliceKeychain custodianKeychain:bobPublicKeychain];
    DMCBlindSignature* bob = [[DMCBlindSignature alloc] initWithCustodianKeychain:bobKeychain];
    
    NSAssert(alice, @"sanity check");
    NSAssert(bob, @"sanity check");
    
    for (uint32_t i = 0; i < 32; i++) {
        // This will be Alice's pubkey that she can use in a destination script.
        DMCKey* pubkey = [alice publicKeyAtIndex:i];
        NSAssert(pubkey, @"sanity check");
        
        //NSLog(@"pubkey = %@", pubkey);
        
        // This will be a hash of Alice's transaction.
        NSData* hash = DMCHash256([[NSString stringWithFormat:@"transaction %ul", i] dataUsingEncoding:NSUTF8StringEncoding]);
        
        //NSLog(@"hash = %@", hash);
        
        // Alice will send this to Bob.
        NSData* blindedHash = [alice blindedHashForHash:hash index:i];
        NSAssert(blindedHash, @"sanity check");
        
        // Bob computes the signature for Alice and sends it back to her.
        NSData* blindSig = [bob blindSignatureForBlindedHash:blindedHash];
        NSAssert(blindSig, @"sanity check");
        
        // Alice receives the blind signature and computes the complete ECDSA signature ready to use in a redeeming transaction.
        NSData* finalSig = [alice unblindedSignatureForBlindSignature:blindSig verifyHash:hash];
        NSAssert(finalSig, @"sanity check");
        
        NSAssert([pubkey isValidSignature:finalSig hash:hash], @"Check that the resulting signature is valid for our original hash and pubkey.");
    }
}


@end
