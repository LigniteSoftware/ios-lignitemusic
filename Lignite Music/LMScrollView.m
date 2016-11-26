//
//  LMScrollView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMScrollView.h"

@interface LMScrollView()<UIScrollViewDelegate>

@property BOOL didSetupContentSize;

@end

@implementation LMScrollView

- (void)scrollViewDidScroll:(UIScrollView*)sender {
	self.contentOffset = CGPointMake(0, self.contentOffset.y);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(self.didSetupContentSize){
		return;
	}
	
	self.delegate = self;
	
	self.didSetupContentSize = YES;
	
	CGRect contentRect = CGRectZero;
	for (UIView *view in self.subviews) {
		contentRect = CGRectUnion(contentRect, view.frame);
	}
	self.contentSize = contentRect.size;
}

@end
