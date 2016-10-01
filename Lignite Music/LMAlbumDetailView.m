//
//  LMAlbumDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMAdaptiveScrollView.h"
#import "LMListEntry.h"
#import "LMButton.h"
#import "LMLabel.h"
#import "LMAlbumDetailView.h"
#import "LMExtras.h"
#import "LMNowPlayingViewController.h"

@interface LMAlbumDetailView() <LMButtonDelegate, LMListEntryDelegate, LMAdaptiveScrollViewDelegate>

@property MPMediaItemCollection *albumCollection;
@property UIImageView *albumArtView;
@property UIView *textBackgroundView, *controlView;
@property LMAdaptiveScrollView *songListView;
@property LMButton *playButton;
@property LMLabel *albumTitleView, *albumArtistView, *albumInfoView;

@end

@implementation LMAlbumDetailView

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.songListView.subviewArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.songListView.subviewArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)sizingFactorialRelativeToWindowForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView height:(BOOL)height {
	if(height){
		return (1.0f/8.0f);
	}
	return 0.9;
}

- (float)topSpacingForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView {
	return 15.0f;
}

- (BOOL)dividerForAdaptiveScrollView:(LMAdaptiveScrollView*)scrollView {
	return true;
}

- (void)prepareSubview:(id)subview forIndex:(NSUInteger)index subviewPreviouslyLoaded:(BOOL)hasLoaded {
	LMListEntry *entry = (LMListEntry*)subview;
	
	if(!hasLoaded){
		[entry setup];
	}
}

- (void)tappedListEntry:(LMListEntry*)entry {
	int index = [self indexOfListEntry:entry];
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:index];
	
	NSLog(@"%@", self.albumCollection.representativeItem.artist);
	
	for(int i = 0; i < self.albumCollection.count; i++){
		[(LMListEntry*)[self.songListView.subviewArray objectAtIndex:i] changeHighlightStatus:(index == i)];
	}
	
	MPMusicPlayerController *controller = [MPMusicPlayerController systemMusicPlayer];
	[controller stop];
	[controller setNowPlayingItem:item];
	[controller setQueueWithItemCollection:self.albumCollection];
	[controller play];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return LIGNITE_RED;
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	int indexOfEntry = [self indexOfListEntry:entry];
	if(indexOfEntry < 0){
		return @"Error!";
	}
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:indexOfEntry];
	return item.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	int indexOfEntry = [self indexOfListEntry:entry];
	if(indexOfEntry < 0){
		return @"Error!";
	}
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:indexOfEntry];
	return [NSString stringWithFormat:@"Length: %@", [LMNowPlayingViewController durationStringTotalPlaybackTime:item.playbackDuration]];
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	return nil;
}

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Clicked button");
}

- (void)pinchedView {
	self.userInteractionEnabled = NO;
	self.hidden = YES;
	[self removeFromSuperview];
}

- (void)setup {
	UIImage *albumArtImage = [[self.albumCollection.representativeItem artwork] imageWithSize:CGSizeMake(500, 500)];
	self.albumArtView = [[UIImageView alloc] initWithImage:albumArtImage];
	self.albumArtView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.albumArtView];
	
	[self.albumArtView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.albumArtView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.albumArtView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
	
	//The text background view is a view which contains the play button and album/artist text associated with this item.
	//It has a white background color.
	self.textBackgroundView = [[UIView alloc]init];
	self.textBackgroundView.backgroundColor = [UIColor whiteColor];
	self.textBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.textBackgroundView];
	
	[self.textBackgroundView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textBackgroundView
													 attribute:NSLayoutAttributeTop
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterY
													multiplier:1.0
													  constant:0]];
	[self.textBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.textBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.125];

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
	[self.playButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.6];
	[self.playButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.6];
	[self.playButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.textBackgroundView withOffset:10];
	
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
	
	[self.albumTitleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.playButton withOffset:10];
	[self.albumTitleView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.textBackgroundView withOffset:6];
	[self.albumTitleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.4];
	[self.albumTitleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textBackgroundView];
	
	//The artist.
	self.albumArtistView = [[LMLabel alloc]init];
	self.albumArtistView.text = self.albumCollection.representativeItem.artist;
	self.albumArtistView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.albumArtistView.textAlignment = NSTextAlignmentLeft;
	self.albumArtistView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumArtistView.numberOfLines = 1;
	[self.textBackgroundView addSubview:self.albumArtistView];
	
	[self.albumArtistView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumTitleView];
	[self.albumArtistView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumTitleView];
	[self.albumArtistView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textBackgroundView];
	[self.albumArtistView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.25];
	
	//The details about the song.
	self.albumInfoView = [[LMLabel alloc]init];
	MPMediaItem *representativeItem = self.albumCollection.representativeItem;
	self.albumInfoView.text = [NSString stringWithFormat:@"%@ | %lu songs", representativeItem.genre, self.albumCollection.count];
	self.albumInfoView.translatesAutoresizingMaskIntoConstraints = NO;
	self.albumInfoView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
	self.albumInfoView.textAlignment = NSTextAlignmentLeft;
	self.albumInfoView.lineBreakMode = NSLineBreakByTruncatingTail;
	self.albumInfoView.numberOfLines = 1;
	[self.textBackgroundView addSubview:self.albumInfoView];
	
	[self.albumInfoView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.albumTitleView];
	[self.albumInfoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.albumArtistView];
	[self.albumInfoView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.albumTitleView];
	[self.albumInfoView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView withMultiplier:0.20];
	
	self.songListView = [[LMAdaptiveScrollView alloc]init];
	self.songListView.translatesAutoresizingMaskIntoConstraints = NO;
	NSMutableArray *itemArray = [NSMutableArray new];
	for(int i = 0; i < self.albumCollection.count; i++){
		LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
		[itemArray addObject:listEntry];
	}
	
	self.songListView.subviewArray = itemArray;
	self.songListView.subviewDelegate = self;
	[self addSubview:self.songListView];
	
	[self.songListView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.textBackgroundView];
	[self.songListView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.songListView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.songListView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	
	self.textBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.textBackgroundView.layer.shadowOpacity = 0.5f;
	self.textBackgroundView.layer.shadowRadius = 7;
	self.textBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
	self.textBackgroundView.layer.masksToBounds = NO;
	
	[self insertSubview:self.textBackgroundView aboveSubview:self.songListView];
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchedView)];
	[self addGestureRecognizer:pinchGesture];
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
