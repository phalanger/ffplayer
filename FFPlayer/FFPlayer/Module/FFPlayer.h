//
//  FFPlayer.h
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFPlayItem : NSObject
@property (retain,atomic) NSString *    url;
@property (assign) CGFloat              position;

-(id) initWithPath:(NSString *)url position:(CGFloat) position;

@end

@interface FFPlayer : NSObject

-(id) init;
-(UIViewController *)playList:(NSArray *)aryList curIndex:(int)curIndex parent:(UIViewController *)parent;

@end
