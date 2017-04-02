// 

#import <Foundation/Foundation.h>

@class DMCKey;

// Implementation of [ECIES](http://en.wikipedia.org/wiki/Integrated_Encryption_Scheme)
// compatible with [Bitcore ECIES](https://github.com/bitpay/bitcore-ecies) implementation.
@interface DMCEncryptedMessage : NSObject

// When encrypting, sender's keypair must contain a private key.
@property(nonatomic) DMCKey* senderKey;

// When decrypting, recipient's keypair must contain a private key.
@property(nonatomic) DMCKey* recipientKey;

- (NSData*) encrypt:(NSData*)plaintext;
- (NSData*) decrypt:(NSData*)ciphertext;

@end
