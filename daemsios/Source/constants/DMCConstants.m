//
//  DMCConstants.m
//  daemsios
//
//  Created by Chance on 2017/4/6.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import "DMCConstants.h"

@implementation DMCConstants

NSString * const MSG_VERSION = @"version";
NSString * const MSG_VERACK = @"verack";
NSString * const MSG_ADDR = @"addr";
NSString * const MSG_INV = @"inv";
NSString * const MSG_GETDATA = @"getdata";
NSString * const MSG_NOTFOUND = @"notfound";
NSString * const MSG_GETBLOCKS = @"getblocks";
NSString * const MSG_GETHEADERS = @"getheaders";
NSString * const MSG_BLOCK = @"block";
NSString * const MSG_HEADERS = @"headers";
NSString * const MSG_GETADDR = @"getaddr";
NSString * const MSG_MEMPOOL = @"mempool";
NSString * const MSG_PING = @"ping";
NSString * const MSG_PONG = @"pong";
NSString * const MSG_FILTERLOAD = @"filterload";
NSString * const MSG_FILTERADD = @"filteradd";
NSString * const MSG_FILTERCLEAR = @"filterclear";
NSString * const MSG_MERKLEBLOCK = @"merkleblock";
NSString * const MSG_ALERT = @"alert";
NSString * const MSG_REJECT = @"reject";
NSString * const MSG_SENDHEADERS = @"sendheaders";
NSString * const MSG_FEEFILTER = @"feefilter";

/***** 新增daems协议 *****/
NSString * const MSG_GETBALANCEBYADDR = @"getbalancebyaddr";
NSString * const MSG_BALANCEBYADDR = @"balancebyaddr";
NSString * const MSG_GETTXIDSBYADDR = @"gettxidsbyaddr";
NSString * const MSG_TXIDSBYADDRESS = @"txidsbyaddress";
NSString * const MSG_GETTXS = @"gettxs";
NSString * const MSG_TX4LIGHTNODE = @"tx4lightnode";
NSString * const MSG_GETAVAILABLECHEQUES = @"getavailablecheques";
NSString * const MSG_AVAILABLECHEQUES = @"availablecheques";
NSString * const MSG_TX = @"tx";
NSString * const MSG_LAYER1TX = @"layer1tx";
NSString * const MSG_REGISTERADDR = @"registeraddr";
NSString * const MSG_REGISTERED = @"registered";
NSString * const MSG_GETNODEADDRESSES = @"getnodeaddresses";
NSString * const MSG_NODEADDRESSES = @"nodeaddresses";
NSString * const MSG_FALLBACK = @"fallback";
NSString * const MSG_DISABLECHEQUE = @"disablecheque";

NSInteger const HEADER_LENGTH = 24;
NSInteger const MAX_MSG_LENGTH = 0x02000000;
NSInteger const MAX_GETDATA_HASHES = 5000;
NSInteger const ENABLED_SERVICES = 0;   // we don't provide full blocks to remote nodes
NSInteger const PROTOCOL_VERSION = 70013;
NSInteger const MIN_PROTO_VERSION = 70002;  // peers earlier than this protocol version not supported (need v0.9 txFee relay rules)
NSInteger const LOCAL_HOST = 0x7f000001;
NSInteger const CONNECT_TIMEOUT = 3;
NSInteger const MEMPOOL_TIMEOUT = 5;

@end
