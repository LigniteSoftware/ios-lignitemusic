//
//  LMAlbumViewItem.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumViewItem.h"
#import "LMLabel.h"
#import "LMOperationQueue.h"
#import "LMShadowView.h"
#import "LMAppIcon.h"

@interface LMAlbumViewItem() <LMButtonDelegate>

@property UIImageView *albumImageView;
@property UIView *contentView, *textBackgroundView;
@property LMShadowView *shadingBackgroundView;
@property UILabel *albumTitleView, *albumArtistView;
@property CAShapeLayer *circleLayer;
@property id trackDelegate;
@property LMOperationQueue *queue;

@end

@implementation LMAlbumViewItem

- (void)clickedButton:(LMButton *)button {
	if(self.trackDelegate){
		[self.trackDelegate clickedPlayButtonOnAlbumViewItem:self];
	}
}

- (void)tappedOnView {
	if(self.trackDelegate){
		[self.trackDelegate clickedAlbumViewItem:self];
	}
}

- (void)updateContentsWithMusicTrack:(LMMusicTrack*)track andNumberOfItems:(NSInteger)numberOfItems {
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
		
	[self.queue cancelAllOperations];
	
		NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
			@autoreleasepool {
				
				MPMediaItemArtwork *artwork = [track.sourceTrack artwork];
				
				//NSLog(@"Artwork %@", artwork);
				__weak UIImage *image = [artwork imageWithSize:artwork.bounds.size];
				
				dispatch_sync(dispatch_get_main_queue(), ^{
					if(operation.cancelled){
						NSLog(@"Rejecting.");
						return;
					}
					self.albumImageView.image = image;
					
					self.albumTitleView.text = track.albumTitle ? track.albumTitle : NSLocalizedString(@"UnknownAlbum", nil);
					self.albumArtistView.text = [NSString stringWithFormat:@"%@ | %ld %@", track.artist, numberOfItems, NSLocalizedString(numberOfItems == 1 ? @"Song" : @"Songs", nil)];
					//self.albumCountView.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfItems];
					
					self.track = track;
				});
				
			}
		}];

		[self.queue addOperation:operation];
	
	//[self.shadingBackgroundView updateConstraints];
}

/**
 Sets up the LMAlbumViewItem with a number of items that's available in that album.

 @param numberOfItems The number of items in the album associated with this item.
 */
- (void)setupWithAlbumCount:(NSUInteger)numberOfItems andDelegate:(id)delegate {
	self.contentView = [UIView new];
	[self addSubview:self.contentView];
	
	[self.contentView autoCenterInSuperview];
	[self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.8];
	[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
	
	//The shading background view gives a shadow effect to the item.
	self.shadingBackgroundView = [[LMShadowView alloc] init];
	[self.contentView addSubview:self.shadingBackgroundView];
	
	[self.shadingBackgroundView autoCenterInSuperview];
	[self.shadingBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.7];
	[self.shadingBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.7];
	
	//The album image view displays the album image.
	self.albumImageView = [[UIImageView alloc]initWithImage:nil];
	self.albumImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumImageView.layer.opaque = NO;
	self.albumImageView.clipsToBounds = YES;
	self.albumImageView.backgroundColor = [UIColor whiteColor];
	[self.contentView addSubview:self.albumImageView];
	
	[self.albumImageView autoCenterInSuperview];
	[self.albumImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.9];
	[self.albumImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.9];
	
	//The text background view is a view which contains the play button and album/artist text associated with this item.
	//It has a white background color.
	self.textBackgroundView = [[UIView alloc]init];
	self.textBackgroundView.backgroundColor = [UIColor whiteColor];
	self.textBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:self.textBackgroundView];
	
	[self.textBackgroundView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.contentView];
	[self.textBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumImageView];
	[self.textBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:1.0];
	[self.textBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.2];
	
	//The play button allows for easy access to playing the album.
	self.playButton = [[LMButton alloc]init];
	self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
	self.playButton.userInteractionEnabled = YES;
	self.playButton.delegate = self;
	[self.textBackgroundView addSubview:self.playButton];
	[self.playButton setupWithImageMultiplier:0.5];
	[self.playButton setImage:[LMAppIcon imageForIcon:LMIconPlay]];
	//self.playButton.backgroundColor = [UIColor blueColor];
	
	[self.playButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.textBackgroundView];
	[self.playButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.8];
	[self.playButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.8];
	//[self.playButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.textBackgroundView];
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
																attribute:NSLayoutAttributeCenterX
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.albumImageView
																 attribute:NSLayoutAttributeLeading
																multiplier:1.0
																  constant:0]];
	
	//The album's title.
	self.albumTitleView = [[LMLabel alloc]init];
//	self.albumTitleView.backgroundColor = [UIColor orangeColor];
	self.albumTitleView.text = self.track.albumTitle;
	self.albumTitleView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumTitleView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.albumTitleView.textAlignment = NSTextAlignmentLeft;
	self.albumTitleView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumTitleView.numberOfLines = 1;
	self.albumTitleView.adjustsFontSizeToFitWidth = NO;
	[self.textBackgroundView addSubview:self.albumTitleView];
	
	[self.albumTitleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.playButton withOffset:10];
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeBottom
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeCenterY
																	   multiplier:1.0
																		 constant:0]];
	[self.albumTitleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.45];
	[self.albumTitleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumImageView];
	
	//The artist.
	self.albumArtistView = [[LMLabel alloc]init];
//	self.albumArtistView.backgroundColor = [UIColor redColor];
	self.albumArtistView.text = self.track.artist;
	self.albumArtistView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.albumArtistView.textAlignment = NSTextAlignmentLeft;
	self.albumArtistView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumArtistView.numberOfLines = 0;
	[self.textBackgroundView addSubview:self.albumArtistView];
	
	[self.albumArtistView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumTitleView];
	[self.albumArtistView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumTitleView];
	[self.albumArtistView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.30];
	[self.albumArtistView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumTitleView];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView)];
	[self.contentView addGestureRecognizer:tapGestureRecognizer];
	
	self.userInteractionEnabled = YES;
	
	self.trackDelegate = delegate;
}

/*
 Initializes an LMAlbumViewItem with a media item (which contains information for the
 album, artist, etc.)
 */
- (id)initWithMusicTrack:(LMMusicTrack*)track {
    self = [super init];
//    self.layer.backgroundColor = [UIColor greenColor].CGColor;
    if(self){
        self.track = track;
	}
    else{
        NSLog(@"LMAlbumViewItem is nil!");
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
