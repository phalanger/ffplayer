//
//  FFLocalFileManager.m
//  FFPlayer
//
//  Created by Coremail on 14-1-17.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFLocalFileManager.h"
#import "FFHelper.h"
#import "FFSetting.h"


/////////////////////////////////////////////////////

@implementation FFLocalItem

-(id) initWithPath:(NSString *)strPath type:(LOCAL_ITEM_TYPE)type
{
    self = [super init];
    if ( self ) {
        self.fullPath = strPath;
        self.fileName = [[strPath pathComponents] lastObject];
        self.type = type;
        self.size = 0;
        self.modifyTime = nil;
    }
    return self;
}

-(id) initWithAttributes:(NSDictionary *) attr path:(NSString *)strPath
{
    self = [super init];
    if ( self ) {
        id fileType = [attr valueForKey:NSFileType];
        
        self.fullPath = strPath;
        self.fileName = [[strPath pathComponents] lastObject];
        if ([fileType isEqual:NSFileTypeDirectory] )
            self.type = LIT_DIR;
        else if (  [FFHelper isSupportMidea:strPath] )
            self.type = LIT_MIDEA;
        else
            self.type = LIT_UNKNOWN;
        
        self.size = [[attr valueForKey:NSFileSize] longLongValue];
        self.modifyTime = [attr valueForKey:NSFileModificationDate];
    }
    return self;
}

-(BOOL) isDir{
    return self.type < LIT_FOLDER_DEF_END;
}

-(int) sortNameHelper {
    if ( self.type > LIT_FOLDER_DEF_END )
        return LIT_FOLDER_DEF_END;
    return self.type;
}

-(BOOL) editable {
    return self.type != LIT_PARENT
    && self.type != LIT_SECRETE
    && self.fullPath != nil;
}

@end

///////////////////////////////////////////

@implementation FFLocalFileManager

+(NSString *) getRootFullPath
{
    NSString * root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                           NSUserDomainMask,
                                                           YES) lastObject];
    return root;
}

+(NSString *) getSecretRootPath
{
    NSString * root = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                           NSUserDomainMask,
                                                           YES) lastObject];
    return [root stringByAppendingPathComponent:@"private"];
}

+(NSString *) getCurrentFolder:(NSString *) strSubPath inSecret:(BOOL) inSecret
{
    NSString * root = (inSecret) ? [FFLocalFileManager getSecretRootPath] : [FFLocalFileManager getRootFullPath];
    if ( strSubPath != nil && strSubPath.length > 0 ) {
        root = [root stringByAppendingPathComponent:strSubPath];
    }
    return root;
}

+(NSArray *) listCurrentFolder:(NSString *) strSubPath inSecret:(BOOL) inSecret
{
    NSMutableArray *ma = [NSMutableArray array];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *folder = [FFLocalFileManager getCurrentFolder:strSubPath inSecret:inSecret];
    
    if ( strSubPath != nil && strSubPath.length > 0 ) {
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil type:LIT_PARENT]];
    } else if ( !inSecret && [[FFSetting default] unlock] ) {
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil type:LIT_SECRETE]];
    } else if ( inSecret )
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil type:LIT_PARENT]];
    
    NSArray *contents = [fm contentsOfDirectoryAtPath:folder error:nil];
    
    for (NSString *filename in contents) {
        
        if (filename.length > 0 &&
            [filename characterAtIndex:0] != '.') {
            
            NSString *path = [folder stringByAppendingPathComponent:filename];
            NSDictionary *attr = [fm attributesOfItemAtPath:path error:nil];
            if (attr) {
                id fileType = [attr valueForKey:NSFileType];
                if ([fileType isEqual: NSFileTypeRegular] ||
                    [fileType isEqual: NSFileTypeSymbolicLink]) {
                    
                    [ma addObject:[[FFLocalItem alloc] initWithAttributes:attr path:path]];
                } else if ( [fileType isEqual:NSFileTypeDirectory] ) {
                    [ma addObject:[[FFLocalItem alloc] initWithAttributes:attr path:path]];
                }
            }
        }
    }
    
    NSMutableArray * arySort = [[NSMutableArray alloc] init];
    [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"sortNameHelper" ascending:YES]];
    int nSort = [[FFSetting default] sortType];
    if ( nSort == SORT_BY_DATE || nSort == SORT_BY_DATE_DESC )
        [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"modifyTime" ascending:(nSort == SORT_BY_DATE)]];
    else if ( nSort == SORT_BY_NAME || nSort == SORT_BY_NAME_DESC )
        [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"fullPath" ascending:(nSort == SORT_BY_NAME)]];
    
    return [[ma sortedArrayUsingDescriptors:arySort] copy];
}

@end
