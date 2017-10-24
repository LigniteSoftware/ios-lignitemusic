//
//  LMTrackPickerController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMTrackPickerController.h"

@interface LMTrackPickerController ()

@end

@implementation LMTrackPickerController

- (void)saveSongSelection {
	NSLog(@"Done");
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
