//
//  LMCompactBrowsingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTiledAlbumCoverView.h"
#import "LMCompactBrowsingView.h"
#import "LMBigListEntry.h"
#import "LMAppIcon.h"

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>

/**
 The actual collection view for displaying collections in a compact method.
 */
@property UICollectionView *collectionView;

/**
 The big list entries that are used in the compact view.
 */
@property NSMutableArray *bigListEntries;

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

@end

@implementation LMCompactBrowsingView

- (LMMusicTrackCollection*)musicTrackCollectionForBigListEntry:(LMBigListEntry*)bigListEntry {
	return [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
	LMMusicTrackCollection *collection = [self musicTrackCollectionForBigListEntry:bigListEntry];
	
	switch(self.musicType){
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			UIImageView *imageView = [UIImageView newAutoLayoutView];
			//			imageView.image = [[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex].representativeItem artistImage];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.layer.shadowColor = [UIColor blackColor].CGColor;
			imageView.layer.shadowRadius = WINDOW_FRAME.size.width/45;
			imageView.layer.shadowOffset = CGSizeMake(0, imageView.layer.shadowRadius/2);
			imageView.layer.shadowOpacity = 0.25f;
			return imageView;
		}
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists: {
			//No need for prep since we're just gonna prep once
			LMTiledAlbumCoverView *tiledAlbumCover = [LMTiledAlbumCoverView newAutoLayoutView];
			tiledAlbumCover.musicCollection = collection;
			return tiledAlbumCover;
		}
		default: {
			NSLog(@"Windows fucking error!");
			return nil;
		}
	}
	
	UIView *contentSubview = [UIView newAutoLayoutView];
	
	contentSubview.backgroundColor = [UIColor purpleColor];
	
	return contentSubview;
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	CGRect frame = [[self.collectionView.visibleCells firstObject] frame];
	
	if(frame.size.width == 0){
		CGSize initialSize = [self collectionView:self.collectionView
										   layout:self.collectionView.collectionViewLayout
						   sizeForItemAtIndexPath:[NSIndexPath indexPathWithIndex:bigListEntry.collectionIndex]];
		frame = CGRectMake(0, 0, initialSize.width, initialSize.height);
	}
	
	return height ? 0.1 : 1.0;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
//	NSLog(@"%@ changed large", bigListEntry);
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	return [[[self musicTrackCollectionForBigListEntry:infoView.associatedBigListEntry] representativeItem] albumTitle];
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return [[[self musicTrackCollectionForBigListEntry:infoView.associatedBigListEntry] representativeItem] artist];
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Single tapped!");
}

- (void)contentViewDoubleTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	[self.musicPlayer stop];
	[self.musicPlayer setNowPlayingCollection:[self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex]];
	[self.musicPlayer play];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.musicTrackCollections.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor orangeColor];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMBigListEntry *bigListEntry = [self.bigListEntries objectAtIndex:indexPath.row];
	
	[cell.contentView addSubview:bigListEntry];
	[bigListEntry autoPinEdgesToSuperviewEdges];
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	//	NSLog(@"Path %@", indexPath);
	NSInteger factor = 3;
	
	CGFloat sideLength = self.frame.size.width/factor;
	
	sideLength -= 15;
	
	CGFloat spacing = (self.frame.size.width-(sideLength*factor))/(factor+1);
	
	NSLog(@"Fuck %f", spacing);
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
	flowLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
	flowLayout.minimumLineSpacing = spacing;
	
	NSLog(@"Fuck %@", NSStringFromCGSize(CGSizeMake(sideLength, sideLength * (2.8/2.0))));
	
	return CGSizeMake(sideLength, sideLength * (2.8/2.0));
}

- (void)reloadContents {
	[self.collectionView removeFromSuperview];
	self.collectionView = nil;
	
	for(UIView *subview in self.bigListEntries){
		[subview removeFromSuperview];
	}
	
	self.didLayoutConstraints = NO;
	
	[self layoutIfNeeded];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		
//		self.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
//		self.musicType = LMMusicTypeAlbums;
		
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		
		self.bigListEntries = [NSMutableArray new];
		
		for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
			LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
			bigListEntry.infoDelegate = self;
			bigListEntry.entryDelegate = self;
			bigListEntry.collectionIndex = i;
			[bigListEntry setup];
			
			[self.bigListEntries addObject:bigListEntry];
		}
		
		
		self.backgroundColor = [UIColor whiteColor];
		self.collectionView.backgroundColor = [UIColor whiteColor];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
	}
}

@end
