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
#import "GCDWebServer.h"

//https://github.com/swisspol/GCDWebServer
//https://github.com/swisspol/ComicFlow

enum {
    SWITCH_ENABLE_INTERNAL_PLAYER,
    MENU_RESET_PASSWORD,
    SWITCH_AUTO_PLAY_NEXT,
    MENU_SORT_TYPE,
    MENU_SEEK_DELTA,
    SWITCH_HTTP_UPLOAD,
    MENU_ABOUT,
};

@interface FFSettingViewController () <UITextFieldDelegate>
{
    NSArray *sectionHeader;
    NSArray *sectionCellCount;
    
    GCDWebServer* webServer;
}
@end

@implementation FFSettingViewController

- (void)viewDidLoad
{
    self.tabBarItem.title = self.title = self.navigationItem.title = NSLocalizedString(@"Setting", @"Setting title");

    sectionHeader = [NSArray arrayWithObjects:NSLocalizedString(@"Global Setting", nil),
                                        NSLocalizedString(@"Upload", nil),
                                        NSLocalizedString(@"Movie player", nil),
                                        NSLocalizedString(@"Other", nil),
                                    nil];
    
    
    webServer = [[GCDWebServer alloc] init];
    
    // Add a handler to respond to requests on any URL
    [webServer addDefaultHandlerForMethod:@"GET"
                             requestClass:[GCDWebServerRequest class]
                             processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                 
                                 return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
                                 
                             }];
}

-(void) reloadSetting
{
    NSMutableArray * aryGlobal = [@[ @(SWITCH_ENABLE_INTERNAL_PLAYER)
                                
                                ] mutableCopy];
    
    NSMutableArray * aryUpload = [@[ @(SWITCH_HTTP_UPLOAD)
                                    ] mutableCopy];

    NSMutableArray * aryMovie = [@[ @(SWITCH_AUTO_PLAY_NEXT)
                                ,@(MENU_SORT_TYPE)
                                ,@(MENU_SEEK_DELTA)
                                ] mutableCopy];
    NSMutableArray * aryOther = [@[ @(MENU_ABOUT)
                                ] mutableCopy];
    
    if ( [[FFSetting default] unlock] )
        [aryGlobal addObject:@(MENU_RESET_PASSWORD)];
    
    sectionCellCount = @[ aryGlobal, aryUpload, aryMovie, aryOther ];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionHeader.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)sectionCellCount[section] count];
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

-(void) addInputToCell:(UITableViewCell *)cell placeHolder:(NSString *)str withTag:(int)tag inFrame:(CGRect)rect
{
    UITextField *txtField=[[UITextField alloc]initWithFrame:rect];
    txtField.tag = tag;
    txtField.delegate = self;
    txtField.enablesReturnKeyAutomatically = YES;
    txtField.returnKeyType = UIReturnKeyDone;
    txtField.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    txtField.autoresizesSubviews=YES;
    txtField.layer.cornerRadius=10.0;
    [txtField setBorderStyle:UITextBorderStyleRoundedRect];
    [txtField setPlaceholder:str];
    [cell.contentView addSubview:txtField];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"SettingItem" forIndexPath:indexPath];
    FFSetting * setting = [FFSetting default];
    NSArray * sec = sectionCellCount[indexPath.section];
    NSNumber * nID = sec[indexPath.row];
    switch ( [nID intValue] ) {
        case SWITCH_ENABLE_INTERNAL_PLAYER: {
            cell.textLabel.text = NSLocalizedString(@"Enable internal player", nil);
            [self addSwitchToCell:cell withTag:SWITCH_ENABLE_INTERNAL_PLAYER withValue:[setting enableInternalPlayer]];
        } break;

        case MENU_RESET_PASSWORD: {
            cell.textLabel.text = NSLocalizedString(@"Reset password", nil);
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } break;

        case SWITCH_HTTP_UPLOAD: {
            cell.textLabel.text = NSLocalizedString(@"Open Web Server for upload", nil);
            [self addSwitchToCell:cell withTag:SWITCH_HTTP_UPLOAD withValue:[webServer isRunning]];
            [self addInputToCell:cell placeHolder:@"Port:8080" withTag:SWITCH_HTTP_UPLOAD inFrame:CGRectMake( 265, 3, 80, 38)];
        } break;
            
        case SWITCH_AUTO_PLAY_NEXT: {
            cell.textLabel.text = NSLocalizedString(@"Auto play next", nil);
            [self addSwitchToCell:cell withTag:SWITCH_AUTO_PLAY_NEXT withValue:[setting autoPlayNext]];
            
        } break;
            
        case MENU_SORT_TYPE:{
            cell.textLabel.text = NSLocalizedString(@"Sort", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [FFSettingViewController getSortString:[setting sortType]];
        } break;
            
        case MENU_SEEK_DELTA: {
            cell.textLabel.text = NSLocalizedString(@"Seek delta", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d(%@)",  [setting seekDelta], NSLocalizedString(@"sec",nil)];
        } break;
            
        case MENU_ABOUT: {
            cell.textLabel.text = NSLocalizedString(@"About", nil);
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } break;
            
        default:
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
        case SWITCH_HTTP_UPLOAD:
            // Use convenience method that runs server on port 8080 until SIGINT received
            if ( [aswitch isOn] )
                [webServer runWithPort:8080];
            else
                [webServer stop];
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
    NSArray * sec = sectionCellCount[indexPath.section];
    NSNumber * nID = sec[indexPath.row];
    switch ( [nID intValue] ) {
        case MENU_RESET_PASSWORD:
            if ( [[FFSetting default] unlock] ) { //reset password
                [self resetPassword];
            } break;
        case MENU_SORT_TYPE: {
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
        }break;
            
        case MENU_SEEK_DELTA: {
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
            } break;
        default:
            break;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ( textField.tag == SWITCH_HTTP_UPLOAD ) {
        
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"%d", textField.tag);
    NSInteger nextTag = textField.tag + 1;
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSetting]; // to reload selected cell
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
