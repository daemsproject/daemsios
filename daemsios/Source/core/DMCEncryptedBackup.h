// 

// Implementation of [Automatic Encrypted Wallet Backups](https://github.com/oleganza/daemsCoin-papers/blob/master/AutomaticEncryptedWalletBackups.md) scheme.
// For test vectors, see unit tests (DMCEncryptedBackup+Tests.m).

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned char, DMCEncryptedBackupVersion) {
    DMCEncryptedBackupVersion1 = 0x01,
};

@class DMCNetwork;
@class DMCKey;
@interface DMCEncryptedBackup : NSObject

// Default version is DMCEncryptedBackupVersion1.
@property(nonatomic, readonly) DMCEncryptedBackupVersion version;

// Timestamp of the backup. If not specified, during encryption set to current time.
@property(nonatomic, readonly) NSTimeInterval timestamp;
@property(nonatomic, readonly) NSDate* date;

@property(nonatomic, readonly) NSData* decryptedData;
@property(nonatomic, readonly) NSData* encryptedData;

@property(nonatomic, readonly) NSString* walletID;
@property(nonatomic, readonly) DMCKey* authenticationKey;

+ (instancetype) encrypt:(NSData*)data backupKey:(NSData*)backupKey;
+ (instancetype) encrypt:(NSData*)data backupKey:(NSData*)backupKey timestamp:(NSTimeInterval)timestamp;
+ (instancetype) decrypt:(NSData*)data backupKey:(NSData*)backupKey;

+ (NSData*) backupKeyForNetwork:(DMCNetwork*)network masterKey:(NSData*)masterKey;
+ (DMCKey*) authenticationKeyWithBackupKey:(NSData*)backupKey;
+ (NSString*) walletIDWithAuthenticationKey:(NSData*)authPubkey;

// For testing/audit purposes only:

@property(nonatomic, readonly) NSData* encryptionKey;
@property(nonatomic, readonly) NSData* iv;
@property(nonatomic, readonly) NSData* merkleRoot;
@property(nonatomic, readonly) NSData* ciphertext;
@property(nonatomic, readonly) NSData* dataForSigning;
@property(nonatomic, readonly) NSData* signature;

@end
