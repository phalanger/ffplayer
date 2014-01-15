//
//  FFHelper.h
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFHelper : NSObject

+ (float)iOSVersion;
+(BOOL) isSupportMidea:(NSString *)path;
+(BOOL) isInternalPlayerSupport:(NSString *)path;
+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation;
+(BOOL) isIpad;

@end

///////////////////////////////////////////////////

enum SORT_TYPE
{
    SORT_BY_NAME,
    SORT_BY_NAME_DESC,
    SORT_BY_DATE,
    SORT_BY_DATE_DESC,
    SORT_RANDOM
};

@interface FFSetting : NSObject

-(id) init;

-(BOOL) enableInternalPlayer;
-(void) setEnableInternalPlayer:(BOOL) bo;

-(BOOL) autoPlayNext;
-(void) setAutoPlayNext:(BOOL) bo;

-(int) sortType;
-(void) setSortType:(int) type;

-(int) seekDelta;
-(void) setSeekDelta:(int) n;

@end
