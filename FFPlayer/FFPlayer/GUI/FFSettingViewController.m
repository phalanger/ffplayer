//
//  FFSecondViewController.m
//  FFPlayer
//
//  Created by Coremail on 14-1-13.
//  Copyright (c) 2014年 Coremail. All rights reserved.
//

#import "FFSettingViewController.h"
#import "FFHelper.h"
#import "FFAlertView.h"

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
    
    sectionCellCount = [NSArray arrayWithObjects:[NSNumber numberWithInt:1 + ([[FFSetting default] unlock] ? 1 : 0) ]
                                                , [NSNumber numberWithInt:3]
                                                , [NSNumber numberWithInt:1], nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionHeader.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSNumber *)sectionCellCount[section] integerValue];
}

+(NSString *)getSortString:(int)type
{
    NSString * str = nil;
    switch (type) {
        case SORT_BY_DATE:
            str = NSLocalizedString(@"By Date", nil); break;
        case SORT_BY_DATE_DESC:
            str = NSLocalizedString(@"By Date Desc", nil); break;
        case SORT_RANDOM:
            str = NSLocalizedString(@"Randon", nil); break;
        case SORT_BY_NAME_DESC:
            str = NSLocalizedString(@"By Name Desc", nil); break;
        default:
            str = NSLocalizedString(@"By Name", nil); break;
    }
    return str;
}

-(void) addSwitchToCell:(UITableViewCell *)cell withTag:(int)tag withValue:(BOOL)val
{
    cell.detailTextLabel.text = nil;
    UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
    switchview.tag = tag;
    switchview.on = val;
    [switchview addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchview;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SettingItem" forIndexPath:indexPath];
    FFSetting * setting = [FFSetting default];
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Enable internal player", nil);
                [self addSwitchToCell:cell withTag:SWITCH_ENABLE_INTERNAL_PLAYER withValue:[setting enableInternalPlayer]];
            } else if ( indexPath.row == 1 ) {
                cell.textLabel.text = NSLocalizedString(@"Reset password", nil);
                cell.detailTextLabel.text = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Auto play next", nil);
                [self addSwitchToCell:cell withTag:SWITCH_AUTO_PLAY_NEXT withValue:[setting autoPlayNext]];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"Sort", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.detailTextLabel.text = [FFSettingViewController getSortString:[setting sortType]];
            } else if (indexPath.row == 2) {
                cell.textLabel.text = NSLocalizedString(@"Seek delta", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d(%@)",  [setting seekDelta], NSLocalizedString(@"sec",nil)];
            }
            break;
        case 2:
            if ( indexPath.row == 0 ) {
                cell.textLabel.text = NSLocalizedString(@"Reset password", nil);
                cell.detailTextLabel.text = nil;
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
    FFSetting * setting = [FFSetting default];

    switch (aswitch.tag)
    {
        case SWITCH_ENABLE_INTERNAL_PLAYER:
            [setting setEnableInternalPlayer:[aswitch isOn]];
            break;
        case SWITCH_AUTO_PLAY_NEXT:
            [setting setAutoPlayNext:[aswitch isOn]];
            break;
        default:
            break;
    }
}

-(void) resetPassword {
    [FFAlertView inputPassword2: NSLocalizedString(@"Reset password", nil)
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
                             [[FFSetting default] setPassword:pass];
                         }
                     }
              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                 okButtonTitles:NSLocalizedString(@"OK", nil)
     ];
}
-(void) checkPasswordBeforeReset
{
    __weak FFSettingViewController * weakSelf = self;
    [FFAlertView showWithTitle:NSLocalizedString(@"Input the old password", nil)
                       message:nil
                   defaultText:nil
                         style:UIAlertViewStyleSecureTextInput
                    usingBlock:^(NSUInteger btn, NSString * strPass) {
                        if ( btn == 0 || !strPass)
                            return;
                        else if ( ![[FFSetting default] checkPassword:strPass] ) {
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:NSLocalizedString(@"Password error!", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil] show];
                        } else {
                            [weakSelf resetPassword];
                        }
                    }
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
             otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0:
            if ( indexPath.row == 1 && [[FFSetting default] unlock] ) { //reset password
                [self resetPassword];
            }
            break;
        case 1:
            if ( indexPath.row == 1 ) {
                [FFAlertView showWithTitle:NSLocalizedString(@"Sort Type", nil)
                                   message:NSLocalizedString(@"Select sort type.", nil)
                               defaultText:nil
                                     style:UIAlertViewStyleDefault
                                usingBlock:^(NSUInteger btn,NSString * text) {
                                    if ( btn == 0 )
                                        return;
                                    --btn;
                                    [[FFSetting default] setSortType:btn];
                                    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
                                    cell.detailTextLabel.text = [FFSettingViewController getSortString:btn];
                                }
                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                         otherButtonTitles: NSLocalizedString(@"By Name", nil)
                                            ,NSLocalizedString(@"By Name Desc", nil)
                                            ,NSLocalizedString(@"By Date", nil)
                                            ,NSLocalizedString(@"By Date Desc", nil)
                                            ,NSLocalizedString(@"Randon", nil)
                                    , nil];
            } else if ( indexPath.row == 2 ) {
                [FFAlertView showWithTitle:NSLocalizedString(@"Seek delta seconds", nil)
                                   message:nil
                               defaultText:nil
                                     style:UIAlertViewStyleDefault
                                usingBlock:^(NSUInteger btn,NSString * text) {
                                    int sec[] = { 0,5,10,20,60};
                                    if ( btn == 0 )
                                        return;
                                    else
                                        btn = sec[btn];
                                    [[FFSetting default] setSeekDelta:btn];
                                    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
                                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d(%@)", btn, NSLocalizedString(@"sec",nil)];
                                }
                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                         otherButtonTitles: NSLocalizedString(@"5(s)", nil)
                                            ,NSLocalizedString(@"10(s)", nil)
                                            ,NSLocalizedString(@"20(s)", nil)
                                            ,NSLocalizedString(@"60(s)", nil)
                                    , nil];
            }
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
