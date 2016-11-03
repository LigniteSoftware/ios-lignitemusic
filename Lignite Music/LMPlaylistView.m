//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistView.h"
#import "LMControlBarView.h"
#import "LMAppIcon.h"
#import "LMTableView.h"
#import "LMTiledAlbumCoverView.h"
#import "LMCollectionInfoView.h"

@interface LMPlaylistView()<LMControlBarViewDelegate, LMTableViewSubviewDelegate, LMCollectionInfoViewDelegate>

@property LMTableView *rootTableView;

@property LMControlBarView *controlBarView;

@property float windowPercentage;

@property LMTiledAlbumCoverView *tiledAlbumCoverView;

@property LMCollectionInfoView *infoView;

@end

@implementation LMPlaylistView

- (NSString*)titleForInfoView:(LMCollectionInfoView *)infoView {
	return @"Title!";
}

- (NSString*)leftTextForInfoView:(LMCollectionInfoView *)infoView {
	return @"Left text!";
}

- (NSString*)rightTextForInfoView:(LMCollectionInfoView *)infoView {
	return nil;
	return @"Right text!";
}

- (UIImage*)centerImageForInfoView:(LMCollectionInfoView *)infoView {
	return nil;
	return [UIImage imageNamed:@"icon_bug.png"];
}

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlay]];
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 4;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	float windowPercentage = newSize.height/self.frame.size.height;
	
	self.windowPercentage = windowPercentage;
	
	[self.rootTableView reloadSize];
}

/**
 See LMTableView for documentation on this function.
 */
- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	return height ? self.windowPercentage : 0.2;
}

/**
 See LMTableView for documentation on this function.
 */
- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 100;
	//TODO fix this
}

/**
 See LMTableView for documentation on this function.
 */
- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return NO;
}

- (BOOL)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"Tapped index %d", index);
	return YES;
}

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	
}

- (id)prepareSubviewAtIndex:(NSUInteger)index {	
	if(index == 0){
		return self.controlBarView;
	}
	UIView *shitpostView = [UIView newAutoLayoutView];
	shitpostView.backgroundColor = [UIColor yellowColor];
	return shitpostView;
}

- (void)changeShit {
	if(self.tiledAlbumCoverView){
		self.tiledAlbumCoverView.hidden = YES;
		[self.tiledAlbumCoverView removeFromSuperview];
		self.tiledAlbumCoverView = nil;
	}
	
	self.tiledAlbumCoverView = [LMTiledAlbumCoverView newAutoLayoutView];
//	self.tiledAlbumCoverView.backgroundColor = [UIColor orangeColor];
	[self addSubview:self.tiledAlbumCoverView];
	
	[self.tiledAlbumCoverView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
	[self.tiledAlbumCoverView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.tiledAlbumCoverView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-20];
	[self.tiledAlbumCoverView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self withOffset:-20];
}

- (void)setup {
//	self.infoView = [LMCollectionInfoView newAutoLayoutView];
//	self.infoView.delegate = self;
//	[self addSubview:self.infoView];
//	
//	[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
//	[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
//	[self.infoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:300];
//	[self.infoView autoSetDimension:ALDimensionHeight toSize:75];
//	
//	[self.infoView reloadData];
	
//	[self changeShit];
//	
//	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeShit)];
//	[self addGestureRecognizer:gesture];
	
	//[NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(changeShit) userInfo:nil repeats:YES];
	
//	self.controlBarView = [LMControlBarView newAutoLayoutView];
//	self.controlBarView.backgroundColor = [UIColor whiteColor];
//	self.controlBarView.delegate = self;
//	[self addSubview:self.controlBarView];
//	
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
	
//	[self.controlBarView setup];
//	
//	self.rootTableView = [LMTableView newAutoLayoutView];
//	self.rootTableView.subviewDelegate = self;
//	self.rootTableView.amountOfItemsTotal = 1;
//	self.rootTableView.dynamicCellSize = YES;
//	[self addSubview:self.rootTableView];
//	
//	[self.rootTableView autoCenterInSuperview];
//	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
//	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	
//	[self.rootTableView regenerate:NO];
//
//	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(invertControlBar)];
//	[self addGestureRecognizer:gesture];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
