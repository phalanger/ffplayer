//
//  FFPlayer.m
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFHelper.h"
#import "FFPlayer.h"
#import "FFMovieViewController.h"
#import "FFInternalMoviePlayerController.h"
#import "ALMoviePlayerControls.h"

@implementation FFPlayItem

-(id) initWithPath:(NSString *)url position:(CGFloat) position
{
    self = [super init];
    if ( self ) {
        self->_position = position;
        self->_url = url;
    }
    return self;
}

@end

////////////////////////////////////////

@interface FFPlayer () <FFMovieCallback>
{
    NSArray * _playList;
    int         _curIndex;
    __weak UIViewController *  _parentView;
}
@end

@implementation FFPlayer

-(id) init
{
    self = [super init];
    if ( self ) {
        self->_playList = nil;
        self->_curIndex  = 0;
        self->_parentView = nil;
    }
    
    return self;
}

-(UIViewController *)playList:(NSArray *)aryList curIndex:(int)curIndex parent:(UIViewController *)parent
{
    _playList = aryList;
    _parentView = parent;
    _curIndex = curIndex;
    if ( _playList.count == 0 || curIndex < 0 || curIndex >= _playList.count )
        return nil;
    
    return [self play:_playList[_curIndex] animated:NO];
}

-(BOOL) hasNext
{
    return _curIndex < _playList.count - 1;
}

-(BOOL) hasPre
{
    return _curIndex > 0;
}

-(UIViewController *) play:(FFPlayItem *)item animated:(BOOL)animated
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    NSString * path = item.url;
    
    if ([path.pathExtension isEqualToString:@"wmv"])
        parameters[FFMovieParameterMinBufferedDuration] = @(5.0);
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[FFMovieParameterDisableDeinterlacing] = @(YES);
    
//    KxMovieViewController *vc = [KxMovieViewController movieViewControllerWithContentPath:path parameters:parameters];
//    vc.delegate = self;
    
    UIViewController * vc = nil;
    if ( [FFHelper isInternalPlayerSupport:path] ) {
        FFInternalMoviePlayerController * vc1 = [FFInternalMoviePlayerController movieViewControllerWithDelegate:self];
        [vc1 playMovie:path pos:0.f parameters:parameters];
        vc = vc1;
    } else {
        FFMovieViewController * vc2 = [FFMovieViewController movieViewControllerWithDelegate:self];
        [vc2 playMovie:path pos:0.f parameters:parameters];
        vc = vc2;
    }
    [_parentView presentViewController:vc animated:animated completion:nil];
    return vc;
}

-(void) onFinish:(UIViewController *)control curPos:(CGFloat)curPos
{
    
}

-(void) onNext:(UIViewController *)control curPos:(CGFloat)curPos
{
    if ( [self hasNext] ) {
        [control dismissViewControllerAnimated:NO completion:nil];
        ++_curIndex;
        [self play:_playList[_curIndex] animated:NO];
    } else
        [control dismissViewControllerAnimated:YES completion:nil];
}

-(void) onPre:(UIViewController *)control curPos:(CGFloat)curPos
{
    if ( [self hasPre] ) {
        [control dismissViewControllerAnimated:NO completion:nil];
        --_curIndex;
        [self play:_playList[_curIndex] animated:NO];
    } else
        [control dismissViewControllerAnimated:YES completion:nil];
}

@end
