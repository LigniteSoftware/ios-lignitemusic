//
//  LMPlaylistEditorViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistEditorViewController.h"
#import "LMColour.h"
#import "LMAppIcon.h"
#import "LMImagePickerView.h"

@interface LMPlaylistEditorViewController ()

/**
 The image picker view.
 */
@property LMImagePickerView *imagePickerView;

@end

@implementation LMPlaylistEditorViewController

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Test" style:UIBarButtonItemStyleDone target:self action:nil];
	
	
	self.imagePickerView = [LMImagePickerView newAutoLayoutView];
	[self.view addSubview:self.imagePickerView];
	
	[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.imagePickerView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:88];
	[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.5/10.0)];
	[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
