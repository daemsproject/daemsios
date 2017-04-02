// 

#import <Foundation/Foundation.h>

/*!
 * Converts string transaction or block ID (reversed tx hash in hex format) to binary hash.
 */
NSData* DMCHashFromID(NSString* identifier);

/*!
 * Converts hash of the transaction or block to its string ID (reversed hash in hex format).
 */
NSString* DMCIDFromHash(NSData* hash);
