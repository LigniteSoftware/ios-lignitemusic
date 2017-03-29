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

@interface LMBigListEntry()

@property UIView *contentSubviewBackgroundView;


@property NSLayoutConstraint* controlBarViewHeightConstraint;

@end

@implementation LMBigListEntry

- (instancetype)init {
	self = [super init];
	if(self) {
		self.contentViewWidthMultiplier = 0.8;
	}
	return self;
}

+ (float)sizeForBigListEntryWhenOpened:(BOOL)opened forDelegate:(id<LMBigListEntryDelegate>)delegate {
	float contentViewHeightFactorial = [delegate contentSubviewFactorial:YES forBigListEntry:nil];
	float infoViewHeightFactorial = (1.0/9.0);
	
	return (contentViewHeightFactorial+infoViewHeightFactorial)*WINDOW_FRAME.size.height+20;
}

- (void)reloadData {
	[self.collectionInfoView reloadData];
	[self.entryDelegate contentSubviewForBigListEntry:self];
}

- (void)tappedContentView:(UITapGestureRecognizer*)recognizer {
	if([self.entryDelegate respondsToSelector:@selector(contentViewTappedForBigListEntry:)]){
		[self.entryDelegate contentViewTappedForBigListEntry:self];
	}
}

- (void)doubleTappedContentView:(UITapGestureRecognizer*)recognizer {
	if([self.entryDelegate respondsToSelector:@selector(contentViewDoubleTappedForBigListEntry:)]){
		[self.entryDelegate contentViewDoubleTappedForBigListEntry:self];
	}
}

- (void)setup {
	self.contentView = [self.entryDelegate contentSubviewForBigListEntry:self];

//	self.contentView = [UIView newAutoLayoutView];
//	[self.contentView setBackgroundColor:[UIColor greenColor]];

	float contentViewHeightFactorial = [self.entryDelegate contentSubviewFactorial:YES forBigListEntry:self];
	float contentViewWidthFactorial = [self.entryDelegate contentSubviewFactorial:NO forBigListEntry:self];

	if(contentViewHeightFactorial == 0.0){
		NSLog(@"Rejecting, gutless piece of shit.");
		return;
	}

//	self.backgroundColor = [UIColor orangeColor];
 
	UIView *contentView = self.contentView;
//	contentView.layer.shadowColor = [UIColor blackColor].CGColor;
//	contentView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
//	contentView.layer.shadowOffset = CGSizeMake(0, contentView.layer.shadowRadius/2);
//	contentView.layer.shadowOpacity = 0.5f;
	[self addSubview:contentView];
	
	[contentView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:contentViewWidthFactorial];
//	[contentView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*contentViewHeightFactorial];
	
	[contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];

	UITapGestureRecognizer *contentDoubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTappedContentView:)];
	contentDoubleTapGesture.numberOfTapsRequired = 2;
	[contentView addGestureRecognizer:contentDoubleTapGesture];
	
	UITapGestureRecognizer *contentTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedContentView:)];
	[contentView addGestureRecognizer:contentTapGesture];
//	[contentTapGesture requireGestureRecognizerToFail:contentDoubleTapGesture];
	contentView.userInteractionEnabled = YES;

	
	self.collectionInfoView = [LMCollectionInfoView newAutoLayoutView];
	self.collectionInfoView.delegate = self.infoDelegate;
	self.collectionInfoView.associatedBigListEntry = self;
	[self addSubview:self.collectionInfoView];
	
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:-7.5];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:-7.5];
	[self.collectionInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	[self.collectionInfoView reloadData];

	[self.entryDelegate sizeChangedToLargeSize:self.isLargeSize withHeight:[LMBigListEntry sizeForBigListEntryWhenOpened:self.isLargeSize forDelegate:self.entryDelegate] forBigListEntry:self];
}

@end
