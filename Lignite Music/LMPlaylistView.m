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

@interface LMPlaylistView()<LMControlBarViewDelegate>

@property LMControlBarView *controlBarView;

@end

@implementation LMPlaylistView

- (UIImage*)imageWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	return [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconPlay]];
}

- (uint8_t)amountOfButtonsForControlBarView:(LMControlBarView *)controlBar {
	return 4;
}

- (void)buttonTappedWithIndex:(uint8_t)index forControlBarView:(LMControlBarView *)controlBar {
	NSLog(@"Tapped index %d", index);
}

- (void)invertControlBar {
	[self.controlBarView invert];
}

- (void)setup {
	self.controlBarView = [LMControlBarView newAutoLayoutView];
	self.controlBarView.backgroundColor = [UIColor whiteColor];
	self.controlBarView.delegate = self;
	[self addSubview:self.controlBarView];
	
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.controlBarView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
	
	[self.controlBarView setup];
	
	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(invertControlBar)];
	[self addGestureRecognizer:gesture];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
