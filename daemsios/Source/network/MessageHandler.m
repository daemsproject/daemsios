//
//  MessageHandler.m
//  daemsios
//
//  Created by Chance on 2017/4/6.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import "MessageHandler.h"

@implementation MessageHandler

- (BOOL)handleInputStream:(NSInputStream *)inputStream error:(NSError **)error {
    return true;
}


/**
 组织错误消息
 
 @param message -
 @return -
 */
- (NSError *)error:(NSString *)message, ... NS_FORMAT_FUNCTION(1,2)
{
    va_list args;
    
    va_start(args, message);
    NSError *error = [NSError errorWithDomain:@"Daems" code:500
                                     userInfo:@{NSLocalizedDescriptionKey:[[NSString alloc] initWithFormat:message arguments:args]}];
    va_end(args);
    return error;
}

@end
