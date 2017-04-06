//
//  DMCConstants.h
//  daemsios
//
//  Created by Chance on 2017/4/6.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 DMC币的常量，方便日后扩展
 */
@interface DMCConstants : NSObject

/******************** 协议命令 ********************/

// 网络通信基础协议方法: https://en.bitcoin.it/wiki/Protocol_documentation
// 巴比特的说明: http://www.8btc.com/protocol_specification

extern NSString * const MSG_VERSION;
extern NSString * const MSG_VERACK;
extern NSString * const MSG_ADDR;
extern NSString * const MSG_INV;
extern NSString * const MSG_GETDATA;
extern NSString * const MSG_NOTFOUND;
extern NSString * const MSG_GETBLOCKS;
extern NSString * const MSG_GETHEADERS;
extern NSString * const MSG_BLOCK;
extern NSString * const MSG_HEADERS;
extern NSString * const MSG_GETADDR;
extern NSString * const MSG_MEMPOOL;
extern NSString * const MSG_PING;
extern NSString * const MSG_PONG;
extern NSString * const MSG_FILTERLOAD;
extern NSString * const MSG_FILTERADD;
extern NSString * const MSG_FILTERCLEAR;
extern NSString * const MSG_MERKLEBLOCK;
extern NSString * const MSG_ALERT;
extern NSString * const MSG_REJECT;
extern NSString * const MSG_SENDHEADERS;
extern NSString * const MSG_FEEFILTER;

/***** 新增daems协议 *****/
extern NSString * const MSG_GETBALANCEBYADDR;
extern NSString * const MSG_BALANCEBYADDR;
extern NSString * const MSG_GETTXIDSBYADDR;
extern NSString * const MSG_TXIDSBYADDRESS;
extern NSString * const MSG_GETTXS;
extern NSString * const MSG_TX4LIGHTNODE;
extern NSString * const MSG_GETAVAILABLECHEQUES;
extern NSString * const MSG_AVAILABLECHEQUES;
extern NSString * const MSG_TX;
extern NSString * const MSG_LAYER1TX;
extern NSString * const MSG_REGISTERADDR;
extern NSString * const MSG_REGISTERED;
extern NSString * const MSG_GETNODEADDRESSES;
extern NSString * const MSG_NODEADDRESSES;
extern NSString * const MSG_FALLBACK;
extern NSString * const MSG_DISABLECHEQUE;

/******************** 其它约束 ********************/

extern NSInteger const HEADER_LENGTH;
extern NSInteger const MAX_MSG_LENGTH;
extern NSInteger const MAX_GETDATA_HASHES;
extern NSInteger const ENABLED_SERVICES;
extern NSInteger const PROTOCOL_VERSION;
extern NSInteger const MIN_PROTO_VERSION;
extern NSInteger const LOCAL_HOST;
extern NSInteger const CONNECT_TIMEOUT;
extern NSInteger const MEMPOOL_TIMEOUT;


@end
