// Oleg Andreev <oleganza@gmail.com>

#import "DMCTransaction.h"
#import "DMCTransactionOutput.h"
#import "DMCScript.h"
#import "DMCAddress.h"
#import "DMCData.h"
#import "DMCHashID.h"
#import "DMCProtocolSerialization.h"

@interface DMCTransactionOutput ()
@end

@implementation DMCTransactionOutput

- (id) init {
    return [self initWithValue:-1 script:[[DMCScript alloc] init]];
}

- (id) initWithValue:(DMCAmount)value {
    return [self initWithValue:value script:[[DMCScript alloc] init]];
}

- (id) initWithValue:(DMCAmount)value address:(DMCAddress*)address {
    return [self initWithValue:value script:[[DMCScript alloc] initWithAddress:address]];
}

- (id) initWithValue:(DMCAmount)value script:(DMCScript*)script {
    if (self = [super init]) {
        _value = value;
        _script = script;

        _index = DMCTransactionOutputIndexUnknown;
        _confirmations = NSNotFound;
        _spent = NO;
        _spentConfirmations = NSNotFound;
    }
    return self;
}

// Parses tx output from a data buffer.
- (id) initWithData:(NSData*)data {
    if (self = [self init]) {
        if (![self parseData:data]) return nil;
    }
    return self;
}

// Reads tx output from the stream.
- (id) initWithStream:(NSInputStream*)stream {
    if (self = [self init]) {
        if (![self parseStream:stream]) return nil;
    }
    return self;
}

// Constructs transaction input from a dictionary representation
- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [self init]) {
        NSString* valueString = dictionary[@"value"];
        if (!valueString) valueString = @"0";
        
        // Parse amount.
        // "12" => 1,200,000,000 satoshis (12 DMC)
        // "4.5" => 450,000,000 satoshis
        // "0.12000000" => 12,000,000 satoshis
        NSArray* comps = [valueString componentsSeparatedByString:@"."];
        
        _value = 0;
        if (comps.count >= 1) _value += DMCCoin * [(NSString*)comps[0] integerValue];
        if (comps.count >= 2) _value += [[(NSString*)comps[1] stringByPaddingToLength:8 withString:@"0" startingAtIndex:0] longLongValue];
        
        NSString* scriptString = dictionary[@"scriptPubKey"] ?: @"";
        _script = [[DMCScript alloc] initWithString:scriptString];
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone {
    DMCTransactionOutput* txout = [[DMCTransactionOutput alloc] init];
    txout.value = self.value;
    txout.script = [self.script copy];

    // Copy informational properties:
    txout.index           = _index;
    txout.transactionHash = _transactionHash; // copy bare ivar, so we don't copy transaction.transactionHash which may be derived from _transaction.
    txout.transaction     = _transaction;
    txout.blockHeight     = _blockHeight;
    txout.confirmations   = _confirmations;
    txout.userInfo        = _userInfo;

    return txout;
}

- (NSData*) data {
    return [self computePayload];
}

- (NSData*) computePayload {
    NSMutableData* payload = [NSMutableData data];
    
    [payload appendBytes:&_value length:sizeof(_value)];
    
    NSData* scriptData = _script.data ?: [NSData data];
    [payload appendData:[DMCProtocolSerialization dataForVarInt:scriptData.length]];
    [payload appendData:scriptData];
    
    return payload;
}

- (NSString*) description {
    NSData* txhash = self.transactionHash;
    return [NSString stringWithFormat:@"<%@:0x%p%@%@ %@ DMC '%@'%@>", [self class], self,
            (txhash ? [NSString stringWithFormat:@" %@", DMCHexFromData(txhash)]: @""),
            (_index == DMCTransactionOutputIndexUnknown ? @"" : [NSString stringWithFormat:@":%d", _index]),
            [self formattedDMCValue:_value],
            _script.string,
            (_confirmations == NSNotFound ? @"" : [NSString stringWithFormat:@" %d confirmations", (unsigned int)_confirmations])];
}

- (NSString*) formattedDMCValue:(DMCAmount)value {
    return [NSString stringWithFormat:@"%lld.%@", value / DMCCoin, [NSString stringWithFormat:@"%08lld", value % DMCCoin]];
}

// Returns a dictionary representation suitable for encoding in JSON or Plist.
- (NSDictionary*) dictionaryRepresentation {
    return self.dictionary;
}

- (NSDictionary*) dictionary {
    return @{
             @"value": [self formattedDMCValue:_value],
             // TODO: like in DMCTransactionInput, have an option to put both "asm" and "hex" representations of the script.
             @"scriptPubKey": _script.string ?: @"",
             };
}

- (uint32_t) index {
    // Remember the index as it does not change when we add more outputs.
    if (_transaction && _index == DMCTransactionOutputIndexUnknown) {
        NSUInteger idx = [_transaction.outputs indexOfObject:self];
        if (idx != NSNotFound) {
            _index = (uint32_t)idx;
        }
    }
    return _index;
}

- (NSData*) transactionHash {
    // Do not remember transaction hash as it changes when we add another output or change some metadata of the tx.
    if (_transactionHash) return _transactionHash;
    if (_transaction) return _transaction.transactionHash;
    return nil;
}

- (NSString*) transactionID {
    return DMCIDFromHash(self.transactionHash);
}

- (void) setTransactionID:(NSString *)transactionID {
    self.transactionHash = DMCHashFromID(transactionID);
}



#pragma mark - Serialization and parsing



- (BOOL) parseData:(NSData*)data {
    if (!data) return NO;
    NSInputStream* stream = [NSInputStream inputStreamWithData:data];
    [stream open];
    BOOL result = [self parseStream:stream];
    [stream close];
    return result;
}

- (BOOL) parseStream:(NSInputStream*)stream {
    if (!stream) return NO;
    if (stream.streamStatus == NSStreamStatusClosed) return NO;
    if (stream.streamStatus == NSStreamStatusNotOpen) return NO;
    
    // Read value
    if ([stream read:(uint8_t*)(&_value) maxLength:sizeof(_value)] != sizeof(_value)) return NO;
    
    // Read script
    NSData* scriptData = [DMCProtocolSerialization readVarStringFromStream:stream];
    if (!scriptData) return NO;
    _script = [[DMCScript alloc] initWithData:scriptData];
    
    return YES;
}





#pragma mark - Informational Properties


- (NSString*) blockID {
    return DMCIDFromHash(self.blockHash);
}

- (void) setBlockID:(NSString *)blockID {
    self.blockHash = DMCHashFromID(blockID);
}

- (NSData*) blockHash {
    return _blockHash ?: self.transaction.blockHash;
}

- (NSInteger) blockHeight {
    if (_blockHeight != 0) {
        return _blockHeight;
    }
    if (self.transaction) {
        return self.transaction.blockHeight;
    }
    return _blockHeight;
}

- (NSDate*) blockDate {
    return _blockDate ?: self.transaction.blockDate;
}

- (NSUInteger) confirmations {
    if (_confirmations != NSNotFound) {
        return _confirmations;
    }
    if (self.transaction) {
        return self.transaction.confirmations;
    }
    return NSNotFound;
}





@end
