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

@interface LMAlbumViewController () <UIScrollViewDelegate>

@property UIScrollView *rootScrollView;
@property UILabel *titleLabel, *subtitleLabel;
@property NSMutableArray *albumsItemArray;
@property NSUInteger albumsCount;
@property MPMediaQuery *everything;
@property CGRect exampleAlbumItemFrame;

@end

@implementation LMAlbumViewController

- (BOOL)prefersStatusBarHidden {
	return true;
}

bool loaded = false;

- (void)prepareAlbumViewItemWithConstraints:(LMAlbumViewItem*)item atIndex:(NSUInteger)index {
	if(!self.everything){
		NSLog(@"self.everything doesn't exist!");
		return;
	}
	
	[self.rootScrollView addSubview:item];
	item.translatesAutoresizingMaskIntoConstraints = NO;
	
	float heightFactorialOfAlbumItem = 0.4;
	
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
	
	//NSLog(@"Visible frame %@", NSStringFromCGRect(visibleFrame));
	
	int amountOfItems = (visibleFrame.origin.y + visibleFrame.size.height)/self.exampleAlbumItemFrame.size.height;
	//NSLog(@"Have seen %d", amountOfItems);
	
	int8_t itemsDrawn = 0;
	while(itemsDrawn < 4 && amountOfItems > 0){
		int itemToDraw = (amountOfItems-itemsDrawn);
		if(itemToDraw < 0 || itemToDraw >= self.albumsItemArray.count){
			itemsDrawn = 4;
			break;
		}
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:itemToDraw];
		//NSLog(@"Draw item %d (current size %f)", itemToDraw, item.frame.size.height);
		if(![item isDescendantOfView:self.rootScrollView]){
			//NSLog(@"Adding");
			[self prepareAlbumViewItemWithConstraints:item atIndex:itemToDraw];
		}
		itemsDrawn++;
	}
	//NSLog(@"Removing %d", itemsDrawn);
	int amountOfItemsAbove = (int)self.albumsItemArray.count-amountOfItems;
	int amountOfItemsBelow = amountOfItems-itemsDrawn;
	NSLog(@"Above %d below %d", amountOfItemsAbove, amountOfItemsBelow);
	while(amountOfItemsAbove > -1){
		int itemToRemove = (int)self.albumsItemArray.count-1-amountOfItemsAbove;
		NSLog(@"Removing %d", itemToRemove);
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:itemToRemove];
		if([item isDescendantOfView:self.rootScrollView]){
			[item removeFromSuperview];
		}
		amountOfItemsAbove--;
	}
	while(amountOfItemsBelow > 0){
		int itemToRemove = (int)amountOfItemsBelow-1;
		NSLog(@"Below removing %d", itemToRemove);
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:itemToRemove];
		if([item isDescendantOfView:self.rootScrollView]){
			[item removeFromSuperview];
		}
		amountOfItemsBelow--;
	}
	/*
	while(amountOfItems > -1){
		NSLog(@"Amount of items %d", amountOfItems);
		LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:amountOfItems];
		[item removeFromSuperview];
		amountOfItems--;
	}
	 */
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
	//self.albumsCount = everything.collections.count;
	self.albumsCount = 10;
	
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
