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

@interface LMNowPlayingAnimationView()

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
@property NSLayoutConstraint *nextTrackCircleViewHeightConstraint;

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
@property NSLayoutConstraint *previousTrackCircleViewHeightConstraint;

/**
 The feedback generator for when the user changes tracks successfully.
 */
@property UISelectionFeedbackGenerator *feedbackGenerator;

@end

@implementation LMNowPlayingAnimationView

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		
		self.nextTrackCircleView = [LMNowPlayingAnimationCircle new];
		self.nextTrackCircleView.icon = LMIconNextTrack;
		self.nextTrackCircleView.direction = LMNowPlayingAnimationCircleDirectionClockwise;
		self.nextTrackCircleView.squareMode = self.squareMode;
		[self addSubview:self.nextTrackCircleView];
		
		self.nextTrackCircleViewLeadingConstraint = [self.nextTrackCircleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self];
		self.nextTrackCircleViewHeightConstraint = [self.nextTrackCircleView autoSetDimension:ALDimensionHeight toSize:100.0f];
		[self.nextTrackCircleView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.nextTrackCircleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.nextTrackCircleView];
		
		
		self.previousTrackCircleView = [LMNowPlayingAnimationCircle new];
		self.previousTrackCircleView.icon = LMIconPreviousTrack;
		self.previousTrackCircleView.direction = LMNowPlayingAnimationCircleDirectionCounterClockwise;
		self.previousTrackCircleView.squareMode = self.squareMode;
		[self addSubview:self.previousTrackCircleView];
		
		self.previousTrackCircleViewTrailingConstraint = [self.previousTrackCircleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self];
		self.previousTrackCircleViewHeightConstraint = [self.previousTrackCircleView autoSetDimension:ALDimensionHeight toSize:100.0f];
		[self.previousTrackCircleView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.previousTrackCircleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.previousTrackCircleView];
	}
}

- (LMNowPlayingAnimationViewResult)progress:(CGPoint)progressPoint fromStartingPoint:(CGPoint)startingPoint {
	BOOL isGoingToNextTrack = (startingPoint.x - progressPoint.x) > startingPoint.x;
	
	if(isGoingToNextTrack){
		self.nextTrackCircleViewLeadingConstraint.constant = progressPoint.x;
		self.previousTrackCircleViewTrailingConstraint.constant = 0;
		
		CGFloat halfWindowFrame = WINDOW_FRAME.size.width / 2.0;
		CGFloat progress = (MIN(fabs(progressPoint.x), (halfWindowFrame * 2.0)) / (halfWindowFrame * 2.0));
		
		NSLog(@"next. X %f - %f", progressPoint.x, progress);
		
		self.nextTrackCircleViewHeightConstraint.constant = self.squareMode ? self.frame.size.height : ((halfWindowFrame / 2.0) + (WINDOW_FRAME.size.width * progress));
		
		CGFloat circleProgress = progress * 2.0f;
		[self.nextTrackCircleView setProgress:MIN(1, circleProgress)];
		
		return (circleProgress >= 1.0f) ? LMNowPlayingAnimationViewResultSkipToNextComplete : LMNowPlayingAnimationViewResultSkipToNextIncomplete;
	}
	else{
		self.previousTrackCircleViewTrailingConstraint.constant = progressPoint.x;
		self.nextTrackCircleViewLeadingConstraint.constant = 0;
		
		CGFloat halfWindowFrame = WINDOW_FRAME.size.width / 2.0;
		CGFloat progress = (MIN(fabs(progressPoint.x), (halfWindowFrame * 2.0)) / (halfWindowFrame * 2.0));
		
		NSLog(@"previous. X %f - %f", progressPoint.x, progress);
		
		self.previousTrackCircleViewHeightConstraint.constant = self.squareMode ? self.frame.size.height : ((halfWindowFrame / 2.0) + (WINDOW_FRAME.size.width * progress));
		
		CGFloat circleProgress = progress * 2.0f;
		[self.previousTrackCircleView setProgress:MIN(1, 1 - circleProgress)];
		
		return (circleProgress >= 1.0f) ? LMNowPlayingAnimationViewResultGoToPreviousComplete : LMNowPlayingAnimationViewResultGoToPreviousIncomplete;
	}
}

- (void)finishAnimationWithResult:(LMNowPlayingAnimationViewResult)result acceptQuickGesture:(BOOL)acceptQuickGesture {
	[self layoutIfNeeded];
	
	BOOL gestureIncomplete = (result == LMNowPlayingAnimationViewResultSkipToNextIncomplete)
	|| (result == LMNowPlayingAnimationViewResultGoToPreviousIncomplete);
	if(gestureIncomplete && !acceptQuickGesture){
		[self cancelAnimation];
		return;
	}
	
	self.feedbackGenerator = [UISelectionFeedbackGenerator new];
	[self.feedbackGenerator prepare];
	[self.feedbackGenerator selectionChanged];
	
	BOOL skipToNext = (result == LMNowPlayingAnimationViewResultSkipToNextComplete) || (result == LMNowPlayingAnimationViewResultSkipToNextIncomplete);
	
	NSLayoutConstraint *heightConstraintToUse = skipToNext ? self.nextTrackCircleViewHeightConstraint : self.previousTrackCircleViewHeightConstraint;
	NSLayoutConstraint *sideConstraintToUse = skipToNext ? self.nextTrackCircleViewLeadingConstraint : self.previousTrackCircleViewTrailingConstraint;
	LMNowPlayingAnimationCircle *circleViewToUse = skipToNext ? self.nextTrackCircleView : self.previousTrackCircleView;
	
	heightConstraintToUse.constant = (WINDOW_FRAME.size.height * 2.0);
	sideConstraintToUse.constant = (skipToNext ? -1 : 1) * (WINDOW_FRAME.size.height + (WINDOW_FRAME.size.width / 2.0));
	
	[circleViewToUse setProgress:skipToNext ? 1.0f : 0.0f];
	
	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
	} completion:^(BOOL finished) {
		NSLog(@"Finished %d", finished);
		if(finished){
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^{
				[self layoutIfNeeded];
				
				heightConstraintToUse.constant = 100;
				sideConstraintToUse.constant = (skipToNext ? -1 : 1) * (WINDOW_FRAME.size.width + 105);
				
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
	
	self.nextTrackCircleViewHeightConstraint.constant = 100.0f;
	self.nextTrackCircleViewLeadingConstraint.constant = 0.0f;
	
	[self.nextTrackCircleView setProgress:0.0f animated:YES];
	
	
	self.previousTrackCircleViewHeightConstraint.constant = 100.0f;
	self.previousTrackCircleViewTrailingConstraint.constant = 0.0f;
	
	[self.previousTrackCircleView setProgress:1.0f animated:YES];
	

	[UIView animateWithDuration:0.3 animations:^{
		[self layoutIfNeeded];
	}];
}

@end
