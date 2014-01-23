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
#import "XMLDictionary.h"

static NSString* _serverName = nil;
static dispatch_queue_t _connectionQueue = NULL;

@interface FFURLPath : NSObject
@property (atomic)  NSString *  path;
@property (assign)  BOOL        inSecret;
@end

@implementation FFURLPath
@end

////////////////////////////////////////////

@interface GCDWebServerDataResponse (XMLExtensions)
+ (GCDWebServerDataResponse*)responseWithXML:(NSDictionary*)text withStatusCode:(NSInteger)statusCode;
- (id)initWithXML:(NSDictionary*)text withStatusCode:(NSInteger)statusCode;
@end

@implementation GCDWebServerDataResponse (XMLExtensions)

+ (GCDWebServerDataResponse*)responseWithXML:(NSDictionary*)text withStatusCode:(NSInteger)statusCode
{
    return [[self alloc] initWithXML:text withStatusCode:statusCode];
}

- (id)initWithXML:(NSDictionary*)text withStatusCode:(NSInteger)statusCode
{
    NSData* data = [[text XMLString] dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return nil;
    }
    self = [self initWithData:data contentType:@"text/xml; charset=utf-8"];
    self.statusCode = statusCode;
    return self;
}

@end

////////////////////////////////////////////

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

-(void) getFolderContent:(NSString *)subPath content:(NSMutableString *)content inSecret:(BOOL)inSecret
{
    NSByteCountFormatter *byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setAllowedUnits:NSByteCountFormatterUseMB];
    NSString * strRoot = inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
    
    NSArray * ary = [FFLocalFileManager listCurrentFolder:subPath inSecret:inSecret];
    for ( FFLocalItem * item in ary ) {
        NSString * strSubItem = [item.fullPath substringFromIndex:(strRoot.length + 1)];
        NSString * strDisplay = [item.fileName gtm_stringByEscapingForHTML];
        if ( item.type == LIT_PARENT ) {
            strDisplay = @"Parent";
            if ( subPath == nil ) {
                [content appendFormat:@"<tr><td><a href=\"download.html\">[%@]</a></td><td></td></tr>", strDisplay];
            } else {
                [content appendFormat:@"<tr><td><a href=\"download.html?%@\">[%@]</a></td><td></td></tr>", [FFWebServer convertPathToURL:[subPath stringByDeletingLastPathComponent] inSecret:inSecret], strDisplay];
            }
        } else if ( item.type == LIT_SECRETE ) {
            strDisplay = @"Secret";
            [content appendFormat:@"<tr><td><a href=\"download.html?%@\">[%@]</a></td><td></td></tr>", [FFWebServer convertPathToURL:nil inSecret:YES], strDisplay];
        } else if ( item.isDir) {
            [content appendFormat:@"<tr><td><a href=\"download.html?%@\">[%@]</a></td><td></td></tr>", [FFWebServer convertPathToURL:strSubItem inSecret:inSecret], strDisplay];
        } else {
            [content appendFormat:@"<tr><td><a href=\"download?%@\">%@</a></td><td>%@</td></tr>", [FFWebServer convertPathToURL:strSubItem inSecret:inSecret], strDisplay, [byteCountFormatter stringFromByteCount:item.size]];
        }
    }
}

-(void) getFolderContentInXML:(NSString *)subPath data:(NSMutableDictionary *)data inSecret:(BOOL)inSecret parentURL:(NSString *)parentURL
{
//    NSString * strRoot = inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
    
    NSMutableDictionary * root = [[NSMutableDictionary alloc] init];
    [root setObject:@{ @"xmlns:d" : @"DAV:" } forKey:XMLDictionaryAttributesKey];
    [data setObject:root forKey:@"d:multistatus"];
    NSMutableArray * aryResponse = [[NSMutableArray alloc] init];
    [root setObject:aryResponse forKey:@"d:response"];
    
    NSArray * ary = [FFLocalFileManager listCurrentFolder:subPath inSecret:inSecret];
    for ( FFLocalItem * item in ary ) {
        if ( item.type == LIT_PARENT || item.type == LIT_SECRETE )
            continue;
        else {
            NSMutableDictionary * response = [[NSMutableDictionary alloc] init];
            NSMutableDictionary * propstat = [[NSMutableDictionary alloc] init];
            NSMutableDictionary * prop = [[NSMutableDictionary alloc] init];

            [aryResponse addObject:response];
                [response setObject:[parentURL stringByAppendingPathComponent:item.fileName] forKey:@"d:href"];
                [response setObject:propstat forKey:@"d:propstat"];
                    [propstat setObject:@"HTTP/1.1 200 OK" forKey:@"d:status"];
                    [propstat setObject:prop forKey:@"d:prop"];
                        [prop setObject:item.fileName forKey:@"d:displayname"];
                        [prop setObject:item.fileName forKey:@"d:name"];
                        if ( item.type == LIT_DIR )
                            [prop setObject:@{ @"d:collection" : @{} } forKey:@"d:resourcetype"];
                        else
                            [prop setObject:@{} forKey:@"d:resourcetype"];
        }
    }
}

-(NSString *)normalizedPath:(NSString *)subPath
{
    if ( subPath != nil ) {
        NSRange r;
        while ( (r=[subPath rangeOfString:@"../"]).location == 0 )
            subPath = [subPath substringFromIndex:3];
        subPath = [subPath stringByReplacingOccurrencesOfString:@"/../" withString:@"/"];
    }
    return subPath;
}

-(FFURLPath *) getInputPath:(NSDictionary *)dic
{
    FFURLPath * url = [[FFURLPath alloc] init];
    url.inSecret = NO;
    url.path = nil;
    if ( dic != nil ) {
        NSString * subPath = [[dic objectForKey:@"id"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        subPath = [self normalizedPath:subPath];
        if ( subPath != nil && subPath.length == 0 )
            subPath = nil;
        
        url.path = subPath;
        url.inSecret = ([[dic objectForKey:@"sec"] intValue] != 0) && [[FFSetting default] unlock];
    }
    return url;
}

-(FFURLPath *) getInputPathByURLPath:(NSString *)urlInput
{
    FFURLPath * url = [[FFURLPath alloc] init];
    url.inSecret = NO;
    url.path = nil;
    if ( urlInput != nil ) {
        NSMutableArray * aryPath = [[urlInput pathComponents] mutableCopy];
        if ( aryPath.count > 0 ) {
            if ( [aryPath[0] isEqualToString:@"/"] )
                [aryPath removeObjectAtIndex:0];
            if ( aryPath.count > 0 ) {
                if ( [aryPath[0] isEqualToString:@"sec"] && [[FFSetting default] unlock] )
                    url.inSecret = YES;
                [aryPath removeObjectAtIndex:0];
            }
            NSString * subPath = [NSString pathWithComponents:aryPath];
            subPath = [self normalizedPath:subPath];
            if ( subPath != nil && subPath.length == 0 )
                subPath = nil;
            url.path = subPath;
        }
    }
    return url;
}

+(NSString *) convertPathToURL:(NSString *)path inSecret:(BOOL)inSecret
{
    NSMutableString * str = [[NSMutableString alloc] init];
    if ( path != nil && path.length > 0 )
        [str appendFormat:@"id=%@", [[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]
                                            ];
    if ( inSecret ) {
        if ( str.length > 0 )
            [str appendString:@"&"];
        [str appendString:@"sec=1"];
    }
    return str;
}

- (NSString *)DAVClass
{
    return(@"1,2");
}

- (NSArray *)allowedMethods
{
    return([NSArray arrayWithObjects:@"OPTIONS", @"GET", @"HEAD", @"PUT", @"POST", @"COPY", @"PROPFIND", @"DELETE", @"MKCOL", @"MOVE", @"PROPPATCH", @"LOCK", @"UNLOCK", NULL]);
}

-(void) initHandle {
    
    NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
    NSString* footer = [NSString stringWithFormat:@"%@ - %@",
                        [[UIDevice currentDevice] name],
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSDictionary* baseVariables = [NSDictionary dictionaryWithObjectsAndKeys:footer, @"footer", nil];
    __weak FFWebServer * weakSelf = self;
    
    [self addHandlerForBasePath:@"/" localPath:websitePath indexFilename:nil cacheAge:3600];
    
    [self addHandlerForMethod:@"PROPFIND" pathRegex:@"/.*" requestClass:[GCDWebServerDataRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        GCDWebServerDataRequest * requestData = (GCDWebServerDataRequest *)request;
        
        NSInteger theDepth = -1;
        NSString *theDepthString = [requestData.headers objectForKey:@"Depth"];
        if (theDepthString != NULL)
        {
            if ([theDepthString isEqualToString:@"0"])
                theDepth = 0;
            else if ([theDepthString isEqualToString:@"1"])
                theDepth = 1;
            else if ([theDepthString isEqualToString:@"infinity"])
                theDepth = -1;
            else
                return [GCDWebServerDataResponse responseWithXML:@{} withStatusCode:400];
        }
        
        NSString *theRootPath = [request.URL.path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        FFURLPath * path = [weakSelf getInputPathByURLPath:theRootPath];
        
        NSMutableDictionary * dicData = [[NSMutableDictionary alloc] init];
        [weakSelf getFolderContentInXML:path.path data:dicData inSecret:path.inSecret parentURL:theRootPath];
        
        return [GCDWebServerDataResponse responseWithXML:dicData withStatusCode:200];
    }];
    
    [self addHandlerForMethod:@"OPTIONS" pathRegex:@"/.*" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        GCDWebServerResponse * response = [GCDWebServerResponse responseWithStatusCode:200];
        [response setValue:[weakSelf DAVClass] forAdditionalHeader:@"DAV"];
        [response setValue:[[weakSelf allowedMethods] componentsJoinedByString:@","] forAdditionalHeader:@"Allow"];
        
        return response;
        
    }];

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
        
        NSMutableString* content = [[NSMutableString alloc] init];
        FFURLPath * path = [weakSelf getInputPath:request.query];
        
        [weakSelf getFolderContent:path.path content:content inSecret:path.inSecret];
        [variables setObject:content forKey:@"content"];
        [variables setObject:[FFWebServer convertPathToURL:path.path inSecret:path.inSecret] forKey:@"uploadPath"];
        NSString * strCurrentPath = path.path == nil ? @"/" : path.path;
        if ( path.inSecret )
            strCurrentPath = [NSString stringWithFormat:@"%@ (Secret)", strCurrentPath];
        [variables setObject:strCurrentPath forKey:@"currentPath"];

        response = [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        return response;
    }];
    
    [self addHandlerForMethod:@"GET" path:@"/download" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        GCDWebServerResponse* response = nil;
        FFURLPath * url = [weakSelf getInputPath:request.query];
        NSString * strRoot = url.inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
        NSString * path = [strRoot stringByAppendingPathComponent:url.path];
        if ( [[NSFileManager defaultManager]  fileExistsAtPath:path] ) {
            response = [GCDWebServerFileResponse responseWithFile:path isAttachment:YES];
        } else {
            response = [GCDWebServerResponse responseWithStatusCode:404];
        }
        return response;
    }];
    
    [self addHandlerForMethod:@"GET" path:@"/createFolder" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        GCDWebServerResponse* response = nil;
        FFURLPath * url = [weakSelf getInputPath:request.query];
        NSString * strRoot = url.inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
        NSString * path = [strRoot stringByAppendingPathComponent:url.path];
        NSString * newPath = [request.query objectForKey:@"name"];
        if ( [[NSFileManager defaultManager]  fileExistsAtPath:path] && newPath != nil && newPath.length > 0 ) {
            path = [path stringByAppendingPathComponent:[weakSelf normalizedPath:newPath]];
            if ( ![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil] )
                response = [GCDWebServerDataResponse responseWithHTML:NSLocalizedString(@"Create folder error", nil)];
            else
                response = [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:
                                                                        [NSString stringWithFormat:@"/download.html?%@",[FFWebServer convertPathToURL:url.path inSecret:url.inSecret] ]
                                                                       ] permanent:NO];
        } else {
            response = [GCDWebServerResponse responseWithStatusCode:404];
        }
        return response;
    }];
    
    [self addHandlerForMethod:@"POST" path:@"/upload" requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSString* html = NSLocalizedString(@"Successfully Uploaded", nil);
        GCDWebServerMultiPartFile* file = [[(GCDWebServerMultiPartFormRequest*)request files] objectForKey:@"file"];
        
        FFURLPath * targetUrl = [weakSelf getInputPath:request.query];
        NSString * strRoot = targetUrl.inSecret ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
        NSString * targetPath = [strRoot stringByAppendingPathComponent:targetUrl.path == nil ? @"" : targetUrl.path];

        NSString* fileName = file.fileName;
        NSString* temporaryPath = file.temporaryPath;
        
        if (fileName.length && ![fileName hasPrefix:@"."]) {
            
            NSString* filePath = [targetPath stringByAppendingPathComponent:fileName];
            NSFileManager * mgr = [NSFileManager defaultManager];
            int i = 0;
            while ( [mgr fileExistsAtPath:filePath] ) {
                NSString * strNewName = [NSString stringWithFormat:@"%@(%d).%@", [fileName stringByDeletingPathExtension],i++, [fileName pathExtension]];
                filePath = [targetPath stringByAppendingPathComponent:strNewName];
            }
            
            NSError* error = nil;
            if (![mgr moveItemAtPath:temporaryPath toPath:filePath error:&error]) {
                return [GCDWebServerResponse responseWithStatusCode:402];
                /*
                html = NSLocalizedString(@"SERVER_STATUS_ERROR", nil);
                html = NSLocalizedString(@"SERVER_STATUS_UNSUPPORTED", nil);
                html = NSLocalizedString(@"SERVER_STATUS_INVALID", nil);
                 */
            }
        } else
            return [GCDWebServerResponse responseWithStatusCode:402];
        return [GCDWebServerDataResponse responseWithHTML:html];
    }];
}

@end
