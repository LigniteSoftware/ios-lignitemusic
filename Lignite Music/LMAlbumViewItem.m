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

@interface LMAlbumViewItem()

@property UIImageView *albumImageView;
@property UIView *textBackgroundView;
@property UILabel *albumTitleView, *albumArtistView;
@property LMButton *playButton;
@property MPMediaItem *item;
@property CAShapeLayer *circleLayer;

@end

@implementation LMAlbumViewItem

- (void)load {
	self.albumImageView = [[UIImageView alloc]initWithImage:[self.item.artwork imageWithSize:CGSizeMake(500, 500)]];
	self.albumImageView.translatesAutoresizingMaskIntoConstraints = NO;
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
	
	self.playButton = [[LMButton alloc]init];
	self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self.textBackgroundView addSubview:self.playButton];
	[self.playButton setupWithImageMultiplier:0.5];
	[self.playButton setImage:[UIImage imageNamed:@"play_white.png"]];
	//self.playButton.backgroundColor = [UIColor blueColor];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeCenterY
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
	
	self.albumTitleView = [[UILabel alloc]init];
	self.albumTitleView.text = self.item.albumTitle;
	self.albumTitleView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumTitleView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.albumTitleView.minimumScaleFactor = 10/self.albumTitleView.font.pointSize;
	self.albumTitleView.textAlignment = NSTextAlignmentLeft;
	self.albumTitleView.numberOfLines = 0;
	self.albumTitleView.adjustsFontSizeToFitWidth = YES;
	[self.textBackgroundView addSubview:self.albumTitleView];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumTitleView
													 attribute:NSLayoutAttributeLeading
													 relatedBy:NSLayoutRelationEqual
														toItem:self.playButton
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.0
													  constant:10]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeTop
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeTop
																	   multiplier:1.0
																		 constant:10]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeHeight
																	   multiplier:0.4
																		 constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.albumTitleView
																		attribute:NSLayoutAttributeWidth
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeWidth
																	   multiplier:1.0
																		 constant:0]];
	
	self.albumArtistView = [[UILabel alloc]init];
	self.albumArtistView.text = self.item.artist;
	self.albumArtistView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.albumArtistView.minimumScaleFactor = 6/self.albumArtistView.font.pointSize;
	self.albumArtistView.textAlignment = NSTextAlignmentLeft;
	self.albumArtistView.numberOfLines = 0;
	self.albumArtistView.adjustsFontSizeToFitWidth = YES;
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
																		attribute:NSLayoutAttributeWidth
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeWidth
																	   multiplier:1.0
																		 constant:0]];
	
	self.albumImageView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.albumImageView.layer.shadowOpacity = 0.25f;
	self.albumImageView.layer.shadowRadius = self.frame.size.width/2 + 10;
	self.albumImageView.layer.shadowOffset = CGSizeMake(0, 0);
	self.albumImageView.layer.masksToBounds = 0;
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
