//
//  DMCPeer.h

#import <Foundation/Foundation.h>


#if DAEMSCOIN_TESTNET
#define DAEMSCOIN_STANDARD_PORT 18333
#else
#define DAEMSCOIN_STANDARD_PORT 8333
#endif

#define DAEMSCOIN_TIMEOUT_CODE  1001

#define SERVICES_NODE_NETWORK 0x01 // services value indicating a node carries full blocks, not just headers
#define SERVICES_NODE_BLOOM   0x04 // BIP111: https://github.com/bitcoin/bips/blob/master/bip-0111.mediawiki
#define USER_AGENT            [NSString stringWithFormat:@"/daems:%@/",\
                               NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]]

// 网络通信基础协议方法: https://en.bitcoin.it/wiki/Protocol_documentation
// 巴比特的说明: http://www.8btc.com/protocol_specification
#define MSG_VERSION     @"version"
#define MSG_VERACK      @"verack"
#define MSG_ADDR        @"addr"
#define MSG_INV         @"inv"
#define MSG_GETDATA     @"getdata"
#define MSG_NOTFOUND    @"notfound"
#define MSG_GETBLOCKS   @"getblocks"
#define MSG_GETHEADERS  @"getheaders"
#define MSG_BLOCK       @"block"
#define MSG_HEADERS     @"headers"
#define MSG_GETADDR     @"getaddr"
#define MSG_MEMPOOL     @"mempool"
#define MSG_PING        @"ping"
#define MSG_PONG        @"pong"
#define MSG_FILTERLOAD  @"filterload"
#define MSG_FILTERADD   @"filteradd"
#define MSG_FILTERCLEAR @"filterclear"
#define MSG_MERKLEBLOCK @"merkleblock"
#define MSG_ALERT       @"alert"
#define MSG_REJECT      @"reject"      // BIP61: https://github.com/bitcoin/bips/blob/master/bip-0061.mediawiki
#define MSG_SENDHEADERS @"sendheaders" // BIP130: https://github.com/bitcoin/bips/blob/master/bip-0130.mediawiki
#define MSG_FEEFILTER   @"feefilter"   // BIP133: https://github.com/bitcoin/bips/blob/master/bip-0133.mediawiki
/***** 新增daems协议 *****/
#define MSG_GETBALANCEBYADDR        @"getbalancebyaddr"
#define MSG_BALANCEBYADDR           @"balancebyaddr"
#define MSG_GETTXIDSBYADDR          @"gettxidsbyaddr"
#define MSG_TXIDSBYADDRESS          @"txidsbyaddress"
#define MSG_GETTXS                  @"gettxs"
#define MSG_TX4LIGHTNODE            @"tx4lightnode"
#define MSG_GETAVAILABLECHEQUES     @"getavailablecheques"
#define MSG_AVAILABLECHEQUES        @"availablecheques"
#define MSG_TX                      @"tx"
#define MSG_LAYER1TX                @"layer1tx"
#define MSG_REGISTERADDR            @"registeraddr"
#define MSG_REGISTERED              @"registered"
#define MSG_GETNODEADDRESSES        @"getnodeaddresses"
#define MSG_NODEADDRESSES           @"nodeaddresses"
#define MSG_FALLBACK                @"fallback"
#define MSG_DISABLECHEQUE           @"disablecheque"


#define REJECT_INVALID     0x10 // transaction is invalid for some reason (invalid signature, output value > input, etc)
#define REJECT_SPENT       0x12 // an input is already spent
#define REJECT_NONSTANDARD 0x40 // not mined/relayed because it is "non-standard" (type or version unknown by server)
#define REJECT_DUST        0x41 // one or more output amounts are below the 'dust' threshold
#define REJECT_LOWFEE      0x42 // transaction does not have enough fee/priority to be relayed or mined

typedef union _UInt256 UInt256;
typedef union _UInt128 UInt128;

@class DMCPeer, DMCTransaction, DMCMerkleBlock;

@protocol DMCPeerDelegate<NSObject>
@required

- (void)peerConnected:(DMCPeer *)peer;
- (void)peer:(DMCPeer *)peer disconnectedWithError:(NSError *)error;
- (void)peer:(DMCPeer *)peer relayedPeers:(NSArray *)peers;
- (void)peer:(DMCPeer *)peer relayedTransaction:(DMCTransaction *)transaction;
- (void)peer:(DMCPeer *)peer hasTransaction:(UInt256)txHash;
- (void)peer:(DMCPeer *)peer rejectedTransaction:(UInt256)txHash withCode:(uint8_t)code;

// called when the peer relays either a merkleblock or a block header, headers will have 0 totalTransactions
- (void)peer:(DMCPeer *)peer relayedBlock:(DMCMerkleBlock *)block;

- (void)peer:(DMCPeer *)peer notfoundTxHashes:(NSArray *)txHashes andBlockHashes:(NSArray *)blockhashes;
- (void)peer:(DMCPeer *)peer setFeePerKb:(uint64_t)feePerKb;
- (DMCTransaction *)peer:(DMCPeer *)peer requestedTransaction:(UInt256)txHash;

@end

//连接状态枚举
typedef enum : NSInteger {
    DMCPeerStatusDisconnected = 0,
    DMCPeerStatusConnecting,
    DMCPeerStatusConnected
} DMCPeerStatus;

@interface DMCPeer : NSObject<NSStreamDelegate>

@property (nonatomic, readonly) id<DMCPeerDelegate> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;

// set this to the timestamp when the wallet was created to improve initial sync time (interval since refrence date)
@property (nonatomic, assign) NSTimeInterval earliestKeyTime;

@property (nonatomic, readonly) DMCPeerStatus status;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) UInt128 address;
@property (nonatomic, readonly) uint16_t port;
@property (nonatomic, readonly) uint64_t services;
@property (nonatomic, readonly) uint32_t version;
@property (nonatomic, readonly) uint64_t nonce;
@property (nonatomic, readonly) NSString *useragent;
@property (nonatomic, readonly) uint32_t lastblock;
@property (nonatomic, readonly) uint64_t feePerKb; // minimum tx fee rate peer will accept
@property (nonatomic, readonly) NSTimeInterval pingTime;
@property (nonatomic, readonly) NSTimeInterval relaySpeed; // headers or block->totalTx per second being relayed
@property (nonatomic, assign) NSTimeInterval timestamp; // timestamp reported by peer (interval since refrence date)
@property (nonatomic, assign) int16_t misbehavin;

@property (nonatomic, assign) BOOL needsFilterUpdate; // set this when wallet addresses need to be added to bloom filter
@property (nonatomic, assign) uint32_t currentBlockHeight; // set this to local block height (helps detect tarpit nodes)
@property (nonatomic, assign) BOOL synced; // use this to keep track of peer state


/**
 以IP地址和端口初始化一个节点

 @param address IP地址
 @param port 端口
 @return 实例
 */
+ (instancetype)peerWithAddress:(UInt128)address andPort:(uint16_t)port;


/**
 以IP地址和端口初始化一个节点
 */
- (instancetype)initWithAddress:(UInt128)address andPort:(uint16_t)port;


/**
 以IP地址和端口初始化一个节点

 @param address IP地址
 @param port 端口
 @param timestamp 时间(version >= 31402)
 @param services 该连接允许的特性
 @return ——
 */
- (instancetype)initWithAddress:(UInt128)address port:(uint16_t)port timestamp:(NSTimeInterval)timestamp services:(uint64_t)services;


/**
 设置委托

 @param delegate 委托对象
 @param delegateQueue 线程队列
 */
- (void)setDelegate:(id<DMCPeerDelegate>)delegate queue:(dispatch_queue_t)delegateQueue;


/**
 建立链接
 */
- (void)connect;


/**
 断开链接
 */
- (void)disconnect;


/**
 发送消息

 @param message 消息主体payload
 @param type 类型
 */
- (void)sendMessage:(NSData *)message type:(NSString *)type;


/**
 filterload, filteradd, filterclear, merkleblock的数据发送
 bip-0037解析 https://github.com/bitcoin/bips/blob/master/bip-0037.mediawiki
 @param filter ——
 */
- (void)sendFilterloadMessage:(NSData *)filter;


- (void)sendMempoolMessage:(NSArray *)publishedTxHashes completion:(void (^)(BOOL success))completion;

- (void)sendGetheadersMessageWithLocators:(NSArray *)locators andHashStop:(UInt256)hashStop;
- (void)sendGetblocksMessageWithLocators:(NSArray *)locators andHashStop:(UInt256)hashStop;
- (void)sendInvMessageWithTxHashes:(NSArray *)txHashes;
- (void)sendGetdataMessageWithTxHashes:(NSArray *)txHashes andBlockHashes:(NSArray *)blockHashes;
- (void)sendGetaddrMessage;
- (void)sendPingMessageWithPongHandler:(void (^)(BOOL success))pongHandler;
- (void)rerequestBlocksFrom:(UInt256)blockHash; // useful to get additional transactions after a bloom filter update

@end
