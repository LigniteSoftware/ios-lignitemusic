//
//  LMMiniPlayerView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMiniPlayerView.h"
#import "LMTrackInfoView.h"
#import "LMTrackDurationView.h"
#import "LMOperationQueue.h"
#import "LMNowPlayingView.h"
#import "LMProgressSlider.h"

@interface  LMMiniPlayerView()<LMMusicPlayerDelegate, LMProgressSliderDelegate>

@property LMView *miniPlayerBackgroundView;

@property LMView *trackInfoAndDurationBackgroundView;
@property LMTrackInfoView *trackInfoView;
@property LMProgressSlider *progressSlider;

@property LMView *albumArtImageBackgroundView;
@property UIImageView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMMiniPlayerView

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
	long totalPlaybackTime = self.loadedTrack.playbackDuration;
	
	long currentHours = (currentPlaybackTime / 3600);
	long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
	int currentSeconds = (currentPlaybackTime % 60);
	
	long totalHours = (totalPlaybackTime / 3600);
	
	if(totalHours > 0){
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"LongSongDurationOfDuration", nil),
										 (int)currentHours, (int)currentMinutes, currentSeconds,
										 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
	else{
		self.progressSlider.rightText = [NSString stringWithFormat:NSLocalizedString(@"ShortSongDurationOfDuration", nil),
										 (int)currentMinutes, currentSeconds,
										 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	
}

- (void)changeMusicTrack:(LMMusicTrack *)newTrack withIndex:(NSInteger)index {
	self.loadedTrack = newTrack;
	self.loadedTrackIndex = index;
	
//	NSLog(@"ID is %@: %lld", newTrack.title, newTrack.persistentID);
	
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	__block __weak NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *titlesIcon = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
		UIImage *albumImage = noTrackPlaying ? titlesIcon : [newTrack albumArt];
		if(!albumImage){
			albumImage = titlesIcon;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.albumArtImageView.image = albumImage;
		});
	}];
	
	[self.queue addOperation:operation];
	
	if(noTrackPlaying){
		self.trackInfoView.titleText = NSLocalizedString(@"NoMusic", nil);
		self.trackInfoView.artistText = NSLocalizedString(@"NoMusicDescription", nil);
		self.trackInfoView.albumText = @"";
		self.progressSlider.rightText = NSLocalizedString(@"BlankDuration", nil);
		self.progressSlider.leftText = NSLocalizedString(@"NoMusic", nil);
		return;
	}
	
	self.trackInfoView.titleText = newTrack.title ? newTrack.title : NSLocalizedString(@"UnknownTitle", nil);
	self.trackInfoView.artistText = newTrack.artist ? newTrack.artist : NSLocalizedString(@"UnknownArtist", nil);
	self.trackInfoView.albumText = newTrack.albumTitle ? newTrack.albumTitle : NSLocalizedString(@"UnknownAlbumTitle", nil);
	
	if(self.musicPlayer.nowPlayingCollection){
		self.progressSlider.leftText =
		[NSString stringWithFormat:NSLocalizedString(@"SongXofX", nil),
		 (int)self.loadedTrackIndex+1,
		 (int)self.musicPlayer.nowPlayingCollection.count];
	}
	else{
		self.progressSlider.leftText =
		[NSString stringWithFormat:NSLocalizedString(@"SongX", nil),
		 (int)self.loadedTrackIndex+1];
	}
	
	self.progressSlider.rightText = [LMNowPlayingView durationStringTotalPlaybackTime:newTrack.playbackDuration];
	[self updateSongDurationLabelWithPlaybackTime:0];
	[self.progressSlider reset];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (void)progressSliderValueChanged:(CGFloat)newValue isFinal:(BOOL)isFinal {
	//NSLog(@"New value %f", newValue);
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	if(isFinal){
		[self.musicPlayer setCurrentPlaybackTime:newValue];
	}
	else{
		[self updateSongDurationLabelWithPlaybackTime:newValue];
	}
}

- (void)musicCurrentPlaybackTimeDidChange:(NSTimeInterval)newPlaybackTime {
	if(self.musicPlayer.nowPlayingTrack.persistentID != self.loadedTrack.persistentID){
		return;
	}
	
	if(self.progressSlider.userIsInteracting){
		return;
	}
	
	[self updateSongDurationLabelWithPlaybackTime:newPlaybackTime];
	
	self.progressSlider.finalValue = self.loadedTrack.playbackDuration;
	self.progressSlider.value = newPlaybackTime;
}

- (void)tappedMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer invertPlaybackState];
}

- (void)setup {
	self.albumArtImageBackgroundView = [LMView newAutoLayoutView];
	[self addSubview:self.albumArtImageBackgroundView];
	
	NSArray *albumArtImageBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
	}];
	[LMLayoutManager addNewPortraitConstraints:albumArtImageBackgroundViewPortraitConstraints];
	
	NSArray *albumArtImageBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.albumArtImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
	}];
	[LMLayoutManager addNewLandscapeConstraints:albumArtImageBackgroundViewLandscapeConstraints];
	
	
	
	
	self.albumArtImageView = [UIImageView newAutoLayoutView];
	[self.albumArtImageBackgroundView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	
	
	self.trackInfoAndDurationBackgroundView = [LMView newAutoLayoutView];
//	self.trackInfoAndDurationBackgroundView.backgroundColor = [UIColor cyanColor];
	[self addSubview:self.trackInfoAndDurationBackgroundView];
	
	NSArray *trackInfoAndDurationBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumArtImageBackgroundView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.albumArtImageView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-15];
	}];
	[LMLayoutManager addNewPortraitConstraints:trackInfoAndDurationBackgroundViewPortraitConstraints];
	
	NSArray *trackInfoAndDurationBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtImageView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtImageBackgroundView];
		[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	}];
	[LMLayoutManager addNewLandscapeConstraints:trackInfoAndDurationBackgroundViewLandscapeConstraints];
	
	
	
	self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
	self.trackInfoView.textAlignment = NSTextAlignmentLeft;
	[self.trackInfoAndDurationBackgroundView addSubview:self.trackInfoView];
	
	[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.trackInfoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:1];
	[self.trackInfoView autoMatchDimension:ALDimensionHeight
							   toDimension:ALDimensionHeight
									ofView:self.trackInfoAndDurationBackgroundView
							withMultiplier:(6.5/10.0)];
	
	
	self.progressSlider = [LMProgressSlider newAutoLayoutView];
	self.progressSlider.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:0.25];
	self.progressSlider.finalValue = 0;
	self.progressSlider.delegate = self;
	self.progressSlider.value = 0;
	self.progressSlider.lightTheme = YES;
	[self.trackInfoAndDurationBackgroundView addSubview:self.progressSlider];
	
	
	NSArray *progressSliderPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView];
		[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView];
		[self.progressSlider autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
		[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/5.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:progressSliderPortraitConstraints];
	
	NSArray *progressSliderLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView];
		[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView];
		[self.progressSlider autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView];
		[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/11.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:progressSliderLandscapeConstraints];
	
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedMiniPlayer)];
	[self addGestureRecognizer:tapGesture];
	
	[self.musicPlayer addMusicDelegate:self];
	
	NSLog(@"Setup miniplayer");
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Error creating mini player view!");
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
