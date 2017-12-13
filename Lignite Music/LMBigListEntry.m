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
#import "LMTriangleView.h"
#import "LMColour.h"
#import "LMButton.h"
#import "LMEditView.h"
#import "LMThemeEngine.h"

@interface LMBigListEntry()<LMThemeEngineDelegate>

@property UIView *contentSubviewBackgroundView;

@property NSLayoutConstraint* controlBarViewHeightConstraint;

/**
 The background view for the tap to edit feature, when enabled.
 */
@property LMEditView *tapToEditBackgroundView;

/**
 The tap to delete view.
 */
@property UIView *tapToDeleteView;

@end

@implementation LMBigListEntry

@synthesize editing = _editing;

- (BOOL)editing {
	return _editing;
}

- (void)setEditing:(BOOL)editing {
	_editing = editing;
	
//	[self.contentView addSubview:self.tapToEditBackgroundView];
//	[self.contentView bringSubviewToFront:self.tapToEditBackgroundView];
	
	[UIView animateWithDuration:0.3 animations:^{
		if(editing){
			self.tapToEditBackgroundView.hidden = NO;
		}
		self.tapToEditBackgroundView.alpha = editing;
	} completion:^(BOOL finished) {
		if(finished){
			self.tapToEditBackgroundView.hidden = !editing;
		}
	}];
}

- (void)editViewTapped {
	NSLog(@"Edit tapped");
	
	if([self.entryDelegate respondsToSelector:@selector(editTappedForBigListEntry:)]){
		[self.entryDelegate editTappedForBigListEntry:self];
	}
}

- (void)deleteViewTapped {
	NSLog(@"Delete tapped");
	
	if([self.entryDelegate respondsToSelector:@selector(deleteTappedForBigListEntry:)]){
		[self.entryDelegate deleteTappedForBigListEntry:self];
	}
}

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

- (void)themeChanged:(LMTheme)theme {
	self.tapToDeleteView.backgroundColor = [LMColour mainColour];
}

- (void)setup {
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
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
 
	UIView *contentView = (UIView*)self.contentView;
//	contentView.layer.shadowColor = [UIColor blackColor].CGColor;
//	contentView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
//	contentView.layer.shadowOffset = CGSizeMake(0, contentView.layer.shadowRadius/2);
//	contentView.layer.shadowOpacity = 0.5f;
	[self addSubview:contentView];
	
	[contentView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:contentViewWidthFactorial];
//	[contentView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height*contentViewHeightFactorial];
	
	[contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView];

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
	self.collectionInfoView.largeMode = YES;
	[self addSubview:self.collectionInfoView];
	
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:-7.5];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:-7.5];
	[self.collectionInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contentView];
	[self.collectionInfoView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	[self.collectionInfoView reloadData];
	
	
//	LMTriangleView *testView = [LMTriangleView newAutoLayoutView];
//	testView.backgroundColor = [UIColor orangeColor];
//	testView.maskDirection = LMTriangleMaskDirectionUpwards;
//	[self addSubview:testView];
//	
//	[testView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.collectionInfoView withOffset:-20];
//	[testView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.5];
//	[testView autoAlignAxisToSuperviewAxis:ALAxisVertical];
//	[testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.2];
	

	[self.entryDelegate sizeChangedToLargeSize:self.isLargeSize withHeight:[LMBigListEntry sizeForBigListEntryWhenOpened:self.isLargeSize forDelegate:self.entryDelegate] forBigListEntry:self];
	
	
	self.tapToEditBackgroundView = [LMEditView newAutoLayoutView];
	self.tapToEditBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:(3.0/5.0)];
	self.tapToEditBackgroundView.alpha = self.editing;
	
//	self.tapToEditBackgroundView.hidden = YES;
	self.tapToEditBackgroundView.layer.masksToBounds = YES;
	self.tapToEditBackgroundView.layer.cornerRadius = 8.0f;
	self.tapToEditBackgroundView.userInteractionEnabled = YES;
	[contentView addSubview:self.tapToEditBackgroundView];
	
	self.tapToEditBackgroundView.hidden = !self.editing;
	
	NSLog(@"ttebv %p", self.tapToEditBackgroundView);
	
	[self.tapToEditBackgroundView autoPinEdgesToSuperviewEdges];
	
	UITapGestureRecognizer *editTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(editViewTapped)];
	[self.tapToEditBackgroundView addGestureRecognizer:editTapGestureRecognizer];
	
	UILabel *tapToEditLabel = [UILabel newAutoLayoutView];
	tapToEditLabel.text = NSLocalizedString(@"TapToEdit", nil);
	tapToEditLabel.textColor = [UIColor whiteColor];
	tapToEditLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
	tapToEditLabel.textAlignment = NSTextAlignmentCenter;
	tapToEditLabel.numberOfLines = 0;
	[self.tapToEditBackgroundView addSubview:tapToEditLabel];
	
	[tapToEditLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[tapToEditLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[tapToEditLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[tapToEditLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:contentView withMultiplier:(2.0/3.0)];
	
	
	self.tapToDeleteView = [UIView newAutoLayoutView];
	self.tapToDeleteView.backgroundColor = [LMColour mainColour];
	[self.tapToEditBackgroundView addSubview:self.tapToDeleteView];
	
	[self.tapToDeleteView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.tapToDeleteView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.tapToDeleteView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.tapToDeleteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:tapToEditLabel];
	
	
	UIImageView *deleteIconImageView = [UIImageView newAutoLayoutView];
	deleteIconImageView.image = [LMAppIcon imageForIcon:LMIconXCross];
	deleteIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	[self.tapToDeleteView addSubview:deleteIconImageView];
	
	[deleteIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.tapToDeleteView withMultiplier:(1.0/3.0)];
	[deleteIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.tapToDeleteView withMultiplier:(1.0/3.0)];
	[deleteIconImageView autoCenterInSuperview];
	
	UITapGestureRecognizer *deleteTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(deleteViewTapped)];
	[self.tapToDeleteView addGestureRecognizer:deleteTapGestureRecognizer];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
//	NSLog(@"%@ %@", NSStringFromCGRect(self.superview.superview.frame), [[self.superview.superview class] description]);
}

- (void)removeFromSuperview {
	[super removeFromSuperview];
	
	[[LMThemeEngine sharedThemeEngine] removeDelegate:self];
}

@end
