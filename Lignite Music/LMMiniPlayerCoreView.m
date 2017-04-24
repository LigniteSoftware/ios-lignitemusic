//
//  LMMiniPlayerCoreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/17/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButtonNavigationBar.h"
#import "LMMiniPlayerCoreView.h"
#import "LMCoreViewController.h"
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

/**
 The array of samples for determining which direction the gesture is headed in.
 */
@property NSMutableArray *samplesArray;

@end

@implementation LMMiniPlayerCoreView

- (void)loadMusicTracksBasedOffIndex:(NSInteger)indexOfCenter {
    if(indexOfCenter > self.musicPlayer.nowPlayingCollection.items.count){
        indexOfCenter = 0;
    }
    
	NSInteger nextTrackIndex = indexOfCenter+1;
	NSInteger previousTrackIndex = indexOfCenter-1;
	if(nextTrackIndex >= self.musicPlayer.nowPlayingCollection.count){
		nextTrackIndex = 0;
	}
	if(previousTrackIndex < 0){
		previousTrackIndex = self.musicPlayer.nowPlayingCollection.count-1;
	}
	
	[self.centerMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:indexOfCenter] withIndex:indexOfCenter];
	[self.leadingMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:nextTrackIndex]
									   withIndex:nextTrackIndex];
	[self.trailingMiniPlayerView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:previousTrackIndex]
										withIndex:previousTrackIndex];
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
    //Test code for calculating rates of the translations. Will break after one use
    static float amountOfTimes;
    static BOOL hasDoneThis;
    static NSTimeInterval startingTime;
    NSTimeInterval currentTime = [[NSDate new] timeIntervalSince1970];
    
    if(!hasDoneThis){
        hasDoneThis = YES;
        startingTime = [[NSDate new] timeIntervalSince1970];
    }
    
    amountOfTimes = amountOfTimes + 1.0;
    NSTimeInterval timeDifference = currentTime-startingTime;
    float rate = amountOfTimes/timeDifference;
    
    int threshhold = 3;
    
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    static BOOL userIsGoingInYAxis;
    
    [self.samplesArray addObject:NSStringFromCGPoint(translation)];
    
    if(self.samplesArray.count < threshhold){
        return;
    }
    else if(self.samplesArray.count == threshhold){
        CGFloat changeInX = 0;
        CGFloat changeInY = 0;
        //Calculate which direction the user is trying to send shit
        for(NSString *sampleString in self.samplesArray){
            CGPoint sample = CGPointFromString(sampleString);
            changeInX += sample.x;
            changeInY += sample.y;
        }
        
        changeInX = changeInX/self.samplesArray.count;
        changeInY = changeInY/self.samplesArray.count;
        
        userIsGoingInYAxis = fabs(changeInY) > fabs(changeInX);
    }
    else{
        if(userIsGoingInYAxis){
            NSLog(@"Sending to core (%@)", NSStringFromCGPoint(translation));
            
            LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
            [coreViewController panNowPlayingUp:recognizer];
            
            if(translation.y > 0){
                LMButtonNavigationBar *navigationBar = (LMButtonNavigationBar*)self.buttonNavigationBar;
                [navigationBar handlePan:recognizer];
            }
            
            if(recognizer.state == UIGestureRecognizerStateEnded){
                self.samplesArray = [NSMutableArray new];
            }
        }
        else{
            if(!self.musicPlayer.nowPlayingTrack){
                return;
            }
            else{
                NSLog(@"Now playing %@", self.musicPlayer.nowPlayingTrack.title);
            }
            
            NSLog(@"Translation %@ (%f/sec)", NSStringFromCGPoint(translation), rate);
            
            CGFloat totalTranslation = translation.x;
            
            CGFloat newAlpha = 1.0 - fabs(totalTranslation)/(self.centerMiniPlayerView.frame.size.width/2);
            
            if(newAlpha < 0){
                newAlpha = 0;
            }
            
            self.centerMiniPlayerView.alpha = newAlpha;
            self.leadingMiniPlayerView.alpha = 1.0 - newAlpha;
            self.trailingMiniPlayerView.alpha = self.leadingMiniPlayerView.alpha;
            
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
                
                self.samplesArray = [NSMutableArray new];
                
                [UIView animateWithDuration:0.15 animations:^{
                    if(rebuildConstraints){
                        self.centerMiniPlayerView.alpha = 0;
                        self.leadingMiniPlayerView.alpha = nextSong ? 1 : 0;
                        self.trailingMiniPlayerView.alpha = nextSong ? 0 : 1;
                    }
                    else{
                        self.centerMiniPlayerView.alpha = 1;
                        self.leadingMiniPlayerView.alpha = 0;
                        self.trailingMiniPlayerView.alpha = 0;
                    }
                    [self layoutIfNeeded];
                } completion:^(BOOL finished) {
                    if(finished){
                        if(rebuildConstraints){
                            [self rebuildConstraints:nextSong];
                            
                            self.skipToNextTrackOnTimerFire = nextSong;
                            
                            self.skipTracksTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
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
    }
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Hey");
		
		self.backgroundColor = [UIColor whiteColor];
		
		self.clipsToBounds = YES;
		
		self.otherConstraints = [NSMutableArray new];
        self.samplesArray = [NSMutableArray new];
		
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
		
		self.centerMiniPlayerView.clipsToBounds = YES;
		self.leadingMiniPlayerView.clipsToBounds = YES;
		self.trailingMiniPlayerView.clipsToBounds = YES;
		
		NSLog(@"Index of %ld", self.musicPlayer.indexOfNowPlayingTrack);
		
		[self loadMusicTracksBasedOffIndex:self.musicPlayer.indexOfNowPlayingTrack];
	}
}

@end
