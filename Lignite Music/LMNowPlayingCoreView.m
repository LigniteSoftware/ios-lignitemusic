//
//  LMNowPlayingCoreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 3/25/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButtonNavigationBar.h"
#import "LMNowPlayingCoreView.h"
#import "LMCoreViewController.h"
#import "LMTutorialView.h"
#import "LMNowPlayingView.h"

@interface LMNowPlayingCoreView()<UIGestureRecognizerDelegate, LMMusicPlayerDelegate>

/**
 The NowPlaying which goes in the back.
 */
@property LMNowPlayingView *trailingNowPlayingView;

/**
 The NowPlaying which goes in the middle.
 */
@property LMNowPlayingView *centreNowPlayingView;

/**
 The NowPlaying which goes in the front.
 */
@property LMNowPlayingView *leadingNowPlayingView;

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
 The leading constraint for the center NowPlaying. This is the constraint which the pan gesture uses for the motion of views.
 */
@property NSLayoutConstraint *nowPlayingLeadingConstraint;

/**
 The other constraints, will handle this soon.
 */
@property NSMutableArray *otherConstraints;

/**
 The array of samples for determining which direction the gesture is headed in.
 */
@property NSMutableArray *samplesArray;

@end

@implementation LMNowPlayingCoreView

- (void)loadMusicTracksBasedOffIndex:(NSInteger)indexOfCenter {
	if(self.musicPlayer.nowPlayingCollection.count == 0){
		[self.centreNowPlayingView changeMusicTrack:nil withIndex:-1];
		[self.leadingNowPlayingView changeMusicTrack:nil withIndex:-1];
		[self.trailingNowPlayingView changeMusicTrack:nil withIndex:-1];
		return;
	}
	
    if(indexOfCenter >= self.musicPlayer.nowPlayingCollection.items.count){
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
	
	NSLog(@"indexes %d/%d/%d count %d", (int)previousTrackIndex, (int)indexOfCenter, (int)nextTrackIndex, (int)self.musicPlayer.nowPlayingCollection.count);
	
	NSLog(@"Spook");
	
    [self.centreNowPlayingView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:indexOfCenter] withIndex:indexOfCenter];
    [self.leadingNowPlayingView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:nextTrackIndex]
                                       withIndex:nextTrackIndex];
    [self.trailingNowPlayingView changeMusicTrack:[self.musicPlayer.nowPlayingCollection.items objectAtIndex:previousTrackIndex]
                                        withIndex:previousTrackIndex];
}

- (void)trackAddedToQueue:(LMMusicTrack *)trackAdded {
	NSInteger nowPlayingTrackIndex = self.musicPlayer.indexOfNowPlayingTrack;
	[self loadMusicTracksBasedOffIndex:nowPlayingTrackIndex];
}

- (void)trackRemovedFromQueue:(LMMusicTrack *)trackRemoved {
	NSInteger nowPlayingTrackIndex = self.musicPlayer.indexOfNowPlayingTrack;
	[self loadMusicTracksBasedOffIndex:nowPlayingTrackIndex];
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
    NSInteger nowPlayingTrackIndex = self.musicPlayer.indexOfNowPlayingTrack;
    [self loadMusicTracksBasedOffIndex:nowPlayingTrackIndex];
	
	NSLog(@"Refresh core");
}

- (void)trackMovedInQueue:(LMMusicTrack *)trackMoved {
//	NSInteger nowPlayingTrackIndex = self.musicPlayer.indexOfNowPlayingTrack;
//	[self loadMusicTracksBasedOffIndex:nowPlayingTrackIndex];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
    
}

- (void)skipTracks {
    //	self.skipToNextTrackOnTimerFire ? [self.musicPlayer skipToNextTrack] : [self.musicPlayer skipToPreviousItem];
    [self.musicPlayer setNowPlayingTrack:self.centreNowPlayingView.loadedTrack];
}

- (void)rebuildConstraints:(BOOL)leadingIsCenter {
    NSArray *oldNowPlayings = @[ self.trailingNowPlayingView, self.centreNowPlayingView, self.leadingNowPlayingView ];
    
    [self.centreNowPlayingView removeFromSuperview];
    [self.leadingNowPlayingView removeFromSuperview];
    [self.trailingNowPlayingView removeFromSuperview];
    
    // [ 0 1 2 ] swipe -> 0 [ 1 2 * ] convert -> [ 1 2 0 ]
    if(leadingIsCenter){
        self.trailingNowPlayingView = oldNowPlayings[1];
        self.centreNowPlayingView = oldNowPlayings[2];
        self.leadingNowPlayingView = oldNowPlayings[0];
    }
    // [ 0 1 2 ] swipe -> [ * 0 1 ] 2 convert -> [ 2 0 1 ]
    else{
        self.trailingNowPlayingView = oldNowPlayings[2];
        self.centreNowPlayingView = oldNowPlayings[0];
        self.leadingNowPlayingView = oldNowPlayings[1];
    }
	
//	self.centerNowPlayingView.backgroundColor = [UIColor orangeColor];
//	self.trailingNowPlayingView.backgroundColor = [UIColor yellowColor];
//	self.leadingNowPlayingView.backgroundColor = [UIColor redColor];
	
	NSLog(@"Loaded tracks: %@/%@/%@", self.trailingNowPlayingView.loadedTrack.title, self.centreNowPlayingView.loadedTrack.title, self.leadingNowPlayingView.loadedTrack.title);
    
    [self addSubview:self.centreNowPlayingView];
    [self addSubview:self.leadingNowPlayingView];
    [self addSubview:self.trailingNowPlayingView];
    
    self.nowPlayingLeadingConstraint = [self.centreNowPlayingView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
    [self.centreNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    [self.centreNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
    [self.centreNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
    
    [self.otherConstraints addObject:[self.trailingNowPlayingView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.centreNowPlayingView]];
    [self.trailingNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    [self.trailingNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
    [self.trailingNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
    
    [self.otherConstraints addObject:[self.leadingNowPlayingView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.centreNowPlayingView]];
    [self.leadingNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    [self.leadingNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
    [self.leadingNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
    
    [self loadMusicTracksBasedOffIndex:self.centreNowPlayingView.loadedTrackIndex];
    
    [self layoutIfNeeded];
    
    LMNowPlayingView *oldCenterNowPlayingView = [oldNowPlayings objectAtIndex:1];
    if([oldCenterNowPlayingView nowPlayingQueueOpen]){
        [oldCenterNowPlayingView setNowPlayingQueueOpen:NO animated:NO];
    }
    
    
    NSLog(@"Constraints rebuilt.");
}

- (void)panNowPlaying:(UIPanGestureRecognizer *)recognizer {
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
//            [self.centerNowPlayingView panNowPlayingDown:recognizer];
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            
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
            
            if(recognizer.state == UIGestureRecognizerStateEnded){
                
                if((translation.y >= self.frame.size.height/10.0)){
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
            
            //	NSLog(@"%f to %f %@", translation.y, totalTranslation, NSStringFromCGPoint(self.currentPoint));
            
            if(self.skipTracksTimer){
                [self.skipTracksTimer invalidate];
                self.skipTracksTimer = nil;
            }
            
            self.nowPlayingLeadingConstraint.constant = totalTranslation;
            
            [self layoutIfNeeded];
            
            if(recognizer.state == UIGestureRecognizerStateEnded){
                [self layoutIfNeeded];
                
                BOOL nextSong = translation.x < -self.frame.size.width/5;
                BOOL rebuildConstraints = YES;
                
                if(translation.x > self.frame.size.width/5){
                    NSLog(@"Slide forward");
                    self.nowPlayingLeadingConstraint.constant = self.frame.size.width;
                }
                else if(nextSong){
                    NSLog(@"Slide backward");
                    self.nowPlayingLeadingConstraint.constant = -self.frame.size.width;
                }
                else{
                    NSLog(@"Reset to center");
                    self.nowPlayingLeadingConstraint.constant = 0;
                    rebuildConstraints = NO;
                }
                
                self.samplesArray = [NSMutableArray new];
                
                [UIView animateWithDuration:0.15 animations:^{
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
        
        self.otherConstraints = [NSMutableArray new];
        self.samplesArray = [NSMutableArray new];
        
        self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
        [self.musicPlayer addMusicDelegate:self];
        
        self.centreNowPlayingView = [LMNowPlayingView newAutoLayoutView];
        //		self.centerNowPlayingView.backgroundColor = [UIColor orangeColor];
        self.centreNowPlayingView.coreViewController = (LMCoreViewController*)self.rootViewController;
        [self addSubview:self.centreNowPlayingView];
        
        self.nowPlayingLeadingConstraint = [self.centreNowPlayingView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
        [self.centreNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
        [self.centreNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [self.centreNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
        
        
        UIPanGestureRecognizer *nowPlayingPanGesture =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panNowPlaying:)];
        nowPlayingPanGesture.delegate = self;
        [self.centreNowPlayingView addGestureRecognizer:nowPlayingPanGesture];
        
        
        self.trailingNowPlayingView = [LMNowPlayingView newAutoLayoutView];
        //		self.trailingNowPlayingView.backgroundColor = [UIColor yellowColor];
        self.trailingNowPlayingView.coreViewController = (LMCoreViewController*)self.rootViewController;
        [self addSubview:self.trailingNowPlayingView];
        
        [self.otherConstraints addObject:[self.trailingNowPlayingView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.centreNowPlayingView]];
        [self.trailingNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
        [self.trailingNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [self.trailingNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
        

        
        UIPanGestureRecognizer *nowPlayingTrailingPanGesture =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panNowPlaying:)];
        nowPlayingTrailingPanGesture.delegate = self;
        [self.trailingNowPlayingView addGestureRecognizer:nowPlayingTrailingPanGesture];
        
        
        self.leadingNowPlayingView = [LMNowPlayingView newAutoLayoutView];
        //		self.leadingNowPlayingView.backgroundColor = [UIColor redColor];
        self.leadingNowPlayingView.coreViewController = (LMCoreViewController*)self.rootViewController;
        [self addSubview:self.leadingNowPlayingView];
        
        [self.otherConstraints addObject:[self.leadingNowPlayingView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.centreNowPlayingView]];
        [self.leadingNowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
        [self.leadingNowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [self.leadingNowPlayingView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		
		
//		self.centerNowPlayingView.backgroundColor = [UIColor orangeColor];
//		self.trailingNowPlayingView.backgroundColor = [UIColor yellowColor];
//		self.leadingNowPlayingView.backgroundColor = [UIColor redColor];

		self.centreNowPlayingView.backgroundColor = [UIColor whiteColor];
		self.trailingNowPlayingView.backgroundColor = [UIColor whiteColor];
		self.leadingNowPlayingView.backgroundColor = [UIColor whiteColor];
		
		self.centreNowPlayingView.nowPlayingCoreView = self;
		self.trailingNowPlayingView.nowPlayingCoreView = self;
		self.leadingNowPlayingView.nowPlayingCoreView = self;

        
        UIPanGestureRecognizer *nowPlayingLeadingPanGesture =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(panNowPlaying:)];
        nowPlayingLeadingPanGesture.delegate = self;
        [self.leadingNowPlayingView addGestureRecognizer:nowPlayingLeadingPanGesture];
        
        //		LMMusicTrackCollection *currentCollection = self.musicPlayer.nowPlayingCollection;
        //		if(currentCollection == nil){
        //			
        //		}
        
        NSLog(@"Index of %ld", self.musicPlayer.indexOfNowPlayingTrack);
        
        [self loadMusicTracksBasedOffIndex:self.musicPlayer.indexOfNowPlayingTrack];
        
        
        if([LMTutorialView tutorialShouldRunForKey:LMTutorialKeyNowPlaying]){
            LMTutorialView *tutorialView = [[LMTutorialView alloc] initForAutoLayoutWithTitle:NSLocalizedString(@"TutorialFullScreenPlaybackTitle", nil)
                                                                                  description:NSLocalizedString(@"TutorialFullScreenPlaybackDescription", nil)
                                                                                          key:LMTutorialKeyNowPlaying];
            [self addSubview:tutorialView];
            tutorialView.boxAlignment = LMTutorialViewAlignmentCenter;
            tutorialView.arrowAlignment = LMTutorialViewAlignmentCenter;
            tutorialView.icon = [LMAppIcon imageForIcon:LMIconTutorialSwipe];
			
			[tutorialView autoPinEdgesToSuperviewEdges];
            
            self.tutorialView = tutorialView;
        }
    }
}

@end
