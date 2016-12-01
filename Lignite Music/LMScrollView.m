//
//  LMScrollView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMScrollView.h"
#import "LMExtras.h"

@interface LMScrollView()<UIScrollViewDelegate>

@property BOOL didSetupContentSize;

@end

@implementation LMScrollView

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
	contentRect = CGRectMake(0, 0, WINDOW_FRAME.size.width /* I know, it's hacky. */, contentRect.size.height);
	
	self.contentSize = contentRect.size;
}

@end
