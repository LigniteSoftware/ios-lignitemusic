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

@interface LMCompactBrowsingView()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LMCollectionInfoViewDelegate, LMBigListEntryDelegate, LMControlBarViewDelegate>

@property UICollectionView *collectionView;

@end

@implementation LMCompactBrowsingView

- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry {
//	id contentSubview = [self.contentViewsArray objectAtIndex:bigListEntry.collectionIndex % self.bigListEntriesArray.count];
	
//	[self.delegate prepareContentSubview:contentSubview forBigListEntry:bigListEntry];
	
	UIView *contentSubview = [UIView newAutoLayoutView];
	
	contentSubview.backgroundColor = [UIColor orangeColor];
	
	return contentSubview;
}

- (float)contentSubviewFactorial:(BOOL)height forBigListEntry:(LMBigListEntry *)bigListEntry {
	CGRect frame = [[self.collectionView.visibleCells firstObject] frame];
	if(frame.size.width == 0){
		frame = CGRectMake(0, 0, 117, 177);
	}
	CGFloat percentage = frame.size.width/self.frame.size.width;
	NSLog(@"Frame %f%% %@", percentage, NSStringFromCGRect([[self.collectionView.visibleCells firstObject] frame]));
	return height ? 0.1 : 1.0;
}

- (void)sizeChangedToLargeSize:(BOOL)largeSize withHeight:(float)newHeight forBigListEntry:(LMBigListEntry*)bigListEntry {
	//If the new size is large/opened
	NSLog(@"%@ changed large", bigListEntry);
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (BOOL)buttonHighlightedWithIndex:(uint8_t)index wasJustTapped:(BOOL)wasJustTapped forControlBar:(LMControlBarView *)controlBar {
	return NO;
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 3;
}

- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView {
	return @"title";
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"left text";
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView {
	return @"right text";
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
	return 25;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor greenColor];
	
	LMBigListEntry *bigListEntry = [LMBigListEntry newAutoLayoutView];
	bigListEntry.infoDelegate = self;
	bigListEntry.entryDelegate = self;
	bigListEntry.controlBarDelegate = self;
	bigListEntry.collectionIndex = 1;
	[bigListEntry setup];
	
	[cell.contentView addSubview:bigListEntry];
	[bigListEntry autoPinEdgesToSuperviewEdges];
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	//	NSLog(@"Path %@", indexPath);
	NSInteger factor = 3;
	
	CGFloat sideLength = self.frame.size.width/factor;
	
	sideLength -= 20;
	
	CGFloat spacing = (self.frame.size.width-(sideLength*factor))/(factor+1);
	
	NSLog(@"Fuck %f", spacing);
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
	flowLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
	flowLayout.minimumLineSpacing = spacing;
	
	NSLog(@"Fuck %@", NSStringFromCGSize(CGSizeMake(sideLength, sideLength * (3.0/2.0))));
	
	return CGSizeMake(sideLength, sideLength * (3.0/2.0));
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
//		fuck.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		//	fuck.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
		//	fuck.itemSize = CGSizeMake(90, 120);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
	}
}

@end
