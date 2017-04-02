// 

#import <Foundation/Foundation.h>

// Outpoint is a reference to a transaction output (byt tx hash and output index).
// It is a part of DMCTransactionInput.
@interface DMCOutpoint : NSObject <NSCopying>

// Hash of the previous transaction.
@property(nonatomic) NSData* txHash;

// Transaction ID referenced by this input (reversed txHash in hex).
@property(nonatomic) NSString* txID;

// Index of the previous transaction's output.
@property(nonatomic) uint32_t index;

- (id) initWithHash:(NSData*)hash index:(uint32_t)index;

- (id) initWithTxID:(NSString*)txid index:(uint32_t)index;

@end
