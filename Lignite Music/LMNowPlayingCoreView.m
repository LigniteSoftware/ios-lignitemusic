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
#import "LMColour.h"

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

//For volume control
@property MPVolumeView *systemVolumeView;
@property UISlider *systemVolumeViewSlider;
@property UIView *volumeView;
@property NSLayoutConstraint *volumeViewTopConstraint;
@property UIView *volumePercentageBackgroundView;
@property NSLayoutConstraint *volumePercentageBackgroundViewTopConstraint;
@property UILabel *volumePercentageLabel;

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
    [self.nowPlayingView reload];
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
//    NSTimeInterval currentTime = [[NSDate new] timeIntervalSince1970];
	
    if(!hasDoneThis){
        hasDoneThis = YES;
        startingTime = [[NSDate new] timeIntervalSince1970];
    }
    
    amountOfTimes = amountOfTimes + 1.0;
//    NSTimeInterval timeDifference = currentTime-startingTime;
//    float rate = amountOfTimes/timeDifference;
	
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
			
			if(self.nowPlayingView.nowPlayingQueueOpen){
				return;
			}
            
//            NSLog(@"Translation %@ (%f/sec)", NSStringFromCGPoint(translation), rate);
			
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

- (void)changeVolumeGesture:(UIPanGestureRecognizer*)recogniser {
	static float amountOfTimes;
	static BOOL executedXGesture;
	static float startingVolume;
	static NSTimeInterval startingTime;
	NSTimeInterval currentTime = [[NSDate new] timeIntervalSince1970];
	
	if(startingTime == 0){
		startingTime = [[NSDate new] timeIntervalSince1970];
		startingVolume = self.systemVolumeViewSlider.value;
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
//			NSLog(@"Y axis");
			
			CGPoint centrePoint = CGPointFromString(self.samplesArray.firstObject);
			CGPoint latestPoint = CGPointFromString(self.samplesArray.lastObject);
			
			CGFloat location = [recogniser locationInView:self].y;
			
			NSLog(@"Constant %f location %f frame %@ centre %@ latest %@", self.volumeViewTopConstraint.constant, location, NSStringFromCGRect(self.frame), NSStringFromCGPoint(centrePoint), NSStringFromCGPoint(latestPoint));
			
			if(self.samplesArray.count == (threshhold + 1)){
				[UIView animateWithDuration:0.3 animations:^{
					self.volumeView.alpha = 0.75f;
				}];
			}
			
			CGFloat distanceFromCentre = (centrePoint.y - latestPoint.y);
			CGFloat volumeScreenFactor = (self.frame.size.height * 0.95) * 0.06;
			CGFloat differenceInVolume = (distanceFromCentre / volumeScreenFactor) / 10.0;
			CGFloat newVolume = startingVolume + differenceInVolume;
			if(newVolume < 0){
				newVolume = 0.0;
			}
			else if(newVolume > 1.0){
				newVolume = 1.0;
			}
			
			self.volumeViewTopConstraint.constant = self.frame.size.height - (newVolume * self.frame.size.height);
			
			self.volumePercentageLabel.text = [NSString stringWithFormat:@"%.00f%%", ceilf(newVolume * 100.0f)];
			
			BOOL backgroundViewIsInSafeZone =
						((self.frame.size.height - self.volumeViewTopConstraint.constant)
					   > self.volumePercentageBackgroundView.frame.size.height);
			
			if(backgroundViewIsInSafeZone
			   && (self.volumePercentageBackgroundViewTopConstraint.constant < 0)){
				
				[self layoutIfNeeded];
				
				self.volumePercentageBackgroundViewTopConstraint.constant = 20.0f;
				
				[UIView animateWithDuration:0.3 animations:^{
					self.volumePercentageBackgroundView.backgroundColor = [UIColor clearColor];
					
					[self layoutIfNeeded];
				}];
			}
			else if(self.volumePercentageBackgroundViewTopConstraint.constant > 0
					&& !backgroundViewIsInSafeZone){
				[self layoutIfNeeded];
				
				self.volumePercentageBackgroundViewTopConstraint.constant =
					-self.volumePercentageBackgroundView.frame.size.height + 2;
				
				[UIView animateWithDuration:0.3 animations:^{
					self.volumePercentageBackgroundView.backgroundColor = self.volumeView.backgroundColor;
					
					[self layoutIfNeeded];
				}];
			}
			
//			NSLog(@"Distance from centre: %f, factor %f, starting %f, difference in volume %f, new volume %f", distanceFromCentre, volumeScreenFactor, startingVolume, differenceInVolume, newVolume);
		
			
			[self.systemVolumeViewSlider setValue:newVolume animated:YES];
			[self.systemVolumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
		
			if(recogniser.state == UIGestureRecognizerStateEnded){
				self.samplesArray = [NSMutableArray new];
				self.songChangeSwipeGestureStartTime = 0.0f;
				self.songChangeSwipeGestureStartPosition = CGPointMake(0, 0);
				amountOfTimes = 0;
				startingTime = 0;
				NSLog(@"Ended");
				
				[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
					[UIView animateWithDuration:0.3 animations:^{
						self.volumeView.alpha = 0.0f;
					}];
				} repeats:NO];
			}
		}
		else{
			NSLog(@"X axis rate %f samples %d", rate, (int)self.samplesArray.count);
			
			if(self.samplesArray.count >= 5 && !executedXGesture){
				CGFloat changeInX = 0;
				
				for(NSString *sampleString in self.samplesArray){
					CGPoint sample = CGPointFromString(sampleString);
					changeInX += sample.x;
				}
				
				if(changeInX < -500){
					[self.musicPlayer skipToBeginning];
					
					MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
					
					hud.mode = MBProgressHUDModeCustomView;
					UIImage *image = [[UIImage imageNamed:@"icon_rewind"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					hud.customView = [[UIImageView alloc] initWithImage:image];
					hud.square = YES;
					hud.userInteractionEnabled = NO;
					hud.label.text = NSLocalizedString(@"TrackRestarted", nil);
					
					[hud hideAnimated:YES afterDelay:2.0f];
					
					executedXGesture = YES;
				}
				
				NSLog(@"Change in X %f", changeInX);
			}
			
			if(recogniser.state == UIGestureRecognizerStateEnded){
				self.samplesArray = [NSMutableArray new];
				self.songChangeSwipeGestureStartTime = 0.0f;
				self.songChangeSwipeGestureStartPosition = CGPointMake(0, 0);
				amountOfTimes = 0;
				startingTime = 0;
				executedXGesture = NO;
				NSLog(@"Ended");
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
		
		
		
		UIPanGestureRecognizer *doubleFingerVolumeGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(changeVolumeGesture:)];
		[doubleFingerVolumeGesture setMinimumNumberOfTouches:2];
		[self addGestureRecognizer:doubleFingerVolumeGesture];
		
        
        //		LMMusicTrackCollection *currentCollection = self.musicPlayer.nowPlayingCollection;
        //		if(currentCollection == nil){
        //			
        //		}
        
        NSLog(@"Index of %ld", self.musicPlayer.queue.indexOfNowPlayingTrack);
		
		
		self.systemVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-1000, -1000, 100, 100)];
		[self.systemVolumeView sizeToFit];
		self.systemVolumeView.showsRouteButton = NO;
//		self.volumeView.alpha = 0.05f;
//		self.volumeView.showsVolumeSlider = NO;
//		self.volumeView.hidden = YES;
		[self addSubview:self.systemVolumeView];
		
		self.systemVolumeViewSlider = nil;
		for (UIView *view in [self.systemVolumeView subviews]){
			if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
				self.systemVolumeViewSlider = (UISlider*)view;
				break;
			}
		}
		
		self.volumeView = [UIView newAutoLayoutView];
		self.volumeView.backgroundColor = [LMColour blackColour];
		self.volumeView.userInteractionEnabled = NO;
		self.volumeView.alpha = 0.0f;
		[self addSubview:self.volumeView];
		
		[self.volumeView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.volumeView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.volumeView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		self.volumeViewTopConstraint = [self.volumeView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		
		
		self.volumePercentageBackgroundView = [UIView newAutoLayoutView];
		self.volumePercentageBackgroundView.backgroundColor = [LMColour clearColor];
		self.volumePercentageBackgroundView.layer.masksToBounds = YES;
		self.volumePercentageBackgroundView.layer.cornerRadius = 8.0f;
		if(@available(iOS 11.0, *)){
			self.volumePercentageBackgroundView.layer.maskedCorners = (kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner);
		}
//		self.volumePercentageBackgroundView.alpha = self.volume
		[self.volumeView addSubview:self.volumePercentageBackgroundView];
		
		CGFloat bgWidth = MIN(WINDOW_FRAME.size.height, WINDOW_FRAME.size.width) / 2.0;
		if(bgWidth > 200.0f){
			bgWidth = 200.0f;
		}
		
		[self.volumePercentageBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.volumePercentageBackgroundView autoSetDimension:ALDimensionWidth toSize:bgWidth];
		[self.volumePercentageBackgroundView autoSetDimension:ALDimensionHeight toSize:(bgWidth / 2.0)];
		self.volumePercentageBackgroundViewTopConstraint = [self.volumePercentageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20.0f];
		
		
		self.volumePercentageLabel = [UILabel newAutoLayoutView];
		self.volumePercentageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:bgWidth / 4.0];
		self.volumePercentageLabel.textColor = [UIColor whiteColor];
		self.volumePercentageLabel.textAlignment = NSTextAlignmentCentre;
		[self.volumePercentageBackgroundView addSubview:self.volumePercentageLabel];
		
		[self.volumePercentageLabel autoPinEdgesToSuperviewEdges];
		
		
        [self reloadMusicTracks];
		
		if([LMSettings debugInitialisationSounds]){
			AudioServicesPlaySystemSound(1258);
		}
    }
}

@end
