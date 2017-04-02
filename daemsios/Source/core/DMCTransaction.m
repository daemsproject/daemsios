// Oleg Andreev <oleganza@gmail.com>

#import "DMCTransaction.h"
#import "DMCTransactionInput.h"
#import "DMCTransactionOutput.h"
#import "DMCProtocolSerialization.h"
#import "DMCData.h"
#import "DMCScript.h"
#import "DMCErrors.h"
#import "DMCHashID.h"

NSData* DMCTransactionHashFromID(NSString* txid) {
    return DMCHashFromID(txid);
}

NSString* DMCTransactionIDFromHash(NSData* txhash) {
    return DMCIDFromHash(txhash);
}

@interface DMCTransaction ()
@end

@implementation DMCTransaction

- (id) init {
    if (self = [super init]) {
        // init default values
        _version = DMCTransactionCurrentVersion;
        _lockTime = 0;
        _inputs = @[];
        _outputs = @[];
        _blockHeight = 0;
        _blockDate = nil;
        _confirmations = NSNotFound;
        _fee = -1;
        _inputsAmount = -1;
    }
    return self;
}

// Parses tx from data buffer.
- (id) initWithData:(NSData*)data {
    if (self = [self init]) {
        if (![self parseData:data]) return nil;
    }
    return self;
}

// Parses tx from hex string.
- (id) initWithHex:(NSString*)hex {
    return [self initWithData:DMCDataFromHex(hex)];
}

// Parses input stream (useful when parsing many transactions from a single source, e.g. a block).
- (id) initWithStream:(NSInputStream*)stream {
    if (self = [self init]) {
        if (![self parseStream:stream]) return nil;
    }
    return self;
}

// Constructs transaction from dictionary representation
- (id) initWithDictionary:(NSDictionary*)dictionary {
    if (self = [self init]) {
        _version = (uint32_t)[dictionary[@"ver"] unsignedIntegerValue];
        _lockTime = (uint32_t)[dictionary[@"lock_time"] unsignedIntegerValue];
        
        NSMutableArray* ins = [NSMutableArray array];
        for (id dict in dictionary[@"in"]) {
            DMCTransactionInput* txin = [[DMCTransactionInput alloc] initWithDictionary:dict];
            if (!txin) return nil;
            [ins addObject:txin];
        }
        _inputs = ins;
        
        NSMutableArray* outs = [NSMutableArray array];
        for (id dict in dictionary[@"out"]) {
            DMCTransactionOutput* txout = [[DMCTransactionOutput alloc] initWithDictionary:dict];
            if (!txout) return nil;
            [outs addObject:txout];
        }
        _outputs = outs;
    }
    return self;
}

// Returns a dictionary representation suitable for encoding in JSON or Plist.
- (NSDictionary*) dictionaryRepresentation {
    return self.dictionary;
}

- (NSDictionary*) dictionary {
    return @{
      @"hash":      self.transactionID,
      @"ver":       @(_version),
      @"vin_sz":    @(_inputs.count),
      @"vout_sz":   @(_outputs.count),
      @"lock_time": @(_lockTime),
      @"size":      @(self.data.length),
      @"in":        [_inputs valueForKey:@"dictionary"],
      @"out":       [_outputs valueForKey:@"dictionary"],
    };
}


#pragma mark - NSObject



- (BOOL) isEqual:(DMCTransaction*)object {
    if (![object isKindOfClass:[DMCTransaction class]]) return NO;
    return [object.transactionHash isEqual:self.transactionHash];
}

- (NSUInteger) hash {
    if (self.transactionHash.length >= sizeof(NSUInteger)) {
        // Interpret first bytes as a hash value
        return *((NSUInteger*)self.transactionHash.bytes);
    } else {
        return 0;
    }
}

- (id) copyWithZone:(NSZone *)zone {
    DMCTransaction* tx = [[DMCTransaction alloc] init];
    tx->_inputs = [[NSArray alloc] initWithArray:self.inputs copyItems:YES]; // so each element is copied individually
    tx->_outputs = [[NSArray alloc] initWithArray:self.outputs copyItems:YES]; // so each element is copied individually
    for (DMCTransactionInput* txin in tx.inputs) {
        txin.transaction = self;
    }
    for (DMCTransactionOutput* txout in tx.outputs) {
        txout.transaction = self;
    }
    tx.version = self.version;
    tx.lockTime = self.lockTime;

    // Copy informational properties as is.
    tx.blockHash     = [_blockHash copy];
    tx.blockHeight   = _blockHeight;
    tx.blockDate     = _blockDate;
    tx.confirmations = _confirmations;
    tx.userInfo      = _userInfo;

    return tx;
}



#pragma mark - Properties


- (NSData*) transactionHash {
    return DMCHash256(self.data);
}

- (NSString*) displayTransactionHash { // deprecated
    return self.transactionID;
}

- (NSString*) transactionID {
    return DMCIDFromHash(self.transactionHash);
}

- (NSString*) blockID {
    return DMCIDFromHash(self.blockHash);
}

- (void) setBlockID:(NSString *)blockID {
    self.blockHash = DMCHashFromID(blockID);
}

- (NSData*) data {
    return [self computePayload];
}

- (NSString*) hex {
    return DMCHexFromData(self.data);
}

- (NSData*) computePayload {
    NSMutableData* payload = [NSMutableData data];
    
    // 4-byte version
    uint32_t ver = _version;
    [payload appendBytes:&ver length:4];
    
    // varint with number of inputs
    [payload appendData:[DMCProtocolSerialization dataForVarInt:_inputs.count]];
    
    // input payloads
    for (DMCTransactionInput* input in _inputs) {
        [payload appendData:input.data];
    }
    
    // varint with number of outputs
    [payload appendData:[DMCProtocolSerialization dataForVarInt:_outputs.count]];
    
    // output payloads
    for (DMCTransactionOutput* output in _outputs) {
        [payload appendData:output.data];
    }
    
    // 4-byte lock_time
    uint32_t lt = _lockTime;
    [payload appendBytes:&lt length:4];
    
    return payload;
}


#pragma mark - Methods


// Adds input script
- (void) addInput:(DMCTransactionInput*)input {
    if (!input) return;
    [self linkInput:input];
    _inputs = [_inputs arrayByAddingObject:input];
}

- (void) linkInput:(DMCTransactionInput*)input {
    if (!(input.transaction == nil || input.transaction == self)) {
        @throw [NSException exceptionWithName:@"DMCTransaction consistency error!" reason:@"Can't add an input to a transaction when it references another transaction." userInfo:nil];
        return;
    }
    input.transaction = self;
}

// Adds output script
- (void) addOutput:(DMCTransactionOutput*)output {
    if (!output) return;
    [self linkOutput:output];
    _outputs = [_outputs arrayByAddingObject:output];
}

- (void) linkOutput:(DMCTransactionOutput*)output {
    if (!(output.transaction == nil || output.transaction == self)) {
        @throw [NSException exceptionWithName:@"DMCTransaction consistency error!" reason:@"Can't add an output to a transaction when it references another transaction." userInfo:nil];
        return;
    }
    output.index = DMCTransactionOutputIndexUnknown; // reset to be recomputed lazily later
    output.transactionHash = nil; // can't be reliably set here because transaction may get updated.
    output.transaction = self;
}

- (void) setInputs:(NSArray *)inputs {
    [self removeAllInputs];
    for (DMCTransactionInput* txin in inputs) {
        [self addInput:txin];
    }
}

- (void) setOutputs:(NSArray *)outputs {
    [self removeAllOutputs];
    for (DMCTransactionOutput* txout in outputs) {
        [self addOutput:txout];
    }
}

- (void) removeAllInputs {
    for (DMCTransactionInput* txin in _inputs) {
        txin.transaction = nil;
    }
    _inputs = @[];
}

- (void) removeAllOutputs {
    for (DMCTransactionOutput* txout in _outputs) {
        txout.transaction = nil;
    }
    _outputs = @[];
}

- (BOOL) isCoinbase {
    // Coinbase transaction has one input and it must be coinbase.
    return (_inputs.count == 1 && [(DMCTransactionInput*)_inputs[0] isCoinbase]);
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
    
    if ([stream read:(uint8_t*)&_version maxLength:sizeof(_version)] != sizeof(_version)) return NO;
    
    {
        uint64_t inputsCount = 0;
        if ([DMCProtocolSerialization readVarInt:&inputsCount fromStream:stream] == 0) return NO;
        
        NSMutableArray* ins = [NSMutableArray array];
        for (uint64_t i = 0; i < inputsCount; i++)
        {
            DMCTransactionInput* input = [[DMCTransactionInput alloc] initWithStream:stream];
            if (!input) return NO;
            [self linkInput:input];
            [ins addObject:input];
        }
        _inputs = ins;
    }

    {
        uint64_t outputsCount = 0;
        if ([DMCProtocolSerialization readVarInt:&outputsCount fromStream:stream] == 0) return NO;
            
        NSMutableArray* outs = [NSMutableArray array];
        for (uint64_t i = 0; i < outputsCount; i++)
        {
            DMCTransactionOutput* output = [[DMCTransactionOutput alloc] initWithStream:stream];
            if (!output) return NO;
            [self linkOutput:output];
            [outs addObject:output];
        }
        _outputs = outs;
    }
    
    if ([stream read:(uint8_t*)&_lockTime maxLength:sizeof(_lockTime)] != sizeof(_lockTime)) return NO;
    
    return YES;
}


#pragma mark - Signing a transaction



// Hash for signing a transaction.
// You should supply the output script of the previous transaction, desired hash type and input index in this transaction.
- (NSData*) signatureHashForScript:(DMCScript*)subscript inputIndex:(uint32_t)inputIndex hashType:(DMCSignatureHashType)hashType error:(NSError**)errorOut {
    // Create a temporary copy of the transaction to apply modifications to it.
    DMCTransaction* tx = [self copy];
    
    // We may have a scriptmachine instantiated without a transaction (for testing),
    // but it should not use signature checks then.
    if (!tx || inputIndex == 0xFFFFFFFF) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain
                                                      code:DMCErrorScriptError
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Transaction and valid input index must be provided for signature verification.", @"")}];
        return nil;
    }
    
    // Note: BitcoinQT returns a 256-bit little-endian number 1 in such case, but it does not matter
    // because it would crash before that in CScriptCheck::operator()(). We normally won't enter this condition
    // if script machine is instantiated with initWithTransaction:inputIndex:, but if it was just -init-ed, it's better to check.
    if (inputIndex >= tx.inputs.count) {
        if (errorOut) *errorOut = [NSError errorWithDomain:DMCErrorDomain
                                                      code:DMCErrorScriptError
                                                  userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                                     NSLocalizedString(@"Input index is out of bounds for transaction: %d >= %d.", @""),
                                                                                        (int)inputIndex, (int)tx.inputs.count]}];
        return nil;
    }
    
    // In case concatenating two scripts ends up with two codeseparators,
    // or an extra one at the end, this prevents all those possible incompatibilities.
    // Note: this normally never happens because there is no use for OP_CODESEPARATOR.
    // But we have to do that cleanup anyway to not break on rare transaction that use that for lulz.
    // Also: we modify the same subscript which is used several times for multisig check, but that's what BitcoinQT does as well.
    [subscript deleteOccurrencesOfOpcode:OP_CODESEPARATOR];
    
    // Blank out other inputs' signature scripts
    // and replace our input script with a subscript (which is typically a full output script from the previous transaction).
    for (DMCTransactionInput* txin in tx.inputs) {
        txin.signatureScript = [[DMCScript alloc] init];
    }
    ((DMCTransactionInput*)tx.inputs[inputIndex]).signatureScript = subscript;
    
    // Blank out some of the outputs depending on DMCSignatureHashType
    // Default is SIGHASH_ALL - all inputs and outputs are signed.
    if ((hashType & SIGHASH_OUTPUT_MASK) == SIGHASH_NONE) {
        // Wildcard payee - we can pay anywhere.
        [tx removeAllOutputs];
        
        // Blank out others' input sequence numbers to let others update transaction at will.
        for (NSUInteger i = 0; i < tx.inputs.count; i++) {
            if (i != inputIndex) {
                ((DMCTransactionInput*)tx.inputs[i]).sequence = 0;
            }
        }
    } else if ((hashType & SIGHASH_OUTPUT_MASK) == SIGHASH_SINGLE) {
        // Single mode assumes we sign an output at the same index as an input.
        // Outputs before the one we need are blanked out. All outputs after are simply removed.
        // Only lock-in the txout payee at same index as txin.
        uint32_t outputIndex = inputIndex;
        
        // If outputIndex is out of bounds, BitcoinQT is returning a 256-bit little-endian 0x01 instead of failing with error.
        // We should do the same to stay compatible.
        if (outputIndex >= tx.outputs.count) {
            static unsigned char littleEndianOne[32] = {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
            return [NSData dataWithBytes:littleEndianOne length:32];
        }
        
        // All outputs before the one we need are blanked out. All outputs after are simply removed.
        // This is equivalent to replacing outputs with (i-1) empty outputs and a i-th original one.
        DMCTransactionOutput* myOutput = tx.outputs[outputIndex];
        [tx removeAllOutputs];
        for (int i = 0; i < outputIndex; i++) {
            [tx addOutput:[[DMCTransactionOutput alloc] init]];
        }
        [tx addOutput:myOutput];
        
        // Blank out others' input sequence numbers to let others update transaction at will.
        for (NSUInteger i = 0; i < tx.inputs.count; i++) {
            if (i != inputIndex) {
                ((DMCTransactionInput*)tx.inputs[i]).sequence = 0;
            }
        }
    }
    
    // Blank out other inputs completely. This is not recommended for open transactions.
    if (hashType & SIGHASH_ANYONECANPAY) {
        DMCTransactionInput* input = tx.inputs[inputIndex];
        [tx removeAllInputs];
        [tx addInput:input];
    }
    
    // Important: we have to hash transaction together with its hash type.
    // Hash type is appended as little endian uint32 unlike 1-byte suffix of the signature.
    NSMutableData* fulldata = [tx.data mutableCopy];
    uint32_t hashType32 = OSSwapHostToLittleInt32((uint32_t)hashType);
    [fulldata appendBytes:&hashType32 length:sizeof(hashType32)];
    
    NSData* hash = DMCHash256(fulldata);
    
//    NSLog(@"\n----------------------\n");
//    NSLog(@"TX: %@", DMCHexFromData(fulldata));
//    NSLog(@"TX SUBSCRIPT: %@ (%@)", DMCHexFromData(subscript.data), subscript);
//    NSLog(@"TX HASH: %@", DMCHexFromData(hash));
//    NSLog(@"TX PLIST: %@", tx.dictionary);
    
    return hash;
}






#pragma mark - Amounts and fee



@synthesize fee=_fee;
@synthesize inputsAmount=_inputsAmount;

- (void) setFee:(DMCAmount)fee {
    _fee = fee;
    _inputsAmount = -1; // will be computed from fee or inputs.map(&:value)
}

- (DMCAmount) fee {
    if (_fee != -1) {
        return _fee;
    }

    DMCAmount ia = self.inputsAmount;
    if (ia != -1) {
        return ia - self.outputsAmount;
    }

    return -1;
}

- (void) setInputsAmount:(DMCAmount)inputsAmount {
    _inputsAmount = inputsAmount;
    _fee = -1; // will be computed from inputs and outputs amount on the fly.
}

- (DMCAmount) inputsAmount {
    if (_inputsAmount != -1) {
        return _inputsAmount;
    }

    if (_fee != -1) {
        return _fee + self.outputsAmount;
    }

    // Try to figure the total amount from amounts on inputs.
    // If all of them are non-nil, we have a valid amount.

    DMCAmount total = 0;
    for (DMCTransactionInput* txin in self.inputs) {
        DMCAmount v = txin.value;
        if (v == -1) {
            return -1;
        }
        total += v;
    }
    return total;
}

- (DMCAmount) outputsAmount {
    DMCAmount a = 0;
    for (DMCTransactionOutput* txout in self.outputs) {
        a += txout.value;
    }
    return a;
}






#pragma mark - Fees



// Computes estimated fee for this tx size using default fee rate.
// @see DMCTransactionDefaultFeeRate.
- (DMCAmount) estimatedFee {
    return [self estimatedFeeWithRate:DMCTransactionDefaultFeeRate];
}

// Computes estimated fee for this tx size using specified fee rate (satoshis per 1000 bytes).
- (DMCAmount) estimatedFeeWithRate:(DMCAmount)feePerK {
    return [DMCTransaction estimateFeeForSize:self.data.length feeRate:feePerK];
}

// Computes estimated fee for the given tx size using specified fee rate (satoshis per 1000 bytes).
+ (DMCAmount) estimateFeeForSize:(NSInteger)txsize feeRate:(DMCAmount)feePerK {
    if (feePerK <= 0) return 0;
    DMCAmount fee = 0;
    while (txsize > 0) { // add fee rate for each (even incomplete) 1K byte chunk
        txsize -= 1000;
        fee += feePerK;
    }
    return fee;
}




// TO BE REVIEWED:



// Minimum base fee to send a transaction.
+ (DMCAmount) minimumFee {
    NSNumber* n = [[NSUserDefaults standardUserDefaults] objectForKey:@"DMCTransactionMinimumFee"];
    if (!n) return 10000;
    return (DMCAmount)[n longLongValue];
}

+ (void) setMinimumFee:(DMCAmount)fee {
    fee = MIN(fee, DMC_MAX_MONEY);
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:fee] forKey:@"DMCTransactionMinimumFee"];
}

// Minimum base fee to relay a transaction.
+ (DMCAmount) minimumRelayFee {
    NSNumber* n = [[NSUserDefaults standardUserDefaults] objectForKey:@"DMCTransactionMinimumRelayFee"];
    if (!n) return 10000;
    return (DMCAmount)[n longLongValue];
}

+ (void) setMinimumRelayFee:(DMCAmount)fee {
    fee = MIN(fee, DMC_MAX_MONEY);
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:fee] forKey:@"DMCTransactionMinimumRelayFee"];
}


// Minimum fee to relay the transaction
- (DMCAmount) minimumRelayFee {
    return [self minimumFeeForSending:NO];
}

// Minimum fee to send the transaction
- (DMCAmount) minimumSendFee {
    return [self minimumFeeForSending:YES];
}

- (DMCAmount) minimumFeeForSending:(BOOL)sending {
    // See also CTransaction::GetMinFee in BitcoinQT and calculate_minimum_fee in daemsCoin-ruby
    
    // BitcoinQT calculates min fee based on current block size, but it's unused and constant value is used today instead.
    NSUInteger baseBlockSize = 1000;
    // BitcoinQT has some complex formulas to determine when we shouldn't allow free txs. To be done later.
    BOOL allowFree = YES;
    
    DMCAmount baseFee = sending ? [DMCTransaction minimumFee] : [DMCTransaction minimumRelayFee];
    NSUInteger txSize = self.data.length;
    NSUInteger newBlockSize = baseBlockSize + txSize;
    DMCAmount minFee = (1 + txSize / 1000) * baseFee;
    
    if (allowFree) {
        if (newBlockSize == 1) {
            // Transactions under 10K are free
            // (about 4500 DMC if made of 50 DMC inputs)
            if (txSize < 10000)
                minFee = 0;
        } else {
            // Free transaction area
            if (newBlockSize < 27000)
                minFee = 0;
        }
    }
    
    // To limit dust spam, require base fee if any output is less than 0.01
    if (minFee < baseFee) {
        for (DMCTransactionOutput* txout in _outputs) {
            if (txout.value < DMCCent) {
                minFee = baseFee;
                break;
            }
        }
    }
    
    // Raise the price as the block approaches full
    if (baseBlockSize != 1 && newBlockSize >= DMC_MAX_BLOCK_SIZE_GEN/2) {
        if (newBlockSize >= DMC_MAX_BLOCK_SIZE_GEN)
            return DMC_MAX_MONEY;
        minFee *= DMC_MAX_BLOCK_SIZE_GEN / (DMC_MAX_BLOCK_SIZE_GEN - newBlockSize);
    }
    
    if (minFee < 0 || minFee > DMC_MAX_MONEY) minFee = DMC_MAX_MONEY;
    
    return minFee;
}



@end
