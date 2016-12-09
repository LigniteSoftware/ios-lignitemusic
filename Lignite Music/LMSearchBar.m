//
//  LMSearchBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/4/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchBar.h"
#import "LMColour.h"
#import "LMMusicPlayer.h"
#import "LMAppIcon.h"

@interface LMSearchBar()<UITextFieldDelegate>

/**
 The text field which search terms are inputted into.
 */
@property UITextField *searchTextField;

/**
 The background view for the clear text button.
 */
@property UIView *clearTextButtonBackgroundView;

/**
 The image view for the clear text button.
 */
@property UIImageView *clearTextButtonImageView;

/**
 The current search term. Should be put against any other search term in queue to make sure there are no overlapping instances.
 */
@property NSString *currentSearchTerm;


@property MPMusicPlayerController *musicPlayer;


@end

@implementation LMSearchBar

- (void)searchFieldDidChange {
	NSLog(@"%@", self.searchTextField.text);
	
	NSString *searchTerm = self.searchTextField.text;
	
	self.currentSearchTerm = searchTerm;
	
	if(self.delegate){
		[self.delegate searchTermChangedTo:searchTerm];
	}
}

- (void)tappedClearSearch {
	self.searchTextField.text = @"";
	[self searchFieldDidChange];
	[self dismissKeyboard];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	NSDictionary *info = notification.userInfo;
	NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	CGRect keyboardFrame = [value CGRectValue];
		
	[self.delegate searchDialogOpened:YES withKeyboardHeight:keyboardFrame.size.height];
}

- (void)keyboardWillHide:(NSNotification*)notification {
	[self.delegate searchDialogOpened:NO withKeyboardHeight:0.0];
}

//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	[UIView setAnimationsEnabled:NO];
//	[NSTimer scheduledTimerWithTimeInterval:0.50 repeats:NO block:^(NSTimer * _Nonnull timer) {
//		[UIView setAnimationsEnabled:YES];
//	}];
//}
//
//- (void)textFieldDidEndEditing:(UITextField *)textField {
//	[UIView setAnimationsEnabled:NO];
//	[NSTimer scheduledTimerWithTimeInterval:1.10 repeats:NO block:^(NSTimer * _Nonnull timer) {
//		[UIView setAnimationsEnabled:YES];
//	}];
//}

//- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//	[textField resignFirstResponder];
//	return YES;
//}

- (void)dismissKeyboard {
	[self.delegate searchDialogOpened:NO withKeyboardHeight:0.0];
	[self endEditing:YES];
}

- (void)showKeyboard {
	[self.searchTextField becomeFirstResponder];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
		
		self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
		
		self.backgroundColor = [LMColour darkGrayColour];
		
		self.didLayoutConstraints = YES;
	
		
		self.clearTextButtonBackgroundView = [UIView newAutoLayoutView];
		self.clearTextButtonBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self addSubview:self.clearTextButtonBackgroundView];
		
		[self.clearTextButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.clearTextButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.clearTextButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
		[self.clearTextButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedClearSearch)];
		[self.clearTextButtonBackgroundView addGestureRecognizer:tapGesture];
		
		
		self.clearTextButtonImageView = [UIImageView newAutoLayoutView];
		self.clearTextButtonImageView.image = [LMAppIcon imageForIcon:LMIconXCross];
		self.clearTextButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.clearTextButtonBackgroundView addSubview:self.clearTextButtonImageView];
		
		[self.clearTextButtonImageView autoCenterInSuperview];
		[self.clearTextButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.clearTextButtonBackgroundView withMultiplier:(1.0/2.0)];
		[self.clearTextButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.clearTextButtonBackgroundView withMultiplier:(1.0/2.0)];
		
		
		self.searchTextField = [UITextField newAutoLayoutView];
		self.searchTextField.textColor = [UIColor whiteColor];
		self.searchTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.frame.size.height/2.25];
		self.searchTextField.delegate = self;
		[self.searchTextField addTarget:self
								 action:@selector(searchFieldDidChange)
					   forControlEvents:UIControlEventEditingChanged];
		[self addSubview:self.searchTextField];
		
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeTop];
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[self.searchTextField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.clearTextButtonBackgroundView withOffset:-10.0];
	}
	
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
