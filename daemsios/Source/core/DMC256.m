// 

#import "DMC256.h"
#import "DMCData.h"

// 1. Structs are already defined in the .h file.

// 2. Constants

const DMC160 DMC160Zero = {0,0,0,0,0};
const DMC256 DMC256Zero = {0,0,0,0};
const DMC512 DMC512Zero = {0,0,0,0,0,0,0,0};

const DMC160 DMC160Max = {0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff};
const DMC256 DMC256Max = {0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL};
const DMC512 DMC512Max = {0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,
                          0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL};

// Using ints assuming little-endian platform. 160-bit chunk actually begins with 82963d5e. Same thing about the rest.
// Digest::SHA512.hexdigest("DaemsCoin/DMC160Null")[0,2*20].scan(/.{8}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// 82963d5edd842f1e6bd2b6bc2e9a97a40a7d8652
const DMC160 DMC160Null = {0x5e3d9682,0x1e2f84dd,0xbcb6d26b,0xa4979a2e,0x52867d0a};

// Digest::SHA512.hexdigest("DaemsCoin/DMC256Null")[0,2*32].scan(/.{16}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e
const DMC256 DMC256Null = {0x54e926e81f7a00d1LL,0xc3445f849515e209LL,0x98b5b685521d41b9LL,0x5e9a99a5bfaa8522LL};

// Digest::SHA512.hexdigest("DaemsCoin/DMC512Null")[0,2*64].scan(/.{16}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// 62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f0363e01b5d7a53c4a2e5a76d283f3e4a04d28ab54849c6e3e874ca31128bcb759e1
const DMC512 DMC512Null = {0x6e6e8392dd64ce62LL,0x5236623fee3ed899LL,0xf27222c2f89c04f6LL,0x36f038178662b295LL,0x2e4a3ca5d7b5013eLL,0x4da0e4f383d2765aLL,0x873e6e9c8454ab28LL,0xe159b7bc2811a34cLL};


// 3. Comparison

BOOL DMC160Equal(DMC160 chunk1, DMC160 chunk2) {
// Which one is faster: memcmp or word-by-word check? The latter does not need any loop or extra checks to compare bytes.
//    return memcmp(&chunk1, &chunk2, sizeof(chunk1)) == 0;
    return chunk1.words32[0] == chunk2.words32[0]
        && chunk1.words32[1] == chunk2.words32[1]
        && chunk1.words32[2] == chunk2.words32[2]
        && chunk1.words32[3] == chunk2.words32[3]
        && chunk1.words32[4] == chunk2.words32[4];
}

BOOL DMC256Equal(DMC256 chunk1, DMC256 chunk2) {
    return chunk1.words64[0] == chunk2.words64[0]
        && chunk1.words64[1] == chunk2.words64[1]
        && chunk1.words64[2] == chunk2.words64[2]
        && chunk1.words64[3] == chunk2.words64[3];
}

BOOL DMC512Equal(DMC512 chunk1, DMC512 chunk2) {
    return chunk1.words64[0] == chunk2.words64[0]
        && chunk1.words64[1] == chunk2.words64[1]
        && chunk1.words64[2] == chunk2.words64[2]
        && chunk1.words64[3] == chunk2.words64[3]
        && chunk1.words64[4] == chunk2.words64[4]
        && chunk1.words64[5] == chunk2.words64[5]
        && chunk1.words64[6] == chunk2.words64[6]
        && chunk1.words64[7] == chunk2.words64[7];
}

NSComparisonResult DMC160Compare(DMC160 chunk1, DMC160 chunk2) {
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}

NSComparisonResult DMC256Compare(DMC256 chunk1, DMC256 chunk2) {
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}

NSComparisonResult DMC512Compare(DMC512 chunk1, DMC512 chunk2) {
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}



// 4. Operations


// Inverse (b = ~a)
DMC160 DMC160Inverse(DMC160 chunk) {
    chunk.words32[0] = ~chunk.words32[0];
    chunk.words32[1] = ~chunk.words32[1];
    chunk.words32[2] = ~chunk.words32[2];
    chunk.words32[3] = ~chunk.words32[3];
    chunk.words32[4] = ~chunk.words32[4];
    return chunk;
}

DMC256 DMC256Inverse(DMC256 chunk) {
    chunk.words64[0] = ~chunk.words64[0];
    chunk.words64[1] = ~chunk.words64[1];
    chunk.words64[2] = ~chunk.words64[2];
    chunk.words64[3] = ~chunk.words64[3];
    return chunk;
}

DMC512 DMC512Inverse(DMC512 chunk) {
    chunk.words64[0] = ~chunk.words64[0];
    chunk.words64[1] = ~chunk.words64[1];
    chunk.words64[2] = ~chunk.words64[2];
    chunk.words64[3] = ~chunk.words64[3];
    chunk.words64[4] = ~chunk.words64[4];
    chunk.words64[5] = ~chunk.words64[5];
    chunk.words64[6] = ~chunk.words64[6];
    chunk.words64[7] = ~chunk.words64[7];
    return chunk;
}

// Swap byte order
DMC160 DMC160Swap(DMC160 chunk) {
    DMC160 chunk2;
    chunk2.words32[4] = OSSwapConstInt32(chunk.words32[0]);
    chunk2.words32[3] = OSSwapConstInt32(chunk.words32[1]);
    chunk2.words32[2] = OSSwapConstInt32(chunk.words32[2]);
    chunk2.words32[1] = OSSwapConstInt32(chunk.words32[3]);
    chunk2.words32[0] = OSSwapConstInt32(chunk.words32[4]);
    return chunk2;
}

DMC256 DMC256Swap(DMC256 chunk) {
    DMC256 chunk2;
    chunk2.words64[3] = OSSwapConstInt64(chunk.words64[0]);
    chunk2.words64[2] = OSSwapConstInt64(chunk.words64[1]);
    chunk2.words64[1] = OSSwapConstInt64(chunk.words64[2]);
    chunk2.words64[0] = OSSwapConstInt64(chunk.words64[3]);
    return chunk2;
}

DMC512 DMC512Swap(DMC512 chunk) {
    DMC512 chunk2;
    chunk2.words64[7] = OSSwapConstInt64(chunk.words64[0]);
    chunk2.words64[6] = OSSwapConstInt64(chunk.words64[1]);
    chunk2.words64[5] = OSSwapConstInt64(chunk.words64[2]);
    chunk2.words64[4] = OSSwapConstInt64(chunk.words64[3]);
    chunk2.words64[3] = OSSwapConstInt64(chunk.words64[4]);
    chunk2.words64[2] = OSSwapConstInt64(chunk.words64[5]);
    chunk2.words64[1] = OSSwapConstInt64(chunk.words64[6]);
    chunk2.words64[0] = OSSwapConstInt64(chunk.words64[7]);
    return chunk2;
}

// Bitwise AND operation (a & b)
DMC160 DMC160AND(DMC160 chunk1, DMC160 chunk2) {
    chunk1.words32[0] = chunk1.words32[0] & chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] & chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] & chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] & chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] & chunk2.words32[4];
    return chunk1;
}

DMC256 DMC256AND(DMC256 chunk1, DMC256 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] & chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] & chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] & chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] & chunk2.words64[3];
    return chunk1;
}

DMC512 DMC512AND(DMC512 chunk1, DMC512 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] & chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] & chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] & chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] & chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] & chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] & chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] & chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] & chunk2.words64[7];
    return chunk1;
}

// Bitwise OR operation (a | b)
DMC160 DMC160OR(DMC160 chunk1, DMC160 chunk2) {
    chunk1.words32[0] = chunk1.words32[0] | chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] | chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] | chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] | chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] | chunk2.words32[4];
    return chunk1;
}

DMC256 DMC256OR(DMC256 chunk1, DMC256 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] | chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] | chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] | chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] | chunk2.words64[3];
    return chunk1;
}

DMC512 DMC512OR(DMC512 chunk1, DMC512 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] | chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] | chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] | chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] | chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] | chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] | chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] | chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] | chunk2.words64[7];
    return chunk1;
}

// Bitwise exclusive-OR operation (a ^ b)
DMC160 DMC160XOR(DMC160 chunk1, DMC160 chunk2) {
    chunk1.words32[0] = chunk1.words32[0] ^ chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] ^ chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] ^ chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] ^ chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] ^ chunk2.words32[4];
    return chunk1;
}

DMC256 DMC256XOR(DMC256 chunk1, DMC256 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] ^ chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] ^ chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] ^ chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] ^ chunk2.words64[3];
    return chunk1;
}

DMC512 DMC512XOR(DMC512 chunk1, DMC512 chunk2) {
    chunk1.words64[0] = chunk1.words64[0] ^ chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] ^ chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] ^ chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] ^ chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] ^ chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] ^ chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] ^ chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] ^ chunk2.words64[7];
    return chunk1;
}

DMC512 DMC512Concat(DMC256 chunk1, DMC256 chunk2) {
    DMC512 result;
    *((DMC256*)(&result)) = chunk1;
    *((DMC256*)(((unsigned char*)&result) + sizeof(chunk2))) = chunk2;
    return result;
}


// 5. Conversion functions


// Conversion to NSData
NSData* NSDataFromDMC160(DMC160 chunk) {
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

NSData* NSDataFromDMC256(DMC256 chunk) {
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

NSData* NSDataFromDMC512(DMC512 chunk) {
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

// Conversion from NSData.
// If NSData is not big enough, returns DMCHash{160,256,512}Null.
DMC160 DMC160FromNSData(NSData* data) {
    if (data.length < 160/8) return DMC160Null;
    DMC160 chunk = *((DMC160*)data.bytes);
    return chunk;
}

DMC256 DMC256FromNSData(NSData* data) {
    if (data.length < 256/8) return DMC256Null;
    DMC256 chunk = *((DMC256*)data.bytes);
    return chunk;
}

DMC512 DMC512FromNSData(NSData* data) {
    if (data.length < 512/8) return DMC512Null;
    DMC512 chunk = *((DMC512*)data.bytes);
    return chunk;
}


// Returns lowercase hex representation of the chunk

NSString* NSStringFromDMC160(DMC160 chunk) {
    const int length = 20;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i) {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

NSString* NSStringFromDMC256(DMC256 chunk) {
    const int length = 32;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i) {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

NSString* NSStringFromDMC512(DMC512 chunk) {
    const int length = 64;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i) {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

// Conversion from hex NSString (lower- or uppercase).
// If string is invalid or data is too short, returns DMCHash{160,256,512}Null.
DMC160 DMC160FromNSString(NSString* string) {
    return DMC160FromNSData(DMCDataFromHex(string));
}

DMC256 DMC256FromNSString(NSString* string) {
    return DMC256FromNSData(DMCDataFromHex(string));
}

DMC512 DMC512FromNSString(NSString* string) {
    return DMC512FromNSData(DMCDataFromHex(string));
}



