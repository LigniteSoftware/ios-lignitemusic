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

@property UIView *contentSubviewBackgroundView;
@property id contentView;

@property LMCollectionInfoView *collectionInfoView;

@property LMControlBarView *controlBarView;
@property NSLayoutConstraint* controlBarViewHeightConstraint;

@end

@implementation LMBigListEntry

+ (float)smallSizeForBigListEntryWithDelegate:(id<LMBigListEntryDelegate>)delegate {
	float contentViewHeightFactorial = [delegate contentSubviewHeightFactorialForBigListEntry:nil];
	float infoViewHeightFactorial = (1.0/10.0);
	
	return (contentViewHeightFactorial+infoViewHeightFactorial)*WINDOW_FRAME.size.height+20+[LMControlBarView heightWhenIsOpened:NO];
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return [self.controlBarDelegate amountOfButtonsForControlBarView:controlBar];
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	[self layoutIfNeeded];
	
	self.controlBarViewHeightConstraint.constant = newSize.height;
	
	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
	}];
	
	self.isLargeSize = self.controlBarView.isOpen;
	
	[self.entryDelegate sizeChangedToLargeSize:self.controlBarView.isOpen withHeight:[LMBigListEntry smallSizeForBigListEntryWithDelegate:self.entryDelegate]+(self.controlBarView.isOpen ? newSize.height-[LMControlBarView heightWhenIsOpened:NO] : 0) forBigListEntry:self];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [self.controlBarDelegate imageWithIndex:index forControlBarView:controlBar];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [self.controlBarDelegate buttonTappedWithIndex:index forControlBarView:controlBar];
}

- (void)invertControlView {
	[self.controlBarView invert:YES];
}

- (void)setLarge:(BOOL)large animated:(BOOL)animated {
	large ? [self.controlBarView open:animated] : [self.controlBarView close:animated];
}

- (void)reloadData {
	[self.collectionInfoView reloadData];
	[self.entryDelegate contentSubviewForBigListEntry:self];
}

- (void)setup {
	self.contentView = [self.entryDelegate contentSubviewForBigListEntry:self];

//	self.contentView = [UIView newAutoLayoutView];
//	[self.contentView setBackgroundColor:[UIColor greenColor]];

	float contentViewHeightFactorial = [self.entryDelegate contentSubviewHeightFactorialForBigListEntry:self];
	float infoViewHeightFactorial = (1.0/10.0);

	if(contentViewHeightFactorial == 0.0){
		NSLog(@"Rejecting, gutless piece of shit.");
		return;
	}

//	self.backgroundColor = [UIColor orangeColor];

	UIView *contentView = self.contentView;
	[self addSubview:contentView];
	
	[contentView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.8];
	[contentView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*contentViewHeightFactorial];
	
	self.collectionInfoView = [LMCollectionInfoView newAutoLayoutView];
	self.collectionInfoView.delegate = self.infoDelegate;
	[self addSubview:self.collectionInfoView];
	
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.collectionInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView withOffset:10];
	[self.collectionInfoView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*infoViewHeightFactorial];
	
	[self.collectionInfoView reloadData];
	
	self.controlBarView = [LMControlBarView newAutoLayoutView];
	self.controlBarView.delegate = self;
	self.controlBarView.userInteractionEnabled = YES;
	[self addSubview:self.controlBarView];

	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
	[self.controlBarView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoView withOffset:10];
	self.controlBarViewHeightConstraint = [self.controlBarView autoSetDimension:ALDimensionHeight toSize:[LMControlBarView heightWhenIsOpened:NO]];
	
	[self.controlBarView setup];

	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(invertControlView)];
	[self.collectionInfoView addGestureRecognizer:tapGesture];

	[self.entryDelegate sizeChangedToLargeSize:NO withHeight:[LMBigListEntry smallSizeForBigListEntryWithDelegate:self.entryDelegate] forBigListEntry:self];
}

@end
