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
#import "LMMusicPlayer.h"

@interface  LMMiniPlayerView()<LMMusicPlayerDelegate, LMTrackDurationDelegate>

@property UIView *miniPlayerBackgroundView;

@property UIView *trackInfoAndDurationBackgroundView;
@property LMTrackInfoView *trackInfoView;
@property LMTrackDurationView *trackDurationView;

@property UIView *albumArtImageBackgroundView;
@property UIImageView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMMusicPlayer *musicPlayer;

@end

@implementation LMMiniPlayerView

- (void)updateSongDurationLabelWithPlaybackTime:(long)currentPlaybackTime {
	long totalPlaybackTime = self.musicPlayer.nowPlayingTrack.playbackDuration;
	
	long currentHours = (currentPlaybackTime / 3600);
	long currentMinutes = ((currentPlaybackTime / 60) - currentHours*60);
	int currentSeconds = (currentPlaybackTime % 60);
	
	long totalHours = (totalPlaybackTime / 3600);
	
	if(totalHours > 0){
		self.trackDurationView.songDurationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LongSongDurationOfDuration", nil),
														 (int)currentHours, (int)currentMinutes, currentSeconds,
														 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
	else{
		self.trackDurationView.songDurationLabel.text = [NSString stringWithFormat:NSLocalizedString(@"ShortSongDurationOfDuration", nil),
														 (int)currentMinutes, currentSeconds,
														 [LMNowPlayingView durationStringTotalPlaybackTime:totalPlaybackTime]];
	}
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	NSLog(@"Got a new track called %@ for the miniplayer", newTrack.title);
	
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	BOOL noTrackPlaying = ![self.musicPlayer hasTrackLoaded];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *titlesIcon = [LMAppIcon imageForIcon:LMIconTitles];
		UIImage *albumImage = noTrackPlaying ? titlesIcon : [newTrack albumArt];
		if(!albumImage){
			albumImage = titlesIcon;
		}
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.albumArtImageView.image = albumImage;
		});
	}];
	
	[self.queue addOperation:operation];
	
	if(noTrackPlaying){
		[self.trackInfoView.titleLabel setText:NSLocalizedString(@"NoMusic", nil)];
		[self.trackInfoView.artistLabel setText:NSLocalizedString(@"NoMusicDescription", nil)];
		[self.trackInfoView.albumLabel setText:@""];
		[self.trackDurationView.songDurationLabel setText:NSLocalizedString(@"BlankDuration", nil)];
		[self.trackDurationView.songCountLabel setText:NSLocalizedString(@"NoMusic", nil)];
		self.albumArtImageView.image = nil;
		return;
	}
	
	self.trackInfoView.titleLabel.text = newTrack.title;
	self.trackInfoView.artistLabel.text = newTrack.artist;
	self.trackInfoView.albumLabel.text = newTrack.albumTitle;
	
	if(self.musicPlayer.nowPlayingCollection){
		self.trackDurationView.songCountLabel.text =
		[NSString stringWithFormat:NSLocalizedString(@"SongXofX", nil),
		 (int)self.musicPlayer.indexOfNowPlayingTrack+1,
		 (int)self.musicPlayer.nowPlayingCollection.count];
	}
	else{
		self.trackDurationView.songCountLabel.text =
		[NSString stringWithFormat:NSLocalizedString(@"SongX", nil),
		 (int)self.musicPlayer.indexOfNowPlayingTrack+1];
	}
	
	self.trackDurationView.songDurationLabel.text = [LMNowPlayingView durationStringTotalPlaybackTime:newTrack.playbackDuration];
	[self updateSongDurationLabelWithPlaybackTime:self.musicPlayer.currentPlaybackTime];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (void)seekSliderValueChanged:(float)newValue isFinal:(BOOL)isFinal {
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
	if(self.trackDurationView.shouldUpdateValue){
		[self updateSongDurationLabelWithPlaybackTime:newPlaybackTime];
		
		self.trackDurationView.seekSlider.minimumValue = 0;
		self.trackDurationView.seekSlider.maximumValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
		[UIView animateWithDuration:1.0 animations:^{
			[self.trackDurationView.seekSlider setValue:newPlaybackTime animated:YES];
		}];
	}
}

- (void)tappedMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	if([self.trackDurationView didJustFinishEditing]){
		return;
	}
	[self.musicPlayer invertPlaybackState];
}

- (void)swipedRightMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	if([self.trackDurationView didJustFinishEditing]){
		return;
	}
	
	[self.musicPlayer skipToNextTrack];
}

- (void)swipedLeftMiniPlayer {
	if(![self.musicPlayer hasTrackLoaded]){
		return;
	}
	if([self.trackDurationView didJustFinishEditing]){
		return;
	}
	
	[self.musicPlayer autoBackThrough];
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
//  Rest in peace ;(
	
	[self.albumArtImageBackgroundView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtImageBackgroundView withMultiplier:(8.0/10.0)];
	
	self.trackInfoAndDurationBackgroundView = [UIView newAutoLayoutView];
	[self addSubview:self.trackInfoAndDurationBackgroundView];
	
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumArtImageView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.albumArtImageBackgroundView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.albumArtImageView];
	[self.trackInfoAndDurationBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	
	self.trackInfoView = [LMTrackInfoView newAutoLayoutView];
	[self addSubview:self.trackInfoView];
	
	[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoAndDurationBackgroundView];
	[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.trackInfoAndDurationBackgroundView];
	[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoAndDurationBackgroundView withOffset:-10];
	[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.trackInfoAndDurationBackgroundView withMultiplier:(6.0/10.0)];
	
	[self.trackInfoView setupWithTextAlignment:NSTextAlignmentLeft];
	
	self.trackDurationView = [LMTrackDurationView newAutoLayoutView];
	self.trackDurationView.delegate = self;
	[self addSubview:self.trackDurationView];
	
	[self.trackDurationView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackInfoView withOffset:4];
	[self.trackDurationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView];
	[self.trackDurationView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackInfoView withOffset:-8];
	[self.trackDurationView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.trackInfoAndDurationBackgroundView];
	
	[self.trackDurationView setup];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedMiniPlayer)];
	[self addGestureRecognizer:tapGesture];
	
	UISwipeGestureRecognizer *swipeToRightGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedRightMiniPlayer)];
	swipeToRightGesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self addGestureRecognizer:swipeToRightGesture];
	
	UISwipeGestureRecognizer *swipeToLeftGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedLeftMiniPlayer)];
	swipeToLeftGesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self addGestureRecognizer:swipeToLeftGesture];
	
	[self.musicPlayer addMusicDelegate:self];
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicCurrentPlaybackTimeDidChange:self.musicPlayer.currentPlaybackTime];
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
