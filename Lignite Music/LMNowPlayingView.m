//
//  LMNowPlayingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMNowPlayingView.h"
#import "LMAlbumArtView.h"
#import "UIImage+AverageColour.h"
#import "UIColor+isLight.h"
#import "LMOperationQueue.h"
#import "LMTrackDurationView.h"
#import "LMTrackInfoView.h"
#import "LMButton.h"
#import "LMColour.h"

@interface LMNowPlayingView() <LMMusicPlayerDelegate, LMButtonDelegate, LMTrackDurationDelegate>

@property UIImageView *backgroundImageView;
@property UIView *shadingView;

@property UIView *albumArtRootView;
@property LMAlbumArtView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMTrackDurationView *trackDurationView;

@property LMTrackInfoView *trackInfoView;

@property BOOL loaded;

@property UIView *shuffleModeBackgroundView, *repeatModeBackgroundView, *playlistBackgroundView;
@property LMButton *shuffleModeButton, *repeatModeButton, *playlistButton;
@property UILabel *shuffleTitleLabel, *repeatTitleLabel, *playlistTitleLabel;

@end

@implementation LMNowPlayingView

+ (NSString*)durationStringTotalPlaybackTime:(long)totalPlaybackTime {
	long totalHours = (totalPlaybackTime / 3600);
	int totalMinutes = (int)((totalPlaybackTime / 60) - totalHours*60);
	int totalSeconds = (totalPlaybackTime % 60);
	
	if(totalHours > 0){
		return [NSString stringWithFormat:NSLocalizedString(@"LongSongDuration", nil), (int)totalHours, totalMinutes, totalSeconds];
	}
	
	return [NSString stringWithFormat:NSLocalizedString(@"ShortSongDuration", nil), totalMinutes, totalSeconds];
}

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

- (void)seekSliderValueChanged:(float)newValue isFinal:(BOOL)isFinal {
	//NSLog(@"New value %f", newValue);
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

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		//UIImage *image = [track albumArt];
		UIImage *albumImage = [newTrack albumArt];
		
		UIColor *averageColour = [albumImage averageColour];
		BOOL isLight = [averageColour isLight];
		self.shadingView.backgroundColor = isLight ? [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25] : [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
		UIColor *newTextColour = isLight ? [UIColor blackColor] : [UIColor whiteColor];
		
		CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[gaussianBlurFilter setDefaults];
		CIImage *inputImage = [CIImage imageWithCGImage:[albumImage CGImage]];
		[gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
		[gaussianBlurFilter setValue:@5 forKey:kCIInputRadiusKey];
		
		CIImage *outputImage = [gaussianBlurFilter outputImage];
		CIContext *context   = [CIContext contextWithOptions:nil];
		CGImageRef cgimg     = [context createCGImage:outputImage fromRect:[inputImage extent]];
		UIImage *image       = [UIImage imageWithCGImage:cgimg];
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			self.backgroundImageView.image = image;
			
			self.trackInfoView.titleLabel.textColor = newTextColour;
			self.trackInfoView.artistLabel.textColor = newTextColour;
			self.trackInfoView.albumLabel.textColor = newTextColour;
			self.trackDurationView.songDurationLabel.textColor = newTextColour;
			self.trackDurationView.songCountLabel.textColor = newTextColour;
			
			if(albumImage.size.height > 0){
				[self.albumArtImageView updateContentWithMusicTrack:newTrack];
			}
						
			//[self.albumArtImageView setupWithAlbumImage:albumImage];
			//[self.albumArtImageView setImage:[item.artwork imageWithSize:CGSizeMake(self.frame.size.width, self.frame.size.width)]];
		});
	}];
	
	[self.queue addOperation:operation];
	
	if(!self.musicPlayer.nowPlayingTrack){
		[self.trackInfoView.titleLabel setText:NSLocalizedString(@"NoMusic", nil)];
		[self.trackInfoView.artistLabel setText:NSLocalizedString(@"NoMusicDescription", nil)];
		[self.trackInfoView.albumLabel setText:@""];
		[self.trackDurationView.songDurationLabel setText:NSLocalizedString(@"BlankDuration", nil)];
		[self.trackDurationView.songCountLabel setText:NSLocalizedString(@"NoMusic", nil)];
		
		UIImage *albumImage;
		albumImage = [UIImage imageNamed:@"lignite_background_portrait.png"];
		self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.backgroundImageView.image = albumImage;
		
		[self.albumArtImageView updateContentWithMusicTrack:nil];
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

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Hey button %@", button);
	if(button == self.shuffleModeButton){
		self.musicPlayer.shuffleMode = !self.musicPlayer.shuffleMode;
		
		[UIView animateWithDuration:0.25 animations:^{
			[button setColour:self.musicPlayer.shuffleMode ? [UIColor whiteColor] : [LMColour fadedColour]];
		}];
	}
}

- (void)reloadButtonTitles {
	NSString *shuffleArray[] = {
		@"DefaultShuffleMode", @"OffShuffleMode", @"SongsShuffleMode", @"AlbumsShuffleMode"
	};
	NSString *repeatArray[] = {
		@"DefaultRepeatMode", @"OffRepeatMode", @"ThisRepeatMode", @"AllRepeatMode"
	};
	self.shuffleTitleLabel.text = NSLocalizedString(shuffleArray[self.musicPlayer.shuffleMode], nil);
	self.repeatTitleLabel.text = NSLocalizedString(repeatArray[self.musicPlayer.repeatMode], nil);
}

- (void)pinchedNowPlaying {
	[self.musicPlayer removeMusicDelegate:self];
	[self.rootViewController closeNowPlayingView];
}

- (void)tappedNowPlaying {
	if([self.trackDurationView didJustFinishEditing]){
		return;
	}
	[self.musicPlayer invertPlaybackState];
}

- (void)swipedRightNowPlaying {
	[self.musicPlayer skipToNextTrack];
}

- (void)swipedLeftNowPlaying {
	[self.musicPlayer autoBackThrough];
}

- (void)setup {
	self.backgroundImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"lignite_background_portrait.png"]];
	self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self addSubview:self.backgroundImageView];
	
	[self.backgroundImageView autoCenterInSuperview];
	[self.backgroundImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:1.1];
	[self.backgroundImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:1.1];
	
	self.shadingView = [UIView newAutoLayoutView];
	self.shadingView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
	[self.backgroundImageView addSubview:self.shadingView];
	
	[self.shadingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.backgroundImageView];
	[self.shadingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.backgroundImageView];
	[self.shadingView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.shadingView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	self.albumArtRootView = [UIView newAutoLayoutView];
	self.albumArtRootView.backgroundColor = [UIColor clearColor];
	[self addSubview:self.albumArtRootView];
	
	[self.albumArtRootView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
	[self.albumArtRootView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.albumArtRootView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[self.albumArtRootView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.albumArtRootView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self
																		attribute:NSLayoutAttributeWidth
																	   multiplier:1.0
																		 constant:0];
	heightConstraint.priority = UILayoutPriorityRequired;
	[self addConstraint:heightConstraint];
	
	self.albumArtImageView = [[LMAlbumArtView alloc]init];
	self.albumArtImageView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.albumArtRootView addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
	[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.albumArtRootView withMultiplier:0.9];
	[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumArtRootView withMultiplier:0.9];
	
	[self.albumArtImageView setupWithAlbumImage:nil];
	self.albumArtImageView.backgroundColor = [UIColor clearColor];
	
	self.trackDurationView = [[LMTrackDurationView alloc]init];
	self.trackDurationView.translatesAutoresizingMaskIntoConstraints = NO;
	self.trackDurationView.delegate = self;
//	self.trackDurationView.backgroundColor = [UIColor yellowColor];
	[self addSubview:self.trackDurationView];
	[self.trackDurationView setup];
	
	self.trackDurationView.seekSlider.minimumValue = 0;
	self.trackDurationView.seekSlider.maximumValue = self.musicPlayer.nowPlayingTrack.playbackDuration;
	self.trackDurationView.seekSlider.value = self.musicPlayer.currentPlaybackTime;
	
	[self.trackDurationView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtImageView withOffset:10];
	[self.trackDurationView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtImageView withOffset:-10];
	[self.trackDurationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtImageView];
	NSLayoutConstraint *constraint = [self.trackDurationView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/10.0)];
	constraint.priority = UILayoutPriorityRequired;
	
	self.trackInfoView = [[LMTrackInfoView alloc]init];
	self.trackInfoView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.trackInfoView];
	[self.trackInfoView setupWithTextAlignment:NSTextAlignmentCenter];
	
	[self.trackInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackDurationView];
	[self.trackInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.trackDurationView];
	[self.trackInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.trackDurationView];
	[self.trackInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/5.0)];
	
	self.shuffleModeBackgroundView = [UIView newAutoLayoutView];
	self.repeatModeBackgroundView = [UIView newAutoLayoutView];
	self.playlistBackgroundView = [UIView newAutoLayoutView];
	
	self.shuffleModeButton = [[LMButton alloc]initForAutoLayout];
	self.repeatModeButton = [[LMButton alloc]initForAutoLayout];
	self.playlistButton = [[LMButton alloc]initForAutoLayout];
	
	self.shuffleTitleLabel = [[UILabel alloc]initForAutoLayout];
	self.repeatTitleLabel = [[UILabel alloc]initForAutoLayout];
	self.playlistTitleLabel = [[UILabel alloc]initForAutoLayout];
	
	NSArray *backgrounds = @[
		self.shuffleModeBackgroundView, self.repeatModeBackgroundView, self.playlistBackgroundView
	];
	NSArray *buttons = @[
		self.shuffleModeButton, self.repeatModeButton, self.playlistButton
	];
//	NSArray *titleLabels = @[
//		self.shuffleTitleLabel, self.repeatTitleLabel, self.playlistTitleLabel
//	];
//	NSArray *titles = @[
//		@"Shuffle", @"Repeat", @"Settings"
//	];
	NSArray *images = @[
		@"shuffle_black.png", @"repeat_black.png", @"settings.png"
	];
	
	for(int i = 0; i < buttons.count; i++){
		BOOL isFirst = (i == 0);
		
		UIView *background = [backgrounds objectAtIndex:i];
		UIView *previousBackground = isFirst ? self.trackInfoView : [backgrounds objectAtIndex:i-1];
		
		//background.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
		[self addSubview:background];
		
		[background autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.trackInfoView withOffset:10];
		[background autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		[background autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:previousBackground];
		[background autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.trackInfoView withMultiplier:(1.0/3.0)];
		
//		UILabel *titleLabel = [titleLabels objectAtIndex:i];
//		
//		titleLabel.text = [titles objectAtIndex:i];
//		titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
//		//titleLabel.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
//		titleLabel.textAlignment = NSTextAlignmentCenter;
//		[background addSubview:titleLabel];
//		
//		[titleLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:background withOffset:-10];
//		[titleLabel autoSetDimension:ALDimensionHeight toSize:20];
//		[titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:background];
//		[titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:background];
		
		LMButton *button = [buttons objectAtIndex:i];
		button.userInteractionEnabled = YES;
		[button setDelegate:self];
		[button setupWithImageMultiplier:0.5];
		[button setImage:[UIImage imageNamed:[images objectAtIndex:i]]];
		[button setColour:[LMColour fadedColour]];
		[background addSubview:button];

		[button autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[button autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:-20];
		[button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:background withMultiplier:0.50];
		[button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:background];
	}
	
	[self.shuffleModeButton setColour:self.musicPlayer.shuffleMode ? [UIColor whiteColor] : [LMColour fadedColour]];
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self reloadButtonTitles];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchedNowPlaying)];
	[self addGestureRecognizer:pinchGesture];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedNowPlaying)];
	[self addGestureRecognizer:tapGesture];
	
	UISwipeGestureRecognizer *swipeToRightGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedRightNowPlaying)];
	swipeToRightGesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self addGestureRecognizer:swipeToRightGesture];
	
	UISwipeGestureRecognizer *swipeToLeftGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipedLeftNowPlaying)];
	swipeToLeftGesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self addGestureRecognizer:swipeToLeftGesture];
}

//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//	NSLog(@"Hey");
//}

@end
