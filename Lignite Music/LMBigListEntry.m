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
@property float currentControlBarViewHeight;

@end

@implementation LMBigListEntry

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"New size for control bar %@", NSStringFromCGSize(newSize));
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return YES;
}

- (void)setup {
	self.contentView = [self.entryDelegate contentSubviewForBigListEntry:self];
	float contentViewHeightFactorial = [self.entryDelegate contentSubviewHeightFactorialForBigListEntry:self];
	float infoViewHeightFactorial = (1.0/8.0);
	
	self.rootView = [UIView newAutoLayoutView];
	self.rootView.backgroundColor = [UIColor blueColor];
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
	
	[self.entryDelegate sizeChangedTo:CGSizeMake(WINDOW_FRAME.size.width, self.rootViewHeightConstraint.constant) forBigListEntry:self];
}

@end
