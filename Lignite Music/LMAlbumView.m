//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAlbumDetailView.h"
#import "LMNowPlayingViewController.h"
#import "LMAlbumViewItem.h"
#import "LMAlbumView.h"
#import "LMButton.h"
#import "LMTableView.h"
#import "LMTableViewCell.h"

@interface LMAlbumView () <LMAlbumViewItemDelegate, LMTableViewSubviewDelegate>

@property LMTableView *rootTableView;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property NSArray<LMMusicTrackCollection*>* albumCollections;
@property float lastUpdatedContentOffset;
@property BOOL loaded, hasLoadedInitialItems;

@property NSLayoutConstraint *topConstraint;

@end

@implementation LMAlbumView

- (void)dismissViewOnTop {
	[self layoutIfNeeded];
	self.topConstraint.constant = self.frame.size.height;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
}

/**
 When an album view item is clicked, this is called. The system should then enter into detail view for the album view.

 @param item The item which was tapped.
 */
- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item {
	NSLog(@"I see you have tapped item with index %lu", (unsigned long)item.collectionIndex);
	
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:item.collectionIndex];
	NSLog(@"Collection %@", collection.representativeItem.artist);
//	
//	LMAlbumDetailView *detailView = [[LMAlbumDetailView alloc]initWithMediaItemCollection:[self.everything.collections objectAtIndex:item.collectionIndex]];
//	//detailView.rootViewController = self;
//	detailView.translatesAutoresizingMaskIntoConstraints = NO;
//	[self addSubview:detailView];
//	
//	self.topConstraint = [detailView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:self.frame.size.height];
//	[detailView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
//	[detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
//	[detailView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
//	
//	[detailView setup];
//	
//	[self layoutIfNeeded];
//	self.topConstraint.constant = 0;
//	[UIView animateWithDuration:0.5 delay:0.1
//		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
//						options:0 animations:^{
//							[self layoutIfNeeded];
//						} completion:nil];
}

- (void)openNowPlayingView {
//	LMNowPlayingViewController *nowPlayingController = [self.storyboard instantiateViewControllerWithIdentifier:@"nowPlayingController"];
	//[self presentViewController:nowPlayingController animated:YES completion:nil];
	NSLog(@"Open now playing");
}


/**
 When an album view item's play button is tapped, this is called. The system should then start playing the album and display
 the now playing view.

 @param item The item which had its play button clicked.
 */
- (void)clickedPlayButtonOnAlbumViewItem:(LMAlbumViewItem*)item {
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:item.collectionIndex];
	
	[self.musicPlayer setNowPlayingCollection:collection];
	[self.musicPlayer play];
	
	[self openNowPlayingView];
}

/**
 See LMTableView for documentation on this function.
 */
- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(height){
		return 0.4;
	}
	return 0.8;
}

/**
 See LMTableView for documentation on this function.
 */
- (float)topSpacingForTableView:(LMTableView *)tableView {
	return -10;
}

/**
 See LMTableView for documentation on this function.
 */
- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return false;
}

/**
 See LMTableView for documentation on this function.
 */
- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(self.hasLoadedInitialItems){
		return;
	}
	
	for(int i = 0; i < amount; i++){
		LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:i];
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMusicTrack:collection.representativeItem];
		[newItem setupWithAlbumCount:collection.count andDelegate:self];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
	}
	self.hasLoadedInitialItems = YES;
}

/**
 See LMTableView for documentation on this function.
 */
- (id)prepareSubviewAtIndex:(NSUInteger)index {
//	LMAlbumViewItem *item = (LMAlbumViewItem*)subview;
//	item.collectionIndex = index;
//	
//	if(!hasLoaded){
//		if(!self.everything){
//			NSLog(@"self.everything doesn't exist!");
//			return;
//		}
//		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:index];
//		[item setupWithAlbumCount:[collection count] andDelegate:self];
//	}
	
	LMAlbumViewItem *albumViewItem = [self.albumsItemArray objectAtIndex:index % self.albumsItemArray.count];
	LMMusicTrackCollection *collection = [self.albumCollections objectAtIndex:index];
	[albumViewItem updateContentsWithMusicTrack:collection.representativeItem andNumberOfItems:collection.count];
	albumViewItem.collectionIndex = index;
	
	return albumViewItem;
}

/**
 Called when the view did layout its subviews and redrawing needs to occur for any other views.
 */
- (void)layoutSubviews {
	if(self.loaded){
		return;
	}
	self.loaded = YES;
	
	self.albumsItemArray = [[NSMutableArray alloc]init];
	
	NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
	
	self.albumCollections = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums];
	self.albumsCount = self.albumCollections.count;
	
	NSLog(@"Logging items from a generic query...");
	
	self.rootTableView = [[LMTableView alloc]init];
	self.rootTableView.amountOfItemsTotal = self.albumsCount;
	self.rootTableView.subviewDelegate = self;
	[self.rootTableView prepareForUse];
	[self addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
//	CGRect currentFrame = self.frame;
//	CGRect rootFrame = currentFrame;
//	self.rootScrollView = [[LMAdaptiveScrollView alloc]initWithFrame:rootFrame];
//	self.rootScrollView.subviewArray = self.albumsItemArray;
//	self.rootScrollView.subviewDelegate = self;
//	self.rootScrollView.backgroundColor = [UIColor whiteColor];
//	//[self.rootScrollView setContentSize:CGSizeMake(self.frame.size.width, self.frame.size.height*2)];
//	[self addSubview:self.rootScrollView];
//	
//	[self.rootScrollView reloadContentSizeWithIndex:self.albumsCount-1];
//	[self.rootScrollView layoutSubviews];
	
	NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(openNowPlayingView)];
	[self addGestureRecognizer:pinchGesture];
}

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//	
//	NSLog(@"Album view got a memory warning.");
//    // Dispose of any resources that can be recreated.
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
