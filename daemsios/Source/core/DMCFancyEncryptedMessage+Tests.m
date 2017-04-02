//
//  DMCFancyEncryptedMessage+Tests.m
//  DaemsCoin
//
//  Created by Oleg Andreev on 21.06.2014.
//  Copyright (c) 2014 Oleg Andreev. All rights reserved.
//

#import "DMCFancyEncryptedMessage+Tests.h"

#import "DMCKey.h"
#import "DMCData.h"
#import "DMCBigNumber.h"
#import "DMCCurvePoint.h"

@implementation DMCFancyEncryptedMessage (Tests)

+ (void) runAllTests {
    [self testProofOfWork];
    [self testMessages];
}

+ (void) testMessages {
    DMCKey* key = [[DMCKey alloc] initWithPrivateKey:DMCSHA256([@"some key" dataUsingEncoding:NSUTF8StringEncoding])];
    
    NSString* originalString = @"Hello!";
    
    DMCFancyEncryptedMessage* msg = [[DMCFancyEncryptedMessage alloc] initWithData:[originalString dataUsingEncoding:NSUTF8StringEncoding]];

    msg.difficultyTarget = 0x00FFFFFF;
    
    //NSLog(@"difficulty: %@ (%x)", [self binaryString32:msg.difficultyTarget], msg.difficultyTarget);
    
    NSData* encryptedMsg = [msg encryptedDataWithKey:key seed:DMCDataFromHex(@"deadbeef")];
    
    NSAssert(msg.difficultyTarget == 0x00FFFFFF, @"check the difficulty target");
    
    //NSLog(@"encrypted msg = %@   hash: %@...", DMCHexFromData(encryptedMsg), DMCHexFromData([DMCHash256(encryptedMsg) subdataWithRange:NSMakeRange(0, 8)]));
    
    DMCFancyEncryptedMessage* receivedMsg = [[DMCFancyEncryptedMessage alloc] initWithEncryptedData:encryptedMsg];
    
    NSAssert(receivedMsg, @"pow and format are correct");
    
    NSError* error = nil;
    NSData* decryptedData = [receivedMsg decryptedDataWithKey:key error:&error];
    
    NSAssert(decryptedData, @"should decrypt correctly");
    
    NSString* string = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    NSAssert(string, @"should decode a UTF-8 string");
    
    NSAssert([string isEqualToString:originalString], @"should decrypt the original string");
}

+ (void) testProofOfWork {
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:0] == 0, @"0x00 -> 0");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:0xFF] == 0xFFFFFFFF, @"0x00 -> 0");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:1] == 0, @"order is zero");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:2] == 0, @"order is zero");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:3] == 0, @"order is zero");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:4] == 1, @"order is zero, and tail starts with 1");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:5] == 1, @"order is zero, and tail starts with 1");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:6] == 1, @"order is zero, and tail starts with 1");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:7] == 1, @"order is zero, and tail starts with 1");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:8] == 2, @"order is one, but tail is zero");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:8+3] == 2, @"order is one, but tail is zero");
    NSAssert([DMCFancyEncryptedMessage targetForCompactTarget:8+4] == 3, @"order is one, and tail starts with 1");
    
    uint8_t t = 0;
    do {
        // normalize t
        uint8_t nt = t;
        uint32_t order = t >> 3;
        if (order == 0) nt = t >> 2;
        if (order == 1) nt = t & (0xff - 1 - 2);
        if (order == 2) nt = t & (0xff - 1);

        uint32_t target = [DMCFancyEncryptedMessage targetForCompactTarget:t];
        
        uint8_t t2 = [DMCFancyEncryptedMessage compactTargetForTarget:target];
        
        // uncomment this line to visualize data
        
        //NSLog(@"byte = % 4d %@   target = %@ % 11d", (int)t, [self binaryString8:t], [self binaryString32:target], target);
        //NSLog(@"t = % 4d %@ (%@) -> %@ % 11d -> %@ % 3d", (int)t, [self binaryString8:t], [self binaryString8:nt], [self binaryString32:target], target, [self binaryString8:t2], (int)t2);
        
        NSAssert(nt == t2, @"should transform back and forth correctly");
        
        if (t == 0xff) break;
        t++;
    } while (1);
}

+ (NSString*) binaryString8:(uint8_t)byte {
    return [NSString stringWithFormat:@"%d%d%d%d%d%d%d%d",
            (int)((byte >> 7) & 1),
            (int)((byte >> 6) & 1),
            (int)((byte >> 5) & 1),
            (int)((byte >> 4) & 1),
            (int)((byte >> 3) & 1),
            (int)((byte >> 2) & 1),
            (int)((byte >> 1) & 1),
            (int)((byte >> 0) & 1)
            ];
}

+ (NSString*) binaryString32:(uint32_t)eent {
    return [NSString stringWithFormat:@"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
            (int)((eent >> 31) & 1),
            (int)((eent >> 30) & 1),
            (int)((eent >> 29) & 1),
            (int)((eent >> 28) & 1),
            (int)((eent >> 27) & 1),
            (int)((eent >> 26) & 1),
            (int)((eent >> 25) & 1),
            (int)((eent >> 24) & 1),
            (int)((eent >> 23) & 1),
            (int)((eent >> 22) & 1),
            (int)((eent >> 21) & 1),
            (int)((eent >> 20) & 1),
            (int)((eent >> 19) & 1),
            (int)((eent >> 18) & 1),
            (int)((eent >> 17) & 1),
            (int)((eent >> 16) & 1),
            (int)((eent >> 15) & 1),
            (int)((eent >> 14) & 1),
            (int)((eent >> 13) & 1),
            (int)((eent >> 12) & 1),
            (int)((eent >> 11) & 1),
            (int)((eent >> 10) & 1),
            (int)((eent >> 9) & 1),
            (int)((eent >> 8) & 1),
            (int)((eent >> 7) & 1),
            (int)((eent >> 6) & 1),
            (int)((eent >> 5) & 1),
            (int)((eent >> 4) & 1),
            (int)((eent >> 3) & 1),
            (int)((eent >> 2) & 1),
            (int)((eent >> 1) & 1),
            (int)((eent >> 0) & 1)
            ];
}

@end
