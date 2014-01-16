//
//  FFLocalViewController.m
//  FFPlayer
//
//  Created by Coremail on 14-1-14.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFLocalViewController.h"
#import "KxMovieViewController.h"
#import "FFHelper.h"
#import "FFPlayer.h"
#import "FFAlertView.h"

typedef enum {
    LIT_PARENT,
    LIT_SECRETE,
    LIT_DIR,
    LIT_FOLDER_DEF_END,
    
    LIT_MIDEA,
    LIT_PIC,
    LIT_ZIP,
    LIT_UNKNOWN
} LOCAL_ITEM_TYPE;

@interface FFLocalItem : NSObject
@property (retain,atomic)   NSString *  fullPath;
@property (retain,atomic)   NSString *  fileName;
@property (retain,atomic)   NSDate *    modifyTime;
@property (assign)  unsigned long long  size;
@property (assign)  LOCAL_ITEM_TYPE     type;
@property (readonly, getter = isDir)   BOOL   isDir;
@property (readonly, getter = sortNameHelper)   int    sortNameHelper;
@property (readonly)  BOOL          editable;
-(id) initWithPath:(NSString *)strPath type:(LOCAL_ITEM_TYPE)type;
-(id) initWithAttributes:(NSDictionary *) attrs path:(NSString *)strPath;
@end

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

enum {
    IN_LOCAL,
    IN_SECRET,
};

@interface FFLocalViewController ()
{
    NSArray *   _localMovies;
    NSString * _currentPath;
    UIBarButtonItem *           btnEdit;
    UIBarButtonItem *           btnDone;
    FFPlayer *                  _ffplayer;
    
    NSArray *                   itemToMove;
    int                         currentState;
}
@end

@implementation FFLocalViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) switchToSelectFolderAndMoveItems:(NSArray *)aryItemToMove
{
    itemToMove = aryItemToMove;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSFileManager defaultManager] createDirectoryAtPath:[self getSecretRootPath] withIntermediateDirectories:NO attributes:nil error:nil];
    currentState = IN_LOCAL;
    
    if ( itemToMove != nil ) {
        self.title = self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Move to %@", nil), _currentPath == nil ? @"/" : _currentPath];
        btnEdit = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(exitMove:)];
        btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(switchEditMode:)];
        self.navigationItem.rightBarButtonItem = btnDone;
        self.navigationItem.leftBarButtonItem = btnEdit;
    } else {
        self.title = self.navigationItem.title = NSLocalizedString(@"Local", @"Local Files");
        btnEdit = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(switchEditMode:)];
        btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(switchEditMode:)];
        self.navigationItem.rightBarButtonItem = btnEdit;
    }

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    _ffplayer = [[FFPlayer alloc] init];
    
    UIBarButtonItem * flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem * btnAddFolder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFolder:)];
    UIBarButtonItem * btnRename = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(editItem:)];
    UIBarButtonItem * btnMove = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(moveItem:)];
    UIBarButtonItem * btnDelete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletItem:)];

    self.toolbarItems = [ NSArray arrayWithObjects: flex,btnAddFolder,
                                                    flex,btnRename,
                                                    flex,btnMove,
                                                    flex,btnDelete,
                                                    flex,nil ];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadMovies];
}

-(NSString *) getRootFullPath
{
    NSString * root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                           NSUserDomainMask,
                                                           YES) lastObject];
    return root;
}

-(NSString *) getSecretRootPath
{
    NSString * root = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                           NSUserDomainMask,
                                                           YES) lastObject];
    return [root stringByAppendingPathComponent:@"private"];
}

-(NSString *) getCurrentFullPath
{
    NSString * root = (currentState == IN_SECRET) ? [self getSecretRootPath] : [self getRootFullPath];
    if ( _currentPath != nil && _currentPath.length > 0 ) {
        root = [root stringByAppendingPathComponent:_currentPath];
    }
    return root;
}

- (void) reloadMovies
{
    NSMutableArray *ma = [NSMutableArray array];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *folder = [self getCurrentFullPath];
    
    if ( _currentPath != nil && _currentPath.length > 0 ) {
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil type:LIT_PARENT]];
    } else if ( currentState == IN_LOCAL && [[FFSetting default] unlock] ) {
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil type:LIT_SECRETE]];
    } else if ( currentState == IN_SECRET )
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
                    
                    if ( [FFHelper isSupportMidea:path] ) {
                        [ma addObject:[[FFLocalItem alloc] initWithAttributes:attr path:path]];
                    }
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
    
    _localMovies = [[ma sortedArrayUsingDescriptors:arySort] copy];

    NSString * strTitle = nil;
    if ( itemToMove != nil ) {
        if ( currentState == IN_SECRET )
            strTitle = [NSString stringWithFormat:NSLocalizedString(@"Move to %@ (Secret)", nil), _currentPath == nil ? @"/" : _currentPath];
        else
            strTitle = [NSString stringWithFormat:NSLocalizedString(@"Move to %@", nil), _currentPath == nil ? @"/" : _currentPath];
    } else    {
        if ( _currentPath == nil ) {
            if ( currentState == IN_SECRET )
                strTitle = NSLocalizedString(@"Secret", nil);
            else
                strTitle = NSLocalizedString(@"Local", @"Local Files");
        } else {
            if ( currentState == IN_SECRET )
                strTitle = [NSString stringWithFormat:@"%@ (%@)", _currentPath, NSLocalizedString(@"Secret", nil)];
            else
                strTitle = _currentPath;
        }
    }
    self.title = self.navigationItem.title = strTitle;
    [self.tableView reloadData];
}

-(void) switchEditMode:(id)sender
{
    if ( itemToMove != nil ) {
        //Check taget is the same as select items;
        FFLocalItem * item1 = [itemToMove firstObject];
        NSString * strSrcPath = [item1.fullPath stringByDeletingLastPathComponent];
        NSString * strTarPath = [self getCurrentFullPath];
        if ( ![strTarPath isEqualToString:strSrcPath] ) {
            NSFileManager * mgr = [NSFileManager defaultManager];
            NSMutableArray * aryFailList = [[NSMutableArray alloc] init];
            for (FFLocalItem * item in itemToMove) {
                NSString * targetFull = [strTarPath stringByAppendingPathComponent:item.fileName];
                if ( ![mgr moveItemAtPath:item.fullPath toPath:targetFull error:nil] ) {
                    [aryFailList addObject:item.fileName];
                }
            }
            [self exitMove:sender];
            if ( aryFailList.count > 0 ) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                            message:[NSString stringWithFormat:NSLocalizedString(@"Move %@ fail!", nil), [aryFailList componentsJoinedByString:@","]]
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                  otherButtonTitles:nil] show];
            }
        }
    } else {
        self.tableView.editing = !self.tableView.editing;
        self.navigationItem.rightBarButtonItem = self.tableView.editing ? btnDone : btnEdit;
        [self.navigationController setToolbarHidden:!self.tableView.editing];
    }
}

-(void) exitMove:(id)sender
{
    if ( itemToMove == nil )
        return;
    [self.navigationController setToolbarHidden:NO];
    if (self.presentingViewController || !self.navigationController)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

-(NSString *)makeSureFileName:(NSString *)str
{
    NSString * trimFolder = [str stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([trimFolder hasPrefix:@"."])
        trimFolder = [trimFolder stringByReplacingCharactersInRange:NSMakeRange(0,1)  withString:@"_"];
    return trimFolder;
}

-(void) addFolder:(id)sender
{
    __weak FFLocalViewController * weakSelf = self;
    [FFAlertView showWithTitle:NSLocalizedString(@"Create Folder", nil)
                       message:nil
                   defaultText:@""
                         style:UIAlertViewStylePlainTextInput
                    usingBlock:^(NSUInteger btn, NSString * folder) {
                        if ( btn == 0 )
                            return;
                        NSFileManager * mgr = [NSFileManager defaultManager];
                        NSString * trimFolder = [self makeSureFileName:folder];
                        if ( !trimFolder)
                            return;
                        NSString * strFullPath = [[self getCurrentFullPath] stringByAppendingPathComponent:trimFolder];
                        NSError * err = nil;
                        [mgr createDirectoryAtPath:strFullPath withIntermediateDirectories:NO attributes:nil error:&err];
                        if ( err != nil ) {
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:NSLocalizedString(@"Create folder fail!", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil] show];
                        } else {
                            FFLocalViewController * strongSelf = weakSelf;
                            [strongSelf reloadMovies];
                        }
                        
                    }
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"Create", nil), nil
     ];
}

-(NSArray *)getAllSelected
{
    NSMutableArray * arySelectedItems = [[NSMutableArray alloc] init];
    
    size_t i = 0;
    for ( FFLocalItem *item in _localMovies ) {
        if ( item.editable ) {
            UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if ( cell.isSelected )
                [arySelectedItems addObject:item];
        }
        ++i;
    }
    return arySelectedItems;
}

-(void) deletItem:(id)sender
{
    NSArray * arySelected = [self getAllSelected];
    if ( arySelected.count == 0 )
        return;
    
    __weak FFLocalViewController * weakSelf = self;
    [FFAlertView showWithTitle: (( arySelected.count == 1 ) ? NSLocalizedString(@"Delete Item ?", nil) : NSLocalizedString(@"Delete Items ?", nil))
                       message:nil
                   defaultText:nil
                         style:UIAlertViewStyleDefault
                    usingBlock:^(NSUInteger btn, NSString * folder) {
                        if ( btn == 0 )
                            return;
                        FFLocalViewController * strongSelf = weakSelf;
                        NSFileManager * mgr = [NSFileManager defaultManager];
                        for ( FFLocalItem *item in arySelected ) {
                                if ( ![mgr removeItemAtPath:item.fullPath error:nil] ) {
                                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete %@ fail!", nil),item.fileName]
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                      otherButtonTitles:nil] show];
                                }
                        }
                        [strongSelf reloadMovies];
                    }
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"Delete", nil), nil
     ];
}

-(void) editItem:(id)sender
{
    NSArray * arySelected = [self getAllSelected];
    if ( arySelected.count == 0 )
        return;
    else if ( arySelected.count > 1 ) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                    message:NSLocalizedString(@"Only support rename one file/directory!", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Close", nil)
                          otherButtonTitles:nil] show];
        return;
    }

    __weak FFLocalViewController * weakSelf = self;
    FFLocalItem *item = [arySelected firstObject];
    [FFAlertView showWithTitle:NSLocalizedString(@"Modify name", nil)
                       message:nil
                   defaultText:item.fileName
                         style:UIAlertViewStylePlainTextInput
                    usingBlock:^(NSUInteger btn, NSString * folder) {
                            if ( btn == 0 )
                                return;
                            NSString * strTrimPath = [self makeSureFileName:folder];
                            if ( !strTrimPath || [strTrimPath isEqualToString:item.fileName] )
                                return;
                            NSString * strNewPath = [[self getCurrentFullPath] stringByAppendingPathComponent:strTrimPath];
                            NSFileManager * mgr = [NSFileManager defaultManager];
                            if ( ![mgr moveItemAtPath:item.fullPath toPath:strNewPath error:nil] ) {
                                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Rename %@ -> %@ fail!", nil),item.fileName, strTrimPath]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                  otherButtonTitles:nil] show];
                            } else {
                                FFLocalViewController * strongSelf = weakSelf;
                                [strongSelf reloadMovies];
                            }
                        }
            cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"Modify", nil), nil
    ];
}

-(void) moveItem:(id)sender
{
    NSArray * arySelected = [self getAllSelected];
    if ( arySelected.count == 0 )
        return;

    FFLocalViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LocalFile"];
    [vc switchToSelectFolderAndMoveItems:arySelected];
    [self.navigationController setToolbarHidden:YES];
    [self.navigationController pushViewController:vc animated:TRUE];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _localMovies.count;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FFLocalItem * item = _localMovies[indexPath.row];
	return item.editable ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    FFLocalItem * item = _localMovies[indexPath.row];
    
    if ( item.isDir ) {
        
        NSString * strPath = item.fileName;
        if ( item.type == LIT_PARENT )
            strPath = NSLocalizedString(@"Parent", nil);
        else if ( item.type == LIT_SECRETE )
            strPath = NSLocalizedString(@"Secret", nil);
        
        cell.textLabel.text = [NSString stringWithFormat:@"[%@]", strPath];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.detailTextLabel.text = nil;
        cell.detailTextLabel.textColor = cell.textLabel.textColor = [UIColor blackColor];
        if ( item.type == LIT_SECRETE )
            cell.imageView.image = [UIImage imageNamed:@"padlock"];
        else
            cell.imageView.image = [UIImage imageNamed:@"folder"];
        
        if ( item.type == LIT_DIR && itemToMove != nil )  {   //in Moveing mode
            for (FFLocalItem * check in itemToMove) {
                if ( [check.fullPath isEqualToString:item.fullPath] ) {
                    cell.detailTextLabel.textColor = cell.textLabel.textColor = [UIColor grayColor];
                    break;
                }
            }
        }
    } else {
        cell.textLabel.text = item.fileName;

        NSByteCountFormatter *byteCountFormatter = [[NSByteCountFormatter alloc] init];
        [byteCountFormatter setAllowedUnits:NSByteCountFormatterUseMB];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:item.modifyTime], [byteCountFormatter stringFromByteCount:item.size]];
        
        if ( itemToMove != nil )  {   //in Moveing mode
            cell.detailTextLabel.textColor = cell.textLabel.textColor = [UIColor grayColor];
        } else {
            cell.detailTextLabel.textColor = cell.textLabel.textColor = [UIColor blackColor];
        }
        
        if (item.type == LIT_MIDEA )
            cell.imageView.image = [UIImage imageNamed:@"movie"];
        else
            cell.imageView.image = [UIImage imageNamed:@"disk"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( tableView.editing ) {
        
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        FFLocalItem * item = _localMovies[indexPath.row];
        switch (item.type) {
            case LIT_PARENT:
            {
                if ( _currentPath == nil && currentState == IN_SECRET ) {
                    currentState = IN_LOCAL;
                } else {
                    _currentPath = [_currentPath stringByDeletingLastPathComponent];
                    if ( _currentPath.length == 0 )
                        _currentPath = nil;
                }
                [self reloadMovies];
            }break;
            case LIT_SECRETE:
            {
                currentState = IN_SECRET;
                [self reloadMovies];
            }break;
            case LIT_DIR:
            {
                if ( _currentPath == nil )
                    _currentPath = item.fileName;
                else
                    _currentPath = [_currentPath stringByAppendingPathComponent:item.fileName];
                [self reloadMovies];
            }break;
            case LIT_MIDEA:
            {
                NSMutableArray  * aryList = [[NSMutableArray alloc] init];
                int index = 0, i = 0;
                for ( FFLocalItem * it in _localMovies) {
                    if  ( it.type != LIT_MIDEA )
                        continue;
                    else if ( it == item )
                        index = i;
                    [aryList addObject:[[FFPlayItem alloc] initWithPath:it.fullPath position:0.0]];
                    ++i;
                }
                [_ffplayer playList:aryList curIndex:index parent:self];
            }break;
            default:
            {
                
            }break;
        };
    }
}

-(void) unlock:(BOOL) bo
{
    [[FFSetting default] setUnlock:bo];
    if ( !bo && currentState == IN_SECRET ) {
        currentState = IN_LOCAL;
        _currentPath = nil;
    }
    [self reloadMovies];
}

-(void) toggleLock
{
    if ( ![[FFSetting default] hasPassword] ) {
        __weak FFLocalViewController * weakSelf = self;
        return [FFAlertView inputPassword2: NSLocalizedString(@"Input unlock initial password", nil)
                            message: NSLocalizedString(@"First input the password.", nil)
                           message2:NSLocalizedString(@"Confirm the password", nil)
                         usingBlock:^(BOOL notTheSame,NSString * pass) {
                             if ( notTheSame ) {
                                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                             message:NSLocalizedString(@"Password not the same!", nil)
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                   otherButtonTitles:nil] show];
                             } else {
                                 [[NSFileManager defaultManager] createDirectoryAtPath:[self getSecretRootPath] withIntermediateDirectories:YES attributes:nil error:nil];
                                 [[FFSetting default] setPassword:pass];
                                 FFLocalViewController * strongSelf = weakSelf;
                                 [strongSelf unlock:YES];
                             }
                         }
                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                     okButtonTitles:NSLocalizedString(@"OK", nil)
         ];
    } else if ( [[FFSetting default] unlock] ) {
        return [self unlock:FALSE];
    }
    
    __weak FFLocalViewController * weakSelf = self;
    [FFAlertView showWithTitle: NSLocalizedString(@"Input unlock password", nil)
                       message:nil
                   defaultText:@""
                         style:UIAlertViewStyleSecureTextInput
                    usingBlock:^(NSUInteger btn, NSString * pass) {
                        if ( btn == 0 || !pass)
                            return;
                        else if ( [[FFSetting default] checkPassword:pass] ) {
                            FFLocalViewController * strongSelf = weakSelf;
                            return [strongSelf unlock:YES];
                        }
                    }
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"Unlock", nil), nil
     ];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    FFLocalItem * item = _localMovies[indexPath.row];
    return item.editable;
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
