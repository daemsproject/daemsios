//
//  MessageHandler.h
//  daemsios
//
//  Created by Chance on 2017/4/6.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MessageHandler;


/**
 消息处理委托
 */
@protocol MessageHandlerDelegate <NSObject>


/**
 消息包输出，回调给上层，上层进行推送
 
 @param handler 处理器对象
 @param buff 消息包
 */
- (void)messageHandler:(MessageHandler *)handler output:(NSData *)buff;


@end


/**
 消息处理器基类
 */
@interface MessageHandler : NSObject


/**
 委托
 */
@property (nonatomic, weak) id<MessageHandlerDelegate> delegate;

/**
 解析输入流，子类负责具体协议的解析，解析完成后，需要推送给对方的，
 通过回调messageHandler:(MessageHandler *)handler output:(NSData *)buff;
 
 @param inputStream 输入流引用对象
 */
- (BOOL)handleInputStream:(NSInputStream *)inputStream error:(NSError **)error;

/**
 组织错误消息
 
 @param message -
 @return -
 */
- (NSError *)error:(NSString *)message, ... NS_FORMAT_FUNCTION(1,2);

@end
