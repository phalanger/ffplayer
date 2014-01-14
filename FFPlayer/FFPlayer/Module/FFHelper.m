//
//  FFHelper.m
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFHelper.h"

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

@end

//////////////////////////////////////////////////////

@interface FFSetting ()
{
    NSUserDefaults * _setting;
}
@end

@implementation FFSetting

-(id) init
{
    self = [super init];
    self->_setting = [NSUserDefaults standardUserDefaults];
    return self;
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

@end
