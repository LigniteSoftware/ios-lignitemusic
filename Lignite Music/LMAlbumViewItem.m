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
#import "LMButton.h"
#import "LMLabel.h"
#import "LMAlbumCountLabel.h"
#import "LMOperationQueue.h"

@interface LMAlbumViewItem() <LMButtonDelegate>

@property UIImageView *albumImageView;
@property UIView *shadingBackgroundView, *textBackgroundView;
@property UILabel *albumTitleView, *albumArtistView, *albumCountView;
@property LMButton *playButton;
@property CAShapeLayer *circleLayer;
@property id itemDelegate;
@property LMOperationQueue *queue;

@end

@implementation LMAlbumViewItem

- (void)clickedButton:(LMButton *)button {
	if(self.itemDelegate){
		[self.itemDelegate clickedPlayButtonOnAlbumViewItem:self];
	}
}

- (void)tappedOnView {
	if(self.itemDelegate){
		[self.itemDelegate clickedAlbumViewItem:self];
	}
}

- (void)updateContentsWithMediaItem:(MPMediaItem*)item andNumberOfItems:(NSInteger)numberOfItems {
	if(!self.queue){
		self.queue = [[LMOperationQueue alloc] init];
	}
		
	[self.queue cancelAllOperations];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		UIImage *image = [item.artwork imageWithSize:CGSizeMake(500, 500)];
		dispatch_sync(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			self.albumImageView.image = image;
			NSLog(@"Done.");
		});
	}];

	[self.queue addOperation:operation];
	
	self.albumTitleView.text = item.albumTitle;
	self.albumArtistView.text = item.artist;
	self.albumCountView.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfItems];
	
	self.item = item;
}

/**
 Sets up the LMAlbumViewItem with a number of items that's available in that album.

 @param numberOfItems The number of items in the album associated with this item.
 */
- (void)setupWithAlbumCount:(NSUInteger)numberOfItems andDelegate:(id)delegate {
	//The shading background view gives a shadow effect to the item.
	self.shadingBackgroundView = [UIView new];
	self.shadingBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	self.shadingBackgroundView.backgroundColor = [UIColor whiteColor];
	self.shadingBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.shadingBackgroundView.layer.shadowOpacity = 0.75f;
	self.shadingBackgroundView.layer.shadowRadius = self.frame.size.width/2 + 20;
	self.shadingBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
	self.shadingBackgroundView.layer.masksToBounds = NO;
	[self addSubview:self.shadingBackgroundView];
	
	[self.shadingBackgroundView autoCenterInSuperview];
	[self.shadingBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.7];
	[self.shadingBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:0.7];
	
	//The album image view displays the album image.
	self.albumImageView = [[UIImageView alloc]initWithImage:[self.item.artwork imageWithSize:CGSizeMake(500, 500)]];
	self.albumImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumImageView.layer.cornerRadius = 10;
	self.albumImageView.layer.masksToBounds = YES;
	self.albumImageView.layer.opaque = NO;
	self.albumImageView.clipsToBounds = YES;
	self.albumImageView.backgroundColor = [UIColor blueColor];
	[self addSubview:self.albumImageView];
	
	[self.albumImageView autoCenterInSuperview];
	[self.albumImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.9];
	[self.albumImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:0.9];
	
	//The text background view is a view which contains the play button and album/artist text associated with this item.
	//It has a white background color.
	self.textBackgroundView = [[UIView alloc]init];
	self.textBackgroundView.backgroundColor = [UIColor whiteColor];
	self.textBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.textBackgroundView];
	
	[self.textBackgroundView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
	[self.textBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.albumImageView];
	[self.textBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:1.0];
	[self.textBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withMultiplier:0.2];
	
	//The play button allows for easy access to playing the album.
	self.playButton = [[LMButton alloc]init];
	self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
	self.playButton.userInteractionEnabled = YES;
	self.playButton.delegate = self;
	[self.textBackgroundView addSubview:self.playButton];
	[self.playButton setupWithImageMultiplier:0.5];
	[self.playButton setImage:[UIImage imageNamed:@"play_white.png"]];
	//self.playButton.backgroundColor = [UIColor blueColor];
	
	[self.playButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.textBackgroundView];
	[self.playButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.8];
	[self.playButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.8];
	[self.playButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.textBackgroundView];
	
	//The album's title.
	self.albumTitleView = [[LMLabel alloc]init];
	self.albumTitleView.text = self.item.albumTitle;
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
	[self.albumTitleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.4];
	[self.albumTitleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textBackgroundView];
	
	//The artist.
	self.albumArtistView = [[LMLabel alloc]init];
	self.albumArtistView.text = self.item.artist;
	self.albumArtistView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.albumArtistView.textAlignment = NSTextAlignmentLeft;
	self.albumArtistView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumArtistView.numberOfLines = 0;
	[self.textBackgroundView addSubview:self.albumArtistView];
	
	[self.albumArtistView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumTitleView];
	[self.albumArtistView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumTitleView];
	[self.albumArtistView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.25];
	[self.albumArtistView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textBackgroundView];
	
	//The amount of songs in this album.
	self.albumCountView = [LMAlbumCountLabel new];
	self.albumCountView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumCountView.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfItems];
	self.albumCountView.textColor = [UIColor whiteColor];
	self.albumCountView.textAlignment = NSTextAlignmentCenter;
	[self addSubview:self.albumCountView];
	
	[self.albumCountView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.5];
	[self.albumCountView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.5];
	[self.albumCountView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textBackgroundView];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumCountView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeTop
													multiplier:1.0
													  constant:0]];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView)];
	[self addGestureRecognizer:tapGestureRecognizer];
	
	self.userInteractionEnabled = YES;
	
	self.itemDelegate = delegate;
}

/*
 Initializes an LMAlbumViewItem with a media item (which contains information for the
 album, artist, etc.)
 */
- (id)initWithMediaItem:(MPMediaItem*)item {
    self = [super init];
//    self.layer.backgroundColor = [UIColor greenColor].CGColor;
    if(self){
        self.item = item;
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
