// 

#import "DMCBlockHeader.h"
#import "DMCData.h"
#import "DMCHashID.h"

@implementation DMCBlockHeader

+ (NSUInteger) headerLength {
    return 4 + 32 + 32 + 4 + 4 + 4;
}

- (id) init {
    if (self = [super init]) {
        // init default values
        _version = DMCBlockCurrentVersion;
        _previousBlockHash = DMCZero256();
        _merkleRootHash = DMCZero256();
        _time = 0;
        _difficultyTarget = 0;
        _nonce = 0;
        _confirmations = NSNotFound;
    }
    return self;
}

- (id) initWithData:(NSData*)data {
    if (self = [self init]) {
        if (![self parseData:data]) return nil;
    }
    return self;
}

- (id) initWithStream:(NSInputStream*)stream {
    if (self = [self init]) {
        if (![self parseStream:stream]) return nil;
    }
    return self;
}

- (NSString*) previousBlockID {
    return DMCIDFromHash(self.previousBlockHash);
}

- (void) setPreviousBlockID:(NSString *)previousBlockID {
    self.previousBlockHash = DMCHashFromID(previousBlockID) ?: DMCZero256();
}

- (NSData*) blockHash {
    return DMCHash256(self.data);
}

- (NSString*) blockID {
    return DMCIDFromHash(self.blockHash);
}

- (NSDate*) date {
    return [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)self.time];
}

- (void) setDate:(NSDate *)date {
    _time = (uint32_t)round(date.timeIntervalSince1970);
}

- (NSData*) data {
    return [self computePayload];
}

- (NSData*) computePayload {
    NSMutableData* data = [NSMutableData data];

    int32_t version = OSSwapHostToLittleInt32(_version);
    [data appendBytes:&version length:sizeof(version)];
    
    [data appendData:self.previousBlockHash ?: DMCZero256()];
    [data appendData:self.merkleRootHash ?: DMCZero256()];
    
    uint32_t time = OSSwapHostToLittleInt32(_time);
    [data appendBytes:&time length:sizeof(time)];

    uint32_t target = OSSwapHostToLittleInt32(_difficultyTarget);
    [data appendBytes:&target length:sizeof(target)];

    uint32_t nonce = OSSwapHostToLittleInt32(_nonce);
    [data appendBytes:&nonce length:sizeof(nonce)];
    
    return data;
}

- (BOOL) parseData:(NSData*)data {
    
    // TODO
    
    return YES;
}

- (BOOL) parseStream:(NSStream*)stream {
    // TODO
    
    return YES;
}

- (id) copyWithZone:(NSZone *)zone {
    DMCBlockHeader* bh = [[DMCBlockHeader alloc] init];
    bh.version = self->_version;
    bh.previousBlockHash = [self->_previousBlockHash copy];
    bh.merkleRootHash = [self->_merkleRootHash copy];
    bh.time = self->_time;
    bh.difficultyTarget = self->_difficultyTarget;
    bh.nonce = self->_nonce;

    bh.height = self->_height;
    bh.confirmations = self->_confirmations;
    bh.userInfo = self->_userInfo;
    
    return bh;
}

@end
