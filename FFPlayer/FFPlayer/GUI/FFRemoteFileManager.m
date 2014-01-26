//
//  FFRemoteFileManager.m
//  FFPlayer
//
//  Created by cyt on 14-1-26.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFRemoteFileManager.h"
#import "FFLocalFileManager.h"

@interface FFRemoteFileManager ()
{
    NSArray *   arySection;
    NSArray *   arySectionArray;
    NSMutableArray * aryURLHistory;
    NSMutableArray * arySparkList;
}

@end

@implementation FFRemoteFileManager

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
    
    aryURLHistory = [[NSMutableArray alloc] init];
    arySparkList = [[NSMutableArray alloc] init];
    [arySparkList addObject:@"Add"];
    
    NSArray * loadSparkList = [[NSArray alloc] initWithContentsOfFile:[FFLocalFileManager getSparkSvrListPath]];
    if ( loadSparkList != nil )
        [arySparkList addObjectsFromArray:loadSparkList];
    NSArray * loadURLHistory = [[NSArray alloc] initWithContentsOfFile:[FFLocalFileManager getURLHistoryPath]];
    if ( loadURLHistory != nil )
        [aryURLHistory addObjectsFromArray:loadURLHistory];
    
    arySection = @[
        NSLocalizedString(@"URL History", nil)
        ,NSLocalizedString(@"Spark Server", nil)
    ];
    arySectionArray = @[
        aryURLHistory
        ,arySparkList
    ];
    
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [arySection count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return arySection[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [arySectionArray[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ( indexPath.section == 0) {  //URL history
        cell.textLabel.text = aryURLHistory[ indexPath.row ];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ( indexPath.section == 1 ) { //Sprk Server
        if ( indexPath.row == 0 ) {
            cell.textLabel.text = NSLocalizedString(@"Add Server IP", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.textLabel.text = arySparkList[ indexPath.row ];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ( indexPath.section == 0 ) {
        
    } else if ( indexPath.section == 1 ) {
        if ( indexPath.row == 0 ) {
            
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
