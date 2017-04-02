// Oleg Andreev <oleganza@gmail.com>

#import "DMCData.h"
#import "DMCKey.h"
#import "DMCBigNumber.h"
#import "DMCCurvePoint+Tests.h"

@implementation DMCCurvePoint (Tests)

+ (void) runAllTests {
    [self testPublicKey];
    [self testDiffieHellman];
}

+ (void) testPublicKey {
    // Should be able to create public key N = n*G via DMCKey API as well as raw EC arithmetic using DMCCurvePoint.
    
    NSData* privateKeyData = DMCHash256([@"Private Key Seed" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // 1. Make the pubkey using DMCKey API.
    
    DMCKey* key = [[DMCKey alloc] initWithPrivateKey:privateKeyData];
    
    
    // 2. Make the pubkey using DMCCurvePoint API.
    
    DMCBigNumber* bn = [[DMCBigNumber alloc] initWithUnsignedBigEndian:privateKeyData];
    
    DMCCurvePoint* generator = [DMCCurvePoint generator];
    DMCCurvePoint* pubkeyPoint = [[generator copy] multiply:bn];
    DMCKey* keyFromPoint = [[DMCKey alloc] initWithCurvePoint:pubkeyPoint];
    
    // 2.1. Test serialization
    
    NSAssert([pubkeyPoint isEqual:[[DMCCurvePoint alloc] initWithData:pubkeyPoint.data]], @"test serialization");
    
    // 3. Compare the two pubkeys.
    
    NSAssert([keyFromPoint isEqual:key], @"pubkeys should be equal");
    NSAssert([key.curvePoint isEqual:pubkeyPoint], @"points should be equal");
}

+ (void) testDiffieHellman {
    // Alice: a, A=a*G. Bob: b, B=b*G.
    // Test shared secret: a*B = b*A = (a*b)*G.
    
    NSData* alicePrivateKeyData = DMCHash256([@"alice private key" dataUsingEncoding:NSUTF8StringEncoding]);
    NSData* bobPrivateKeyData = DMCHash256([@"bob private key" dataUsingEncoding:NSUTF8StringEncoding]);
    
//    NSLog(@"Alice privkey: %@", DMCHexFromData(alicePrivateKeyData));
//    NSLog(@"Bob privkey:   %@", DMCHexFromData(bobPrivateKeyData));
    
    DMCBigNumber* aliceNumber = [[DMCBigNumber alloc] initWithUnsignedBigEndian:alicePrivateKeyData];
    DMCBigNumber* bobNumber = [[DMCBigNumber alloc] initWithUnsignedBigEndian:bobPrivateKeyData];
    
//    NSLog(@"Alice number: %@", aliceNumber.hexString);
//    NSLog(@"Bob number:   %@", bobNumber.hexString);
    
    DMCKey* aliceKey = [[DMCKey alloc] initWithPrivateKey:alicePrivateKeyData];
    DMCKey* bobKey = [[DMCKey alloc] initWithPrivateKey:bobPrivateKeyData];
    
    NSAssert([aliceKey.privateKey isEqual:aliceNumber.unsignedBigEndian], @"");
    NSAssert([bobKey.privateKey isEqual:bobNumber.unsignedBigEndian], @"");
    
    DMCCurvePoint* aliceSharedSecret = [bobKey.curvePoint multiply:aliceNumber];
    DMCCurvePoint* bobSharedSecret   = [aliceKey.curvePoint multiply:bobNumber];
    
//    NSLog(@"(a*B).x = %@", aliceSharedSecret.x.decimalString);
//    NSLog(@"(b*A).x = %@", bobSharedSecret.x.decimalString);
    
    DMCBigNumber* sharedSecretNumber = [[aliceNumber mutableCopy] multiply:bobNumber mod:[DMCCurvePoint curveOrder]];
    DMCCurvePoint* sharedSecret = [[DMCCurvePoint generator] multiply:sharedSecretNumber];
    
    NSAssert([aliceSharedSecret isEqual:bobSharedSecret], @"Should have the same shared secret");
    NSAssert([aliceSharedSecret isEqual:sharedSecret], @"Multiplication of private keys should yield a private key for the shared point");
}


@end
