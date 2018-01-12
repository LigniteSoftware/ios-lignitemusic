//
//  LMExpandableTrackListView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableTrackListControlBar.h"
#import "LMFloatingDetailViewControls.h"
#import "LMExpandableInnerShadowView.h"
#import "LMMusicCollectionsView.h"
#import "LMEmbeddedDetailView.h"
#import "YIInnerShadowView.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMTriangleView.h"
#import "LMDetailView.h"

@interface LMEmbeddedDetailView()<LMExpandableTrackListControlBarDelegate, LMDetailViewDelegate, LMFloatingDetailViewButtonDelegate, LMLayoutChangeDelegate>

/**
 The control/navigation bar which goes above the view's collection view.
 */
@property LMExpandableTrackListControlBar *expandableTrackListControlBar;

/**
 The floating controls which go on the right side.
 */
@property LMFloatingDetailViewControls *floatingControls;

/**
 The width constraint for floating controls so that we can adjust the multiplier when iPad rotates.
 */
@property NSLayoutConstraint *floatingControlsWidthConstraint;

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
	
//	size.height += [LMExpandableTrackListControlBar recommendedHeight];
	
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

- (void)hideFloatingControls {
	[UIView animateWithDuration:0.1 animations:^{
		self.floatingControls.alpha = 0.0;
	}];
}

- (void)floatingDetailViewButtonTapped:(LMFloatingDetailViewButton *)button {
	switch(button.type){
		case LMFloatingDetailViewControlButtonTypeClose: {
			LMCollectionViewFlowLayout *flowLayout = (LMCollectionViewFlowLayout*)self.flowLayout;
			flowLayout.indexOfItemDisplayingDetailView = LMNoDetailViewSelected;
			break;
		}
		case LMFloatingDetailViewControlButtonTypeShuffle: {
			LMMusicTrackCollection *collectionToUse = nil;
			if(self.detailView.showingAlbumTileView){
				collectionToUse = self.detailView.musicTrackCollection;
			}
			else if(!self.detailView.showingAlbumTileView && self.detailView.musicTrackCollectionToUseForSpecificTrackCollection){
				collectionToUse = self.detailView.musicTrackCollectionToUseForSpecificTrackCollection;
			}
			else if(!self.detailView.musicTrackCollectionToUseForSpecificTrackCollection){
				collectionToUse = self.detailView.musicTrackCollection;
			}
			
			LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
			[musicPlayer stop];
			[musicPlayer setShuffleMode:LMMusicShuffleModeOn];
			[musicPlayer setNowPlayingCollection:collectionToUse];
			[musicPlayer play];
			
			NSLog(@"Shuffle...");
			break;
		}
		case LMFloatingDetailViewControlButtonTypeBack: {
			[self.detailView setShowingSpecificTrackCollection:NO animated:YES];
			break;
		}
	}
}

- (void)detailViewIsShowingAlbumTileView:(BOOL)showingAlbumTileView {
	self.isChangingSize = YES;

	self.floatingControls.showingBackButton = !showingAlbumTileView;
	
//	self.expandableTrackListControlBar.mode = !showingAlbumTileView ? LMExpandableTrackListControlBarModeControlWithAlbumDetail : LMExpandableTrackListControlBarModeGeneralControl;
}

//- (void)rootViewWillTransitionToSize:(CGSize)size
//		   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//
//	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		self.floatingControlsWidthConstraint.multiplier = LMLayoutManager.isLandscape ? (0.75/10.0) : (1.25/10.0);
//	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		//Nothing, yet
//	}];
//}

- (void)layoutSubviews {	
	self.backgroundColor = [UIColor yellowColor];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
	
//	for(UIView *subview in self.subviews){
//		[subview removeFromSuperview];
//		subview.hidden = YES;
//	}
		
	
		self.clipsToBounds = NO;
		
		
//		if([LMLayoutManager isiPad]){
//			[[LMLayoutManager sharedLayoutManager] addDelegate:self];
//		}
		
		
		self.detailView.flowLayout = self.flowLayout;
		self.detailView.delegate = self;
		
		
//		self.expandableTrackListControlBar = [LMExpandableTrackListControlBar newAutoLayoutView];
//		self.expandableTrackListControlBar.delegate = self;
//		self.expandableTrackListControlBar.musicTrackCollection = self.musicTrackCollection;
////		self.expandableTrackListControlBar.mode = LMExpandableTrackListControlBarModeControlWithAlbumDetail;
//		[self addSubview:self.expandableTrackListControlBar];
//
//		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[self.expandableTrackListControlBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		
		
		self.floatingControls = [LMFloatingDetailViewControls newAutoLayoutView];
		self.floatingControls.delegate = self;
		[self addSubview:self.floatingControls];
		
		[self.floatingControls autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.floatingControls autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.floatingControls autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.floatingControls autoSetDimension:ALDimensionWidth toSize:83.0f];
//		self.floatingControlsWidthConstraint =
//			[self.floatingControls autoMatchDimension:ALDimensionWidth
//										  toDimension:ALDimensionWidth
//											   ofView:self
//									   withMultiplier:[LMLayoutManager isiPad] ? (1.25/10.0) : (2.0/10.0)];
		
		
		//Detail view is created in init
		
		[self.detailView autoPinEdgesToSuperviewEdges];
		
//		[self.detailView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.expandableTrackListControlBar];
//		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//		[self.detailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
						
		
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
