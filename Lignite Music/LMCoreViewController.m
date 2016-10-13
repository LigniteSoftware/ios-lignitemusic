//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMAppDelegate.h"
#import <PureLayout/PureLayout.h>
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMAlbumView.h"
#import "LMNowPlayingView.h"

@interface LMCoreViewController () <LMMusicPlayerDelegate>

@property LMMusicPlayer *musicPlayer;
@property LMNowPlayingView *nowPlayingView;
@property LMAlbumView *albumView;

@property NSLayoutConstraint *topConstraint;

@end

@implementation LMCoreViewController

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	NSLog(@"Got new playback state %d", newState);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	NSLog(@"Got new track, title %@", newTrack.title);
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)pause {
	NSLog(@"Dude!");
	[self.musicPlayer pause];
}

- (void)play {
	NSLog(@"Dude");
	
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(pause)
								   userInfo:nil
									repeats:NO];
	
	NSArray *items = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists];
	NSLog(@"Got %lu items.", (unsigned long)items.count);
	
	int random = rand() % items.count;
	NSLog(@"%d", random);
	LMMusicTrackCollection *collection = [items objectAtIndex:random];
	[self.musicPlayer setNowPlayingCollection:collection];
	[self.musicPlayer setNowPlayingTrack:collection.representativeItem];
	[self.musicPlayer play];
}

- (void)openNowPlayingView {
	if(self.nowPlayingView){
		return;
	}
	
	self.nowPlayingView = [[LMNowPlayingView alloc]init];
	self.nowPlayingView.translatesAutoresizingMaskIntoConstraints = NO;
	self.nowPlayingView.backgroundColor = [UIColor blueColor];
	self.nowPlayingView.musicPlayer = self.musicPlayer;
	self.nowPlayingView.rootViewController = self;
	[self.view addSubview:self.nowPlayingView];
	
	[self.nowPlayingView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.topConstraint = [self.nowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:self.view.frame.size.height];
	[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.nowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	[self.nowPlayingView setup];
	
	[self.view layoutIfNeeded];
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:0.5 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:nil];
}

- (void)closeNowPlayingView {
	[self.view layoutIfNeeded];
	self.topConstraint.constant = self.view.frame.size.height*1.5;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:^(BOOL finished) {
							self.nowPlayingView = nil;
						}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	NSLog(@"Loaded");
    // Do any additional setup after loading the view.
	self.musicPlayer = [(LMAppDelegate*)[[UIApplication sharedApplication] delegate] musicPlayer];
	[self.musicPlayer addMusicDelegate:self];

	self.albumView = [[LMAlbumView alloc]init];
	self.albumView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumView.musicPlayer = self.musicPlayer;
	self.albumView.rootViewController = self;
	[self.view addSubview:self.albumView];
	
	[self.albumView autoCenterInSuperview];
	[self.albumView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.albumView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	[NSTimer scheduledTimerWithTimeInterval:0.75
									 target:self
								   selector:@selector(openNowPlayingView)
								   userInfo:nil
									repeats:NO];
	
//	self.nowPlayingView = [[LMNowPlayingView alloc]init];
//	self.nowPlayingView.translatesAutoresizingMaskIntoConstraints = NO;
//	self.nowPlayingView.backgroundColor = [UIColor blueColor];
//	self.nowPlayingView.musicPlayer = self.musicPlayer;
//	[self.view addSubview:self.nowPlayingView];
//	
//	[self.nowPlayingView autoCenterInSuperview];
//	[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
//	[self.nowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
//	
//	[self.nowPlayingView setup];
	
//	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(play)];
//	[self.view addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
