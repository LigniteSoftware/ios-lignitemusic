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
#import "LMMusicCollectionsView.h"
#import "LMEmbeddedDetailView.h"
#import "YIInnerShadowView.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMTriangleView.h"
#import "LMDetailView.h"

@interface LMEmbeddedDetailView()<LMExpandableTrackListControlBarDelegate, LMDetailViewDelegate>

/**
 The control/navigation bar which goes above the view's collection view.
 */
@property LMExpandableTrackListControlBar *expandableTrackListControlBar;

/**
 The actual detail view which contains the contents of whatever.
 */
@property LMDetailView *detailView;

/**
 The view which displays the inner shadow.
 */
@property LMExpandableInnerShadowView *innerShadowView;

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
@property NSLayoutConstraint *albumTileViewLeadingConstraint;

/**
 The music track collection to use in loading data, as a specific track collection may have been set.
 */
@property LMMusicTrackCollection *musicTrackCollectionToUse;

/**
 Whether or not the album tile view is being displayed.
 */
@property (readonly) BOOL showingAlbumTileView;

@end

@implementation LMEmbeddedDetailView

- (CGSize)totalSize {
	CGSize size = [self.detailView totalSize];
	
	size.height += [LMExpandableTrackListControlBar recommendedHeight];
	
	return size;
}

- (void)closeButtonTappedForExpandableTrackListControlBar:(LMExpandableTrackListControlBar *)controlBar {
	NSLog(@"\"really?\"");
	LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.flowLayout;
	flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
}

- (void)backButtonTappedForExpandableTrackListControlBar:(LMExpandableTrackListControlBar *)controlBar {
	NSLog(@"\"back?\"");
	[self.detailView setShowingSpecificTrackCollection:NO animated:YES];
}

- (void)detailViewIsShowingAlbumTileView:(BOOL)showingAlbumTileView {
	self.isChangingSize = YES;
	
	self.expandableTrackListControlBar.mode = !showingAlbumTileView ? LMExpandableTrackListControlBarModeControlWithAlbumDetail : LMExpandableTrackListControlBarModeGeneralControl;
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
		
		
		self.detailView.flowLayout = self.flowLayout;
		self.detailView.delegate = self;
		
		
		self.expandableTrackListControlBar = [LMExpandableTrackListControlBar newAutoLayoutView];
		self.expandableTrackListControlBar.delegate = self;
		self.expandableTrackListControlBar.musicTrackCollection = self.musicTrackCollection;
//		self.expandableTrackListControlBar.mode = LMExpandableTrackListControlBarModeControlWithAlbumDetail;
		[self addSubview:self.expandableTrackListControlBar];
		
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		
		//Detail view is created in init
		
		[self.detailView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandableTrackListControlBar];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
						
		
		self.innerShadowView = [LMExpandableInnerShadowView newAutoLayoutView];
		self.innerShadowView.backgroundColor = [UIColor clearColor];
		self.innerShadowView.userInteractionEnabled = NO;
		self.innerShadowView.flowLayout = self.flowLayout;
//		[self addSubview:self.innerShadowView];
		
//		[self.innerShadowView autoPinEdgesToSuperviewEdges];
		
//		[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
//			LMCollectionViewFlowLayout *flowLayout = self.flowLayout;
//			flowLayout.test = YES;
//			
//			[self setShowingSpecificTrackCollection:YES animated:NO];
//			
//			[UIView animateWithDuration:0.25 animations:^{
////				[flowLayout invalidateLayout];
//				[flowLayout.collectionView performBatchUpdates:nil completion:nil];
//			}];
//			
////			[flowLayout.collectionView performBatchUpdates:nil completion:nil];
//		} repeats:NO];
	}
	else{
		LMCollectionViewFlowLayout *flowLayout = self.flowLayout;
		
		if(!CGRectEqualToRect(self.innerShadowView.frameOfItemTriangleIsAppliedTo, flowLayout.frameOfItemDisplayingDetailView)){
			[self.innerShadowView removeFromSuperview];
			
			self.innerShadowView = [LMExpandableInnerShadowView newAutoLayoutView];
			self.innerShadowView.backgroundColor = [UIColor clearColor];
			self.innerShadowView.userInteractionEnabled = NO;
			self.innerShadowView.flowLayout = self.flowLayout;
			[self addSubview:self.innerShadowView];
			
			[self.innerShadowView autoPinEdgesToSuperviewEdges];
		}
	}
	
	if(!self.specificTrackCollections){
		self.albumTileViewLeadingConstraint.constant = -self.frame.size.width;
	}
	
	[super layoutSubviews];
	
	NSLog(@"My own frame %@", NSStringFromCGRect(self.frame));
}

- (instancetype)initWithMusicTrackCollection:(LMMusicTrackCollection*)musicTrackCollection musicType:(LMMusicType)musicType {
	self = [super initForAutoLayout];
	if(self){
		self.musicTrackCollection = musicTrackCollection;
		self.musicType = musicType;
		
		self.detailView = [[LMDetailView alloc] initWithMusicTrackCollection:self.musicTrackCollection musicType:self.musicType];
		self.detailView.backgroundColor = [UIColor blueColor];
		[self addSubview:self.detailView];
	}
	return self;
}

@end
