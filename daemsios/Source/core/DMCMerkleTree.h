// 

#import <Foundation/Foundation.h>

@interface DMCMerkleTree : NSObject

// Returns the merkle root of the tree, a 256-bit hash.
@property(nonatomic, readonly) NSData* merkleRoot;

// Returns YES if the merkle tree has duplicate items in the tail that cause merkle root collision.
// See also CVE-2012-2459.
@property(nonatomic, readonly) BOOL hasTailDuplicates;

// Builds a merkle tree based on raw hashes.
- (id) initWithHashes:(NSArray*)hashes;

// Builds a merkle tree based on transaction hashes.
- (id) initWithTransactions:(NSArray* /* [DMCTransaction] */)transactions;

// Builds a merkle tree based on DMCHash256 hashes of each NSData item.
- (id) initWithDataItems:(NSArray* /* [NSData] */)dataItems;

@end
