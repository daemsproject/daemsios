// 

#import "DMCOutpoint.h"
#import "DMCTransaction.h"
#import "DMCHashID.h"

@implementation DMCOutpoint

- (id) initWithHash:(NSData*)hash index:(uint32_t)index {
    if (hash.length != 32) return nil;
    if (self = [super init]) {
        _txHash = hash;
        _index = index;
    }
    return self;
}

- (id) initWithTxID:(NSString*)txid index:(uint32_t)index {
    NSData* hash = DMCHashFromID(txid);
    return [self initWithHash:hash index:index];
}

- (NSString*) txID {
    return DMCIDFromHash(self.txHash);
}

- (void) setTxID:(NSString *)txID {
    self.txHash = DMCHashFromID(txID);
}

- (NSUInteger) hash {
    const NSUInteger* words = _txHash.bytes;
    return words[0] + self.index;
}

- (BOOL) isEqual:(DMCOutpoint*)object {
    return [self.txHash isEqual:object.txHash] && self.index == object.index;
}

- (id) copyWithZone:(NSZone *)zone {
    return [[DMCOutpoint alloc] initWithHash:_txHash index:_index];
}

@end
