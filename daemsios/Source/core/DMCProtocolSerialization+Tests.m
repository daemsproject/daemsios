// Oleg Andreev <oleganza@gmail.com>

#import "DMCProtocolSerialization+Tests.h"
#import "DMCData.h"

@implementation DMCProtocolSerialization (Tests)

+ (void) assertNumber:(uint64_t)number serializesToHex:(NSString*)hexForm {
    NSUInteger requiredLength = hexForm.length / 2;
    
    NSData* data = [DMCProtocolSerialization dataForVarInt:number];
    //NSLog(@"data = %@", data);
    NSAssert([data isEqualToData:DMCDataFromHex(hexForm)], @"Should encode correctly");
    uint64_t value = 0;
    NSUInteger len = [DMCProtocolSerialization readVarInt:&value fromData:data];
    NSAssert(len == requiredLength, @"Should read correct number of bytes");
    NSAssert(value == number, @"Should read original value");
    
    NSInputStream* stream = [NSInputStream inputStreamWithData:data];
    [stream open];
    len = [DMCProtocolSerialization readVarInt:&value fromStream:stream];
    [stream close];
    NSAssert(len == requiredLength, @"Should read 1 byte");
    NSAssert(value == number, @"Should read original value");
}

+ (void) runAllTests {
    [self assertNumber:0   serializesToHex:@"00"];
    [self assertNumber:252 serializesToHex:@"fc"];
    [self assertNumber:255ULL serializesToHex:@"fdff00"];
    [self assertNumber:12345ULL serializesToHex:@"fd3930"];
    [self assertNumber:65535ULL serializesToHex:@"fdffff"];
    [self assertNumber:65536ULL serializesToHex:@"fe00000100"];
    [self assertNumber:1234567890ULL serializesToHex:@"fed2029649"];
    [self assertNumber:1234567890123ULL serializesToHex:@"ffcb04fb711f010000"];
    [self assertNumber:UINT64_MAX serializesToHex:@"ffffffffffffffffff"];
}

@end
