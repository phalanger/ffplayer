//
//  FFSecondViewController.m
//  FFPlayer
//
//  Created by Coremail on 14-1-13.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFSettingViewController.h"

enum {
    SWITCH_ENABLE_INTERNAL_PLAYER = 0x01,
    SWITCH_AUTO_PLAY_NEXT = 0x2,
};

@interface FFSettingViewController ()
{
    NSArray *sectionHeader;
    NSArray *sectionCellCount;
}
@end

@implementation FFSettingViewController

- (void)viewDidLoad
{
    self.tabBarItem.title = self.title = self.navigationItem.title = NSLocalizedString(@"Setting", @"Setting title");

    sectionHeader = [NSArray arrayWithObjects:NSLocalizedString(@"Global Setting", nil),
                                        NSLocalizedString(@"Movie player", nil),
                                        NSLocalizedString(@"Other", nil),
                                    nil];
    
    sectionCellCount = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionHeader.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSNumber *)sectionCellCount[section] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SettingItem" forIndexPath:indexPath];
    NSUserDefaults * setting = [NSUserDefaults standardUserDefaults];
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Enable internal player", nil);
                
                UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
                switchview.tag = SWITCH_ENABLE_INTERNAL_PLAYER;
                switchview.on = ![setting integerForKey:@"forbit_internal_player"];
                [switchview addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchview;
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Auto play next", nil);
                
                UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
                switchview.tag = SWITCH_AUTO_PLAY_NEXT;
                switchview.on = ![setting integerForKey:@"pause_after_play"];
                [switchview addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchview;
            }
            break;
        case 2:
            if ( indexPath.row == 0 ) {
                cell.textLabel.text = NSLocalizedString(@"Reset password", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return sectionHeader[section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)switchChanged:(id)sender {
    
    UISwitch* aswitch = sender;
    NSUserDefaults * setting = [NSUserDefaults standardUserDefaults];

    switch (aswitch.tag)
    {
        case SWITCH_ENABLE_INTERNAL_PLAYER:
            [setting setInteger:[aswitch isOn]?0:1 forKey:@"forbit_internal_player"];
            break;
        case SWITCH_AUTO_PLAY_NEXT:
            [setting setInteger:[aswitch isOn]?0:1 forKey:@"pause_after_play"];
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
            break;
        case 2:
            if ( indexPath.row == 0 ) {
            }
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData]; // to reload selected cell
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
