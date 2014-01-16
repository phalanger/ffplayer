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
+ (NSString *)md5HexDigest:(NSString*)input;

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

+(FFSetting *)default;

-(id) init;

-(BOOL) enableInternalPlayer;
-(void) setEnableInternalPlayer:(BOOL) bo;

-(BOOL) autoPlayNext;
-(void) setAutoPlayNext:(BOOL) bo;

-(int) sortType;
-(void) setSortType:(int) type;

-(int) seekDelta;
-(void) setSeekDelta:(int) n;

-(BOOL) scalingModeFit;
-(void) setScalingMode:(int)n;

-(int) lastSelectedTab;
-(void) setLastSelectedTab:(int)n;

-(BOOL) hasPassword;
-(BOOL) checkPassword:(NSString *)str;
-(void) setPassword:(NSString *)str;

-(BOOL) unlock;
-(void) setUnlock:(BOOL) bo;

@end
