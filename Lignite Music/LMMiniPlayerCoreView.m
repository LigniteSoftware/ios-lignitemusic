//
//  LMMiniPlayerCoreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/17/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMiniPlayerCoreView.h"
#import "LMMiniPlayerView.h"

@interface LMMiniPlayerCoreView()<UIGestureRecognizerDelegate>

/**
 The miniplayer which goes in the back.
 */
@property LMMiniPlayerView *trailingMiniPlayerView;

/**
 The miniplayer which goes in the middle.
 */
@property LMMiniPlayerView *centerMiniPlayerView;

/**
 The miniplayer which goes in the front.
 */
@property LMMiniPlayerView *leadingMiniPlayerView;


@property NSLayoutConstraint *miniPlayerLeadingConstraint;
@property NSMutableArray *otherConstraints;

@end

@implementation LMMiniPlayerCoreView

- (void)rebuildConstraints:(BOOL)leadingIsCenter {
	for(UIGestureRecognizer *gestureRecognizer in self.centerMiniPlayerView.gestureRecognizers){
		if([gestureRecognizer class] == [UIPanGestureRecognizer class]){
			[self.centerMiniPlayerView removeGestureRecognizer:gestureRecognizer];
			NSLog(@"Removed center miniplayer gesture recognizer");
		}
	}
	
	NSArray *oldMiniPlayers = @[ self.trailingMiniPlayerView, self.centerMiniPlayerView, self.leadingMiniPlayerView ];
//	for(LMMiniPlayerView *miniPlayer in oldMiniPlayers){
//		for(NSLayoutConstraint *constraint in miniPlayer.constraints){
//			[miniPlayer removeConstraint:constraint];
//			NSLog(@"Removed miniplayer constraint");
//		}
//	}
	
//	[self.miniPlayerLeadingConstraint autoRemove];
//	for(NSLayoutConstraint *constraint in self.otherConstraints){
//		[constraint autoRemove];
//	}
//	
//	self.otherConstraints = [NSMutableArray new];
	
	[self.centerMiniPlayerView removeFromSuperview];
	[self.leadingMiniPlayerView removeFromSuperview];
	[self.trailingMiniPlayerView removeFromSuperview];
	
	// [ 0 1 2 ] swipe -> 0 [ 1 2 * ] convert -> [ 1 2 0 ]
	if(leadingIsCenter){
		self.trailingMiniPlayerView = oldMiniPlayers[1];
		self.centerMiniPlayerView = oldMiniPlayers[2];
		self.leadingMiniPlayerView = oldMiniPlayers[0];
	}
	// [ 0 1 2 ] swipe -> [ * 0 1 ] 2 convert -> [ 2 0 1 ]
	else{
		self.trailingMiniPlayerView = oldMiniPlayers[2];
		self.centerMiniPlayerView = oldMiniPlayers[0];
		self.leadingMiniPlayerView = oldMiniPlayers[1];
	}
	
//	NSArray *newMiniPlayers = @[ self.trailingMiniPlayerView, self.centerMiniPlayerView, self.leadingMiniPlayerView ];
//	for(LMMiniPlayerView *miniPlayer in newMiniPlayers){
//		for(NSLayoutConstraint *constraint in self.constraints){
//			if(constraint.firstItem == miniPlayer || constraint.secondItem == miniPlayer){
//				[self removeConstraint:constraint];
//				NSLog(@"Removed self constraint");
//			}
//		}
//	}
	
	UIPanGestureRecognizer *miniPlayerPanGesture =
	[[UIPanGestureRecognizer alloc] initWithTarget:self
											action:@selector(panMiniPlayer:)];
	miniPlayerPanGesture.delegate = self;
	[self.centerMiniPlayerView addGestureRecognizer:miniPlayerPanGesture];
	
	[self addSubview:self.centerMiniPlayerView];
	[self addSubview:self.leadingMiniPlayerView];
	[self addSubview:self.trailingMiniPlayerView];
	
	self.miniPlayerLeadingConstraint = [self.centerMiniPlayerView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.centerMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.centerMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.centerMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	
	[self.otherConstraints addObject:[self.trailingMiniPlayerView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.centerMiniPlayerView]];
	[self.trailingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.trailingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.trailingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	
	[self.otherConstraints addObject:[self.leadingMiniPlayerView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.centerMiniPlayerView]];
	[self.leadingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.leadingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.leadingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	
	[self layoutIfNeeded];
	
	NSLog(@"Constraints rebuilt.");
}

- (void)panMiniPlayer:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:recognizer.view];

	CGFloat totalTranslation = translation.x;
	
	//	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	self.miniPlayerLeadingConstraint.constant = totalTranslation;
	
	[self layoutIfNeeded];

	if(recognizer.state == UIGestureRecognizerStateEnded){		
		[self layoutIfNeeded];
		
		BOOL rebuildConstraints = YES;
		
		if(translation.x > self.frame.size.width/4){
			NSLog(@"Slide forward");
			self.miniPlayerLeadingConstraint.constant = self.frame.size.width;
		}
		else if(translation.x < -self.frame.size.width/4){
			NSLog(@"Slide backward");
			self.miniPlayerLeadingConstraint.constant = -self.frame.size.width;
		}
		else{
			NSLog(@"Reset to center");
			self.miniPlayerLeadingConstraint.constant = 0;
			rebuildConstraints = NO;
		}
		
		[UIView animateWithDuration:0.25 animations:^{
			[self layoutIfNeeded];
		} completion:^(BOOL finished) {
			if(finished){
				if(rebuildConstraints){
					[self rebuildConstraints:translation.x < -self.frame.size.width/4];
				}
				NSLog(@"Done.");
			}
		}];
	}
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Hey");
		
		self.backgroundColor = [UIColor blueColor];
		
		self.otherConstraints = [NSMutableArray new];
		
		self.centerMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		self.centerMiniPlayerView.backgroundColor = [UIColor orangeColor];
		[self addSubview:self.centerMiniPlayerView];
		
		self.miniPlayerLeadingConstraint = [self.centerMiniPlayerView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.centerMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.centerMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.centerMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		[self.centerMiniPlayerView setup];
		
		UIPanGestureRecognizer *miniPlayerPanGesture =
		[[UIPanGestureRecognizer alloc] initWithTarget:self
												action:@selector(panMiniPlayer:)];
		miniPlayerPanGesture.delegate = self;
		[self.centerMiniPlayerView addGestureRecognizer:miniPlayerPanGesture];
		
		
		self.trailingMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		self.trailingMiniPlayerView.backgroundColor = [UIColor yellowColor];
		[self addSubview:self.trailingMiniPlayerView];
		
		[self.otherConstraints addObject:[self.trailingMiniPlayerView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.centerMiniPlayerView]];
		[self.trailingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.trailingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.trailingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		[self.trailingMiniPlayerView setup];
		
		
		self.leadingMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		self.leadingMiniPlayerView.backgroundColor = [UIColor redColor];
		[self addSubview:self.leadingMiniPlayerView];
		
		[self.otherConstraints addObject:[self.leadingMiniPlayerView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.centerMiniPlayerView]];
		[self.leadingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.leadingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.leadingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		[self.leadingMiniPlayerView setup];

	}
}

@end
