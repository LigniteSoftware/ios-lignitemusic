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

@interface LMAlbumViewController () <UIScrollViewDelegate>

@property UIScrollView *rootScrollView;
@property UILabel *titleLabel, *subtitleLabel;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property MPMediaQuery *everything;
@property CGRect exampleAlbumItemFrame;
@property float lastUpdatedContentOffset;

@end

@implementation LMAlbumViewController

- (BOOL)prefersStatusBarHidden {
	return true;
}

bool loaded = false;
float heightFactorialOfAlbumItem = 0.4;

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
																	 constant:self.rootScrollView.frame.size.height*(heightFactorialOfAlbumItem+0.1)*index+50]];
	
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
																   multiplier:heightFactorialOfAlbumItem
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
		[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.rootScrollView.frame.size.height*(heightFactorialOfAlbumItem+0.1)*(index+1)+50)];
	}

}

- (void)reloadAlbumItems {
	if(self.exampleAlbumItemFrame.size.width == 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:0];
		self.exampleAlbumItemFrame = item.frame;
//		NSLog(@"Got item frame of %@", NSStringFromCGRect(item.frame));
	}
	
	CGRect visibleFrame = CGRectMake(self.rootScrollView.contentOffset.x, self.rootScrollView.contentOffset.y, self.rootScrollView.contentOffset.x + self.rootScrollView.bounds.size.width, self.rootScrollView.bounds.size.height);
	
	if(fabs(self.lastUpdatedContentOffset-visibleFrame.origin.y) < CONTENT_OFFSET_FOR_REFRESH){
		//return;
	}
	
	self.lastUpdatedContentOffset = visibleFrame.origin.y;
	
//	NSLog(@"Updating.");
	
//	NSLog(@"example frame %@", NSStringFromCGRect(self.exampleAlbumItemFrame));
	
	int amountOfItems = 0;
	float totalSpace = (visibleFrame.origin.y + visibleFrame.size.height);
	while(totalSpace > 0){
		totalSpace -= (self.view.frame.size.height*(heightFactorialOfAlbumItem+0.1));
		amountOfItems++;
	}
	//amountOfItems += 2;
//	NSLog(@"Have seen %d with total space ending at %f", amountOfItems, totalSpace);
	
	uint8_t totalAmountOfItemsToDraw = 4;
	
	int8_t itemsDrawn = 0;
	while(itemsDrawn < totalAmountOfItemsToDraw && amountOfItems > 0){
		int itemToDraw = (amountOfItems-itemsDrawn)-1;
		if(itemToDraw < 0 || itemToDraw >= self.albumsItemArray.count){
			itemsDrawn = totalAmountOfItemsToDraw;
			NSLog(@"Breaking %d %ld.", itemToDraw, self.albumsItemArray.count);
			break;
		}
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:itemToDraw];
		//NSLog(@"Draw item %d (current size %f)", itemToDraw, item.frame.size.height);
		if(![item isDescendantOfView:self.rootScrollView]){
//			NSLog(@"Showing item %d", itemToDraw);
			[self prepareAlbumViewItemWithConstraints:item atIndex:itemToDraw];
		}
		itemsDrawn++;
	}
	
	//NSLog(@"The amount of items being drawn is %d", itemsDrawn);
	
	int amountOfItemsAbove = (amountOfItems-itemsDrawn)+1;
	//NSLog(@"The amount of items being hidden above is %d", amountOfItemsAbove);
	
	int amountOfItemsBelow = ((int)self.albumsItemArray.count-amountOfItems);
	//NSLog(@"The amount of items being hidden below is %d", amountOfItemsBelow);
	
	while(amountOfItemsAbove > 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:amountOfItemsAbove-1];
		if([item isDescendantOfView:self.rootScrollView]){
//			NSLog(@"Hiding above item %d", amountOfItemsAbove);
			[item removeFromSuperview];
		}
		amountOfItemsAbove--;
	}
	
	while(amountOfItemsBelow > 0){
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:amountOfItems+amountOfItemsBelow-1];
		if([item isDescendantOfView:self.rootScrollView]){
//			NSLog(@"Hiding below item %d", amountOfItemsBelow);
			[item removeFromSuperview];
		}
		amountOfItemsBelow--;
	}
	
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self reloadAlbumItems];
}

- (void)load {
	if(loaded){
		return;
	}
	loaded = true;
	self.albumsItemArray = [[NSMutableArray alloc]init];
	
	CGRect currentFrame = self.view.frame;
	CGRect rootFrame = currentFrame; //CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, currentFrame.size.height);
	self.rootScrollView = [[UIScrollView alloc]initWithFrame:rootFrame];
	self.rootScrollView.backgroundColor = [UIColor whiteColor];
	[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height*2)];
	[self.view addSubview:self.rootScrollView];
	
	NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
	
	self.everything = [MPMediaQuery albumsQuery];
	[self.everything setGroupingType: MPMediaGroupingAlbum];
	self.albumsCount = self.everything.collections.count;
	//self.albumsCount = 10;
	
	NSLog(@"Logging items from a generic query...");
	
	for(int i = 0; i < self.albumsCount; i++){
	//for(int i = 0; i < 5; i++){
		MPMediaItemCollection *collection = [self.everything.collections objectAtIndex:i];
		//NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
		//NSLog (@"%lu for %@", (unsigned long)[section count], [[section representativeItem] title]);
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:collection.representativeItem withAlbumCount:collection.count];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
		
		[self prepareAlbumViewItemWithConstraints:newItem atIndex:i];
	}
	
	self.rootScrollView.delegate = self;
	
	NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
	
	NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
}


- (void)viewDidLayoutSubviews {
	[self load];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.view.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
