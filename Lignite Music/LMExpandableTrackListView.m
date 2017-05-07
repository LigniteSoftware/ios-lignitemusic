//
//  LMExpandableTrackListView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableInnerShadowView.h"
#import "LMExpandableTrackListView.h"
#import "LMCollectionViewCell.h"
#import "YIInnerShadowView.h"
#import "LMTriangleView.h"
#import "LMListEntry.h"
#import "LMColour.h"

@interface LMExpandableTrackListView()<UICollectionViewDelegate, UICollectionViewDataSource, LMListEntryDelegate>

@property LMExpandableInnerShadowView *testView;

@end

@implementation LMExpandableTrackListView

@synthesize musicTrackCollection = _musicTrackCollection;

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
	
	cell.backgroundColor = [UIColor whiteColor];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	if(cell.contentView.subviews.count == 0){
		NSInteger amountOfColumns = 2;
		NSInteger fixedIndex = (indexPath.row/amountOfColumns) + ((indexPath.row % amountOfColumns)*([self collectionView:self.collectionView numberOfItemsInSection:0]/amountOfColumns));
		
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

//	return CGSizeMake(self.frame.size.width, self.frame.size.height/[self collectionView:self.collectionView numberOfItemsInSection:0]);
	return CGSizeMake(self.frame.size.width/2 - 20, 100);
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
	
//	for(UIView *subview in self.subviews){
//		[subview removeFromSuperview];
//		subview.hidden = YES;
//	}
	
		self.clipsToBounds = NO;
		
		UICollectionViewFlowLayout *fuck = [[UICollectionViewFlowLayout alloc]init];
		fuck.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
		
		self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:fuck];
		self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
		self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
		self.collectionView.backgroundColor = [LMColour superLightGrayColour];
		[self.collectionView registerClass:[LMCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
		[self addSubview:self.collectionView];
		
		[self.collectionView autoPinEdgesToSuperviewEdges];
//		self.collectionView.hidden = YES;
		
		
		self.testView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.testView.backgroundColor = [UIColor clearColor];
		self.testView.userInteractionEnabled = NO;
		self.testView.flowLayout = self.flowLayout;
		[self addSubview:self.testView];
		
		[self.testView autoPinEdgesToSuperviewEdges];
	}
	else{
		[self.collectionView reloadData];
		[self.testView removeFromSuperview];
		
		self.testView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.testView.backgroundColor = [UIColor clearColor];
		self.testView.userInteractionEnabled = NO;
		self.testView.flowLayout = self.flowLayout;
		[self addSubview:self.testView];
		
		[self.testView autoPinEdgesToSuperviewEdges];
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
//	[path addLineToPoint:(CGPoint){self.frame.size.width/2 + self.testView.frame.size.width/2, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, self.frame.size.height}];
//	[path addLineToPoint:(CGPoint){-10, self.frame.size.height}];
//	[path addLineToPoint:(CGPoint){-10, 0}];
//	[path addLineToPoint:(CGPoint){self.frame.size.width/2 - self.testView.frame.size.width/2, 0}];
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
//	NSLog(@"%@", NSStringFromCGRect(self.testView.frame));
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
