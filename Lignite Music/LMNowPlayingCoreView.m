//
//  LMNowPlayingCoreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMNowPlayingAnimationView.h"
#import "LMButtonNavigationBar.h"
#import "LMNowPlayingCoreView.h"
#import "LMCoreViewController.h"
#import "LMNowPlayingView.h"
#import "NSTimer+Blocks.h"
#import "MBProgressHUD.h"
#import "LMSettings.h"

@interface LMNowPlayingCoreView()<UIGestureRecognizerDelegate, LMMusicPlayerDelegate, LMMusicQueueDelegate>

/**
 The now playing view which actually displays the now playing contents.
 */
@property LMNowPlayingView *nowPlayingView;
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

@implementation LMNowPlayingCoreView

@synthesize isOpen = _isOpen;

- (BOOL)isOpen {
	return _isOpen;
}

- (void)setIsOpen:(BOOL)isOpen {
	_isOpen = isOpen;
	
	BOOL disableIdleTimer = (isOpen && ![LMSettings screenShouldTimeoutWhenNowPlayingIsOpen]);
	[UIApplication sharedApplication].idleTimerDisabled = disableIdleTimer;
	
	LMCoreViewController *coreViewController = (LMCoreViewController*)self.rootViewController;
	coreViewController.navigationController.navigationBar.accessibilityElementsHidden = isOpen;
	coreViewController.landscapeNavigationBar.accessibilityElementsHidden = isOpen;
	coreViewController.buttonNavigationBar.accessibilityElementsHidden = isOpen;
	coreViewController.compactView.accessibilityElementsHidden = isOpen;
	coreViewController.titleView.accessibilityElementsHidden = isOpen;
}

- (void)reloadMusicTracks {
    [self.nowPlayingView changeMusicTrack:self.musicPlayer.nowPlayingTrack
									  withIndex:self.musicPlayer.queue.indexOfNowPlayingTrack];
}

- (void)theQueueChangedSoPleaseReloadThankYou {
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	} repeats:NO];
}

- (void)trackAddedToQueue:(LMMusicTrack *)trackAdded {
	[self theQueueChangedSoPleaseReloadThankYou];
}

- (void)trackRemovedFromQueue:(LMMusicTrack *)trackRemoved {
	[self theQueueChangedSoPleaseReloadThankYou];
}

- (void)trackMovedInQueue:(LMMusicTrack *)trackMoved {
	[self theQueueChangedSoPleaseReloadThankYou];
}

- (void)musicPlaybackModesDidChange:(LMMusicShuffleMode)shuffleMode repeatMode:(LMMusicRepeatMode)repeatMode {
	[self theQueueChangedSoPleaseReloadThankYou];
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
    [self reloadMusicTracks];
}

- (void)panNowPlaying:(UIPanGestureRecognizer *)recogniser {
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
//            [self.centreNowPlayingView panNowPlayingDown:recognizer];
            
            CGPoint translation = [recogniser translationInView:recogniser.view];
            
            //	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
            
            if(translation.y < 0){ //Moving upward
                NSLog(@"什麼鬼");
                self.topConstraint.constant = 0;
                return;
            }
            else{ //Moving downward
                self.topConstraint.constant = translation.y;
            }
            
            [self.superview layoutIfNeeded];
            
            if(recogniser.state == UIGestureRecognizerStateEnded){
                if((translation.y >= MAX(WINDOW_FRAME.size.width, WINDOW_FRAME.size.height)/14.0)){
                    self.topConstraint.constant = self.frame.size.height;
                    self.isOpen = NO;
                }
                else{
                    self.topConstraint.constant = 0.0;
                    self.isOpen = YES;
                }
                
                NSLog(@"Finished is open %d", self.isOpen);
                
                [UIView animateWithDuration:0.25 animations:^{
                    [self.superview layoutIfNeeded];
                } completion:^(BOOL finished) {
                    if(finished){
                        [UIView animateWithDuration:0.25 animations:^{
                            [self.rootViewController setNeedsStatusBarAppearanceUpdate];
                        }];
                    }
                }];
            }

            
//            NSLog(@"Sending to core (%@ %@)", NSStringFromCGPoint(translation), self.rootViewController);
            
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

- (void)restartTrack {
	[self.musicPlayer skipToBeginning];
	
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
	
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
        
        self.samplesArray = [NSMutableArray new];
        
        self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
        [self.musicPlayer addMusicDelegate:self];
		[self.musicPlayer.queue addDelegate:self];
        
        self.nowPlayingView = [LMNowPlayingView newAutoLayoutView];
        self.nowPlayingView.coreViewController = (LMCoreViewController*)self.rootViewController;
		self.nowPlayingView.backgroundColor = [UIColor whiteColor];
		self.nowPlayingView.nowPlayingCoreView = self;
        [self addSubview:self.nowPlayingView];
        
		[self.nowPlayingView autoPinEdgesToSuperviewEdges];
		
        
        UIPanGestureRecognizer *nowPlayingPanGesture =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panNowPlaying:)];
        nowPlayingPanGesture.delegate = self;
		nowPlayingPanGesture.maximumNumberOfTouches = 1;
        [self.nowPlayingView addGestureRecognizer:nowPlayingPanGesture];
	
		
		
		self.animationView = [LMNowPlayingAnimationView new];
		self.animationView.userInteractionEnabled = NO;
		[self addSubview:self.animationView];
		
		[self.animationView autoPinEdgesToSuperviewEdges];
	
		
		
		UISwipeGestureRecognizer *doubleFingerSwipeToRestartTrackGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(restartTrack)];
		[doubleFingerSwipeToRestartTrackGesture setNumberOfTouchesRequired:2];
		[doubleFingerSwipeToRestartTrackGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
		[self addGestureRecognizer:doubleFingerSwipeToRestartTrackGesture];
		
        
        //		LMMusicTrackCollection *currentCollection = self.musicPlayer.nowPlayingCollection;
        //		if(currentCollection == nil){
        //			
        //		}
        
        NSLog(@"Index of %ld", self.musicPlayer.queue.indexOfNowPlayingTrack);
        
        [self reloadMusicTracks];
		
		if([LMSettings debugInitialisationSounds]){
			AudioServicesPlaySystemSound(1258);
		}
    }
}

@end
