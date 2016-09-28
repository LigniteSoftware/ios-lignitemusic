//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumViewItem.h"
#import "LMAlbumViewController.h"
#import "LMButton.h"

#define CONTENT_OFFSET_FOR_REFRESH 50.0f
#define ALBUM_ITEM_HEIGHT_FACTORIAL 0.4
#define ALBUM_ITEM_SPACING 50

@interface LMAlbumViewController () <UIScrollViewDelegate>

@property UIScrollView *rootScrollView;
@property UILabel *titleLabel, *subtitleLabel;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property MPMediaQuery *everything;
@property CGRect exampleAlbumItemFrame;
@property float lastUpdatedContentOffset;
@property BOOL loaded;

@end

@implementation LMAlbumViewController

- (BOOL)prefersStatusBarHidden {
	return true;
}


/**
 Prepares an album view item for layouting by setting up its constraints. Also automatically adjusts the size of the
 scroll layer associated with this album view.

 @param item  The item to prepare.
 @param index The index of that item.
 */
- (void)prepareAlbumViewItemWithConstraints:(LMAlbumViewItem*)item atIndex:(NSUInteger)index {
	if(!self.everything){
		NSLog(@"self.everything doesn't exist!");
		return;
	}
	
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
		[item setupWithAlbumCount:[collection count]];
		item.hasLoaded = YES;
	}
	
	if(index >= 3 && self.exampleAlbumItemFrame.size.height == 0){
		[item removeFromSuperview];
	}
	
	if(index == self.albumsCount-1){
		self.rootScrollView.delegate = self;
		[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.rootScrollView.frame.size.height*(ALBUM_ITEM_HEIGHT_FACTORIAL+0.1)*(index+1)+ALBUM_ITEM_SPACING)];
	}

}


/**
 Reloads album items on the screen.
 
 Up to 4 album items are actually on the UIScrollLayer at once, the rest are removed from their superview until needed.
 */
- (void)reloadAlbumItems {
	//If the album item frame which dictates the general size album items should be scaled by doesn't exist, set it up.
	if(self.exampleAlbumItemFrame.size.width == 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:0];
		self.exampleAlbumItemFrame = item.frame;
	}
	
	//The visible frame is what's visible on the screen of the UIScrollView. Its height is the same as the total height for the UIScrollView.
	CGRect visibleFrame = CGRectMake(self.rootScrollView.contentOffset.x, self.rootScrollView.contentOffset.y, self.rootScrollView.contentOffset.x + self.rootScrollView.bounds.size.width, self.rootScrollView.bounds.size.height);
	
	int amountOfItems = 0;
	//Calculate the total amount of space that has been viewed and is being viewed.
	float totalSpace = (visibleFrame.origin.y + visibleFrame.size.height);
	//Calculate the amount of items that are in frame and above it (scrolled past) by subtracting each from the total space.
	while(totalSpace > 0){
		totalSpace -= (self.view.frame.size.height*(ALBUM_ITEM_HEIGHT_FACTORIAL+0.1));
		amountOfItems++;
	}
	
	uint8_t totalAmountOfItemsToDraw = 4;
	
	int8_t itemsDrawn = 0;
	//Determines whether or not an item is in view, and if it is, adds it to the root UIScrollView if it is not already there.
	while(itemsDrawn < totalAmountOfItemsToDraw && amountOfItems > 0){
		int itemToDraw = (amountOfItems-itemsDrawn)-1;
		if(itemToDraw < 0 || itemToDraw >= self.albumsItemArray.count){
			itemsDrawn = totalAmountOfItemsToDraw;
			break;
		}
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:itemToDraw];
		if(![item isDescendantOfView:self.rootScrollView]){
			[self prepareAlbumViewItemWithConstraints:item atIndex:itemToDraw];
		}
		itemsDrawn++;
	}
	
	int amountOfItemsAbove = (amountOfItems-itemsDrawn)+1;
	//Based on the amount of items above the current frame (scrolled past), remove all of those items from their superviews.
	while(amountOfItemsAbove > 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:amountOfItemsAbove-1];
		if([item isDescendantOfView:self.rootScrollView]){
			[item removeFromSuperview];
		}
		amountOfItemsAbove--;
	}
	
	int amountOfItemsBelow = ((int)self.albumsItemArray.count-amountOfItems);
	//Based on the amount of items below the current frame (not yet scrolled past), remove all of those items from their superviews.
	while(amountOfItemsBelow > 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:amountOfItems+amountOfItemsBelow-1];
		if([item isDescendantOfView:self.rootScrollView]){
			[item removeFromSuperview];
		}
		amountOfItemsBelow--;
	}
}


/**
 When the UIScrollView updates, this is called.

 @param scrollView The UIScrollView which updated.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self reloadAlbumItems];
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
	
	CGRect currentFrame = self.view.frame;
	CGRect rootFrame = currentFrame;
	self.rootScrollView = [[UIScrollView alloc]initWithFrame:rootFrame];
	self.rootScrollView.backgroundColor = [UIColor whiteColor];
	[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*2)];
	[self.view addSubview:self.rootScrollView];
	
	NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
	
	self.everything = [MPMediaQuery albumsQuery];
	[self.everything setGroupingType: MPMediaGroupingAlbum];
	self.albumsCount = self.everything.collections.count;
	
	NSLog(@"Logging items from a generic query...");
	
	for(int i = 0; i < self.albumsCount; i++){
		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:i];
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:collection.representativeItem withAlbumCount:collection.count];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
		
		[self prepareAlbumViewItemWithConstraints:newItem atIndex:i];
	}
	
	self.rootScrollView.delegate = self;
	
	NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
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
