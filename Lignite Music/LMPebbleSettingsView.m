//
//  LMPebbleSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 8/9/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMPebbleSettingsView.h"
#import "LMSettingsSwitch.h"
#import "LMSettingsLabel.h"

@interface LMPebbleSettingsView ()

@property NSDictionary *settingsMapping;

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
    
    self.settingsMapping = [[NSDictionary alloc]initWithObjectsAndKeys:@(100), @"pebble_battery_saver", @(101), @"pebble_artist_label", nil];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
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

- (void)addLabelToCell:(UITableViewCell*)cell withID:(NSString*)labelID {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGRect label_rect = CGRectMake(screenRect.origin.x+14, 7, screenRect.size.width-35.0f, 30.0f);
    LMSettingsLabel *label = [[LMSettingsLabel alloc]initWithFrame:label_rect];
    label.text = NSLocalizedString(labelID, nil);
    label.labelID = labelID;
    [cell addSubview:label];
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
    toggle.on = [defaults boolForKey:toggle.switchID];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]init];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch(indexPath.section){
        case 0:
            switch(indexPath.row){
                case 0:
                    [self addLabelToCell:cell withID:@"Battery saver"];
                    [self addToggleToCell:cell withID:@"pebble_battery_saver"];
                    break;
            }
            break;
        case 1:
            switch(indexPath.row){
                case 0:
                    [self addLabelToCell:cell withID:@"Artist label"];
                    [self addToggleToCell:cell withID:@"pebble_artist_label"];
                    break;
            }
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
