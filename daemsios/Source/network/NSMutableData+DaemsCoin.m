//
//  NSMutableData+DaemsCoin.m

#import "NSMutableData+DaemsCoin.h"
#import "NSData+DaemsCoin.h"
#import "NSString+DaemsCoin.h"

static void *secureAllocate(CFIndex allocSize, CFOptionFlags hint, void *info)
{
    void *ptr = malloc(sizeof(CFIndex) + allocSize);
    
    if (ptr) { // we need to keep track of the size of the allocation so it can be cleansed before deallocation
        *(CFIndex *)ptr = allocSize;
        return (CFIndex *)ptr + 1;
    }
    else return NULL;
}

static void secureDeallocate(void *ptr, void *info)
{
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (size) {
        memset(ptr, 0, size);
        free((CFIndex *)ptr - 1);
    }
}

static void *secureReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
    // There's no way to tell ahead of time if the original memory will be deallocted even if the new size is smaller
    // than the old size, so just cleanse and deallocate every time.
    void *newptr = secureAllocate(newsize, hint, info);
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (newptr && size) {
        memcpy(newptr, ptr, (size < newsize) ? size : newsize);
        secureDeallocate(ptr, info);
    }
    
    return newptr;
}

// Since iOS does not page memory to storage, all we need to do is cleanse allocated memory prior to deallocation.
CFAllocatorRef SecureAllocator()
{
    static CFAllocatorRef alloc = NULL;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        CFAllocatorContext context;
        
        context.version = 0;
        CFAllocatorGetContext(kCFAllocatorDefault, &context);
        context.allocate = secureAllocate;
        context.reallocate = secureReallocate;
        context.deallocate = secureDeallocate;
        
        alloc = CFAllocatorCreate(kCFAllocatorDefault, &context);
    });
    
    return alloc;
}

@implementation NSMutableData (DaemsCoin)

+ (NSMutableData *)secureData
{
    return [self secureDataWithCapacity:0];
}

+ (NSMutableData *)secureDataWithCapacity:(NSUInteger)aNumItems
{
    return CFBridgingRelease(CFDataCreateMutable(SecureAllocator(), aNumItems));
}

+ (NSMutableData *)secureDataWithLength:(NSUInteger)length
{
    NSMutableData *d = [self secureDataWithCapacity:length];

    d.length = length;
    return d;
}

+ (NSMutableData *)secureDataWithData:(NSData *)data
{
    return CFBridgingRelease(CFDataCreateMutableCopy(SecureAllocator(), 0, (CFDataRef)data));
}

+ (size_t)sizeOfVarInt:(uint64_t)i
{
    if (i < VAR_INT16_HEADER) return sizeof(uint8_t);
    else if (i <= UINT16_MAX) return sizeof(uint8_t) + sizeof(uint16_t);
    else if (i <= UINT32_MAX) return sizeof(uint8_t) + sizeof(uint32_t);
    else return sizeof(uint8_t) + sizeof(uint64_t);
}

- (void)appendUInt8:(uint8_t)i
{
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt16:(uint16_t)i
{
    i = CFSwapInt16HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt32:(uint32_t)i
{
    i = CFSwapInt32HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt64:(uint64_t)i
{
    i = CFSwapInt64HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendVarInt:(uint64_t)i
{
    if (i < VAR_INT16_HEADER) {
        uint8_t payload = (uint8_t)i;
        
        [self appendBytes:&payload length:sizeof(payload)];
    }
    else if (i <= UINT16_MAX) {
        uint8_t header = VAR_INT16_HEADER;
        uint16_t payload = CFSwapInt16HostToLittle((uint16_t)i);
        
        [self appendBytes:&header length:sizeof(header)];
        [self appendBytes:&payload length:sizeof(payload)];
    }
    else if (i <= UINT32_MAX) {
        uint8_t header = VAR_INT32_HEADER;
        uint32_t payload = CFSwapInt32HostToLittle((uint32_t)i);
        
        [self appendBytes:&header length:sizeof(header)];
        [self appendBytes:&payload length:sizeof(payload)];
    }
    else {
        uint8_t header = VAR_INT64_HEADER;
        uint64_t payload = CFSwapInt64HostToLittle(i);
        
        [self appendBytes:&header length:sizeof(header)];
        [self appendBytes:&payload length:sizeof(payload)];
    }
}

- (void)appendString:(NSString *)s
{
    NSUInteger l = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    [self appendVarInt:l];
    [self appendBytes:s.UTF8String length:l];
}

// MARK: - bitcoin script

- (void)appendScriptPushData:(NSData *)d
{
    if (d.length == 0) {
        return;
    }
    else if (d.length < OP_PUSHDATA1) {
        [self appendUInt8:d.length];
    }
    else if (d.length < UINT8_MAX) {
        [self appendUInt8:OP_PUSHDATA1];
        [self appendUInt8:d.length];
    }
    else if (d.length < UINT16_MAX) {
        [self appendUInt8:OP_PUSHDATA2];
        [self appendUInt16:d.length];
    }
    else {
        [self appendUInt8:OP_PUSHDATA4];
        [self appendUInt32:(uint32_t)d.length];
    }

    [self appendData:d];
}

- (void)appendScriptPubKeyForAddress:(NSString *)address
{
    static uint8_t pubkeyAddress = DAEMSCOIN_PUBKEY_ADDRESS, scriptAddress = DAEMSCOIN_SCRIPT_ADDRESS;
    NSData *d = address.base58checkToData;

    if (d.length != 21) return;

    uint8_t version = *(const uint8_t *)d.bytes;
    NSData *hash = [d subdataWithRange:NSMakeRange(1, d.length - 1)];

#if DAEMSCOIN_TESTNET
    pubkeyAddress = DAEMSCOIN_PUBKEY_ADDRESS_TEST;
    scriptAddress = DAEMSCOIN_SCRIPT_ADDRESS_TEST;
#endif

    if (version == pubkeyAddress) {
        [self appendUInt8:OP_DUP];
        [self appendUInt8:OP_HASH160];
        [self appendScriptPushData:hash];
        [self appendUInt8:OP_EQUALVERIFY];
        [self appendUInt8:OP_CHECKSIG];
    }
    else if (version == scriptAddress) {
        [self appendUInt8:OP_HASH160];
        [self appendScriptPushData:hash];
        [self appendUInt8:OP_EQUAL];
    }
}

// MARK: - bitcoin protocol


/**
 把消息主体封装成带协议的完整消息

 字节空间   描述      数据类型        说明
 4        magic     uint32_t	用于识别消息的来源网络，当流状态位置时，它还用于寻找下一条消息
 12     command     char[12]	识别包内容的ASCII字串，用NULL字符补满，(使用非NULL字符填充会被拒绝)
 4      checksum	uint32_t	sha256(sha256(payload)) 的前4个字节(不包含在version 或 verack 中)
 4      length      uint32_t	payload的字节数
 ?      payload     uchar[]     实际数据
 
 */
- (void)appendMessage:(NSData *)message type:(NSString *)type;
{

    [self appendUInt32:DAEMSCOIN_MAGIC_NUMBER];
    [self appendNullPaddedString:type length:12];
    [self appendUInt32:(uint32_t)message.length];
    [self appendBytes:message.SHA256_2.u32 length:4];
    [self appendBytes:message.bytes length:message.length];
}

- (void)appendNullPaddedString:(NSString *)s length:(NSUInteger)length
{
    NSUInteger l = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    [self appendBytes:s.UTF8String length:l];

    while (l++ < length) {
        [self appendBytes:"\0" length:1];
    }
}

- (void)appendNetAddress:(uint32_t)address port:(uint16_t)port services:(uint64_t)services
{
    address = CFSwapInt32HostToBig(address);
    port = CFSwapInt16HostToBig(port);
    
    [self appendUInt64:services];
    [self appendBytes:"\0\0\0\0\0\0\0\0\0\0\xFF\xFF" length:12]; // IPv4 mapped IPv6 header
    [self appendBytes:&address length:sizeof(address)];
    [self appendBytes:&port length:sizeof(port)];
}

@end
