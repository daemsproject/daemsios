//
//  DMCMessageHandler.m
//  daemsios
//
//  Created by Chance on 2017/4/5.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import "DMCMessageHandler.h"
#import "DMCConstants.h"
#import "NSMutableData+DaemsCoin.h"
#import "NSData+DaemsCoin.h"
#import "Reachability.h"
#import <arpa/inet.h>

@interface DMCMessageHeader : NSObject

@property (nonatomic, assign) uint32_t magic;
@property (nonatomic, strong) NSString *command;
@property (nonatomic, assign) uint32_t length;
@property (nonatomic, assign) uint32_t checksum;

@end

@implementation DMCMessageHeader

@end

@interface DMCMessageHandler ()

//消息主体
@property (nonatomic, strong) NSMutableData *msgHeader, *msgPayload, *outputBuffer;


//使用一个runloop来处理每个节点的连接
@property (nonatomic, strong) NSRunLoop *runLoop;

@end

@implementation DMCMessageHandler

/******************** 重载方法 ********************/

/**
 
 处理输入流

 @param inputStream 输入流
 */
- (BOOL)handleInputStream:(NSInputStream *)inputStream error:(NSError **)error {
    
    //这里的消息解析过于臃肿，需要优化
    while (inputStream.hasBytesAvailable) {
        @autoreleasepool {
            
            //以下程序控制在对每一个消息包的处理

            NSData *message = nil;
            NSString *type = nil;
            
            //开始时，self.msgHeader.length = 0， self.msgPayload = 0
            //headerLen偏移长度
            NSInteger headerLen = self.msgHeader.length, payloadLen = self.msgPayload.length, l = 0;
            uint32_t length = 0, checksum = 0;
            
            /************** 【一】消息头处理 **************/
            
            if (headerLen < HEADER_LENGTH) { // 读取头部，协议中Message的头部不会超过24字节
                self.msgHeader.length = HEADER_LENGTH;  //把前24字节以0填充，增加部分以0填充
                //输入流中的写入数据到头部缓存，开始位以headerLen偏移
                l = [inputStream read:(uint8_t *)self.msgHeader.mutableBytes + headerLen
                            maxLength:self.msgHeader.length - headerLen];
                
                //l为实际读取的长度
                if (l < 0) {    //如果没有数据读取了，则处理下一个消息
                    NSLog(@"error reading message");
                    goto reset;
                }
                
                //消息头长度与实际读取的长度累加
                self.msgHeader.length = headerLen + l;
                
                //读取头4字节的内容，判断是否为聊天币网络识别，一条消息必须以这个内容作为头部开始
                while (self.msgHeader.length >= sizeof(uint32_t) &&
                       [self.msgHeader UInt32AtOffset:0] != DAEMSCOIN_MAGIC_NUMBER) {
#if DEBUG
                    //d9 b4 be f9
                    printf("%c", *(const char *)self.msgHeader.bytes);
#endif
                    //如果不是，移除这些内容，直至找到头4字节能识别为聊天币网络位置
                    [self.msgHeader replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
                }
                
                //头部长度未读取够，继续while读取
                if (self.msgHeader.length < HEADER_LENGTH) continue; // wait for more stream input
            }
            
            //检查command是否用NULL填充结束，使用非NULL字符填充会被拒绝
            if ([self.msgHeader UInt8AtOffset:15] != 0) { // verify msg type field is null terminated
                *error = [self error:@"malformed message header: %@", self.msgHeader];
                goto reset;
            }
            
            /*
             Message Header:
             F9 BE B4 D9                                     - magic ：main 网络
             61 64 64 72  00 00 00 00 00 00 00 00            - "addr"
             1F 00 00 00                                     - payload 长度31字节
             7F 85 39 C2                                     - payload 校验和
             */
            
            type = @((const char *)self.msgHeader.bytes + 4);   //类型
            length = [self.msgHeader UInt32AtOffset:16];        //长度
            checksum = [self.msgHeader UInt32AtOffset:20];      //校验
            
            /************** 【二】消息主体处理 **************/
            
            if (length > MAX_MSG_LENGTH) { // 检查消息长度是否超限制
                *error = [self error:@"error reading %@, message length %u is too long", type, length];
                goto reset;
            }
            
            if (payloadLen < length) { // read message payload
                self.msgPayload.length = length;        //设置payload长度，增加部分以0填充
                
                //从输入流写入数据到payload缓存
                l = [inputStream read:(uint8_t *)self.msgPayload.mutableBytes + payloadLen
                            maxLength:self.msgPayload.length - payloadLen];
                
                //self.msgPayload.length - payloadLen = 剩余需要写入的数量
                
                if (l < 0) {    //读取失败
                    NSLog(@"error reading");
                    goto reset;
                }
                //重新记录消息主体实际长度已写入
                self.msgPayload.length = payloadLen + l;
                if (self.msgPayload.length < length) continue; //长度未到尽头，继续写
            }
            
            if (CFSwapInt32LittleToHost(self.msgPayload.SHA256_2.u32[0]) != checksum) { // 检查payload的前4个字节：sha256(sha256(payload)) == checksum
                *error = [self error:@"error reading %@, invalid checksum %x, expected %x, payload length:%u, expected "
                 "length:%u, SHA256_2:%@", type, self.msgPayload.SHA256_2.u32[0], checksum,
                 (int)self.msgPayload.length, length, uint256_obj(self.msgPayload.SHA256_2)];
                goto reset;
            }
            
            message = self.msgPayload;      //取得消息主体
            self.msgPayload = [NSMutableData data];     //重置消息主体
            //[self acceptMessage:message type:type]; // 处理消息业务
            
        reset:
            // 完整消息提取成功后 或 数据解析异常
            //把消息头和消息主体重置，继续读取符合协议处理的内容
            self.msgHeader.length = self.msgPayload.length = 0;
            
            //如果中途遇到协议约定错误，则连接的节点有问题，退出并返回错误
            if (error != nil) {
                //不在处理这个节点的推送数据，退出
                return false;
            }
        }
    }
    //所有数据完成处理
    return true;
}


/**
 解析协议头，只处理头部内容，解析完则返回头部对象

 @param inputStream 输入流
 @return 头部对象
 */
- (DMCMessageHeader *)decodeHeader:(NSInputStream *)inputStream error:(NSError **)error {
    
    DMCMessageHeader *header = nil; //协议头
    
    NSMutableData *msgHeader = [NSMutableData data];
    
    NSInteger headerLen = 0;
    
    while (inputStream.hasBytesAvailable) {
        @autoreleasepool {
            
            //以下程序控制在对每一个消息包的处理
            
            NSInteger l = 0;
            
            //一段消息开始时headerLen = 0， payloadLen = 0
            
            //headerLen偏移长度
            headerLen = msgHeader.length;
            
            /************** 【一】消息头处理 **************/
            
            if (headerLen < HEADER_LENGTH) { // 读取头部，协议中Message的头部不会超过24字节
                msgHeader.length = HEADER_LENGTH;  //把前24字节以0填充，增加部分以0填充
                //输入流中的写入数据到头部缓存，开始位以headerLen偏移
                l = [inputStream read:(uint8_t *)msgHeader.mutableBytes + headerLen
                            maxLength:msgHeader.length - headerLen];
                
                //l为实际读取的长度
                if (l < 0) {    //如果没有数据读取了，则处理下一个消息
                    NSLog(@"error reading message");
                    goto reset;
                }
                
                //消息头长度与实际读取的长度累加
                msgHeader.length = headerLen + l;
                
                //读取头4字节的内容，判断是否为聊天币网络识别，一条消息必须以这个内容作为头部开始
                while (msgHeader.length >= sizeof(uint32_t) &&
                       [msgHeader UInt32AtOffset:0] != DAEMSCOIN_MAGIC_NUMBER) {
#if DEBUG
                    //d9 b4 be f9
                    printf("%c", *(const char *)msgHeader.bytes);
#endif
                    //如果不是，移除这些内容，直至找到头4字节能识别为聊天币网络位置
                    [msgHeader replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
                }
                
                //头部长度未读取够，继续while读取
                if (msgHeader.length < HEADER_LENGTH) continue; // wait for more stream input
            }
            
            //检查command是否用NULL填充结束，使用非NULL字符填充会被拒绝
            if ([msgHeader UInt8AtOffset:15] != 0) { // verify msg type field is null terminated
                *error = [self error:@"malformed message header: %@", self.msgHeader];
                goto reset;
            }
            
            /*
             Message Header:
             F9 BE B4 D9                                     - magic ：main 网络
             61 64 64 72  00 00 00 00 00 00 00 00            - "addr"
             1F 00 00 00                                     - payload 长度31字节
             7F 85 39 C2                                     - payload 校验和
             */
            
            //记录头部
            header = [[DMCMessageHeader alloc] init];
            header.command = @((const char *)msgHeader.bytes + 4);   //类型
            header.length = [msgHeader UInt32AtOffset:16];        //长度
            header.checksum = [msgHeader UInt32AtOffset:20];      //校验
            
        reset:
            // 完整消息提取成功后 或 数据解析异常
            //把消息头和消息主体重置，继续读取符合协议处理的内容
            msgHeader.length = 0;
            
            //如果中途遇到协议约定错误，则连接的节点有问题，退出并返回错误
            if (error != nil) {
                //不在处理这个节点的推送数据，退出
                return header;
            }
        }
    }
    
    return header;
}


/******************** 协议处理方法 ********************/


/**
 分类处理消息

 @param message 消息负载
 @param type 类型
 */
- (void)acceptMessage:(NSData *)message type:(NSString *)type
{
    /*
    if (self.currentBlock && ! [MSG_TX isEqual:type]) { // if we receive a non-tx message, merkleblock is done
        //当所有交易单接收完
        
         UInt256 hash = self.currentBlock.blockHash;
         
         self.currentBlock = nil;
         self.currentBlockTxHashes = nil;
         [self error:@"incomplete merkleblock %@, expected %u more tx, got %@",
         uint256_obj(hash), (int)self.currentBlockTxHashes.count, type];
     
    }
    else if ([MSG_VERSION isEqual:type]) [self acceptVersionMessage:message];
    else if ([MSG_VERACK isEqual:type]) [self acceptVerackMessage:message];
    else if ([MSG_ADDR isEqual:type]) [self acceptAddrMessage:message];
    else if ([MSG_INV isEqual:type]) [self acceptInvMessage:message];
    else if ([MSG_TX isEqual:type]) [self acceptTxMessage:message];
    else if ([MSG_HEADERS isEqual:type]) [self acceptHeadersMessage:message];
    else if ([MSG_GETADDR isEqual:type]) [self acceptGetaddrMessage:message];
    else if ([MSG_GETDATA isEqual:type]) [self acceptGetdataMessage:message];
    else if ([MSG_NOTFOUND isEqual:type]) [self acceptNotfoundMessage:message];
    else if ([MSG_PING isEqual:type]) [self acceptPingMessage:message];
    else if ([MSG_PONG isEqual:type]) [self acceptPongMessage:message];
    else if ([MSG_MERKLEBLOCK isEqual:type]) [self acceptMerkleblockMessage:message];
    else if ([MSG_REJECT isEqual:type]) [self acceptRejectMessage:message];
    else if ([MSG_FEEFILTER isEqual:type]) [self acceptFeeFilterMessage:message];
    else NSLog(@"%@:%u dropping %@, len:%u, not implemented", self.host, self.port, type, (int)message.length);
    */
}


@end
