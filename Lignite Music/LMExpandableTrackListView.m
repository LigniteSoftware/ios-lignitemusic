//
//  LMExpandableTrackListView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableTrackListControlBar.h"
#import "LMExpandableInnerShadowView.h"
#import "LMExpandableTrackListView.h"
#import "LMMusicCollectionsView.h"
#import "YIInnerShadowView.h"
#import "LMLayoutManager.h"
#import "LMTriangleView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"

#import "NSTimer+Blocks.h"

@interface LMExpandableTrackListView()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate, LMExpandableTrackListControlBarDelegate, LMMusicPlayerDelegate>

/**
 The control/navigation bar which goes above the view's collection view.
 */
@property LMExpandableTrackListControlBar *expandableTrackListControlBar;

/**
 The view which displays the inner shadow.
 */
@property LMExpandableInnerShadowView *innerShadowView;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The currently highlighted entry.
 */
@property NSInteger currentlyHighlightedEntry;

/**
 The specific track collections associated with this browsing view. For example, an artist would have their albums within this array of collections.
 */
@property NSArray<LMMusicTrackCollection*>* specificTrackCollections;

/**
 The tile view of albums used for displaying specific track collections.
 */
@property LMMusicCollectionsView *albumTileView;

/**
 The top constraint for the collection view. Its constant should be the frame's height if displaying the track list.
 */
@property NSLayoutConstraint *collectionViewTopConstraint;

@end

@implementation LMExpandableTrackListView

@synthesize musicTrackCollection = _musicTrackCollection;

+ (NSInteger)numberOfColumns {
	return fmax(1.0, WINDOW_FRAME.size.width/300.0f);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	//	if(self.specificTrackCollections){
	//		int count = 0;
	//		for(LMMusicTrackCollection *collection in self.specificTrackCollections){
	//			for(LMMusicTrack *track in collection.items){
	//				if(track.persistentID == newTrack.persistentID){
	//					newHighlightedIndex = count;
	//					NSLog(@"Found a match");
	//				}
	//			}
	//			count++;  
	//		}
	//	}
	//	else{
	for(int i = 0; i < self.musicTrackCollection.trackCount; i++){
		LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:i];
		
		if(track.persistentID == newTrack.persistentID){
			newHighlightedIndex = i;
		}
	}
	//	}
	
	
	highlightedEntry = [self listEntryForIndex:newHighlightedIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlightedEntry];
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		BOOL updateNowPlayingStatus = self.currentlyHighlightedEntry == -1;
		self.currentlyHighlightedEntry = newHighlightedIndex;
		if(updateNowPlayingStatus){
			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
		}
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	for(id subview in cell.contentView.subviews){
		if([subview class] == [LMListEntry class]){
			return subview;
		}
	}
	return nil;
}

- (void)tappedListEntry:(LMListEntry*)entry {
	if(self.specificTrackCollections){
		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];

		NSLog(@"Launch that bitch %@", collection);
		return;
	}
	
	NSLog(@"Tapped %d", (int)entry.collectionIndex);
	
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlightedEntry];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlightedEntry = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTrackCollection){
#ifdef SPOTIFY
		[self.musicPlayer pause];
#else
		[self.musicPlayer stop];
#endif
		[self.musicPlayer setNowPlayingCollection:self.musicTrackCollection];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return musicTrack.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *musicTrack = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return musicTrack.artist;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
//	if(self.specificTrackCollections){
//		LMMusicTrackCollection *collection = [self.specificTrackCollections objectAtIndex:entry.collectionIndex];
//		return [collection.representativeItem albumArt];
//	}
	LMMusicTrack *track = [self.musicTrackCollection.items objectAtIndex:entry.collectionIndex];
	return [track albumArt];
}

- (LMMusicTrackCollection*)musicTrackCollection {
	return _musicTrackCollection;
}

- (void)setMusicTrackCollection:(LMMusicTrackCollection *)musicTrackCollection {
	_musicTrackCollection = musicTrackCollection;
	
	[self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [LMColour superLightGrayColour];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	if(cell.contentView.subviews.count == 0){
		NSInteger fixedIndex = indexPath.row; // (indexPath.row/[LMExpandableTrackListView numberOfColumns]) + ((indexPath.row % [LMExpandableTrackListView numberOfColumns])*([self collectionView:self.collectionView numberOfItemsInSection:0]/[LMExpandableTrackListView numberOfColumns]));
		
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = fixedIndex;
		listEntry.associatedData = [self.musicTrackCollection.items objectAtIndex:fixedIndex];
		listEntry.isLabelBased = (self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations);
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour superLightGrayColour];
		
		[listEntry autoPinEdgesToSuperviewEdges];
		
		[listEntry changeHighlightStatus:fixedIndex == self.currentlyHighlightedEntry animated:NO];
		
		
		BOOL isInLastRow = indexPath.row >= (self.musicTrackCollection.count-[LMExpandableTrackListView numberOfColumns]);
		
		if(!isInLastRow){
			UIView *dividerView = [UIView newAutoLayoutView];
			dividerView.backgroundColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1.0];
			[listEntry addSubview:dividerView];
			
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[dividerView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-(flowLayout.sectionInset.bottom/2.0)];
			[dividerView autoSetDimension:ALDimensionHeight toSize:1.0];
		}
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.musicTrackCollection.count;
}

+ (CGSize)currentItemSize {
	return CGSizeMake(WINDOW_FRAME.size.width/[LMExpandableTrackListView numberOfColumns] - 20,
					  fmin(([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/8.0, 80));
}

+ (CGSize)sizeForAmountOfItems:(NSInteger)amountOfItems {
	CGSize size = CGSizeMake(WINDOW_FRAME.size.width, 0);
	NSInteger numberOfColumns = [LMExpandableTrackListView numberOfColumns];
	
	size.height += (amountOfItems * [LMExpandableTrackListView currentItemSize].height)/numberOfColumns;
	size.height += (amountOfItems * 10)/numberOfColumns; //Spacing
	size.height += 10;
	size.height += [LMExpandableTrackListControlBar recommendedHeight];
	
	if(numberOfColumns % 2 == 0 && amountOfItems % 2 != 0){ //If the number of columns is even but the amount of actual items is uneven
		size.height += [LMExpandableTrackListView currentItemSize].height;
	}
	
//	size.height = 400;
	
	return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
//	return CGSizeMake(self.frame.size.width, self.frame.size.height/[self collectionView:self.collectionView numberOfItemsInSection:0]);
	return [LMExpandableTrackListView currentItemSize];
}

- (void)closeButtonTappedForExpandableTrackListControlBar:(LMExpandableTrackListControlBar *)controlBar {
	NSLog(@"\"really?\"");
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.flowLayout;
	flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
}

- (void)backButtonTappedForExpandableTrackListControlBar:(LMExpandableTrackListControlBar *)controlBar {
	NSLog(@"\"back?\"");
	self.collectionViewTopConstraint.constant = 0;
	[UIView animateWithDuration:0.25 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)layoutSubviews {
	self.backgroundColor = [UIColor yellowColor];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
	
//	for(UIView *subview in self.subviews){
//		[subview removeFromSuperview];
//		subview.hidden = YES;
//	}
		
	
		self.clipsToBounds = NO;
		
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		[self.musicPlayer addMusicDelegate:self];
		
		self.currentlyHighlightedEntry = -1;
		
		
		
		BOOL usingSpecificTrackCollections = (self.musicType != LMMusicTypePlaylists
											  && self.musicType != LMMusicTypeCompilations
											  && self.musicType != LMMusicTypeAlbums);
		
		if(usingSpecificTrackCollections){
			self.specificTrackCollections = [self.musicPlayer collectionsForRepresentativeTrack:self.musicTrackCollection.representativeItem
																				   forMusicType:self.musicType];
		}
		
		
		self.expandableTrackListControlBar = [LMExpandableTrackListControlBar newAutoLayoutView];
		self.expandableTrackListControlBar.delegate = self;
		self.expandableTrackListControlBar.musicTrackCollection = self.musicTrackCollection;
//		self.expandableTrackListControlBar.mode = LMExpandableTrackListControlBarModeControlWithAlbumDetail;
		[self addSubview:self.expandableTrackListControlBar];
		
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		
		self.albumTileView = [LMMusicCollectionsView newAutoLayoutView];
		self.albumTileView.backgroundColor = [UIColor purpleColor];
		self.albumTileView.trackCollections = self.specificTrackCollections;
		[self addSubview:self.albumTileView];
		
		[self.albumTileView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.albumTileView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandableTrackListControlBar];
		[self.albumTileView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		[self.albumTileView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
		
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.userInteractionEnabled = YES;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
		self.collectionView.backgroundColor = [LMColour superLightGrayColour];
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		self.collectionViewTopConstraint = [self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandableTrackListControlBar];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.collectionView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.albumTileView];
//		self.collectionView.hidden = YES;
		
		if(self.specificTrackCollections){
			self.collectionViewTopConstraint.constant = self.frame.size.width*2;
		}
		
		
		self.innerShadowView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.innerShadowView.backgroundColor = [UIColor clearColor];
		self.innerShadowView.userInteractionEnabled = NO;
		self.innerShadowView.flowLayout = self.flowLayout;
		[self addSubview:self.innerShadowView];
		
		[self.innerShadowView autoPinEdgesToSuperviewEdges];
		
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
		
//		[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
//			self.collectionViewTopConstraint.constant = 0;
//			[UIView animateWithDuration:0.25 animations:^{
//				self.expandableTrackListControlBar.mode = LMExpandableTrackListControlBarModeControlWithAlbumDetail;
//				[self layoutIfNeeded];
//			}];
//		} repeats:NO];
	}
	else{
		[self.collectionView reloadData];
		[self.innerShadowView removeFromSuperview];
		
		self.innerShadowView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.innerShadowView.backgroundColor = [UIColor clearColor];
		self.innerShadowView.userInteractionEnabled = NO;
		self.innerShadowView.flowLayout = self.flowLayout;
		[self addSubview:self.innerShadowView];
		
		[self.innerShadowView autoPinEdgesToSuperviewEdges];
		
		[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	}
	
	[super layoutSubviews];
}

//- (void)drawInnerShadowInContext:(CGContextRef)context
//						withPath:(CGPathRef)path
//					 shadowColor:(CGColorRef)shadowColor
//						  offset:(CGSize)offset
//					  blurRadius:(CGFloat)blurRadius {
//	
//	CGContextSaveGState(context);
//	
//	CGContextAddPath(context, path);
//	CGContextClip(context);
//	
//	CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);
//	
//	CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
//	CGContextBeginTransparencyLayer(context, NULL);
//	CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
//	CGContextSetBlendMode(context, kCGBlendModeSourceOut);
//	CGContextSetFillColorWithColor(context, opaqueShadowColor);
//	CGContextAddPath(context, path);
//	CGContextFillPath(context);
//	CGContextEndTransparencyLayer(context);
//	
//	CGContextRestoreGState(context);
//	
//	CGColorRelease(opaqueShadowColor);
//}
//
//- (UIBezierPath*)path {
//	UIBezierPath *path = [UIBezierPath new];
//	[path moveToPoint:(CGPoint){self.frame.size.width/2, -self.frame.size.height*0.05}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width/2 + self.innerShadowView.frame.size.width/2, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, self.frame.size.height}];
//	[path addLineToPoint:(CGPoint){-10, self.frame.size.height}];
//	[path addLineToPoint:(CGPoint){-10, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width/2 - self.innerShadowView.frame.size.width/2, 0}];
//
//	[path closePath];
//	
//	return path;
//}
//
//
//- (void)drawRect:(CGRect)rect {
//	[super drawRect:rect];
//	
//	NSLog(@"%@", NSStringFromCGRect(self.innerShadowView.frame));
//	
//	[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self path].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
//}

//- (instancetype)init {
//	self = [super init];
//	if(self) {
//		
//	}
//	return self;
//}

@end
