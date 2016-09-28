//
//  LMAlbumViewItem.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumViewItem.h"
#import "LMButton.h"
#import "LMLabel.h"
#import "LMAlbumCountLabel.h"

@interface LMAlbumViewItem()

@property UIImageView *albumImageView;
@property UIView *shadingBackgroundView, *textBackgroundView;
@property UILabel *albumTitleView, *albumArtistView, *albumCountView;
@property LMButton *playButton;
@property CAShapeLayer *circleLayer;

@end

@implementation LMAlbumViewItem


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
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingBackgroundView
													 attribute:NSLayoutAttributeCenterX
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterX
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingBackgroundView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterY
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingBackgroundView
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:0.7
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.shadingBackgroundView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:0.7
													  constant:0]];
	
	//The album image view displays the album image.
	self.albumImageView = [[UIImageView alloc]initWithImage:[self.item.artwork imageWithSize:CGSizeMake(500, 500)]];
	self.albumImageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumImageView.layer.cornerRadius = 10;
	self.albumImageView.layer.masksToBounds = YES;
	self.albumImageView.layer.opaque = NO;
	self.albumImageView.clipsToBounds = YES;
	self.albumImageView.backgroundColor = [UIColor blueColor];
	[self addSubview:self.albumImageView];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumImageView
																	attribute:NSLayoutAttributeCenterX
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self
																	attribute:NSLayoutAttributeCenterX
																   multiplier:1.0
																	 constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumImageView
																	attribute:NSLayoutAttributeCenterY
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self
																	attribute:NSLayoutAttributeCenterY
																   multiplier:1.0
																	 constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumImageView
																	attribute:NSLayoutAttributeWidth
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self
																	attribute:NSLayoutAttributeWidth
																   multiplier:0.9
																	 constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumImageView
																	attribute:NSLayoutAttributeHeight
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self
																	attribute:NSLayoutAttributeWidth
																   multiplier:0.9
																	 constant:0]];
	
	//The text background view is a view which contains the play button and album/artist text associated with this item.
	//It has a white background color.
	self.textBackgroundView = [[UIView alloc]init];
	self.textBackgroundView.backgroundColor = [UIColor whiteColor];
	self.textBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.textBackgroundView];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textBackgroundView
													 attribute:NSLayoutAttributeCenterX
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterX
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textBackgroundView
													 attribute:NSLayoutAttributeBottom
													 relatedBy:NSLayoutRelationEqual
														toItem:self.albumImageView
													 attribute:NSLayoutAttributeBottom
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textBackgroundView
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textBackgroundView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:0.2
													  constant:0]];
	
	//The play button allows for easy access to playing the album.
	self.playButton = [[LMButton alloc]init];
	self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
	self.playButton.userInteractionEnabled = YES;
	self.playButton.delegate = delegate;
	[self.textBackgroundView addSubview:self.playButton];
	[self.playButton setupWithImageMultiplier:0.5];
	[self.playButton setImage:[UIImage imageNamed:@"play_white.png"]];
	//self.playButton.backgroundColor = [UIColor blueColor];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeCenterY
													multiplier:1.0
													  constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeHeight
													multiplier:0.8
													  constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeHeight
													multiplier:0.8
													  constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
																		attribute:NSLayoutAttributeLeading
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeLeading
																	   multiplier:1.0
																		 constant:0]];
	
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
	
	NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:self.albumTitleView
																		 attribute:NSLayoutAttributeLeading
																		 relatedBy:NSLayoutRelationEqual
																			toItem:self.playButton
																		 attribute:NSLayoutAttributeTrailing
																		multiplier:1.0
																		  constant:10];
	[leadingConstraint setPriority:UILayoutPriorityRequired];
	[self.textBackgroundView addConstraint:leadingConstraint];
	
	NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeTop
																		relatedBy:NSLayoutRelationEqual
																		toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeTop
																	multiplier:1.0
																		 constant:10];
	[topConstraint setPriority:UILayoutPriorityRequired];
	[self.textBackgroundView addConstraint:topConstraint];
	
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeHeight
																	   multiplier:0.4
																		 constant:0];
	[heightConstraint setPriority:UILayoutPriorityRequired];
	[self.textBackgroundView addConstraint:heightConstraint];
	
	NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:self.albumTitleView
																		  attribute:NSLayoutAttributeTrailing
																		  relatedBy:NSLayoutRelationEqual
																			 toItem:self.textBackgroundView
																		  attribute:NSLayoutAttributeTrailing
																		 multiplier:1.0
																		   constant:0];
	[trailingConstraint setPriority:UILayoutPriorityRequired];
	[self.textBackgroundView addConstraint:trailingConstraint];
	
	//The artist.
	self.albumArtistView = [[LMLabel alloc]init];
	self.albumArtistView.text = self.item.artist;
	self.albumArtistView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.albumArtistView.textAlignment = NSTextAlignmentLeft;
	self.albumArtistView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumArtistView.numberOfLines = 0;
	[self.textBackgroundView addSubview:self.albumArtistView];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtistView
																		attribute:NSLayoutAttributeLeading
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.playButton
																		attribute:NSLayoutAttributeTrailing
																	   multiplier:1.0
																		 constant:10]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtistView
																		attribute:NSLayoutAttributeTop
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.albumTitleView
																		attribute:NSLayoutAttributeBottom
																	   multiplier:1.0
																		 constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtistView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeHeight
																	   multiplier:0.25
																		 constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtistView
																		attribute:NSLayoutAttributeTrailing
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeTrailing
																	   multiplier:1.0
																		 constant:0]];
	
	//The amount of songs in this album.
	self.albumCountView = [LMAlbumCountLabel new];
	self.albumCountView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumCountView.text = [NSString stringWithFormat:@"%lu", numberOfItems];
	self.albumCountView.textColor = [UIColor whiteColor];
	self.albumCountView.textAlignment = NSTextAlignmentCenter;
	[self addSubview:self.albumCountView];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumCountView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeHeight
													multiplier:0.5
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumCountView
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeHeight
													multiplier:0.5
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumCountView
													 attribute:NSLayoutAttributeTrailing
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumCountView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeTop
													multiplier:1.0
													  constant:0]];
}

/*
 Initializes an LMAlbumViewItem with a media item (which contains information for the
 album, artist, etc.)
 */
- (id)initWithMediaItem:(MPMediaItem*)item withAlbumCount:(NSInteger)count {
    self = [super init];
    //self.layer.backgroundColor = [UIColor blueColor].CGColor;
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
