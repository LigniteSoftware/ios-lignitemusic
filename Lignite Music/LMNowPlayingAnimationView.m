//
//  LMNowPlayingAnimationView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-05.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMNowPlayingAnimationCircle.h"
#import "LMNowPlayingAnimationView.h"
#import "NSTimer+Blocks.h"
#import "LMColour.h"
#import "LMExtras.h"

@interface LMNowPlayingAnimationView()<LMLayoutChangeDelegate>

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The circle view for the next track animation.
 */
@property LMNowPlayingAnimationCircle *nextTrackCircleView;

/**
 The leading constraint of the next track circle view.
 */
@property NSLayoutConstraint *nextTrackCircleViewLeadingConstraint;

/**
 The height constraint of the next track circle view.
 */
@property NSLayoutConstraint *nextTrackCircleViewMainSizeConstraint;

/**
 The alternate dimension constraint of the next track circle view.
 */
@property NSLayoutConstraint *nextTrackCircleViewAlternateSizeConstraint;

/**
 The alternate dimension constraint of the previous track circle view.
 */
@property NSLayoutConstraint *previousTrackCircleViewAlternateSizeConstraint;

/**
 The circle view for the next track animation.
 */
@property LMNowPlayingAnimationCircle *previousTrackCircleView;

/**
 The trailing constraint of the next track circle view.
 */
@property NSLayoutConstraint *previousTrackCircleViewTrailingConstraint;

/**
 The height constraint of the next track circle view.
 */
@property NSLayoutConstraint *previousTrackCircleViewMainSizeConstraint;

/**
 The feedback generator for when the user changes tracks successfully.
 */
@property UISelectionFeedbackGenerator *feedbackGenerator;

/**
 Whether or not the user is interacting in the current moment.
 */
@property BOOL userInteracting;

@end

@implementation LMNowPlayingAnimationView

- (void)rootViewWillTransitionToSize:(CGSize)size
		   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self cancelAnimation];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self cancelAnimation];
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		
		self.nextTrackCircleView = [LMNowPlayingAnimationCircle new];
		self.nextTrackCircleView.icon = LMIconNextTrack;
		self.nextTrackCircleView.direction = LMNowPlayingAnimationCircleDirectionClockwise;
		self.nextTrackCircleView.squareMode = self.squareMode;
		[self addSubview:self.nextTrackCircleView];
		
		self.nextTrackCircleViewLeadingConstraint = [self.nextTrackCircleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self];
		self.nextTrackCircleViewMainSizeConstraint = [self.nextTrackCircleView autoSetDimension:(self.squareMode ? ALDimensionHeight : ALDimensionWidth) toSize:100.0f];
		self.nextTrackCircleViewAlternateSizeConstraint = [self.nextTrackCircleView autoSetDimension:(self.squareMode ? ALDimensionWidth : ALDimensionHeight) toSize:100.0f];
		[self.nextTrackCircleView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		self.previousTrackCircleView = [LMNowPlayingAnimationCircle new];
		self.previousTrackCircleView.icon = LMIconPreviousTrack;
		self.previousTrackCircleView.direction = LMNowPlayingAnimationCircleDirectionCounterClockwise;
		self.previousTrackCircleView.squareMode = self.squareMode;
		[self addSubview:self.previousTrackCircleView];
		
		self.previousTrackCircleViewTrailingConstraint = [self.previousTrackCircleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self];
		self.previousTrackCircleViewMainSizeConstraint = [self.previousTrackCircleView autoSetDimension:(self.squareMode ? ALDimensionHeight : ALDimensionWidth) toSize:100.0f];
		self.previousTrackCircleViewAlternateSizeConstraint = [self.previousTrackCircleView autoSetDimension:(self.squareMode ? ALDimensionWidth : ALDimensionHeight) toSize:100.0f];
		[self.previousTrackCircleView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	}
}

- (LMNowPlayingAnimationViewResult)progress:(CGPoint)progressPoint fromStartingPoint:(CGPoint)startingPoint {
	BOOL isGoingToNextTrack = (startingPoint.x - progressPoint.x) > startingPoint.x;
	
	self.userInteracting = YES;
	
	if(isGoingToNextTrack){
		self.nextTrackCircleViewLeadingConstraint.constant = progressPoint.x;
		self.previousTrackCircleViewTrailingConstraint.constant = 0;
		
		CGFloat smallerDimension = self.frame.size.width;
		CGFloat halfWindowFrame = smallerDimension / 2.0;
		CGFloat progress = (MIN(fabs(progressPoint.x), (halfWindowFrame * 2.0)) / (halfWindowFrame * 2.0));
		
		BOOL isLandscapeSquareMode = ((self.frame.size.height > self.frame.size.width) && self.squareMode);
		CGFloat addition = isLandscapeSquareMode ? -((self.frame.size.height / 5.0) * 4.0) : 0.0f;
		
		NSLog(@"next. X %f - %f", progressPoint.x, progress);
		
		self.nextTrackCircleViewMainSizeConstraint.constant =
			self.squareMode
				? (self.frame.size.height + (self.frame.size.width * progress))
				: ((halfWindowFrame / 2.0) + (smallerDimension * progress));
		
		self.nextTrackCircleViewAlternateSizeConstraint.constant = self.nextTrackCircleViewMainSizeConstraint.constant + addition;
		
		CGFloat circleProgress = progress * 2.0f;
		[self.nextTrackCircleView setProgress:MIN(1, circleProgress)];
		
		return (circleProgress >= 1.0f) ? LMNowPlayingAnimationViewResultSkipToNextComplete : LMNowPlayingAnimationViewResultSkipToNextIncomplete;
	}
	else{
		self.previousTrackCircleViewTrailingConstraint.constant = progressPoint.x;
		self.nextTrackCircleViewLeadingConstraint.constant = 0;
		
		CGFloat smallerDimension = self.frame.size.width;
		CGFloat halfWindowFrame = smallerDimension / 2.0;
		CGFloat progress = (MIN(fabs(progressPoint.x), (halfWindowFrame * 2.0)) / (halfWindowFrame * 2.0));
		
		BOOL isLandscapeSquareMode = ((self.frame.size.height > self.frame.size.width) && self.squareMode);
		CGFloat addition = isLandscapeSquareMode ? -((self.frame.size.height / 5.0) * 4.0) : 0.0f;
		
		NSLog(@"next. X %f - %f", progressPoint.x, progress);
		
		self.previousTrackCircleViewMainSizeConstraint.constant =
			self.squareMode
				? (self.frame.size.height + (self.frame.size.width * progress))
				: ((halfWindowFrame / 2.0) + (smallerDimension * progress));
		
		self.previousTrackCircleViewAlternateSizeConstraint.constant = self.previousTrackCircleViewMainSizeConstraint.constant + addition;
		
		CGFloat circleProgress = progress * 2.0f;
		[self.previousTrackCircleView setProgress:MIN(1, 1 - circleProgress)];
		
		return (circleProgress >= 1.0f) ? LMNowPlayingAnimationViewResultGoToPreviousComplete : LMNowPlayingAnimationViewResultGoToPreviousIncomplete;
	}
}

- (void)finishAnimationWithResult:(LMNowPlayingAnimationViewResult)result
			   acceptQuickGesture:(BOOL)acceptQuickGesture {
	
	[self layoutIfNeeded];
	
	BOOL gestureIncomplete = (result == LMNowPlayingAnimationViewResultSkipToNextIncomplete)
	|| (result == LMNowPlayingAnimationViewResultGoToPreviousIncomplete);
	if(gestureIncomplete && !acceptQuickGesture){
		[self cancelAnimation];
		return;
	}
	
	
	self.userInteracting = NO;
	
	
	self.feedbackGenerator = [UISelectionFeedbackGenerator new];
	[self.feedbackGenerator prepare];
	[self.feedbackGenerator selectionChanged];
	
	BOOL skipToNext = (result == LMNowPlayingAnimationViewResultSkipToNextComplete) || (result == LMNowPlayingAnimationViewResultSkipToNextIncomplete);
	
	NSLayoutConstraint *mainSizeConstraintToUse = skipToNext ? self.nextTrackCircleViewMainSizeConstraint : self.previousTrackCircleViewMainSizeConstraint;
	NSLayoutConstraint *alternateSizeConstraintToUse = skipToNext ? self.nextTrackCircleViewAlternateSizeConstraint : self.previousTrackCircleViewAlternateSizeConstraint;
	NSLayoutConstraint *sideConstraintToUse = skipToNext ? self.nextTrackCircleViewLeadingConstraint : self.previousTrackCircleViewTrailingConstraint;
	LMNowPlayingAnimationCircle *circleViewToUse = skipToNext ? self.nextTrackCircleView : self.previousTrackCircleView;
	
	CGFloat largeFrameDimension = MAX(self.frame.size.height, self.frame.size.width);
	CGFloat smallFrameDimension = MIN(self.frame.size.height, self.frame.size.width);
	
	mainSizeConstraintToUse.constant = ((largeFrameDimension / 3.0) * 4.0);
	alternateSizeConstraintToUse.constant = mainSizeConstraintToUse.constant;
	sideConstraintToUse.constant =
		(skipToNext ? -1 : 1)
		* (mainSizeConstraintToUse.constant - ((mainSizeConstraintToUse.constant - self.frame.size.width) / 2.0));
	
	[circleViewToUse setProgress:skipToNext ? 1.0f : 0.0f];
	
	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		NSLog(@"Finished %d", finished);
		if(finished){
			[NSTimer scheduledTimerWithTimeInterval:0.4 block:^{
				[self layoutIfNeeded];
				
				mainSizeConstraintToUse.constant = self.squareMode ? (self.frame.size.height) : 100.0f;
				alternateSizeConstraintToUse.constant = mainSizeConstraintToUse.constant;
				sideConstraintToUse.constant = (skipToNext ? -1 : 1) * (self.frame.size.width + mainSizeConstraintToUse.constant);
				
				circleViewToUse.progress = skipToNext ? 0.0f : 1.0f;
				circleViewToUse.direction = skipToNext ? LMNowPlayingAnimationCircleDirectionCounterClockwise : LMNowPlayingAnimationCircleDirectionClockwise;
				[circleViewToUse setProgress:skipToNext ? 1.0f : 0.0f animated:YES];
				
				self.feedbackGenerator = nil;
				
				[UIView animateWithDuration:0.3 animations:^{
					[self layoutIfNeeded];
				} completion:^(BOOL finished) {
					if(finished){
						circleViewToUse.direction = skipToNext ? LMNowPlayingAnimationCircleDirectionClockwise : LMNowPlayingAnimationCircleDirectionCounterClockwise;
					}
				}];
			} repeats:NO];
		}
	}];
}

- (void)cancelAnimation {
	[self layoutIfNeeded];
	
	
	self.userInteracting = NO;
	
	
	self.nextTrackCircleViewMainSizeConstraint.constant = self.squareMode ? MAX(self.frame.size.height, self.frame.size.width) : 100.0f;
	self.nextTrackCircleViewAlternateSizeConstraint.constant = self.nextTrackCircleViewMainSizeConstraint.constant;
	self.nextTrackCircleViewLeadingConstraint.constant = 0.0f;
	
	[self.nextTrackCircleView setProgress:0.0f animated:YES];
	
	
	self.previousTrackCircleViewMainSizeConstraint.constant = self.squareMode ? MAX(self.frame.size.height, self.frame.size.width) : 100.0f;
	self.previousTrackCircleViewAlternateSizeConstraint.constant = self.nextTrackCircleViewMainSizeConstraint.constant;
	self.previousTrackCircleViewTrailingConstraint.constant = 0.0f;
	
	[self.previousTrackCircleView setProgress:1.0f animated:YES];
	

	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
	}];
}

@end
