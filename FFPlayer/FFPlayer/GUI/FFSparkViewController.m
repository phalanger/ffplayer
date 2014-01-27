//
//  FFSparkViewController.m
//  FFPlayer
//
//  Created by Coremail on 14-1-27.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFSparkViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "FFAlertView.h"
#import "FFHelper.h"

#define ASYNC_HUD_BEGIN(strTitle)   if ( self.navigationController.navigationBar) self.navigationController.navigationBar.userInteractionEnabled = NO;\
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES]; \
                                    hud.labelText = strTitle;   \
                                    _loading = YES;
#define ASYNC_HUD_END               if ( self.navigationController.navigationBar) self.navigationController.navigationBar.userInteractionEnabled = YES;\
                                    [MBProgressHUD hideHUDForView:self.view animated:YES]; \
                                    _loading = NO;

//////////////////////////////////////////////////

@interface FFSparkItem : NSObject

@property (atomic) NSString *   path;
@property (atomic) NSString *   name;
@property (assign) BOOL         dir;
@property (assign) BOOL         root;
@end

@implementation FFSparkItem

-(id) init {
    self = [super init];
    if ( self != nil ) {
        
    }
    return  self;
}

@end

///////////////////////////////////////////////////

@interface MyJSONResponseSerializer : AFJSONResponseSerializer

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;

@end

@implementation MyJSONResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithReadingOptions:0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    MyJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;
    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
    
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    NSString * fix = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"}{" withString:@"},{"];
    return [super responseObjectForResponse:response data:[fix dataUsingEncoding: NSUTF8StringEncoding] error:error];
}

@end


///////////////////////////////////////////////////

@interface FFSparkViewController ()
{
    UIBarButtonItem *           btnRefresh;
    BOOL         _loading;
    NSString * _setting;
    NSString * _name;
    NSString * _baseURL;
    NSMutableArray *    _arySprkItems;
}
@end

@implementation FFSparkViewController

-(void) setSparkServer:(NSString *)setting baseURL:(NSString *)baseURL name:(NSString *)name
{
    _baseURL = baseURL;
    _name = name;
    if ( [setting rangeOfString:@":"].location == NSNotFound )
        _setting = [NSString stringWithFormat:@"http://%@:27888", setting];
    else
        _setting = [NSString stringWithFormat:@"http://%@", setting];
}

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
    
    _arySprkItems = [[NSMutableArray alloc] init];
    self.title = _name;

    btnRefresh = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefresh:)];
    self.navigationItem.rightBarButtonItem = btnRefresh;
    _loading = FALSE;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self loadList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) onRefresh:(id)sender {
    [self loadList];
}

-(void) needLogin
{
    __weak FFSparkViewController * weakSelf = self;
    [FFAlertView showWithTitle:NSLocalizedString(@"Input the password", nil)
                       message:nil
                   defaultText:nil
                         style:UIAlertViewStyleSecureTextInput
                    usingBlock:^(NSUInteger btn, NSString * str) {
                        if ( btn == 0 || str == nil || str.length == 0 )
                            return;
                        [weakSelf login:str];
                    }
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"OK", nil),nil];
}

-(void) onGetList:(NSDictionary *)dictData
{
    [_arySprkItems removeAllObjects];
    NSArray * aryItems = [((NSDictionary *)dictData) objectForKey:@"data"];
    for ( NSDictionary * dict in aryItems ) {
        
    }
    [self.tableView reloadData];
}

-(void) handleError:(AFHTTPRequestOperation *)operation error:(NSError *)error
{
    NSHTTPURLResponse * respond = operation.response;
    if ( respond.statusCode == 401 ) { //Need login
        [self needLogin];
        return;
    }
    [FFAlertView showWithTitle:NSLocalizedString(@"Error", nil)
                       message:[error description]
                   defaultText:nil
                         style:UIAlertViewStyleDefault
                    usingBlock:nil
             cancelButtonTitle:NSLocalizedString(@"OK", nil)
             otherButtonTitles:nil];
}

-(void) loadList
{
    if ( _loading )
        return;
    
    __weak FFSparkViewController * weakSelf = self;
    ASYNC_HUD_BEGIN( NSLocalizedString(@"Loading", nil) );
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_setting stringByAppendingString:@"/list"]]];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [MyJSONResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        ASYNC_HUD_END;
        [weakSelf onGetList:responseObject];
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ASYNC_HUD_END;
        [weakSelf handleError:operation error:error];
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}

-(void) login:(NSString *)pass
{
    NSString * strMD5 = [FFHelper md5HexDigest:pass];
    NSString * strQuery = [NSString stringWithFormat:@"%@/login_server?spid=%@", _setting, strMD5];
    
    __weak FFSparkViewController * weakSelf = self;
    ASYNC_HUD_BEGIN( NSLocalizedString(@"Login", nil) );

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:strQuery parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        ASYNC_HUD_END;
        NSLog(@"JSON: %@", responseObject);
        [weakSelf loadList];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ASYNC_HUD_END;
        [weakSelf handleError:operation error:error];
    }];
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
    return _arySprkItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
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
