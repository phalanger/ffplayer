//
//  FFWebServer.m
//  FFPlayer
//
//  Created by cyt on 14-1-16.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFWebServer.h"
#import "FFAppDelegate.h"
#import "FFHelper.h"
#import "FFSetting.h"
#import "FFLocalFileManager.h"

static NSString* _serverName = nil;
static dispatch_queue_t _connectionQueue = NULL;

@implementation FFWebServer

@synthesize delegate=_delegate;

+ (void) initialize {
    if (_serverName == nil) {
        _serverName = [[NSString alloc] initWithFormat:NSLocalizedString(@"SERVER_NAME_FORMAT", nil),
                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    }
    if (_connectionQueue == NULL) {
        _connectionQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    }
}

+ (NSString*) serverName {
    return _serverName;
}

-(id)init
{
    self = [super init];
    if ( self != nil )
        [self initHandle];
    return self;
}

+(void) getFolderContent:(NSString *)subPath content:(NSMutableString *)content inSecret:(BOOL)inSecret
{
    if ( subPath != nil ) {
        NSRange r;
        while ( (r=[subPath rangeOfString:@"../"]).location == 0 )
            subPath = [subPath substringFromIndex:3];
        subPath = [subPath stringByReplacingOccurrencesOfString:@"/../" withString:@"/"];
        if ( subPath.length == 0 )
            subPath = nil;
    }
    
    NSByteCountFormatter *byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setAllowedUnits:NSByteCountFormatterUseMB];
    NSString * strRoot = inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
    NSString * strInSec = inSecret ? @"&sec=1" : @"";
    
    NSArray * ary = [FFLocalFileManager listCurrentFolder:subPath inSecret:inSecret];
    for ( FFLocalItem * item in ary ) {
        NSString * strSubItem = [item.fullPath substringFromIndex:(strRoot.length + 1)];
        NSString * strKey = [strSubItem stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * strDisplay = [item.fileName gtm_stringByEscapingForHTML];
        if ( item.type == LIT_PARENT ) {
            strDisplay = @"Parent";
            if ( subPath == nil ) {
                [content appendFormat:@"<tr><td><a href=\"download.html\">[%@]</a></td><td></td></tr>", strDisplay];
            } else {
                strKey = [[subPath stringByDeletingLastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [content appendFormat:@"<tr><td><a href=\"download.html?id=%@%@\">[%@]</a></td><td></td></tr>", strKey == nil ? @"" : strKey, strInSec, strDisplay];
            }
        } else if ( item.type == LIT_SECRETE ) {
            strDisplay = @"Secret";
            [content appendFormat:@"<tr><td><a href=\"download.html?sec=1\">[%@]</a></td><td></td></tr>", strDisplay];
        } else if ( item.isDir) {
            [content appendFormat:@"<tr><td><a href=\"download.html?id=%@%@\">[%@]</a></td><td></td></tr>", strKey, strInSec, strDisplay];
        } else {
            [content appendFormat:@"<tr><td><a href=\"download?id=%@%@\">%@</a></td><td>%@</td></tr>", strKey, strInSec, strDisplay, [byteCountFormatter stringFromByteCount:item.size]];
        }
    }
}

-(void) initHandle {
    
    NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
    NSString* footer = [NSString stringWithFormat:@"%@ - %@",
                        [[UIDevice currentDevice] name],
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSDictionary* baseVariables = [NSDictionary dictionaryWithObjectsAndKeys:footer, @"footer", nil];
    
    [self addHandlerForBasePath:@"/" localPath:websitePath indexFilename:nil cacheAge:3600];
    
    [self addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/index.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        return [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
    }];
    
    [self addHandlerForMethod:@"GET" path:@"/download.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        GCDWebServerResponse* response = nil;
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        
        NSString * strQryRoot = nil;
        NSMutableString* content = [[NSMutableString alloc] init];
        BOOL boInSecret = NO;
        if (request.query != nil ) {
            strQryRoot = [[request.query objectForKey:@"id"] stringByRemovingPercentEncoding];
            boInSecret = ([[request.query objectForKey:@"sec"] intValue] != 0) && [[FFSetting default] unlock];
        }
        [FFWebServer getFolderContent:strQryRoot content:content inSecret:boInSecret];
        [variables setObject:content forKey:@"content"];

        response = [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        return response;
    }];
    
    __weak FFWebServer * weakSelf = self;
    [self addHandlerForMethod:@"GET" path:@"/download" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        GCDWebServerResponse* response = nil;
        NSString* path = nil;
        if (path) {
            response = [GCDWebServerFileResponse responseWithFile:path isAttachment:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate webServerDidDownloadComic:weakSelf];
            });
        } else {
            response = [GCDWebServerResponse responseWithStatusCode:404];
        }
        return response;
    }];
    
    [self addHandlerForMethod:@"GET" path:@"/upload.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        [variables setObject:@"0" forKey:@"remaining"];
        [variables setObject:@"hidden" forKey:@"class"];
        return [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        
    }];
    [self addHandlerForMethod:@"POST" path:@"/upload" requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSString* html = NSLocalizedString(@"SERVER_STATUS_SUCCESS", nil);
        GCDWebServerMultiPartFile* file = [[(GCDWebServerMultiPartFormRequest*)request files] objectForKey:@"file"];
        NSString* fileName = file.fileName;
        NSString* temporaryPath = file.temporaryPath;
        GCDWebServerMultiPartArgument* collection = [[(GCDWebServerMultiPartFormRequest*)request arguments] objectForKey:@"collection"];
        if (fileName.length && ![fileName hasPrefix:@"."]) {
            NSString* extension = [[fileName pathExtension] lowercaseString];
            if (extension) {
                    
                    NSString* directoryPath = nil;
                    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:NULL];
                
                    NSString* filePath = [directoryPath stringByAppendingPathComponent:fileName];
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
                    
                    NSError* error = nil;
                    if ([[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:filePath error:&error]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate webServerDidUploadComic:weakSelf];
                        });
                    } else {
                        html = NSLocalizedString(@"SERVER_STATUS_ERROR", nil);
                        html = NSLocalizedString(@"SERVER_STATUS_UNSUPPORTED", nil);
                        html = NSLocalizedString(@"SERVER_STATUS_INVALID", nil);
                    }
            }
        } else
            return [GCDWebServerResponse responseWithStatusCode:402];
        return [GCDWebServerDataResponse responseWithHTML:html];
    }];
}

@end
