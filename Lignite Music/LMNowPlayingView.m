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
#import "LMOperationQueue.h"
#import "LMTrackDurationView.h"

@interface LMNowPlayingView() <LMMusicPlayerDelegate>

@property UIImageView *backgroundImageView;
@property UIView *shadingView;

@property UIView *albumArtRootView;
@property LMAlbumArtView *albumArtImageView;

@property LMOperationQueue *queue;

@property LMTrackDurationView *trackDurationView;

@property BOOL loaded;

@end

@implementation LMNowPlayingView

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
	
	[self.queue cancelAllOperations];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		//UIImage *image = [track albumArt];
		UIImage *albumImage = [newTrack albumArt];
		
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
			
			if(albumImage.size.height > 0){
				[self.albumArtImageView updateContentWithMusicTrack:newTrack];
			}
						
			//[self.albumArtImageView setupWithAlbumImage:albumImage];
			//[self.albumArtImageView setImage:[item.artwork imageWithSize:CGSizeMake(self.frame.size.width, self.frame.size.width)]];
		});
	}];
	
	[self.queue addOperation:operation];
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
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
	
	int tenthOfWidth = self.frame.size.width/10;
	[self.albumArtRootView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
	[self.albumArtRootView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:tenthOfWidth];
	[self.albumArtRootView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-tenthOfWidth];
	[self.albumArtRootView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:tenthOfWidth];
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
	self.trackDurationView.backgroundColor = [UIColor yellowColor];
	[self addSubview:self.trackDurationView];
	[self.trackDurationView setup];
	
	[self.trackDurationView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumArtRootView];
	[self.trackDurationView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumArtRootView];
	[self.trackDurationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtRootView];
	NSLayoutConstraint *constraint = [self.trackDurationView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/10.0)];
	constraint.priority = UILayoutPriorityRequired;
	
	[self.musicPlayer addMusicDelegate:self];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
}

//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//	NSLog(@"Hey");
//}

@end
