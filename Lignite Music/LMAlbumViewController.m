//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumDetailView.h"
#import "LMNowPlayingViewController.h"
#import "LMAlbumViewItem.h"
#import "LMAlbumViewController.h"
#import "LMButton.h"
#import "LMTableView.h"
#import "LMTableViewCell.h"

@interface LMAlbumViewController () <LMAlbumViewItemDelegate, LMTableViewSubviewDelegate>

@property LMTableView *rootTableView;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property MPMediaQuery *everything;
@property float lastUpdatedContentOffset;
@property BOOL loaded, hasLoadedInitialItems;

@property NSLayoutConstraint *topConstraint;

@end

@implementation LMAlbumViewController

- (void)dismissViewOnTop {
	[self.view layoutIfNeeded];
	self.topConstraint.constant = -self.view.frame.size.height;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:nil];
}

/**
 When an album view item is clicked, this is called. The system should then enter into detail view for the album view.

 @param item The item which was tapped.
 */
- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item {
	NSLog(@"I see you have tapped item with index %lu", item.collectionIndex);
	
	MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:item.collectionIndex];
	NSLog(@"Collection %@", collection.representativeItem.artist);
	
	LMAlbumDetailView *detailView = [[LMAlbumDetailView alloc]initWithMediaItemCollection:[self.everything.collections objectAtIndex:item.collectionIndex]];
	detailView.rootViewController = self;
	detailView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:detailView];
	
	self.topConstraint = [detailView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:-self.view.frame.size.height];
	[detailView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
	[detailView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
	[detailView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	
	[detailView setup];
	
	[self.view layoutIfNeeded];
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:0.5 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:nil];
}

- (void)openNowPlayingView {
	LMNowPlayingViewController *nowPlayingController = [self.storyboard instantiateViewControllerWithIdentifier:@"nowPlayingController"];
	[self presentViewController:nowPlayingController animated:YES completion:nil];
}


/**
 When an album view item's play button is tapped, this is called. The system should then start playing the album and display
 the now playing view.

 @param item The item which had its play button clicked.
 */
- (void)clickedPlayButtonOnAlbumViewItem:(LMAlbumViewItem*)item {
	MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:item.collectionIndex];
	MPMusicPlayerController *controller = [MPMusicPlayerController systemMusicPlayer];
	[controller setQueueWithItemCollection:collection];
	[controller play];
	
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
	
	NSLog(@"Everything exists %d", (self.everything != nil) ? 1 : 0);
	
	for(int i = 0; i < amount; i++){
		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:i];
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:collection.representativeItem];
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
	MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:index];
	[albumViewItem updateContentsWithMediaItem:collection.representativeItem andNumberOfItems:collection.count];
	albumViewItem.collectionIndex = index;
	
	return albumViewItem;
}

/**
 Called when the view did layout its subviews and redrawing needs to occur for any other views.
 */
- (void)viewDidLayoutSubviews {
	if(self.loaded){
		return;
	}
	self.loaded = YES;
	
	self.albumsItemArray = [[NSMutableArray alloc]init];
	
	NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
	
	self.everything = [MPMediaQuery albumsQuery];
	[self.everything setGroupingType: MPMediaGroupingAlbum];
	self.albumsCount = self.everything.collections.count;
	
	NSLog(@"Logging items from a generic query...");
	
	self.rootTableView = [[LMTableView alloc]init];
	self.rootTableView.amountOfItemsTotal = self.albumsCount;
	self.rootTableView.subviewDelegate = self;
	[self.rootTableView prepareForUse];
	[self.view addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
//	CGRect currentFrame = self.view.frame;
//	CGRect rootFrame = currentFrame;
//	self.rootScrollView = [[LMAdaptiveScrollView alloc]initWithFrame:rootFrame];
//	self.rootScrollView.subviewArray = self.albumsItemArray;
//	self.rootScrollView.subviewDelegate = self;
//	self.rootScrollView.backgroundColor = [UIColor whiteColor];
//	//[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*2)];
//	[self.view addSubview:self.rootScrollView];
//	
//	[self.rootScrollView reloadContentSizeWithIndex:self.albumsCount-1];
//	[self.rootScrollView layoutSubviews];
	
	NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(openNowPlayingView)];
	[self.view addGestureRecognizer:pinchGesture];
}

- (BOOL)prefersStatusBarHidden {
	return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.view.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	NSLog(@"Album view got a memory warning.");
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
