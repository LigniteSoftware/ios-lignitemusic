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
#import "YIInnerShadowView.h"
#import "LMLayoutManager.h"
#import "LMTriangleView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"

@interface LMExpandableTrackListView()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate, LMExpandableTrackListControlBarDelegate>

/**
 The control/navigation bar which goes above the view's collection view.
 */
@property LMExpandableTrackListControlBar *expandableTrackListControlBar;

/**
 The view which displays the inner shadow.
 */
@property LMExpandableInnerShadowView *innerShadowView;

@end

@implementation LMExpandableTrackListView

@synthesize musicTrackCollection = _musicTrackCollection;

+ (NSInteger)numberOfColumns {
	return fmax(1.0, WINDOW_FRAME.size.width/300.0f);
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %d", (int)entry.collectionIndex);
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
	return nil;
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
	
	if(cell.contentView.subviews.count == 0){
		NSInteger fixedIndex = (indexPath.row/[LMExpandableTrackListView numberOfColumns]) + ((indexPath.row % [LMExpandableTrackListView numberOfColumns])*([self collectionView:self.collectionView numberOfItemsInSection:0]/[LMExpandableTrackListView numberOfColumns]));
		
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = fixedIndex;
		listEntry.associatedData = [self.musicTrackCollection.items objectAtIndex:fixedIndex];
		listEntry.isLabelBased = (self.musicType == LMMusicTypeAlbums || self.musicType == LMMusicTypeCompilations);
		[cell.contentView addSubview:listEntry];
		listEntry.backgroundColor = [LMColour superLightGrayColour];
		
		[listEntry autoPinEdgesToSuperviewEdges];
		
//		UILabel *testingLabel = [UILabel newAutoLayoutView];
//		testingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
//		testingLabel.text = [NSString stringWithFormat:@"%zd (%zd - %zd)", fixedIndex, indexPath.section, indexPath.row];
//		testingLabel.textAlignment = NSTextAlignmentCenter;
//		[cell.contentView addSubview:testingLabel];
//		
//		[testingLabel autoPinEdgesToSuperviewEdges];
		
//		UIView *testingSubview = [UIView newAutoLayoutView];
//		testingSubview.backgroundColor = [LMColour randomColour];
//		[cell.contentView addSubview:testingSubview];
//
//		[testingSubview autoCenterInSuperview];
//		[testingSubview autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:cell.contentView withMultiplier:0.5];
//		[testingSubview autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:cell.contentView withMultiplier:0.5];
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
					  fmin(([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/8.0, 100));
}

+ (CGSize)sizeForAmountOfItems:(NSInteger)amountOfItems {
	CGSize size = CGSizeMake(WINDOW_FRAME.size.width, 0);
	NSInteger numberOfColumns = [LMExpandableTrackListView numberOfColumns];
	
	size.height += (amountOfItems * [LMExpandableTrackListView currentItemSize].height)/numberOfColumns;
	size.height += (amountOfItems * 10)/numberOfColumns; //Spacing
	size.height += 10;
//	size.height += [LMExpandableTrackListControlBar recommendedHeight];
	
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

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
	
//	for(UIView *subview in self.subviews){
//		[subview removeFromSuperview];
//		subview.hidden = YES;
//	}
	
		self.clipsToBounds = NO;
		
		
		self.expandableTrackListControlBar = [LMExpandableTrackListControlBar newAutoLayoutView];
		self.expandableTrackListControlBar.delegate = self;
		self.expandableTrackListControlBar.musicTrackCollection = self.musicTrackCollection;
		[self addSubview:self.expandableTrackListControlBar];
		
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		
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
		
		[self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandableTrackListControlBar];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		self.collectionView.hidden = YES;
		
		
		self.innerShadowView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.innerShadowView.backgroundColor = [UIColor clearColor];
		self.innerShadowView.userInteractionEnabled = NO;
		self.innerShadowView.flowLayout = self.flowLayout;
		[self addSubview:self.innerShadowView];
		
		[self.innerShadowView autoPinEdgesToSuperviewEdges];
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
