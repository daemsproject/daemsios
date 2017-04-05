//
//  DMCMessageHandler.m
//  daemsios
//
//  Created by Chance on 2017/4/5.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import "DMCMessageHandler.h"

@protocol MessageHandlerDelegate <NSObject>

- (void)handleMessage:(NSData *)message;

@end

@implementation DMCMessageHandler

@end
