//
//  LMAlbumDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAdaptiveScrollView.h"
#import "LMListEntry.h"
#import "LMButton.h"
#import "LMLabel.h"
#import "LMAlbumDetailView.h"
#import "LMExtras.h"

@interface LMAlbumDetailView() <LMButtonDelegate, LMListEntryDelegate, LMAdaptiveScrollViewDelegate>

@property MPMediaItemCollection *albumCollection;
@property UIImageView *albumArtView;
@property UIView *textBackgroundView, *controlView;
@property LMAdaptiveScrollView *songListView;
@property LMButton *playButton;
@property LMLabel *albumTitleView, *albumArtistView;

@end

@implementation LMAlbumDetailView

- (void)prepareSubview:(id)subview forIndex:(NSUInteger)index {
	NSLog(@"Ayy %lu", (unsigned long)index);
	LMListEntry *entry = (LMListEntry*)subview;

	[self.songListView addSubview:entry];
	entry.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self.songListView addConstraint:[NSLayoutConstraint constraintWithItem:entry
																	attribute:NSLayoutAttributeCenterX
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.songListView
																	attribute:NSLayoutAttributeCenterX
																   multiplier:1.0
																	 constant:0]];
	
	[self.songListView addConstraint:[NSLayoutConstraint constraintWithItem:entry
																	attribute:NSLayoutAttributeTop
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.songListView
																	attribute:NSLayoutAttributeTop
																   multiplier:1.0
																	 constant:self.songListView.frame.size.height*(0.4+0.1)*index+5]];
	
	[self.songListView addConstraint:[NSLayoutConstraint constraintWithItem:entry
																	attribute:NSLayoutAttributeWidth
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.songListView
																	attribute:NSLayoutAttributeWidth
																   multiplier:0.8
																	 constant:0]];
	
	[self.songListView addConstraint:[NSLayoutConstraint constraintWithItem:entry
																	attribute:NSLayoutAttributeHeight
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.songListView
																	attribute:NSLayoutAttributeHeight
																   multiplier:0.4
																	 constant:0]];
	
	[entry setup];
	
	if(index == self.albumCollection.count-1){
		NSLog(@"Setting to %f", self.songListView.frame.size.height*(0.4+0.1)*(index+1)+5);
		[self.songListView setContentSize:CGSizeMake(self.frame.size.width, self.frame.size.height*(0.4+0.1)*(index+1)+5)];
	}
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped list entry");
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return LIGNITE_RED;
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	return @"Test title";
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	return @"Subtitle test";
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return nil;
}

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Clicked button");
}

- (void)setup {
	UIImage *albumArtImage = [[self.albumCollection.representativeItem artwork] imageWithSize:CGSizeMake(500, 500)];
	self.albumArtView = [[UIImageView alloc] initWithImage:albumArtImage];
	self.albumArtView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.albumArtView];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtView
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTop
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtView
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArtView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:1.0
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
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self.albumArtView
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
													 attribute:NSLayoutAttributeHeight
													multiplier:0.125
													  constant:0]];
	
	//The play button allows for easy access to playing the album.
	self.playButton = [[LMButton alloc]init];
	self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
	self.playButton.userInteractionEnabled = YES;
	self.playButton.delegate = self;
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
																	   multiplier:0.6
																		 constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
																		attribute:NSLayoutAttributeHeight
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeHeight
																	   multiplier:0.6
																		 constant:0]];
	
	[self.textBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:self.playButton
																		attribute:NSLayoutAttributeLeading
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.textBackgroundView
																		attribute:NSLayoutAttributeLeading
																	   multiplier:1.0
																		 constant:10]];
	
	//The album's title.
	self.albumTitleView = [[LMLabel alloc]init];
	self.albumTitleView.text = self.albumCollection.representativeItem.albumTitle;
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
	self.albumArtistView.text = self.albumCollection.representativeItem.artist;
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
	
	self.songListView = [[LMAdaptiveScrollView alloc]init];
	self.songListView.translatesAutoresizingMaskIntoConstraints = NO;
	NSMutableArray *itemArray = [NSMutableArray new];
	for(int i = 0; i < self.albumCollection.count; i++){
		LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
		[itemArray addObject:listEntry];
	}
	
	self.songListView.subviewArray = itemArray;
	self.songListView.subviewDelegate = self;
	self.songListView.backgroundColor = [UIColor blueColor];
	[self.songListView setContentSize:CGSizeMake(self.frame.size.width, self.frame.size.height/3)];
	[self addSubview:self.songListView];
	
	for(int i = 0; i < self.albumCollection.count; i++){
		LMListEntry *listEntry = (LMListEntry*)[itemArray objectAtIndex:i];
		[self prepareSubview:listEntry forIndex:i];
	}
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.songListView
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self.textBackgroundView
													 attribute:NSLayoutAttributeBottom
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.songListView
													 attribute:NSLayoutAttributeBottom
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeBottom
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.songListView
													 attribute:NSLayoutAttributeLeading
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeLeading
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.songListView
													 attribute:NSLayoutAttributeTrailing
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeTrailing
													multiplier:1.0
													  constant:0]];
	
	self.textBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.textBackgroundView.layer.shadowOpacity = 0.5f;
	self.textBackgroundView.layer.shadowRadius = 7;
	self.textBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
	self.textBackgroundView.layer.masksToBounds = NO;
}

/*
 Initializes an LMAlbumDetailView with a media collection (which contains information for the
 album and all of its tracks)
 */
- (id)initWithMediaItemCollection:(MPMediaItemCollection*)collection {
	self = [super init];
	self.backgroundColor = [UIColor whiteColor];
	if(self){
		self.albumCollection = collection;
	}
	else{
		NSLog(@"LMAlbumDetailView is nil!");
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
