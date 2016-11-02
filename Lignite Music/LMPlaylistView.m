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

@interface LMPlaylistView()<LMControlBarViewDelegate, LMTableViewSubviewDelegate>

@property LMTableView *rootTableView;

@property LMControlBarView *controlBarView;

@property float windowPercentage;

@end

@implementation LMPlaylistView

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlay]];
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 4;
}

- (void)sizeChangedTo:(CGSize)newSize forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"New size is %@", NSStringFromCGSize(newSize));
	
	float windowPercentage = newSize.height/self.frame.size.height;
	NSLog(@"Window percent %f", windowPercentage);
	
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
	return nil;
}

- (void)setup {
	self.controlBarView = [LMControlBarView newAutoLayoutView];
	self.controlBarView.backgroundColor = [UIColor whiteColor];
	self.controlBarView.delegate = self;
//	[self addSubview:self.controlBarView];
//	
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
//	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
	
	[self.controlBarView setup];
	
	self.rootTableView = [LMTableView newAutoLayoutView];
	self.rootTableView.subviewDelegate = self;
	self.rootTableView.amountOfItemsTotal = 1;
	self.rootTableView.dynamicCellSize = YES;
	[self addSubview:self.rootTableView];
	
	[self.rootTableView autoCenterInSuperview];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootTableView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	[self.rootTableView regenerate:NO];
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
