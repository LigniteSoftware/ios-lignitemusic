//
//  LMPebbleSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 8/9/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MessageUI/MFMailComposeViewController.h>
#import "LMPebbleSettingsView.h"
#import "LMSettingsSwitch.h"
#import "LMSettingsLabel.h"

@interface LMPebbleSettingsView () <MFMailComposeViewControllerDelegate>

@property NSDictionary *settingsMapping;
@property NSDictionary *defaultsMapping;

@end

@implementation LMPebbleSettingsView

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.settingsMapping = [[NSDictionary alloc]initWithObjectsAndKeys:@(100), @"pebble_battery_saver", @(101), @"pebble_artist_label", @(102), @"pebble_style_controls", @(103), @"pebble_show_time", nil];
    self.defaultsMapping = [[NSDictionary alloc]initWithObjectsAndKeys:@(0), @"pebble_battery_saver", @(1), @"pebble_artist_label", @(1), @"pebble_style_controls", @(0), @"pebble_show_time", nil];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section){
        case 0:
            return 2;
        case 1:
            return 2;
		case 2:
			return 3;
    }
    return 0;
}

- (void)changeSwitch:(id)theSwitch {
    LMSettingsSwitch *changedSwitch = (LMSettingsSwitch*)theSwitch;
    NSLog(@"value %@", changedSwitch.switchID);
    
    if(self.messageQueue){
        NSNumber *key = [self.settingsMapping objectForKey:changedSwitch.switchID];
        [self.messageQueue enqueue:@{key:@(changedSwitch.on)}];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:changedSwitch.on forKey:changedSwitch.switchID];
    }
}

- (LMSettingsLabel*)addLabelToCell:(UITableViewCell*)cell withID:(NSString*)labelID {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGRect label_rect = CGRectMake(screenRect.origin.x+14, 7, screenRect.size.width-35.0f, 30.0f);
    LMSettingsLabel *label = [[LMSettingsLabel alloc]initWithFrame:label_rect];
    label.text = NSLocalizedString(labelID, nil);
    label.labelID = labelID;
    [cell addSubview:label];
	
	if(!self.messageQueue || !self.messageQueue.watch){
		label.enabled = NO;
	}
	
	return label;
}

- (void)addToggleToCell:(UITableViewCell*)cell withID:(NSString*)switchID{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGRect toggle_rect = CGRectMake(screenRect.size.width-60, 5.0f, 30.0f, 15.0f);
    
    LMSettingsSwitch *toggle = [[LMSettingsSwitch alloc]initWithFrame:toggle_rect];
    [toggle addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
    toggle.on = true;
    toggle.switchID = switchID;
    [cell addSubview:toggle];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:toggle.switchID]){
        toggle.on = [defaults boolForKey:toggle.switchID];
    }
    else{
        toggle.on = [[self.defaultsMapping objectForKey:toggle.switchID] isEqualToValue:@(1)];
    }
	
	if(!self.messageQueue || !self.messageQueue.watch){
		toggle.enabled = NO;
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError*)error;
{
	if (result == MFMailComposeResultSent) {
		NSLog(@"It's away!");
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if(indexPath.section == 2){
		switch(indexPath.row){
			case 0:
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"pebble://appstore/579c3ee922f599cf7e0001ea"]];
				break;
			case 1:
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.lignite.io/feedback/"]];
				break;
			case 2:{
				UIAlertController * alert = [UIAlertController
											 alertControllerWithTitle:@"How to Use"
											 message:@"Hey! Welcome to the first Lignite Music beta. We're going to having a better tutorial soon, don't worry.\n\nTo play/pause the song, tap anywhere on the screen.\n\nTo skip/go to previous song, swipe left or right anywhere on the screen.\n\nDrag the slider to control the playing time.\n\nInstall the Pebble app within the settings page.\n\nYou can replay this tutorial any time in settings."
											 preferredStyle:UIAlertControllerStyleAlert];
				
				UIAlertAction* yesButton = [UIAlertAction
											actionWithTitle:@"Ok, thanks"
											style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) {
												//[defaults setBool:YES forKey:@"shitty_tutorial"];
											}];
				
				[alert addAction:yesButton];
				
				NSArray *viewArray = [[[[[[[[[[[[alert view] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews];
				UILabel *alertMessage = viewArray[1];
				alertMessage.textAlignment = NSTextAlignmentLeft;
				
				[self presentViewController:alert animated:YES completion:nil];
				break;
			}
			case 3:{
				MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
				controller.mailComposeDelegate = self;
				[controller setToRecipients:[[NSArray alloc] initWithObjects:@"jonb@pebble.com", nil]];
				[controller setSubject:@"APP_MSG_BUSY Locking Up Watchapp"];
				[controller setMessageBody:@"Hi there,\n\nI am having an issue with one of my watchapps which causes it to lock up when it gets the APP_MSG_BUSY error. I have to completely restart the watchapp to fix this, it's very frustrating.\n\nThis exact issue is on this forum thread: https://forums.pebble.com/t/how-to-recover-from-app-msg-busy-after-bluetooth-reconnects/22948\n\nHoping this issue is fixed soon.\n\nThanks!" isHTML:NO];
				if (controller){
					//[self presentModalViewController:controller animated:YES];
					[self showViewController:controller sender:self];
				}
				break;
			}
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]init];
	
    switch(indexPath.section){
        case 0:
            switch(indexPath.row){
                case 0:
                    [self addLabelToCell:cell withID:@"Battery saver"];
                    [self addToggleToCell:cell withID:@"pebble_battery_saver"];
                    break;
                case 1:
                    [self addLabelToCell:cell withID:@"Pebble-style controls"];
                    [self addToggleToCell:cell withID:@"pebble_style_controls"];
                    break;
            }
            break;
        case 1:
            switch(indexPath.row){
                case 0:
                    [self addLabelToCell:cell withID:@"Artist label"];
                    [self addToggleToCell:cell withID:@"pebble_artist_label"];
                    break;
				case 1:
					[self addLabelToCell:cell withID:@"Display time"];
					[self addToggleToCell:cell withID:@"pebble_show_time"];
					break;
            }
            break;
		case 2:
			switch(indexPath.row){
				case 0:
					[self addLabelToCell:cell withID:@"Install Pebble App"].enabled = YES;
					break;
				case 1:
					[self addLabelToCell:cell withID:@"Send Feedback/Report Bug"].enabled = YES;
					break;
				case 2:
					[self addLabelToCell:cell withID:@"Replay Tutorial"].enabled = YES;
					break;
				case 3:
					[self addLabelToCell:cell withID:@"Report 'Pebble Internal Error' Bug"].enabled = YES;
					break;
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
    }
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch(section){
        case 0:
            return @"Functionality";
        case 1:
            return @"Look and Feel";
		case 2:
			return @"Other";
    }
    return @"Unknown Section";
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
