//
//  LMBrowsingAssistantView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingAssistantView.h"
#import "LMMiniPlayerView.h"
#import "LMColour.h"

@interface LMBrowsingAssistantView()

@property UIView *currentElementBackgroundView, *selectorBackgroundView;

@property UIView *grabberView;
@property UIImageView *grabberImageView;

@property LMMiniPlayerView *miniPlayerView;

@property CGPoint originalPoint, currentPoint;

@end

@implementation LMBrowsingAssistantView

- (void)moveContentsUp {
	[[self superview] layoutIfNeeded];
	self.textBackgroundConstraint.constant = 0;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y);
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.4 initialSpringVelocity:0.0f
						options:0 animations:^{
							[[self superview] layoutIfNeeded];
						} completion:nil];
}

- (void)moveContentsDown {
	[[self superview] layoutIfNeeded];
	self.textBackgroundConstraint.constant = self.currentElementBackgroundView.frame.size.height-10;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.textBackgroundConstraint.constant);
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.4 initialSpringVelocity:0.0f
						options:0 animations:^{
							[[self superview] layoutIfNeeded];
						} completion:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.frame.origin;
		self.currentPoint = self.frame.origin;
				NSLog(@"Set original point to %@", NSStringFromCGPoint(self.originalPoint));
	}
	float totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
	NSLog(@"%f", totalTranslation);
	
	if(totalTranslation < 0){
		self.textBackgroundConstraint.constant = -sqrt(-totalTranslation);
//		if(self.grabberView.frame.origin.y + self.textBackgroundConstraint.constant >= self.albumArtView.frame.size.height-2){
//			self.textBackgroundConstraint.constant = self.albumArtView.frame.size.height-2-self.textBackgroundView.frame.origin.y;
//		}
	}
	else{
		self.textBackgroundConstraint.constant = totalTranslation;
	}
	
	[[self superview] layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		//NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		
		if((translation.y >= 0)){
			[self moveContentsDown];
		}
		else if((translation.y < 0)){
			[self moveContentsUp];
		}
	}
	
	/*
	 recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
	 recognizer.view.center.y + translation.y);
	 [recognizer setTranslation:CGPointMake(0, 0) inView:self.textBackgroundView];
	 */
 
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	
//	self.selectorBackgroundView = [UIView newAutoLayoutView];
//	self.selectorBackgroundView.backgroundColor = [UIColor orangeColor];
//	[self addSubview:self.selectorBackgroundView];
//	
//	[self.selectorBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
//	[self.selectorBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
//	[self.selectorBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
//	[self.selectorBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/3.0)];
	
	self.currentElementBackgroundView = [UIView newAutoLayoutView];
	self.currentElementBackgroundView.backgroundColor = [UIColor whiteColor];
	[self addSubview:self.currentElementBackgroundView];
	
	[self.currentElementBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.currentElementBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.currentElementBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[self.currentElementBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:/*(2.0/3.0)**/(5.25/6.0)];
	
	self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
	self.miniPlayerView.musicPlayer = self.musicPlayer;
	[self.currentElementBackgroundView addSubview:self.miniPlayerView];
	
	[self.miniPlayerView autoPinEdgesToSuperviewEdges];
	[self.miniPlayerView autoCenterInSuperview];
	
	[self.miniPlayerView setup];
	
	self.currentElementBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	self.currentElementBackgroundView.backgroundColor = [UIColor whiteColor];
	self.currentElementBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.currentElementBackgroundView.layer.shadowOpacity = 0.25f;
	self.currentElementBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
	self.currentElementBackgroundView.layer.masksToBounds = NO;
	self.currentElementBackgroundView.layer.shadowRadius = 5;
	
	self.grabberView = [UIView newAutoLayoutView];
	self.grabberView.backgroundColor = [LMColour ligniteRedColour];
	self.grabberView.layer.masksToBounds = YES;
	self.grabberView.layer.cornerRadius = 10.0;
	[self addSubview:self.grabberView];
	
	[self.grabberView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.grabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
	[self.grabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.currentElementBackgroundView withOffset:30];
	[self.grabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	
	UIPanGestureRecognizer *moveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
	[self.grabberView addGestureRecognizer:moveRecognizer];
	
	self.grabberImageView = [UIImageView newAutoLayoutView];
	self.grabberImageView.image = [UIImage imageNamed:@"triple_dots.png"];
	self.grabberImageView.contentMode = UIViewContentModeScaleAspectFit;
	[self addSubview:self.grabberImageView];
	
	[self.grabberImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.grabberImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.grabberView withMultiplier:(1.0/2.0)];
	[self.grabberImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.currentElementBackgroundView];
	[self.grabberImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	
	[self insertSubview:self.currentElementBackgroundView aboveSubview:self.grabberView];
	
	NSLog(@"Setup.");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
