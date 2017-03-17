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
#import "LMMusicPlayer.h"

@interface  LMMiniPlayerView()<LMMusicPlayerDelegate, LMProgressSliderDelegate>

@property UIView *miniPlayerBackgroundView;

@property UIView *trackInfoAndDurationBackgroundView;
@property LMTrackInfoView *trackInfoView;
@property LMProgressSlider *progressSlider;

@property UIView *albumArtImageBackgroundView;
@property UIImageView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMMusicPlayer *musicPlayer;

/**
 The track which this miniplayer holds.
 */
@property LMMusicTrack *loadedTrack;

@end

@implementation LMMiniPlayerView

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
	long totalPlaybackTime = self.musicPlayer.nowPlayingTrack.playbackDuration;
	
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

- (void)changeMusicTrack:(LMMusicTrack *)newTrack {
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
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
		 (int)self.musicPlayer.indexOfNowPlayingTrack+1,
		 (int)self.musicPlayer.nowPlayingCollection.count];
	}
	else{
		self.progressSlider.leftText =
		[NSString stringWithFormat:NSLocalizedString(@"SongX", nil),
		 (int)self.musicPlayer.indexOfNowPlayingTrack+1];
	}
	
	self.progressSlider.rightText = [LMNowPlayingView durationStringTotalPlaybackTime:newTrack.playbackDuration];
	[self updateSongDurationLabelWithPlaybackTime:self.musicPlayer.currentPlaybackTime];
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
	
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.value = newPlaybackTime;
}

- (void)tappedMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	
	[self.musicPlayer invertPlaybackState];
}

- (void)setup {
	self.albumArtImageBackgroundView = [UIView newAutoLayoutView];
	[self addSubview:self.albumArtImageBackgroundView];
	
	[self.albumArtImageBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.albumArtImageBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	[self.albumArtImageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
	
	self.albumArtImageView = [UIImageView newAutoLayoutView];
//	self.albumArtImageView.layer.masksToBounds = YES;
//	self.albumArtImageView.layer.cornerRadius = 5.0;
//  Rest in peace :)
	
	[self.albumArtImageBackgroundView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	
	self.trackInfoAndDurationBackgroundView = [UIView newAutoLayoutView];
//	self.trackInfoAndDurationBackgroundView.backgroundColor = [UIColor cyanColor];
	[self addSubview:self.trackInfoAndDurationBackgroundView];
	
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumArtImageBackgroundView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.albumArtImageView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	
	
	self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
	self.trackInfoView.textAlignment = NSTextAlignmentLeft;
	[self addSubview:self.trackInfoView];
	
	[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoAndDurationBackgroundView];
	[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.trackInfoAndDurationBackgroundView];
	[self.trackInfoView autoMatchDimension:ALDimensionWidth
							   toDimension:ALDimensionWidth
									ofView:self.trackInfoAndDurationBackgroundView
							withMultiplier:(9.5/10.0)];
	[self.trackInfoView autoMatchDimension:ALDimensionHeight
							   toDimension:ALDimensionHeight
									ofView:self.trackInfoAndDurationBackgroundView
							withMultiplier:(7.0/10.0)];
	
	
	self.progressSlider = [LMProgressSlider newAutoLayoutView];
	self.progressSlider.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:0.25];
	self.progressSlider.finalValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.progressSlider.delegate = self;
	self.progressSlider.value = self.musicPlayer.currentPlaybackTime;
	self.progressSlider.lightTheme = YES;
	[self.trackInfoAndDurationBackgroundView addSubview:self.progressSlider];
	
	[self.progressSlider autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView];
	[self.progressSlider autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView];
	[self.progressSlider autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
	[self.progressSlider autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/5.0)];
	
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedMiniPlayer)];
	[self addGestureRecognizer:tapGesture];
	
	[self.musicPlayer addMusicDelegate:self];
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
