// 

#import <Foundation/Foundation.h>

@class DMCBlock;
@class DMCTransaction;
@class DMCProcessor;
@class DMCNetwork;

extern NSString* const DMCProcessorErrorDomain;

typedef NS_ENUM(NSUInteger, DMCProcessorError) {
    
    // Block already stored in the blockchain (on mainchain or sidechain)
    DMCProcessorErrorDuplicateBlock,
    
    // Block already stored as orphan
    DMCProcessorErrorDuplicateOrphanBlock,
    
    // Block has timestamp below last downloaded checkpoint.
    DMCProcessorErrorTimestampBeforeLastCheckpoint,
    
    // Proof of work is below the minimum possible since the last checkpoint.
    DMCProcessorErrorBelowCheckpointProofOfWork,
    
};

// Data source implements actual storage for blocks, block headers and transactions.
@protocol DMCProcessorDataSource <NSObject>
@required

// Returns a block in the blockchain (mainchain or sidechain), or nil if block is missing.
- (DMCBlock*) blockWithHash:(NSData*)hash;

// Returns YES if the block exists in the blockchain (mainchain or sidechain).
- (BOOL) blockExistsWithHash:(NSData*)hash;

// Returns orphan block with the given hash (or nil if block is not stored among orphans).
- (DMCBlock*) orphanBlockWithHash:(NSData*)hash;

// Returns YES if orphan block exists.
- (BOOL) orphanBlockExistsWithHash:(NSData*)hash;

@end



// Delegate allows to handle errors and selectively ignore them for testing purposes.
@protocol DMCProcessorDelegate <NSObject>
@optional

// For some error codes, userInfo[@"DoS"] contains level of DoS punishment.
// If this method returns NO, error is ignored and processing continues.
- (BOOL) processor:(DMCProcessor*)processor shouldRejectBlock:(DMCBlock*)block withError:(NSError*)error;

// Sent when processing stopped because of an error.
- (void) processor:(DMCProcessor*)processor didRejectBlock:(DMCBlock*)block withError:(NSError*)error;

@end



// Processor implements validation and processing of the incoming blocks and unconfirmed transactions.
// It defers storage to data source which takes care of storing and retrieving all objects efficiently.
@interface DMCProcessor : NSObject

// Network (mainnet/testnet) that should be used by processor.
// Default is mainnet.
@property(nonatomic) DMCNetwork* network;

// Data source provides block headers, blocks, and transactions during the process of verification.
// Should not be nil when processing blocks and transactions.
@property(nonatomic, weak) id<DMCProcessorDataSource> dataSource;

// Delegate allows fine-grained control of errors that happen. Can be nil.
@property(nonatomic, weak) id<DMCProcessorDelegate> delegate;

// Attempts to process the block. Returns YES on success, NO and error on failure.
// Make sure to set dataSource before calling this method.
// See ProcessBlock() in daemsCoind.
- (BOOL) processBlock:(DMCBlock*)block error:(NSError**)errorOut;

// Attempts to add transaction to "memory pool" of unconfirmed transactions.
// Make sure to set dataSource before calling this method.
// See AcceptToMemoryPool() in daemsCoind.
- (BOOL) processTransaction:(DMCTransaction*)transaction error:(NSError**)errorOut;

@end
