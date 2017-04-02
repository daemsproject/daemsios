// 

#import <Foundation/Foundation.h>

// A set of ubiquitous types and functions to deal with fixed-length chunks of data
// (160-bit, 256-bit and 512-bit). These are relevant almost always to hashes,
// but there's no hash-specific about them.
// The purpose of these is to avoid dynamic memory allocations via NSData when
// we need to move exactly 32 bytes around.
//
// We don't call these DMCFixedData256 because these types are way too ubiquituous
// in DaemsCoin to have such an explicit name.
//
// Somewhat similar to uint256 in daemsCoind, but here we don't try
// to pretend that these are integers and then allow arithmetic on them
// and create a mess with the byte order.
// Use DMCBigNumber to do arithmetic on big numbers and convert
// to bignum format explicitly.
// DMCBigNumber has API for converting DMC256 to a big int.
//
// We also declare DMC160 and DMC512 for use with RIPEMD-160, SHA-1 and SHA-512 hashes.


// 1. Fixed-length types

struct private_DMC160
{
    // 160 bits can't be formed with 64-bit words, so we have to use 32-bit ones instead.
    uint32_t words32[5];
} __attribute__((packed));
typedef struct private_DMC160 DMC160;

struct private_DMC256
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[4];
} __attribute__((aligned(1)));
typedef struct private_DMC256 DMC256;

struct private_DMC512
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[8];
} __attribute__((aligned(1)));
typedef struct private_DMC512 DMC512;


// 2. Constants

// All-zero constants
extern const DMC160 DMC160Zero;
extern const DMC256 DMC256Zero;
extern const DMC512 DMC512Zero;

// All-one constants
extern const DMC160 DMC160Max;
extern const DMC256 DMC256Max;
extern const DMC512 DMC512Max;

// First 160 bits of SHA512("DaemsCoin/DMC160Null")
extern const DMC160 DMC160Null;

// First 256 bits of SHA512("DaemsCoin/DMC256Null")
extern const DMC256 DMC256Null;

// Value of SHA512("DaemsCoin/DMC512Null")
extern const DMC512 DMC512Null;


// 3. Comparison

BOOL DMC160Equal(DMC160 chunk1, DMC160 chunk2);
BOOL DMC256Equal(DMC256 chunk1, DMC256 chunk2);
BOOL DMC512Equal(DMC512 chunk1, DMC512 chunk2);

NSComparisonResult DMC160Compare(DMC160 chunk1, DMC160 chunk2);
NSComparisonResult DMC256Compare(DMC256 chunk1, DMC256 chunk2);
NSComparisonResult DMC512Compare(DMC512 chunk1, DMC512 chunk2);


// 4. Operations


// Inverse (b = ~a)
DMC160 DMC160Inverse(DMC160 chunk);
DMC256 DMC256Inverse(DMC256 chunk);
DMC512 DMC512Inverse(DMC512 chunk);

// Swap byte order
DMC160 DMC160Swap(DMC160 chunk);
DMC256 DMC256Swap(DMC256 chunk);
DMC512 DMC512Swap(DMC512 chunk);

// Bitwise AND operation (a & b)
DMC160 DMC160AND(DMC160 chunk1, DMC160 chunk2);
DMC256 DMC256AND(DMC256 chunk1, DMC256 chunk2);
DMC512 DMC512AND(DMC512 chunk1, DMC512 chunk2);

// Bitwise OR operation (a | b)
DMC160 DMC160OR(DMC160 chunk1, DMC160 chunk2);
DMC256 DMC256OR(DMC256 chunk1, DMC256 chunk2);
DMC512 DMC512OR(DMC512 chunk1, DMC512 chunk2);

// Bitwise exclusive-OR operation (a ^ b)
DMC160 DMC160XOR(DMC160 chunk1, DMC160 chunk2);
DMC256 DMC256XOR(DMC256 chunk1, DMC256 chunk2);
DMC512 DMC512XOR(DMC512 chunk1, DMC512 chunk2);

// Concatenation of two 256-bit chunks
DMC512 DMC512Concat(DMC256 chunk1, DMC256 chunk2);


// 5. Conversion functions


// Conversion to NSData
NSData* NSDataFromDMC160(DMC160 chunk);
NSData* NSDataFromDMC256(DMC256 chunk);
NSData* NSDataFromDMC512(DMC512 chunk);

// Conversion from NSData.
// If NSData is not big enough, returns DMCHash{160,256,512}Null.
DMC160 DMC160FromNSData(NSData* data);
DMC256 DMC256FromNSData(NSData* data);
DMC512 DMC512FromNSData(NSData* data);

// Returns lowercase hex representation of the chunk
NSString* NSStringFromDMC160(DMC160 chunk);
NSString* NSStringFromDMC256(DMC256 chunk);
NSString* NSStringFromDMC512(DMC512 chunk);

// Conversion from hex NSString (lower- or uppercase).
// If string is invalid or data is too short, returns DMCHash{160,256,512}Null.
DMC160 DMC160FromNSString(NSString* string);
DMC256 DMC256FromNSString(NSString* string);
DMC512 DMC512FromNSString(NSString* string);



