//
//  LMLayoutManager.m
//  Landscape
//
//  Created by Edwin Finch on 4/19/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMLayoutManager.h"

@interface LMLayoutManager()

@property NSMutableArray<id<LMLayoutChangeDelegate>> *delegates;

@end

@implementation LMLayoutManager

@synthesize currentLayoutClass = _currentLayoutClass;

+ (LMLayoutManager*)sharedLayoutManager {
	static LMLayoutManager *sharedLayoutManager;
	static dispatch_once_t token;
	
	dispatch_once(&token, ^{
		sharedLayoutManager = [self new];
	});
	
	return sharedLayoutManager;
}

- (void)addDelegate:(id<LMLayoutChangeDelegate>)delegate {
	if(!self.delegates){
		self.delegates = [NSMutableArray new];
	}
	
	[self.delegates addObject:delegate];
}

- (BOOL)isLandscape {
	return [self currentLayoutClass] == LMLayoutClassLandscape;
}

- (LMLayoutClass)currentLayoutClass {
	NSAssert(!CGSizeEqualToSize(self.size, CGSizeZero), @"Trait collection is nil and therefore the current layout class cannot be accessed!");
	
//	NSLog(@"Shitpost %ld %ld", self.traitCollection.horizontalSizeClass, self.traitCollection.verticalSizeClass);
	
	return ((self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
			|| self.traitCollection.horizontalSizeClass == self.traitCollection.verticalSizeClass)
		? LMLayoutClassLandscape : LMLayoutClassPortrait;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	for(id<LMLayoutChangeDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(traitCollectionDidChange:)]){
			[delegate traitCollectionDidChange:previousTraitCollection];
		}
	}
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	for(id<LMLayoutChangeDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(rootViewWillTransitionToSize:withTransitionCoordinator:)]){
			[delegate rootViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
		}
	}
}

@end
