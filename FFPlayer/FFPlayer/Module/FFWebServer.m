//
//  FFWebServer.m
//  FFPlayer
//
//  Created by cyt on 14-1-16.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFWebServer.h"
#import "FFAppDelegate.h"

static NSString* _serverName = nil;
static dispatch_queue_t _connectionQueue = NULL;
static NSInteger _connectionCount = 0;

@implementation FFWebServerConnection

- (void) open {
    [super open];
    
    dispatch_sync(_connectionQueue, ^{
        if (_connectionCount == 0) {
            FFWebServer* server = (FFWebServer*)self.server;
            dispatch_async(dispatch_get_main_queue(), ^{
                [server.delegate webServerDidConnect:server];
            });
        }
        _connectionCount += 1;
    });
}

- (void) close {
    dispatch_sync(_connectionQueue, ^{
        _connectionCount -= 1;
        if (_connectionCount == 0) {
            FFWebServer* server = (FFWebServer*)self.server;
            dispatch_async(dispatch_get_main_queue(), ^{
                [server.delegate webServerDidDisconnect:server];
            });
        }
    });
    
    [super close];
}

@end

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

+ (Class) connectionClass {
    return [FFWebServerConnection class];
}

+ (NSString*) serverName {
    return _serverName;
}

- (BOOL) start {
    NSSet* allowedFileExtensions = [NSSet setWithObjects:@"pdf", @"zip", @"cbz", @"rar", @"cbr", nil];
    NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
    NSString* footer = [NSString stringWithFormat:NSLocalizedString(@"SERVER_FOOTER_FORMAT", nil),
                        [[UIDevice currentDevice] name],
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSDictionary* baseVariables = [NSDictionary dictionaryWithObjectsAndKeys:footer, @"footer", nil];
    
    [self addHandlerForBasePath:@"/" localPath:websitePath indexFilename:nil cacheAge:3600];
    
    [self addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/index.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        return [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        
    }];
    
    [self addHandlerForMethod:@"GET" path:@"/download.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        GCDWebServerResponse* response = nil;
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
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
            if (extension && [allowedFileExtensions containsObject:extension]) {
                    
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
    
    if (![self startWithPort:8080 bonjourName:nil]) {
        [self removeAllHandlers];
        return NO;
    }
    
    return YES;
}

- (void) stop {
    [super stop];
    
    [self removeAllHandlers];  // Required to break release cycles (since handler blocks can hold references to server)
}

@end
