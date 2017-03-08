//
//  LMCompactBrowsingView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/4/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCompactBrowsingView.h"
#import "LMBigListEntry.h"
#import "LMAppIcon.h"

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate>

@property UICollectionView *collectionView;

@end

@implementation LMCompactBrowsingView

- (LMMusicTrackCollection*)musicTrackCollectionForBigListEntry:(LMBigListEntry*)bigListEntry {
	return [self.musicTrackCollections objectAtIndex:bigListEntry.collectionIndex];
}

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
//	id contentSubview = [self.contentViewsArray objectAtIndex:bigListEntry.collectionIndex % self.bigListEntriesArray.count];
	
//	[self.delegate prepareContentSubview:contentSubview forBigListEntry:bigListEntry];
	
	LMMusicTrackCollection *collection = [self musicTrackCollectionForBigListEntry:bigListEntry];
	
//	UIImageView *contentSubview = [UIImageView new];
//	
//	contentSubview.contentMode = UIViewContentModeScaleAspectFit;
//	contentSubview.image = [collection.representativeItem albumArt];
	
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
	return [[[self musicTrackCollectionForBigListEntry:infoView.associatedBigListEntry] representativeItem] artist];;
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView*)infoView {
	return nil;
}

- (void)contentViewTappedForBigListEntry:(LMBigListEntry *)bigListEntry {
	NSLog(@"Content view tapped for %@", bigListEntry);
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
	
	LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
	bigListEntry.infoDelegate = self;
	bigListEntry.entryDelegate = self;
	bigListEntry.collectionIndex = (indexPath.section * 3) + indexPath.row;
	[bigListEntry setup];
	
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

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		//	fuck.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
		//	fuck.itemSize = CGSizeMake(90, 120);
		
		self.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		self.backgroundColor = [UIColor whiteColor];
		self.collectionView.backgroundColor = [UIColor whiteColor];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
	}
}

@end
