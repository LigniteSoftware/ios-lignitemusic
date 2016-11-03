//
//  LMBigListEntry.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBigListEntry.h"
#import "LMExtras.h"

@interface LMBigListEntry()<LMControlBarViewDelegate>

@property UIView *rootView;
@property NSLayoutConstraint *rootViewHeightConstraint;

@property UIView *contentSubviewBackgroundView;
@property id contentView;

@property LMCollectionInfoView *collectionInfoView;

@property LMControlBarView *controlBarView;
@property NSLayoutConstraint* controlBarViewHeightConstraint;

@end

@implementation LMBigListEntry

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"New size for control bar %@", NSStringFromCGSize(newSize));
	
	self.rootViewHeightConstraint.constant -= self.controlBarViewHeightConstraint.constant;
	self.rootViewHeightConstraint.constant += newSize.height;
	
	self.controlBarViewHeightConstraint.constant = newSize.height;
	[self.rootView layoutIfNeeded];
	[self layoutIfNeeded];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return YES;
}

- (void)test{
	NSLog(@"Test!");
	[self.controlBarView invert];
}

- (void)setup {
	self.userInteractionEnabled = YES;
	
	self.contentView = [self.entryDelegate contentSubviewForBigListEntry:self];
	float contentViewHeightFactorial = [self.entryDelegate contentSubviewHeightFactorialForBigListEntry:self];
	float infoViewHeightFactorial = (1.0/8.0);
	
	self.rootView = [UIView newAutoLayoutView];
	self.rootView.backgroundColor = [UIColor purpleColor];
	[self addSubview:self.rootView];
	
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	self.rootViewHeightConstraint = [self.rootView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*(contentViewHeightFactorial+infoViewHeightFactorial)];
	
	UIView *contentView = self.contentView;
	[self.rootView addSubview:contentView];
	
	[contentView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rootView withMultiplier:0.8];
	[contentView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*contentViewHeightFactorial];
	
	self.collectionInfoView = [LMCollectionInfoView newAutoLayoutView];
	self.collectionInfoView.backgroundColor = [UIColor orangeColor];
	self.collectionInfoView.delegate = self.infoDelegate;
	[self.rootView addSubview:self.collectionInfoView];
	
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.collectionInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView];
	[self.collectionInfoView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*infoViewHeightFactorial];
	
	[self.collectionInfoView reloadData];
	
	self.controlBarView = [LMControlBarView newAutoLayoutView];
	self.controlBarView.backgroundColor = [UIColor clearColor];
	self.controlBarView.delegate = self;
	[self.rootView addSubview:self.controlBarView];
	
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.controlBarView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoView];
	self.controlBarViewHeightConstraint = [self.controlBarView autoSetDimension:ALDimensionHeight toSize:0];
	
	[self.controlBarView setup];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(test)];
	[self.rootView addGestureRecognizer:tapGesture];
	
	[self.entryDelegate sizeChangedTo:CGSizeMake(WINDOW_FRAME.size.width, self.rootViewHeightConstraint.constant) forBigListEntry:self];
}

@end
