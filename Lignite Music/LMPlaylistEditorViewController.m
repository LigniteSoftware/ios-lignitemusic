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

/**
 The text field for the title of the playlist.
 */
@property UITextField *titleTextField;

/**
 The add songs button which will be tapped by the user to add new songs.
 */
@property UIView *addSongsButtonView;

@end

@implementation LMPlaylistEditorViewController

- (void)addSongsButtonTapped {
	NSLog(@"Add songs...");
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[self.titleTextField resignFirstResponder];
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
	
	
	self.titleTextField = [UITextField newAutoLayoutView];
	self.titleTextField.placeholder = NSLocalizedString(@"YourPlaylistTitle", nil);
	[self.view addSubview:self.titleTextField];
	
	[self.titleTextField autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.titleTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imagePickerView];
	[self.titleTextField autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.imagePickerView withOffset:15];
	
	UIView *textFieldLineView = [UIView newAutoLayoutView];
	textFieldLineView.backgroundColor = [UIColor grayColor];
	[self.view addSubview:textFieldLineView];
	
	[textFieldLineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleTextField withOffset:2];
	[textFieldLineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[textFieldLineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
	[textFieldLineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	
	
	self.addSongsButtonView = [UIView newAutoLayoutView];
	self.addSongsButtonView.backgroundColor = [LMColour ligniteRedColour];
	self.addSongsButtonView.layer.cornerRadius = 8.0f;
	self.addSongsButtonView.layer.masksToBounds = YES;
	[self.view addSubview:self.addSongsButtonView];
	
	[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[self.addSongsButtonView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
	[self.addSongsButtonView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imagePickerView];
	[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(2.0/3.0)];
	
	UITapGestureRecognizer *addSongsButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addSongsButtonTapped)];
	[self.addSongsButtonView addGestureRecognizer:addSongsButtonTapGestureRecognizer];
	
	NSString *text = NSLocalizedString(@"AddSongs", nil);
	UIImage *icon = [LMAppIcon imageForIcon:LMIconAdd];
	
	UIView *backgroundView = [UIView newAutoLayoutView];
	[self.addSongsButtonView addSubview:backgroundView];
	
	[backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.addSongsButtonView withMultiplier:(1.0/4.0)];
	[backgroundView autoCenterInSuperview];
	
	UIImageView *iconView = [UIImageView newAutoLayoutView];
	iconView.image = icon;
	iconView.contentMode = UIViewContentModeScaleAspectFit;
	[backgroundView addSubview:iconView];
	
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:backgroundView];
	
	UILabel *labelView = [UILabel newAutoLayoutView];
	labelView.text = text;
	labelView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
	labelView.textColor = [UIColor whiteColor];
	[backgroundView addSubview:labelView];
	
	[labelView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:iconView withOffset:12.0f];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
