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

@end

@implementation LMAlbumViewController

- (BOOL)prefersStatusBarHidden {
	return true;
}

bool loaded = false;
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
	
	MPMediaQuery *everything = [MPMediaQuery albumsQuery];
	[everything setGroupingType: MPMediaGroupingAlbum];
	
	NSLog(@"Logging items from a generic query...");
	
	for(int i = 0; i < everything.collections.count; i++){
	//for(int i = 0; i < 5; i++){
		MPMediaItemCollection *collection = [everything.collections objectAtIndex:i];
		//NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
		//NSLog (@"%lu for %@", (unsigned long)[section count], [[section representativeItem] title]);
		LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:collection.representativeItem withAlbumCount:collection.count];
		newItem.userInteractionEnabled = YES;
		[self.albumsItemArray addObject:newItem];
		
		[self.rootScrollView addSubview:newItem];
		newItem.translatesAutoresizingMaskIntoConstraints = NO;
		
		float heightFactorialOfAlbumItem = 0.4;
		
		[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:newItem
														 attribute:NSLayoutAttributeCenterX
														 relatedBy:NSLayoutRelationEqual
															toItem:self.rootScrollView
														 attribute:NSLayoutAttributeCenterX
														multiplier:1.0
														  constant:0]];
		
		[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:newItem
																		attribute:NSLayoutAttributeTop
																		relatedBy:NSLayoutRelationEqual
																		   toItem:self.rootScrollView
																		attribute:NSLayoutAttributeTop
																	   multiplier:1.0
																		 constant:self.rootScrollView.frame.size.height*(heightFactorialOfAlbumItem+0.1)*i+50]];
		
		[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:newItem
														 attribute:NSLayoutAttributeWidth
														 relatedBy:NSLayoutRelationEqual
															toItem:self.rootScrollView
														 attribute:NSLayoutAttributeWidth
														multiplier:0.8
														  constant:0]];
		
		[self.rootScrollView addConstraint:[NSLayoutConstraint constraintWithItem:newItem
														 attribute:NSLayoutAttributeHeight
														 relatedBy:NSLayoutRelationEqual
															toItem:self.rootScrollView
														 attribute:NSLayoutAttributeHeight
														multiplier:heightFactorialOfAlbumItem
														  constant:0]];
		
		[newItem load];
		
		if(i == everything.collections.count-1){
			[self.rootScrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.rootScrollView.frame.size.height*(heightFactorialOfAlbumItem+0.1)*(i+1)+50)];
		}
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
