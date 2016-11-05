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

@property BOOL didInitialSetup;

@property CGRect previousFrame;

@end

@implementation LMBigListEntry

//int createdSoFar = 0;
//- (instancetype)init {
//	self = [super init];
//	if(self) {
//		createdSoFar++;
//		NSLog(@"%d LMBigListEntrys created so far", createdSoFar);
//	}
//	return self;
//}

+ (float)smallSizeForBigListEntryWithDelegate:(id<LMBigListEntryDelegate>)delegate {
	float contentViewHeightFactorial = [delegate contentSubviewHeightFactorialForBigListEntry:nil];
	float infoViewHeightFactorial = (1.0/10.0);
	float controlBarFactorial = [LMControlBarView heightWhenIsOpened:NO]/WINDOW_FRAME.size.height;
	
	return (contentViewHeightFactorial+infoViewHeightFactorial+controlBarFactorial)*WINDOW_FRAME.size.height+20;
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	self.rootViewHeightConstraint.constant -= self.controlBarViewHeightConstraint.constant == 0 ? 0 : self.controlBarViewHeightConstraint.constant+20;
	self.rootViewHeightConstraint.constant += newSize.height + 20;
	
	self.controlBarViewHeightConstraint.constant = newSize.height;
	[self.rootView layoutIfNeeded];
	[self layoutIfNeeded];
	
	self.isLargeSize = self.controlBarView.isOpen;
	
	[self.entryDelegate sizeChangedToLargeSize:self.controlBarView.isOpen withHeight:self.rootViewHeightConstraint.constant forBigListEntry:self];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return YES;
}

- (void)invertControlView {
	[self.controlBarView invert:YES];
}

- (void)setLarge:(BOOL)large animated:(BOOL)animated {
	large ? [self.controlBarView open:animated] : [self.controlBarView close:animated];
}

- (void)reloadData {
	[self.collectionInfoView reloadData];
}

- (void)setup {
//	NSLog(@"big entry array index %ld New frame %@ previous frame %@", self.collectionIndex % 40, NSStringFromCGRect(self.frame), NSStringFromCGRect(self.previousFrame));
	
//	self.previousFrame = self.frame;
	
//	if(!self.didInitialSetup){
//		self.didInitialSetup = YES;
	
		self.contentView = [self.entryDelegate contentSubviewForBigListEntry:self];
	
	self.contentView = [UIView newAutoLayoutView];
	[self.contentView setBackgroundColor:[UIColor greenColor]];
	
		float contentViewHeightFactorial = [self.entryDelegate contentSubviewHeightFactorialForBigListEntry:self];
		float infoViewHeightFactorial = (1.0/10.0);
	
		if(contentViewHeightFactorial == 0.0){
			NSLog(@"Rejecting, gutless piece of shit.");
			return;
		}
				
		self.rootView = [UIView newAutoLayoutView];
		[self addSubview:self.rootView];
		
		[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.rootView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		self.rootViewHeightConstraint = [self.rootView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*(contentViewHeightFactorial+infoViewHeightFactorial)];
		
//		self.rootView.backgroundColor = [UIColor colorWithRed:0.2*arc4random_uniform(5) green:0.2*arc4random_uniform(5) blue:0.2*arc4random_uniform(5) alpha:0.5];
	self.rootView.backgroundColor = [UIColor orangeColor];
	
		UIView *contentView = self.contentView;
		[self.rootView addSubview:contentView];
		
		[contentView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rootView withMultiplier:0.8];
		[contentView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*contentViewHeightFactorial];
		
		self.collectionInfoView = [LMCollectionInfoView newAutoLayoutView];
		self.collectionInfoView.delegate = self.infoDelegate;
		[self.rootView addSubview:self.collectionInfoView];
		
		[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.collectionInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView withOffset:10];
		[self.collectionInfoView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*infoViewHeightFactorial];
		
		[self.collectionInfoView reloadData];
		
//		self.controlBarView = [LMControlBarView newAutoLayoutView];
//		self.controlBarView.delegate = self;
//		self.controlBarView.userInteractionEnabled = YES;
//		[self.rootView addSubview:self.controlBarView];
//	
//	return;
//		
//		[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
//		[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
//		[self.controlBarView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoView withOffset:10];
//		self.controlBarViewHeightConstraint = [self.controlBarView autoSetDimension:ALDimensionHeight toSize:0];
//		
//		[self.controlBarView setup];
//		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(invertControlView)];
		[self.collectionInfoView addGestureRecognizer:tapGesture];
	
		[self.entryDelegate sizeChangedToLargeSize:NO withHeight:self.rootViewHeightConstraint.constant + 100 forBigListEntry:self];
//	}
}

@end
