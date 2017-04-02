// 

#ifndef DaemsCoin_DMCUnits_h
#define DaemsCoin_DMCUnits_h

// The smallest unit in DaemsCoin is 1 satoshi.
// Satoshis are 64-bit signed integers.
// The value is signed to allow special value -1 in DMCTransactionOutput.
typedef int64_t DMCAmount;

// This is a deprecated alias to DMCAmount.
// It was a mistake to call amount type by a value unit
// (like using "Kilogram" instead of "Mass").
// This will be deprecated and then reused as a constant value 1 alongside DMCCoin and DMCCent.
typedef int64_t DMCSatoshi DEPRECATED_ATTRIBUTE;

// 100 mln satoshis is one DaemsCoin
static const DMCAmount DMCCoin = 100000000;

// Bitcent is 0.01 DMC
static const DMCAmount DMCCent = 1000000;

// Bit is 0.000001 DMC (100 satoshis)
static const DMCAmount DMCBit = 100;

// Satoshi is the smallest unit representable in daemsCoin transactions.
// IMPORTANT: This will be uncommented when we retire DMCSatoshi type declaration above.
// static const DMCAmount DMCSatoshi = 1;



// Network Rules (changing these will result in incompatibility with other nodes)

// The maximum allowed size for a serialized block, in bytes
static const unsigned int DMC_MAX_BLOCK_SIZE = 1000000;

// The maximum allowed number of signature check operations in a block
static const unsigned int DMC_MAX_BLOCK_SIGOPS = DMC_MAX_BLOCK_SIZE/50;

// No amount larger than this (in satoshi) is valid
static const DMCAmount DMC_MAX_MONEY = 21000000 * DMCCoin;

// Coinbase transaction outputs can only be spent after this number of new blocks
static const int DMC_COINBASE_MATURITY = 100;

// Threshold for -[DMCTransaction lockTime]: below this value it is interpreted as block number, otherwise as UNIX timestamp. */
static const unsigned int DMC_LOCKTIME_THRESHOLD = 500000000; // Tue Nov  5 00:53:20 1985 UTC (max block number is in year ≈11521)

// P2SH BIP16 didn't become active until Apr 1 2012. All txs before this timestamp should not be verified with P2SH rule.
static const uint32_t DMC_BIP16_TIMESTAMP = 1333238400;

// Scripts longer than 10000 bytes are invalid.
static const NSUInteger DMC_MAX_SCRIPT_SIZE = 10000;

// Maximum number of bytes per "pushdata" operation
static const NSUInteger DMC_MAX_SCRIPT_ELEMENT_SIZE = 520; // bytes

// Number of public keys allowed for OP_CHECKMULTISIG
static const NSUInteger DMC_MAX_KEYS_FOR_CHECKMULTISIG = 20;

// Maximum number of operations allowed per script (excluding pushdata operations and OP_<N>)
// Multisig op additionally increases count by a number of pubkeys.
static const NSUInteger DMC_MAX_OPS_PER_SCRIPT = 201;

// Soft Rules (can bend these without becoming incompatible with everyone)

// The maximum number of entries in an 'inv' protocol message
static const unsigned int DMC_MAX_INV_SZ = 50000;

// The maximum size for mined blocks
static const unsigned int DMC_MAX_BLOCK_SIZE_GEN = DMC_MAX_BLOCK_SIZE/2;

// The maximum size for transactions we're willing to relay/mine
static const unsigned int DMC_MAX_STANDARD_TX_SIZE = DMC_MAX_BLOCK_SIZE_GEN/5;


#endif
