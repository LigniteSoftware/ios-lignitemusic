//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMNowPlayingViewController.h"
#import "LMAdaptiveScrollView.h"
#import "LMAlbumViewItem.h"
#import "LMAlbumViewController.h"
#import "LMButton.h"

#define CONTENT_OFFSET_FOR_REFRESH 50.0f
#define ALBUM_ITEM_HEIGHT_FACTORIAL 0.4
#define ALBUM_ITEM_SPACING 50

@interface LMAlbumViewController () <LMAdaptiveScrollViewDelegate, LMAlbumViewItemDelegate>

@property LMAdaptiveScrollView *rootScrollView;
@property UILabel *titleLabel, *subtitleLabel;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property MPMediaQuery *everything;
@property float lastUpdatedContentOffset;
@property BOOL loaded, hasLoadedInitialItems;

@end

@implementation LMAlbumViewController


/**
 When an album view item is clicked, this is called. The system should then enter into detail view for the album view.

 @param item The item which was tapped.
 */
- (void)clickedAlbumViewItem:(LMAlbumViewItem*)item {
	NSLog(@"I see you have tapped item with index %lu", item.collectionIndex);
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
	
	LMNowPlayingViewController *nowPlayingController = [self.storyboard instantiateViewControllerWithIdentifier:@"nowPlayingController"];
	//[self showViewController:nowPlayingController sender:self];
	[self presentViewController:nowPlayingController animated:YES completion:nil];
}

/**
 Prepares an album view item for layouting by setting up its constraints. Also automatically adjusts the size of the
 scroll layer associated with this album view.

 @param subview The item to prepare.
 @param index   The index of that item.
 */
- (void)prepareSubview:(id)subview forIndex:(NSUInteger)index {
	LMAlbumViewItem *item = (LMAlbumViewItem*)subview;
	
	if(!self.everything){
		NSLog(@"self.everything doesn't exist!");
		return;
	}
	
	item.collectionIndex = index;
	
	[self.rootScrollView addSubview:item];
	item.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:item
																	attribute:NSLayoutAttributeCenterX
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.rootScrollView
																	attribute:NSLayoutAttributeCenterX
																   multiplier:1.0
																	 constant:0]];
	
	[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:item
																	attribute:NSLayoutAttributeTop
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.rootScrollView
																	attribute:NSLayoutAttributeTop
																   multiplier:1.0
																	 constant:self.rootScrollView.frame.size.height*(ALBUM_ITEM_HEIGHT_FACTORIAL+0.1)*index+ALBUM_ITEM_SPACING]];
	
	[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:item
																	attribute:NSLayoutAttributeWidth
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.rootScrollView
																	attribute:NSLayoutAttributeWidth
																   multiplier:0.8
																	 constant:0]];
	
	[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:item
																	attribute:NSLayoutAttributeHeight
																	relatedBy:NSLayoutRelationEqual
																	   toItem:self.rootScrollView
																	attribute:NSLayoutAttributeHeight
																   multiplier:ALBUM_ITEM_HEIGHT_FACTORIAL
																	 constant:0]];
	
	MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:index];
	
	if(!item.hasLoaded){
		[item setupWithAlbumCount:[collection count] andDelegate:self];
		item.hasLoaded = YES;
	}
	
	if(index >= 3 && !self.hasLoadedInitialItems){
		[item removeFromSuperview];
	}
	
	if(index == self.albumsCount-1){
		[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.rootScrollView.frame.size.height*(ALBUM_ITEM_HEIGHT_FACTORIAL+0.1)*(index+1)+ALBUM_ITEM_SPACING)];
		self.hasLoadedInitialItems = YES;
	}
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
	
	for(int i = 0; i < self.albumsCount; i++){
		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:i];
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:collection.representativeItem];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
	}
	
	CGRect currentFrame = self.view.frame;
	CGRect rootFrame = currentFrame;
	self.rootScrollView = [[LMAdaptiveScrollView alloc]initWithFrame:rootFrame];
	self.rootScrollView.subviewArray = self.albumsItemArray;
	self.rootScrollView.subviewDelegate = self;
	self.rootScrollView.backgroundColor = [UIColor whiteColor];
	[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*2)];
	[self.view addSubview:self.rootScrollView];
	
	for(int i = 0; i < self.albumsCount; i++){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:i];
		[self prepareSubview:item forIndex:i];
	}
	
	NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
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
