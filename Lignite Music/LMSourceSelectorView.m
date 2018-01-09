//
//  LMSourceSelector.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSourceSelectorView.h"
#import "LMLayoutManager.h"
#import "LMButton.h"
#import "LMCircleView.h"
#import "LMLabel.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMSettings.h"
#import "LMThemeEngine.h"
#import "LMMusicPlayer.h"

@interface LMSourceSelectorView() <LMListEntryDelegate, LMLayoutChangeDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LMThemeEngineDelegate>

/**
 The collection view which displays the contents.
 */
@property UICollectionView *collectionView;

/**
 The array of list entries which go on the collection view.
 */
@property NSMutableArray *listEntryArray;

/**
 The currently highlighted big list entry.
 */
@property NSInteger currentlyHighlighted;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

@end

@implementation LMSourceSelectorView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if([self.delegate respondsToSelector:@selector(sourceSelectorDidScroll:)]){
		[self.delegate sourceSelectorDidScroll:self];
	}
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	if([LMLayoutManager isiPad]){
		return CGSizeMake(self.frame.size.width - 40, ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/LMLayoutManager.listEntryHeightFactorial);
	}
	
	if([LMLayoutManager isLandscape]){
		return CGSizeMake(((WINDOW_FRAME.size.width-(WINDOW_FRAME.size.width/LMLayoutManager.listEntryHeightFactorial) /* Size of the navigation bar */)/2) - 40, WINDOW_FRAME.size.width/LMLayoutManager.listEntryHeightFactorial);
	}
	
	return CGSizeMake(WINDOW_FRAME.size.width - 40, WINDOW_FRAME.size.height/LMLayoutManager.listEntryHeightFactorial);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.sources.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sourceSelectorCellIdentifier" forIndexPath:indexPath];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMListEntry *listEntry = [self.listEntryArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:listEntry];
	[listEntry autoPinEdgesToSuperviewEdges];
	
	if(indexPath.row < [self collectionView:self.collectionView numberOfItemsInSection:0]-1){
		UIView *lineView = [UIView newAutoLayoutView];
		lineView.backgroundColor = [LMColour controlBarGrayColour];
		[cell addSubview:lineView];
		
		[lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:listEntry withOffset:[self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout minimumLineSpacingForSectionAtIndex:0]/2.0f];
		[lineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:listEntry];
		[lineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:listEntry];
		[lineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	}
	
	return cell;
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.listEntryArray.count; i++){
		LMListEntry *indexEntry = [self.listEntryArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.listEntryArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.listEntryArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (void)setCurrentSourceWithIndex:(NSInteger)index {
	LMListEntry *entry = [self listEntryForIndex:index];
	
	LMSource *source = [self.sources objectAtIndex:index];
	
	if(!source.shouldNotHighlight){
		LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
		if(previousHighlightedEntry){
			[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		}
		
		if(self.isMainSourceSelector){
			[entry changeHighlightStatus:YES animated:YES];
		}
		self.currentlyHighlighted = index;
		
		if(self.isMainSourceSelector){
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setInteger:index forKey:LMSettingsKeyLastOpenedSource];
			[defaults synchronize];
		}
	}
	
	[source.delegate sourceSelected:source];
}

- (void)tappedListEntry:(LMListEntry*)entry{
	[self setCurrentSourceWithIndex:entry.collectionIndex];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour mainColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.icon;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Reload collection view
		[self.collectionView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
		
		self.collectionView.contentInset = UIEdgeInsetsMake(([LMLayoutManager isiPhoneX] && ![LMLayoutManager isLandscape] && self.isMainSourceSelector) ? 30 : 10, 20, 20, 20);
	}];
}

- (void)themeChanged:(LMTheme)theme {
	LMListEntry *listEntry = [self.listEntryArray objectAtIndex:self.currentlyHighlighted];
	[listEntry reloadContents];
}

- (void)setup {
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	[[LMThemeEngine sharedThemeEngine] addDelegate:self];
	
	self.backgroundColor = [UIColor whiteColor];
	self.currentlyHighlighted = -1;
	
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.contentInset = UIEdgeInsetsMake(([LMLayoutManager isiPhoneX] && ![LMLayoutManager isLandscape] && self.isMainSourceSelector) ? 30 : 10, 20, 20, 20);
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"sourceSelectorCellIdentifier"];
	[self addSubview:self.collectionView];
	
	self.listEntryArray = [NSMutableArray new];
	
	for(int i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++){
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = i;
		listEntry.iconInsetMultiplier = (1.0/3.0);
		listEntry.iconPaddingMultiplier = (3.0/4.0);
		listEntry.invertIconOnHighlight = YES;
		listEntry.stretchAcrossWidth = YES;
		listEntry.roundedCorners = NO;
		
		[self.listEntryArray addObject:listEntry];
	}
	
	if(self.isMainSourceSelector){
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		NSInteger lastSourceOpened = LMMusicTypeAlbums;
		if([settings objectForKey:LMSettingsKeyLastOpenedSource]){
			NSLog(@"Stored %@", [settings objectForKey:LMSettingsKeyLastOpenedSource]);
			lastSourceOpened = [settings integerForKey:LMSettingsKeyLastOpenedSource];
		}
		
		if(lastSourceOpened >= self.listEntryArray.count){
			return;
		}
		[self tappedListEntry:[self.listEntryArray objectAtIndex:lastSourceOpened]];
	}
	
	
	self.backgroundColor = [UIColor whiteColor];
	self.collectionView.backgroundColor = [UIColor whiteColor];
	[self.collectionView autoPinEdgesToSuperviewEdges];
}

- (void)removeFromSuperview {
	[super removeFromSuperview];
	
	[[LMThemeEngine sharedThemeEngine] removeDelegate:self];
}

@end
