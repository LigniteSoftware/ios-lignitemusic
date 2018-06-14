//
//  LMMiniPlayerCoreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/17/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMNowPlayingAnimationView.h"
#import "LMButtonNavigationBar.h"
#import "LMMiniPlayerCoreView.h"
#import "LMCoreViewController.h"
#import "LMMiniPlayerView.h"
#import "NSTimer+Blocks.h"
#import "MBProgressHUD.h"
#import "LMMusicPlayer.h"

@interface LMMiniPlayerCoreView()<UIGestureRecognizerDelegate, LMMusicPlayerDelegate, LMLayoutChangeDelegate, LMMusicQueueDelegate>

/**
 The miniplayer which goes in the back.
 */
@property LMMiniPlayerView *trailingMiniPlayerView;

/**
 The miniplayer which goes in the middle.
 */
@property LMMiniPlayerView *centreMiniPlayerView;

/**
 The miniplayer which goes in the front.
 */
@property LMMiniPlayerView *leadingMiniPlayerView;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The array of samples for determining which direction the gesture is headed in.
 */
@property NSMutableArray *samplesArray;

/**
 The animation view for transitioning between songs.
 */
@property LMNowPlayingAnimationView *animationView;

/**
 The start time of the swipe gesture for changing songs.
 */
@property NSTimeInterval songChangeSwipeGestureStartTime;

/**
 The start position of the song change swipe gesture.
 */
@property CGPoint songChangeSwipeGestureStartPosition;

@end

@implementation LMMiniPlayerCoreView

- (void)reloadMusicTracks {
	[self.centreMiniPlayerView reload];
}

- (void)trackAddedToQueue:(LMMusicTrack *)trackAdded {
	[self reloadMusicTracks];
}

- (void)trackRemovedFromQueue:(LMMusicTrack *)trackRemoved {
	[self reloadMusicTracks];
}

- (void)trackMovedInQueue:(LMMusicTrack *)trackMoved {
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	} repeats:NO];
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	[self reloadMusicTracks];
}

- (void)queueCompletelyChanged {
	[self reloadMusicTracks];
}

- (void)queueBegan {
	[self reloadMusicTracks];
}

- (void)queueEnded {
	[self reloadMusicTracks];
}

- (void)panMiniPlayer:(UIPanGestureRecognizer *)recogniser {
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
    
    CGPoint translation = [recogniser translationInView:recogniser.view];
	
	if(self.songChangeSwipeGestureStartTime < 1){
		NSLog(@"\n\nSTART\n\n");
		
		self.songChangeSwipeGestureStartTime = [[NSDate new] timeIntervalSince1970];
		self.songChangeSwipeGestureStartPosition = translation;
	}
    
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
//            NSLog(@"Sending to core (%@)", NSStringFromCGPoint(translation));
			
            LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
            [coreViewController panNowPlayingUp:recogniser];
            
            if(recogniser.state == UIGestureRecognizerStateEnded){
                self.samplesArray = [NSMutableArray new];
				self.songChangeSwipeGestureStartTime = 0.0f;
				self.songChangeSwipeGestureStartPosition = CGPointMake(0, 0);
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
            
			CGPoint pointInView = [recogniser translationInView:recogniser.view];
			
			LMNowPlayingAnimationViewResult animationResult = [self.animationView progress:pointInView fromStartingPoint:self.songChangeSwipeGestureStartPosition];
			
			NSLog(@"State %d change %d", (int)recogniser.state, (int)animationResult);
			
			NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
			
			switch(recogniser.state){
				case UIGestureRecognizerStateEnded: {
					self.samplesArray = [NSMutableArray new];
					
					NSTimeInterval timeDifference = (now - self.songChangeSwipeGestureStartTime);
					CGFloat distanceTravelled = fabs(pointInView.x - self.songChangeSwipeGestureStartPosition.x);
					CGFloat pixelsPerSecond = (distanceTravelled / timeDifference);
					
					BOOL acceptQuickGesture = (pixelsPerSecond > 700.0f) && (distanceTravelled > 25.0f);
					
					NSLog(@"Distance travelled: %f points in %f seconds (%f px/s)", distanceTravelled, timeDifference, pixelsPerSecond);
					NSLog(acceptQuickGesture ? @"ACCEPTED (actual result %d)" : @"Failed (actual result %d)", (int)animationResult);
					
					[self.animationView finishAnimationWithResult:animationResult acceptQuickGesture:acceptQuickGesture];
					
					BOOL gestureIncomplete = (animationResult == LMNowPlayingAnimationViewResultSkipToNextIncomplete) || (animationResult == LMNowPlayingAnimationViewResultGoToPreviousIncomplete);
					
					if(!gestureIncomplete || acceptQuickGesture){
						BOOL skipToNext = (animationResult == LMNowPlayingAnimationViewResultSkipToNextComplete) || (animationResult == LMNowPlayingAnimationViewResultSkipToNextIncomplete);
						skipToNext ? [self.musicPlayer skipToNextTrack] : [self.musicPlayer skipToPreviousTrack];
					}
					
					self.songChangeSwipeGestureStartTime = 0.0f;
					self.songChangeSwipeGestureStartPosition = CGPointMake(0, 0);
					NSLog(@"\n\nEND\n\n");
					break;
				}
				default:
					break;
			}
        }
    }
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self layoutIfNeeded];
	}];
}

- (void)restartTrack {
	[self.musicPlayer skipToBeginning];
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:coreViewController.navigationController.view
											  animated:YES];
	
	hud.mode = MBProgressHUDModeCustomView;
	UIImage *image = [[UIImage imageNamed:@"icon_rewind"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	hud.customView = [[UIImageView alloc] initWithImage:image];
	hud.square = YES;
	hud.userInteractionEnabled = NO;
	hud.label.text = NSLocalizedString(@"TrackRestarted", nil);
	
	[hud hideAnimated:YES afterDelay:2.0f];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		NSLog(@"Hey");
		
		self.backgroundColor = [UIColor whiteColor];
		
		self.clipsToBounds = YES;
		
        self.samplesArray = [NSMutableArray new];
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		[self.musicPlayer.queue addDelegate:self];
		
		self.centreMiniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		self.centreMiniPlayerView.rootViewController = self.rootViewController;
//		self.centerMiniPlayerView.backgroundColor = [UIColor orangeColor];
		[self addSubview:self.centreMiniPlayerView];
				
		[self.centreMiniPlayerView autoPinEdgesToSuperviewEdges];
				
		UIPanGestureRecognizer *miniPlayerPanGesture =
		[[UIPanGestureRecognizer alloc] initWithTarget:self
												action:@selector(panMiniPlayer:)];
		miniPlayerPanGesture.delegate = self;
		miniPlayerPanGesture.maximumNumberOfTouches = 1;
		[self.centreMiniPlayerView addGestureRecognizer:miniPlayerPanGesture];
		
		
		
		self.animationView = [LMNowPlayingAnimationView new];
		self.animationView.userInteractionEnabled = NO;
		self.animationView.squareMode = YES;
		[self addSubview:self.animationView];
		
		[self.animationView autoPinEdgesToSuperviewEdges];
		
		
		
		UISwipeGestureRecognizer *doubleFingerSwipeToRestartTrackGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(restartTrack)];
		[doubleFingerSwipeToRestartTrackGesture setNumberOfTouchesRequired:2];
		[doubleFingerSwipeToRestartTrackGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
		[self addGestureRecognizer:doubleFingerSwipeToRestartTrackGesture];

		
		NSLog(@"Index of %ld", self.musicPlayer.queue.indexOfNowPlayingTrack);
		
		[self reloadMusicTracks];
	}
}

@end
