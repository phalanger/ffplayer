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

@interface FFLocalItem : NSObject
@property (retain,atomic)   NSString *  fullPath;
@property (retain,atomic)   NSString *  fileName;
@property (retain,atomic)   NSDate *    modifyTime;
@property (assign)  unsigned long long  size;
@property (assign)   BOOL   isDir;
-(id) initWithPath:(NSString *)strPath isDir:(BOOL)isDir;
-(id) initWithAttributes:(NSDictionary *) attrs path:(NSString *)strPath;
@end

@implementation FFLocalItem

-(id) initWithPath:(NSString *)strPath isDir:(BOOL)isDir
{
    self = [super init];
    if ( self ) {
        self.fullPath = strPath;
        self.fileName = [[strPath pathComponents] lastObject];
        self.isDir = isDir;
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
        self.isDir = [fileType isEqual:NSFileTypeDirectory];
        self.size = [[attr valueForKey:NSFileSize] longLongValue];
        self.modifyTime = [attr valueForKey:NSFileModificationDate];
    }
    return self;
}

@end

////////////////////////////////////////

@interface FFLocalViewController ()
{
    NSArray *   _localMovies;
    NSString * _currentPath;
    UIBarButtonItem *           btnEdit;
    UIBarButtonItem *           btnDone;
    FFPlayer *                  _ffplayer;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tabBarItem.title = self.title = self.navigationItem.title = NSLocalizedString(@"Local", @"Local Files");

    btnEdit = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(switchEditMode:)];
    btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(switchEditMode:)];
    self.navigationItem.rightBarButtonItem = btnEdit;

    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    _ffplayer = [[FFPlayer alloc] init];
    
    UIBarButtonItem * flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem * btnAddFolder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFolder:)];
    UIBarButtonItem * btnEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editItem:)];
    UIBarButtonItem * btnMove = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(moveItem:)];
    UIBarButtonItem * btnDelete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletItem:)];

    self.toolbarItems = [ NSArray arrayWithObjects: flex,btnAddFolder,
                                                    flex,btnEdit,
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

- (void) reloadMovies
{
    NSMutableArray *ma = [NSMutableArray array];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    
    if ( _currentPath != nil && _currentPath.length > 0 ) {
        [ma addObject:[[FFLocalItem alloc] initWithPath:nil isDir:YES]];
        folder = [folder stringByAppendingPathComponent:_currentPath];
    }
    
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
    [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"isDir" ascending:NO]];
    int nSort = [[[FFSetting alloc] init] sortType];
    if ( nSort == SORT_BY_DATE || nSort == SORT_BY_DATE_DESC )
        [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"modifyTime" ascending:(nSort == SORT_BY_DATE)]];
    else if ( nSort == SORT_BY_NAME || nSort == SORT_BY_NAME_DESC )
        [arySort addObject:[NSSortDescriptor sortDescriptorWithKey:@"fullPath" ascending:(nSort == SORT_BY_NAME)]];
    
    _localMovies = [[ma sortedArrayUsingDescriptors:arySort] copy];
    [self.tableView reloadData];
}

-(void) switchEditMode:(id)sender
{
    self.tableView.editing = !self.tableView.editing;
    self.navigationItem.rightBarButtonItem = self.tableView.editing ? btnDone : btnEdit;
    [self.navigationController setToolbarHidden:!self.tableView.editing];
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
                        NSString * trimFolder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@""];
                        if ([trimFolder hasPrefix:@"."])
                            trimFolder = [trimFolder stringByReplacingCharactersInRange:NSMakeRange(0,1)  withString:@"_"];
                        NSFileManager * mgr = [NSFileManager defaultManager];
                        
                        NSString * root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                                NSUserDomainMask,
                                                                                YES) lastObject];
                        if ( _currentPath != nil && _currentPath.length > 0 ) {
                            root = [root stringByAppendingPathComponent:_currentPath];
                        }
                        NSString * strFullPath = [root stringByAppendingPathComponent:folder];
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

-(void) deletItem:(id)sender
{
    
}

-(void) editItem:(id)sender
{
    
}

-(void) moveItem:(id)sender
{
    
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
	return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    FFLocalItem * item = _localMovies[indexPath.row];
    if ( item.isDir ) {
        NSString * strPath = ( item.fullPath == nil )
                                ? NSLocalizedString(@"Parent", nil)
                                : item.fileName;
        cell.textLabel.text = [NSString stringWithFormat:@"[%@]", strPath];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.detailTextLabel.text = nil;
    } else {
        cell.textLabel.text = item.fileName;

        NSByteCountFormatter *byteCountFormatter = [[NSByteCountFormatter alloc] init];
        [byteCountFormatter setAllowedUnits:NSByteCountFormatterUseMB];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:item.modifyTime], [byteCountFormatter stringFromByteCount:item.size]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( tableView.editing ) {
        
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        FFLocalItem * item = _localMovies[indexPath.row];
        if ( item.isDir ) {
            if ( item.fullPath == nil ) {
                NSMutableArray * aryHistory = [[_currentPath pathComponents] mutableCopy];
                [aryHistory removeLastObject];
                if ( [aryHistory count] == 0 )
                    _currentPath = nil;
                else
                    _currentPath = [aryHistory componentsJoinedByString:@"/"];
            } else {
                if ( _currentPath == nil )
                    _currentPath = item.fileName;
                else
                    _currentPath = [_currentPath stringByAppendingPathComponent:item.fileName];
            }
            [self reloadMovies];
        } else {
            NSMutableArray  * aryList = [[NSMutableArray alloc] init];
            int index = 0, i = 0;
            for ( FFLocalItem * it in _localMovies) {
                if  ( it.isDir )
                    continue;
                else if ( it == item )
                    index = i;
                [aryList addObject:[[FFPlayItem alloc] initWithPath:it.fullPath position:0.0]];
                ++i;
                
            }
            [_ffplayer playList:aryList curIndex:index parent:self];
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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
