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
#import "LMMusicPlayer.h"

@interface LMMiniPlayerCoreView()<UIGestureRecognizerDelegate, LMMusicPlayerDelegate>

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

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 Whether or not there is a next track.
 */
@property BOOL hasNextTrack;

/**
 Whether or not there is a previous track from the current playing.
 */
@property BOOL hasPreviousTrack;

/**
 The timer to skip to the next or previous track.
 */
@property NSTimer *skipTracksTimer;

/**
 Whether or not to skip to next when the timer fires. NO for previous track.
 */
@property BOOL skipToNextTrackOnTimerFire;

/**
 The leading constraint for the center miniplayer. This is the constraint which the pan gesture uses for the motion of views.
 */
@property NSLayoutConstraint *miniPlayerLeadingConstraint;

/**
 The other constraints, will handle this soon.
 */
@property NSMutableArray *otherConstraints;

@end

@implementation LMMiniPlayerCoreView

- (void)loadMusicTracksBasedOffIndex:(NSInteger)indexOfCenter {
	NSInteger nextTrackIndex = indexOfCenter+1;
	NSInteger previousTrackIndex = indexOfCenter-1;
	self.hasNextTrack = (nextTrackIndex < self.musicPlayer.nowPlayingCollection.count);
	if(!self.hasNextTrack){
		nextTrackIndex = -1;
	}
	self.hasPreviousTrack = previousTrackIndex > -1;
	
	[self.centerMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:indexOfCenter] withIndex:indexOfCenter];
	if(self.hasNextTrack){
		[self.leadingMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:nextTrackIndex]
										   withIndex:nextTrackIndex];
	}
	if(self.hasPreviousTrack){
		[self.trailingMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:previousTrackIndex]
											withIndex:previousTrackIndex];
	}
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	NSInteger nowPlayingTrackIndex = self.musicPlayer.indexOfNowPlayingTrack;
	[self loadMusicTracksBasedOffIndex:nowPlayingTrackIndex];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (void)skipTracks {
//	self.skipToNextTrackOnTimerFire ? [self.musicPlayer skipToNextTrack] : [self.musicPlayer skipToPreviousItem];
	[self.musicPlayer setNowPlayingTrack:self.centerMiniPlayerView.loadedTrack];
}

- (void)rebuildConstraints:(BOOL)leadingIsCenter {
	NSArray *oldMiniPlayers = @[ self.trailingMiniPlayerView, self.centerMiniPlayerView, self.leadingMiniPlayerView ];
	
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
	
	[self loadMusicTracksBasedOffIndex:self.centerMiniPlayerView.loadedTrackIndex];
	
	[self layoutIfNeeded];
	
	NSLog(@"Constraints rebuilt.");
}

- (void)panMiniPlayer:(UIPanGestureRecognizer *)recognizer {
	if(!self.musicPlayer.nowPlayingTrack){
		return;
	}
	else{
		NSLog(@"Now playing %@", self.musicPlayer.nowPlayingTrack.title);
	}
	
	CGPoint translation = [recognizer translationInView:recognizer.view];

	CGFloat totalTranslation = translation.x;
	
	//	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
	
	if(self.skipTracksTimer){
		[self.skipTracksTimer invalidate];
		self.skipTracksTimer = nil;
	}
	
	self.miniPlayerLeadingConstraint.constant = totalTranslation;
	
	[self layoutIfNeeded];

	if(recognizer.state == UIGestureRecognizerStateEnded){		
		[self layoutIfNeeded];
		
		BOOL nextSong = translation.x < -self.frame.size.width/4;
		BOOL rebuildConstraints = YES;
		
		if(translation.x > self.frame.size.width/4){
			NSLog(@"Slide forward");
			self.miniPlayerLeadingConstraint.constant = self.frame.size.width;
		}
		else if(nextSong){
			NSLog(@"Slide backward");
			self.miniPlayerLeadingConstraint.constant = -self.frame.size.width;
		}
		else{
			NSLog(@"Reset to center");
			self.miniPlayerLeadingConstraint.constant = 0;
			rebuildConstraints = NO;
		}
		
		[UIView animateWithDuration:0.15 animations:^{
			[self layoutIfNeeded];
		} completion:^(BOOL finished) {
			if(finished){
				if(rebuildConstraints){
					[self rebuildConstraints:nextSong];
					
					self.skipToNextTrackOnTimerFire = nextSong;
					
					self.skipTracksTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
																			target:self
																		  selector:@selector(skipTracks)
																		  userInfo:nil
																		   repeats:NO];
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
		
		self.backgroundColor = [UIColor whiteColor];
		
		self.otherConstraints = [NSMutableArray new];
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		
		self.centerMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
//		self.centerMiniPlayerView.backgroundColor = [UIColor orangeColor];
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
//		self.trailingMiniPlayerView.backgroundColor = [UIColor yellowColor];
		[self addSubview:self.trailingMiniPlayerView];
		
		[self.otherConstraints addObject:[self.trailingMiniPlayerView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.centerMiniPlayerView]];
		[self.trailingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.trailingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.trailingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		[self.trailingMiniPlayerView setup];
		
		UIPanGestureRecognizer *miniPlayerTrailingPanGesture =
		[[UIPanGestureRecognizer alloc] initWithTarget:self
												action:@selector(panMiniPlayer:)];
		miniPlayerTrailingPanGesture.delegate = self;
		[self.trailingMiniPlayerView addGestureRecognizer:miniPlayerTrailingPanGesture];
		
		
		self.leadingMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
//		self.leadingMiniPlayerView.backgroundColor = [UIColor redColor];
		[self addSubview:self.leadingMiniPlayerView];
		
		[self.otherConstraints addObject:[self.leadingMiniPlayerView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.centerMiniPlayerView]];
		[self.leadingMiniPlayerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		[self.leadingMiniPlayerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.leadingMiniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		[self.leadingMiniPlayerView setup];
		
		UIPanGestureRecognizer *miniPlayerLeadingPanGesture =
		[[UIPanGestureRecognizer alloc] initWithTarget:self
												action:@selector(panMiniPlayer:)];
		miniPlayerLeadingPanGesture.delegate = self;
		[self.leadingMiniPlayerView addGestureRecognizer:miniPlayerLeadingPanGesture];

//		LMMusicTrackCollection *currentCollection = self.musicPlayer.nowPlayingCollection;
//		if(currentCollection == nil){
//			
//		}
		
		NSLog(@"Index of %ld", self.musicPlayer.indexOfNowPlayingTrack);
		
		[self loadMusicTracksBasedOffIndex:self.musicPlayer.indexOfNowPlayingTrack];
	}
}

@end
