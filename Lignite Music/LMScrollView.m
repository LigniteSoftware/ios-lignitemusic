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

@property LMLayoutManager *layoutManager;

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

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		BOOL isNowLandscape = size.width > size.height;
		
		if(self.landscapeConstraints.count == 0){ //No landscape constraints have been defined, and that's ok. Leave it alone.
			return;
		}
		
		NSLog(@"Rotating %p...", self);
		
		[self removeConstraints:isNowLandscape ? self.portraitConstraints : self.landscapeConstraints];
		[self addConstraints:isNowLandscape ? self.landscapeConstraints : self.portraitConstraints];
		
		[self layoutIfNeeded];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { /* Completion code here, if you wish */ }];
}

- (void)reload {
	self.didSetupContentSize = NO;
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

- (void)beginAddingNewPortraitConstraints {
	self.settingLayoutClass = LMLayoutClassPortrait;
}

- (void)beginAddingNewLandscapeConstraints {
	self.settingLayoutClass = LMLayoutClassLandscape;
}

- (void)endAddingNewConstraints {
	self.settingLayoutClass = LMLayoutClassAll;
}

- (void)addConstraint:(NSLayoutConstraint *)constraint {
	//	NSLog(@"Add constraint %@", NSStringFromCGRect(self.frame));
	
	[super addConstraint:constraint];
	
	if(self.settingLayoutClass == LMLayoutClassAll){
		return;
	}
	
	(self.settingLayoutClass == LMLayoutClassPortrait) ? [self.portraitConstraints addObject:constraint] : [self.landscapeConstraints addObject:constraint];
	
	if(self.settingLayoutClass != [LMLayoutManager sharedLayoutManager].currentLayoutClass){
		//		NSLog(@"Deactivating %ld %ld", (long)self.settingLayoutClass, (long)[LMLayoutManager sharedLayoutManager].currentLayoutClass);
		
		[super removeConstraint:constraint];
	}
}


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
//		self.showsHorizontalScrollIndicator = NO;
	}
	return self;
}

@end
