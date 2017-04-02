// 

#import "DMC256+Tests.h"
#import "DMC256.h"
#import "DMCData.h"

void DMC256TestChunkSize() {
    NSCAssert(sizeof(DMC160) == 20, @"160-bit struct should by 160 bit long");
    NSCAssert(sizeof(DMC256) == 32, @"256-bit struct should by 256 bit long");
    NSCAssert(sizeof(DMC512) == 64, @"512-bit struct should by 512 bit long");
}

void DMC256TestNull() {
    NSCAssert([NSStringFromDMC160(DMC160Null) isEqual:@"82963d5edd842f1e6bd2b6bc2e9a97a40a7d8652"], @"null hash should be correct");
    NSCAssert([NSStringFromDMC256(DMC256Null) isEqual:@"d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"], @"null hash should be correct");
    NSCAssert([NSStringFromDMC512(DMC512Null) isEqual:@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f0363e01b5d7a53c4a2e5a76d283f3e4a04d28ab54849c6e3e874ca31128bcb759e1"], @"null hash should be correct");
}

void DMC256TestOne() {
    DMC256 one = DMC256Zero;
    one.words64[0] = 1;
    NSCAssert([NSStringFromDMC256(one) isEqual:@"0100000000000000000000000000000000000000000000000000000000000000"], @"");
}

void DMC256TestEqual() {
    NSCAssert(DMC256Equal(DMC256Null, DMC256Null), @"equal");
    NSCAssert(DMC256Equal(DMC256Zero, DMC256Zero), @"equal");
    NSCAssert(DMC256Equal(DMC256Max,  DMC256Max),  @"equal");
    
    NSCAssert(!DMC256Equal(DMC256Zero, DMC256Null), @"not equal");
    NSCAssert(!DMC256Equal(DMC256Zero, DMC256Max),  @"not equal");
    NSCAssert(!DMC256Equal(DMC256Max,  DMC256Null), @"not equal");
}

void DMC256TestCompare() {
    NSCAssert(DMC256Compare(DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedSame, @"ordered same");

    NSCAssert(DMC256Compare(DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f035"),
                            DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedAscending, @"ordered asc");
    
    NSCAssert(DMC256Compare(DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f037"),
                            DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedDescending, @"ordered asc");

    NSCAssert(DMC256Compare(DMC256FromNSString(@"61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedAscending, @"ordered same");

    NSCAssert(DMC256Compare(DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            DMC256FromNSString(@"61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedDescending, @"ordered same");

}

void DMC256TestInverse() {
    DMC256 chunk = DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036");
    DMC256 chunk2 = DMC256Inverse(chunk);
    
    NSCAssert(!DMC256Equal(chunk, chunk2), @"not equal");
    NSCAssert(DMC256Equal(chunk, DMC256Inverse(chunk2)), @"equal");
    
    NSCAssert(chunk2.words64[0] == ~chunk.words64[0], @"bytes are inversed");
    NSCAssert(chunk2.words64[1] == ~chunk.words64[1], @"bytes are inversed");
    NSCAssert(chunk2.words64[2] == ~chunk.words64[2], @"bytes are inversed");
    NSCAssert(chunk2.words64[3] == ~chunk.words64[3], @"bytes are inversed");
    
    NSCAssert(DMC256Equal(DMC256Zero, DMC256AND(chunk, chunk2)), @"(a & ~a) == 000000...");
    NSCAssert(DMC256Equal(DMC256Max, DMC256OR(chunk, chunk2)), @"(a | ~a) == 111111...");
    NSCAssert(DMC256Equal(DMC256Max, DMC256XOR(chunk, chunk2)), @"(a ^ ~a) == 111111...");
}

void DMC256TestSwap() {
    DMC256 chunk = DMC256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036");
    DMC256 chunk2 = DMC256Swap(chunk);
    NSCAssert([DMCReversedData(NSDataFromDMC256(chunk)) isEqual:NSDataFromDMC256(chunk2)], @"swap should reverse all bytes");
    
    NSCAssert(chunk2.words64[0] == OSSwapConstInt64(chunk.words64[3]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[1] == OSSwapConstInt64(chunk.words64[2]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[2] == OSSwapConstInt64(chunk.words64[1]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[3] == OSSwapConstInt64(chunk.words64[0]), @"swap should reverse all bytes");
}

void DMC256TestAND() {
    NSCAssert(DMC256Equal(DMC256AND(DMC256Max,  DMC256Max),  DMC256Max),  @"1 & 1 == 1");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Max,  DMC256Zero), DMC256Zero), @"1 & 0 == 0");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Zero, DMC256Max),  DMC256Zero), @"0 & 1 == 0");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Zero, DMC256Null), DMC256Zero), @"0 & x == 0");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Null, DMC256Zero), DMC256Zero), @"x & 0 == 0");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Max,  DMC256Null), DMC256Null), @"1 & x == x");
    NSCAssert(DMC256Equal(DMC256AND(DMC256Null, DMC256Max),  DMC256Null), @"x & 1 == x");
}

void DMC256TestOR() {
    NSCAssert(DMC256Equal(DMC256OR(DMC256Max,  DMC256Max),  DMC256Max),  @"1 | 1 == 1");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Max,  DMC256Zero), DMC256Max),  @"1 | 0 == 1");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Zero, DMC256Max),  DMC256Max),  @"0 | 1 == 1");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Zero, DMC256Null), DMC256Null), @"0 | x == x");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Null, DMC256Zero), DMC256Null), @"x | 0 == x");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Max,  DMC256Null), DMC256Max),  @"1 | x == 1");
    NSCAssert(DMC256Equal(DMC256OR(DMC256Null, DMC256Max),  DMC256Max),  @"x | 1 == 1");
}

void DMC256TestXOR() {
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Max,  DMC256Max),  DMC256Zero),  @"1 ^ 1 == 0");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Max,  DMC256Zero), DMC256Max),  @"1 ^ 0 == 1");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Zero, DMC256Max),  DMC256Max),  @"0 ^ 1 == 1");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Zero, DMC256Null), DMC256Null), @"0 ^ x == x");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Null, DMC256Zero), DMC256Null), @"x ^ 0 == x");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Max,  DMC256Null), DMC256Inverse(DMC256Null)),  @"1 ^ x == ~x");
    NSCAssert(DMC256Equal(DMC256XOR(DMC256Null, DMC256Max),  DMC256Inverse(DMC256Null)),  @"x ^ 1 == ~x");
}

void DMC256TestConcat() {
    DMC512 concat = DMC512Concat(DMC256Null, DMC256Max);
    NSCAssert([NSStringFromDMC512(concat) isEqual:@"d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"
               "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"], @"should concatenate properly");
    
    concat = DMC512Concat(DMC256Max, DMC256Null);
    NSCAssert([NSStringFromDMC512(concat) isEqual:@"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
               "d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"], @"should concatenate properly");
    
}

void DMC256TestConvertToData() {
    // TODO...
}

void DMC256TestConvertToString() {
    // Too short string should yield null value.
    DMC256 chunk = DMC256FromNSString(@"000095409e215952"
                                       "85b6b5982285aabf"
                                       "a5999a5e845f44c3"
                                       "b9411d5d1007a1");
    NSCAssert(DMC256Equal(chunk, DMC256Null), @"too short string => null");
    
    chunk = DMC256FromNSString(@"000095409e215952"
                                "85b6b5982285aabf"
                                "a5999a5e845f44c3"
                                "b9411d5d1007a1b166");
    NSCAssert(chunk.words64[0] == OSSwapBigToHostConstInt64(0x000095409e215952), @"parse correctly");
    NSCAssert(chunk.words64[1] == OSSwapBigToHostConstInt64(0x85b6b5982285aabf), @"parse correctly");
    NSCAssert(chunk.words64[2] == OSSwapBigToHostConstInt64(0xa5999a5e845f44c3), @"parse correctly");
    NSCAssert(chunk.words64[3] == OSSwapBigToHostConstInt64(0xb9411d5d1007a1b1), @"parse correctly");
    
    NSCAssert([NSStringFromDMC256(chunk) isEqual:@"000095409e215952"
                                                  "85b6b5982285aabf"
                                                  "a5999a5e845f44c3"
                                                  "b9411d5d1007a1b1"], @"should serialize to the same string");
}


void DMC256RunAllTests() {
    DMC256TestChunkSize();
    DMC256TestNull();
    DMC256TestOne();
    DMC256TestEqual();
    DMC256TestCompare();
    DMC256TestInverse();
    DMC256TestSwap();
    DMC256TestAND();
    DMC256TestOR();
    DMC256TestXOR();
    DMC256TestConcat();
    DMC256TestConvertToData();
    DMC256TestConvertToString();
}

