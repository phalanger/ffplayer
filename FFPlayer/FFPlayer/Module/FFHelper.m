//
//  FFHelper.m
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFHelper.h"
#import <CommonCrypto/CommonDigest.h>

@implementation FFHelper

+ (float)iOSVersion {
    static float version = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return version;
}

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    if (!application.statusBarHidden && [FFHelper iOSVersion] < 7.0) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

+(BOOL) isIpad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+(BOOL) isSupportMidea:(NSString *)path
{
    NSString *ext = path.pathExtension.lowercaseString;
    
    if ([ext isEqualToString:@"mp3"] ||
        [ext isEqualToString:@"caff"]||
        [ext isEqualToString:@"aiff"]||
        [ext isEqualToString:@"ogg"] ||
        [ext isEqualToString:@"wma"] ||
        [ext isEqualToString:@"m4a"] ||
        [ext isEqualToString:@"mpv"] ||
        [ext isEqualToString:@"m4v"] ||
        [ext isEqualToString:@"wmv"] ||
        [ext isEqualToString:@"3gp"] ||
        [ext isEqualToString:@"mp4"] ||
        [ext isEqualToString:@"mov"] ||
        [ext isEqualToString:@"avi"] ||
        [ext isEqualToString:@"mkv"] ||
        [ext isEqualToString:@"mpeg"]||
        [ext isEqualToString:@"mpg"] ||
        [ext isEqualToString:@"flv"] ||
        [ext isEqualToString:@"vob"])
        return YES;
    
    return NO;
}

+(BOOL) isInternalPlayerSupport:(NSString *)path
{
    /*
     This class plays any movie or audio file supported in iOS. This includes both streamed content and fixed-length files. For movie files, this typically means files with the extensions .mov, .mp4, .mpv, and .3gp and using one of the following compression standards:
     
     H.264 Baseline Profile Level 3.0 video, up to 640 x 480 at 30 fps. (The Baseline profile does not support B frames.)
     MPEG-4 Part 2 video (Simple Profile)
     If you use this class to play audio files, it displays a white screen with a QuickTime logo while the audio plays. For audio files, this class supports AAC-LC audio at up to 48 kHz, and MP3 (MPEG-1 Audio Layer 3) up to 48 kHz, stereo audio.
     */

    NSString *ext = path.pathExtension.lowercaseString;
    
    if (![[FFSetting default] enableInternalPlayer])
        return NO;
    else if ([ext isEqualToString:@"mp3"] ||
        [ext isEqualToString:@"mp4"] ||
        [ext isEqualToString:@"mov"] ||
        [ext isEqualToString:@"mpv"] ||
        [ext isEqualToString:@"3gp"])
        return YES;
    
    return NO;
}

+ (NSString *)md5HexDigest:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];//
    
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end

//////////////////////////////////////////////////////

@interface FFSetting ()
{
    NSUserDefaults * _setting;
    BOOL            _unlock;
}
@end

@implementation FFSetting

-(id) init
{
    self = [super init];
    self->_setting = [NSUserDefaults standardUserDefaults];
    self->_unlock = FALSE;
    return self;
}

+(FFSetting *)default
{
    static FFSetting * setting = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        setting = [[FFSetting alloc] init];
    });
    return setting;
}

-(BOOL) enableInternalPlayer
{
    return ![_setting integerForKey:@"forbit_internal_player"];
}

-(void) setEnableInternalPlayer:(BOOL) bo
{
    [_setting setInteger:bo?0:1 forKey:@"forbit_internal_player"];
    [_setting synchronize];
}

-(BOOL) autoPlayNext
{
    return ![_setting integerForKey:@"pause_after_play"];
}

-(void) setAutoPlayNext:(BOOL) bo
{
    [_setting setInteger:bo?0:1 forKey:@"pause_after_play"];
    [_setting synchronize];
}

-(int) sortType
{
    return [_setting integerForKey:@"sort_type"];
}

-(void) setSortType:(int) type
{
    [_setting setInteger:type forKey:@"sort_type"];
    [_setting synchronize];
}

-(int) seekDelta
{
    int n = [_setting integerForKey:@"seek_delta"];
    if ( n == 0 )
        n = 10;
    return n;
}

-(void) setSeekDelta:(int) n
{
    [_setting setInteger:n forKey:@"seek_delta"];
    [_setting synchronize];
}

-(BOOL) scalingModeFit
{
    return [_setting integerForKey:@"scaling_mode"] != 2;
}

-(void) setScalingMode:(int)n
{
    [_setting setInteger:n forKey:@"scaling_mode"];
    [_setting synchronize];
}

-(int) lastSelectedTab
{
    return [_setting integerForKey:@"last_tab"];
}

-(void) setLastSelectedTab:(int)n
{
    [_setting setInteger:n forKey:@"last_tab"];
    [_setting synchronize];
}

-(BOOL) hasPassword
{
    return [_setting stringForKey:@"password"] != nil;
}

-(BOOL) checkPassword:(NSString *)str
{
    NSString * enc = [FFHelper md5HexDigest:str];
    NSString * save = [_setting stringForKey:@"password"];
    return ( [enc isEqualToString:save]);
}

-(void) setPassword:(NSString *)str
{
    if ( str == nil )
        return;
    [_setting setObject:[FFHelper md5HexDigest:str] forKey:@"password"];
    [_setting synchronize];
}

-(BOOL) unlock
{
    return _unlock;
}

-(void) setUnlock:(BOOL) bo
{
    _unlock = bo;
}

@end
