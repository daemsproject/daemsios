// Oleg Andreev <oleganza@gmail.com>

#import "DMCBase58.h"
#import "DMCData.h"
#import <openssl/bn.h>

static const char* DMCBase58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

NSMutableData* DMCDataFromBase58(NSString* string) {
    return DMCDataFromBase58CString([string cStringUsingEncoding:NSASCIIStringEncoding]);
}

NSMutableData* DMCDataFromBase58Check(NSString* string) {
    return DMCDataFromBase58CheckCString([string cStringUsingEncoding:NSASCIIStringEncoding]);
}

NSMutableData* DMCDataFromBase58CString(const char* cstring) {
    if (cstring == NULL) return nil;
    
    // empty string -> empty data.
    if (cstring[0] == '\0') return [NSMutableData data];
    
    NSMutableData* result = nil;
    
    BN_CTX* pctx = BN_CTX_new();
    __block BIGNUM bn58;   BN_init(&bn58);   BN_set_word(&bn58, 58);
    __block BIGNUM bn;     BN_init(&bn);     BN_zero(&bn);
    __block BIGNUM bnChar; BN_init(&bnChar);
    
    void(^finish)() = ^{
        if (pctx) BN_CTX_free(pctx);
        BN_clear_free(&bn58);
        BN_clear_free(&bn);
        BN_clear_free(&bnChar);
    };
    
    while (isspace(*cstring)) cstring++;
    
    
    // Convert big endian string to bignum
    for (const char* p = cstring; *p; p++) {
        const char* p1 = strchr(DMCBase58Alphabet, *p);
        if (p1 == NULL) {
            while (isspace(*p))
                p++;
            if (*p != '\0') {
                finish();
                return nil;
            }
            break;
        }
        
        BN_set_word(&bnChar, (BN_ULONG)(p1 - DMCBase58Alphabet));
        
        if (!BN_mul(&bn, &bn, &bn58, pctx)) {
            finish();
            return nil;
        }
        
        if (!BN_add(&bn, &bn, &bnChar)) {
            finish();
            return nil;
        }
    }
    
    // Get bignum as little endian data
    
    NSMutableData* bndata = nil;
    {
        size_t bnsize = BN_bn2mpi(&bn, NULL);
        if (bnsize <= 4) {
            bndata = [NSMutableData data];
        } else {
            bndata = [NSMutableData dataWithLength:bnsize];
            BN_bn2mpi(&bn, bndata.mutableBytes);
            [bndata replaceBytesInRange:NSMakeRange(0, 4) withBytes:NULL length:0];
            DMCDataReverse(bndata);
        }
    }
    size_t bnsize = bndata.length;
    
    // Trim off sign byte if present
    if (bnsize >= 2
        && ((unsigned char*)bndata.bytes)[bnsize - 1] == 0
        && ((unsigned char*)bndata.bytes)[bnsize - 2] >= 0x80) {
        bnsize -= 1;
        [bndata setLength:bnsize];
    }
    
    // Restore leading zeros
    int nLeadingZeros = 0;
    for (const char* p = cstring; *p == DMCBase58Alphabet[0]; p++)
        nLeadingZeros++;
    
    result = [NSMutableData dataWithLength:nLeadingZeros + bnsize];
    
    // Copy the bignum to the beginning of array. We'll reverse it then and zeros will become leading zeros.
    [result replaceBytesInRange:NSMakeRange(0, bnsize) withBytes:bndata.bytes length:bnsize];
    
    // Convert little endian data to big endian
    DMCDataReverse(result);
    
    finish();
    
    return result;
}

NSMutableData* DMCDataFromBase58CheckCString(const char* cstring) {
    if (cstring == NULL) return nil;
    
    NSMutableData* result = DMCDataFromBase58CString(cstring);
    size_t length = result.length;
    if (length < 4) {
        return nil;
    }
    NSData* hash = DMCHash256([result subdataWithRange:NSMakeRange(0, length - 4)]);
    
    // Last 4 bytes should be equal first 4 bytes of the hash.
    if (memcmp(hash.bytes, result.bytes + length - 4, 4) != 0) {
        return nil;
    }
    [result setLength:length - 4];
    return result;
}


char* DMCBase58CStringWithData(NSData* data) {
    if (!data) return NULL;
    
    BN_CTX* pctx = BN_CTX_new();
    __block BIGNUM bn58; BN_init(&bn58); BN_set_word(&bn58, 58);
    __block BIGNUM bn0;  BN_init(&bn0);  BN_zero(&bn0);
    __block BIGNUM bn; BN_init(&bn); BN_zero(&bn);
    __block BIGNUM dv; BN_init(&dv); BN_zero(&dv);
    __block BIGNUM rem; BN_init(&rem); BN_zero(&rem);
    
    void(^finish)() = ^{
        if (pctx) BN_CTX_free(pctx);
        BN_clear_free(&bn58);
        BN_clear_free(&bn0);
        BN_clear_free(&bn);
        BN_clear_free(&dv);
        BN_clear_free(&rem);
    };
    
    // Convert big endian data to little endian.
    // Extra zero at the end make sure bignum will interpret as a positive number.
    NSMutableData* tmp = DMCReversedMutableData(data);
    tmp.length += 1;
    
    // Convert little endian data to bignum
    {
        NSUInteger size = tmp.length;
        NSMutableData* mdata = [tmp mutableCopy];
        
        // Reverse to convert to OpenSSL bignum endianess
        DMCDataReverse(mdata);
        
        // BIGNUM's byte stream format expects 4 bytes of
        // big endian size data info at the front
        [mdata replaceBytesInRange:NSMakeRange(0, 0) withBytes:"\0\0\0\0" length:4];
        unsigned char* bytes = mdata.mutableBytes;
        bytes[0] = (size >> 24) & 0xff;
        bytes[1] = (size >> 16) & 0xff;
        bytes[2] = (size >> 8) & 0xff;
        bytes[3] = (size >> 0) & 0xff;
        
        BN_mpi2bn(bytes, (int)mdata.length, &bn);
    }
    
    // Expected size increase from base58 conversion is approximately 137%
    // use 138% to be safe
    NSMutableData* stringData = [NSMutableData dataWithCapacity:data.length*138/100 + 1];
    
    while (BN_cmp(&bn, &bn0) > 0) {
        if (!BN_div(&dv, &rem, &bn, &bn58, pctx)) {
            finish();
            return nil;
        }
        BN_copy(&bn, &dv);
        unsigned long c = BN_get_word(&rem);
        [stringData appendBytes:DMCBase58Alphabet + c length:1];
    }
    finish();
    
    // Leading zeroes encoded as base58 ones ("1")
    const unsigned char* pbegin = data.bytes;
    const unsigned char* pend = data.bytes + data.length;
    for (const unsigned char* p = pbegin; p < pend && *p == 0; p++) {
        [stringData appendBytes:DMCBase58Alphabet + 0 length:1];
    }
    
    // Convert little endian std::string to big endian
    DMCDataReverse(stringData);
    
    [stringData appendBytes:"" length:1];
    
    char* r = malloc(stringData.length);
    memcpy(r, stringData.bytes, stringData.length);
    DMCDataClear(stringData);
    return r;
}

// String in Base58 with checksum
char* DMCBase58CheckCStringWithData(NSData* immutabledata) {
    if (!immutabledata) return NULL;
    // add 4-byte hash check to the end
    NSMutableData* data = [immutabledata mutableCopy];
    NSData* checksum = DMCHash256(data);
    [data appendBytes:checksum.bytes length:4];
    char* result = DMCBase58CStringWithData(data);
    DMCDataClear(data);
    return result;
}

NSString* DMCBase58StringWithData(NSData* data) {
    if (!data) return nil;
    char* s = DMCBase58CStringWithData(data);
    id r = [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
    DMCSecureClearCString(s);
    free(s);
    return r;
}


NSString* DMCBase58CheckStringWithData(NSData* data) {
    if (!data) return nil;
    char* s = DMCBase58CheckCStringWithData(data);
    id r = [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
    DMCSecureClearCString(s);
    free(s);
    return r;
}






