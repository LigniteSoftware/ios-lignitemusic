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

@property (strong) NSMutableArray<NSLayoutConstraint*> *portraitConstraints;

@property (strong) NSMutableArray<NSLayoutConstraint*> *landscapeConstraints;

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
		if(([[[view class] description] isEqualToString:@"UILabel"] && self.adaptForWidth) || !self.adaptForWidth){
			contentRect = CGRectUnion(contentRect, view.frame);
		}
	}
		
	contentRect = CGRectMake(0, 0, self.adaptForWidth ? (contentRect.size.width+30) : self.frame.size.width, self.adaptForWidth ? self.frame.size.height : (contentRect.size.height+20));
	
	self.contentSize = contentRect.size;
}

- (void)reload {
	self.didSetupContentSize = NO;
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

//- (void)beginAddingNewPortraitConstraints {
//	self.settingLayoutClass = LMLayoutClassPortrait;
//}
//
//- (void)beginAddingNewLandscapeConstraints {
//	self.settingLayoutClass = LMLayoutClassLandscape;
//}
//
//- (void)endAddingNewConstraints {
//	self.settingLayoutClass = LMLayoutClassAll;
//}

- (instancetype)init {
	self = [super init];
	if(self) {
		UIEdgeInsets insets = UIEdgeInsetsMake(0.0,
											   0.0,
											   0.0,
											   0.0);
		self.contentInset = insets;
		
		self.layoutMargins = insets;
		
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
	}
	return self;
}

@end
