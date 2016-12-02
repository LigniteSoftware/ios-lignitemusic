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
	
	NSLog(@"Content frame %@", NSStringFromCGRect(contentRect));
	
	contentRect = CGRectMake(0, 0, self.adaptForWidth ? contentRect.size.width : WINDOW_FRAME.size.width, self.adaptForWidth ? self.frame.size.height/4 : contentRect.size.height);
	
	self.contentSize = contentRect.size;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		UIEdgeInsets insets = UIEdgeInsetsMake(0,
											   0.0,
											   0,
											   0.0);
		self.contentInset = insets;
		
		self.layoutMargins = insets;
		
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
	}
	return self;
}

@end
