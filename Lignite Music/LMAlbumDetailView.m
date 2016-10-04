//
//  LMAlbumDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMTableView.h"
#import "LMListEntry.h"
#import "LMButton.h"
#import "LMLabel.h"
#import "LMAlbumDetailView.h"
#import "LMExtras.h"
#import "LMNowPlayingViewController.h"
#import "LMSongDetailControlView.h"

@interface LMAlbumDetailView() <LMButtonDelegate, LMListEntryDelegate, LMTableViewSubviewDelegate>

@property MPMediaItemCollection *albumCollection;
@property UIImageView *albumArtView;
@property UIView *textBackgroundView, *controlView;
@property LMSongDetailControlView *controlBackgroundView;
@property LMTableView *songListTableView;
@property LMButton *playButton;
@property LMLabel *albumTitleView, *albumArtistView, *albumInfoView;
@property NSMutableArray *itemArray;
@property NSInteger currentlyHighlighted;

@property NSLayoutConstraint *textBackgroundConstraint;
@property CGPoint originalPoint, currentPoint;
@property BOOL setupGesture;

@end

@implementation LMAlbumDetailView

- (id)prepareSubviewAtIndex:(NSUInteger)index {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	return entry;
}

- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(height){
		return (1.0f/8.0f);
	}
	return 0.9;
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	LMListEntry *entry = nil;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *indexEntry = [self.itemArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.itemArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 0.0f;
}

- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return true;
}

- (void)tappedListEntry:(LMListEntry*)entry {
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:entry.collectionIndex];
	
	NSLog(@"%@", self.albumCollection.representativeItem.artist);
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = entry.collectionIndex;
	
	MPMusicPlayerController *controller = [MPMusicPlayerController systemMusicPlayer];
	[controller stop];
	[controller setQueueWithItemCollection:self.albumCollection];
	[controller setNowPlayingItem:item];
	[controller play];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return LIGNITE_RED;
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:entry.collectionIndex];
	return item.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	MPMediaItem *item = [self.albumCollection.items objectAtIndex:entry.collectionIndex];
	return [NSString stringWithFormat:NSLocalizedString(@"LengthOfSong", nil), [LMNowPlayingViewController durationStringTotalPlaybackTime:item.playbackDuration]];
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

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
		for(int i = 0; i < amount; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
		}
	}
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self];
	
	NSLog(@"Translation %@", NSStringFromCGPoint(translation));
	
//	if(self.textBackgroundConstraint.constant < 30){
//		self.textBackgroundConstraint.constant = self.currentPoint.y + translation.y;
//	}
//	[self.textBackgroundView layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		self.currentPoint = CGPointMake(self.currentPoint.x, self.currentPoint.y + translation.y);
		
		[self.textBackgroundView layoutIfNeeded];
		self.textBackgroundConstraint.constant = translation.y;
		[UIView animateWithDuration:0.5 delay:0
			 usingSpringWithDamping:0.5 initialSpringVelocity:0.0f
							options:0 animations:^{
			[self layoutIfNeeded];
		} completion:nil];
	}
	
	/*
	recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
										 recognizer.view.center.y + translation.y);
	[recognizer setTranslation:CGPointMake(0, 0) inView:self.textBackgroundView];
	 */
 
}

- (void)layoutSubviews {
	NSLog(@"Hey %@", NSStringFromCGRect(self.textBackgroundView.frame));
	if(!self.setupGesture){
		self.currentPoint = self.textBackgroundView.frame.origin;
		self.setupGesture = YES;
	}
	
	[super layoutSubviews];
}

- (void)setup {
	self.currentlyHighlighted = -1;
	
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
	self.textBackgroundConstraint = [NSLayoutConstraint constraintWithItem:self.textBackgroundView
																 attribute:NSLayoutAttributeTop
																 relatedBy:NSLayoutRelationEqual
																	toItem:self
																 attribute:NSLayoutAttributeCenterY
																multiplier:1.0
																  constant:0];
	[self addConstraint:self.textBackgroundConstraint];
	[self.textBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.textBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.125];
	
	UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
	[self.textBackgroundView addGestureRecognizer:recognizer];

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
	if(representativeItem.genre){
		self.albumInfoView.text = [NSString stringWithFormat:NSLocalizedString(@"AlbumDetailInfoWithGenre", nil), representativeItem.genre, self.albumCollection.count, NSLocalizedString(self.albumCollection.count == 1 ? @"Song" : @"Songs", nil)];
	}
	else{
		self.albumInfoView.text = [NSString stringWithFormat:NSLocalizedString(@"AlbumDetailInfoWithoutGenre", nil), self.albumCollection.count, NSLocalizedString(self.albumCollection.count == 1 ? @"Song" : @"Songs", nil)];
	}
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
	
	self.controlBackgroundView = [[LMSongDetailControlView alloc]init];
	self.controlBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.controlBackgroundView];
	
	[self.controlBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.textBackgroundView];
	[self.controlBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.textBackgroundView];
	[self.controlBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.textBackgroundView];
	
	[self.controlBackgroundView updateConstraints];
	
	self.songListTableView = [[LMTableView alloc]init];
	self.songListTableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.songListTableView.amountOfItemsTotal = self.albumCollection.count;
	self.songListTableView.subviewDelegate = self;
	[self.songListTableView prepareForUse];
	[self addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.controlBackgroundView];
	[self.songListTableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.songListTableView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.songListTableView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	
	self.textBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.textBackgroundView.layer.shadowOpacity = 0.10f;
	self.textBackgroundView.layer.shadowRadius = 5;
	self.textBackgroundView.layer.shadowOffset = CGSizeMake(0, 10);
	self.textBackgroundView.layer.masksToBounds = NO;
	
	[self insertSubview:self.textBackgroundView aboveSubview:self.songListTableView];
	
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
