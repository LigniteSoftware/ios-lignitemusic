//
//  LMLayoutManager.m
//  Landscape
//
//  Created by Edwin Finch on 4/19/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMLayoutManager.h"

@interface LMLayoutManager()

/**
 The array of delegates.
 */
@property NSMutableArray<id<LMLayoutChangeDelegate>> *delegates;

/**
 The arrays of portrait and landscape constraints.
 */
@property (strong) NSMutableArray<NSLayoutConstraint*> *portraitConstraintsArray, *landscapeConstraintsArray;

@end

@implementation LMLayoutManager

@synthesize currentLayoutClass = _currentLayoutClass;

+ (LMLayoutManager*)sharedLayoutManager {
	static LMLayoutManager *sharedLayoutManager;
	static dispatch_once_t token;
	
	dispatch_once(&token, ^{
		sharedLayoutManager = [self new];
		sharedLayoutManager.portraitConstraintsArray = [NSMutableArray new];
		sharedLayoutManager.landscapeConstraintsArray = [NSMutableArray new];
	});
	
	return sharedLayoutManager;
}

- (void)addDelegate:(id<LMLayoutChangeDelegate>)delegate {
	if(!self.delegates){
		self.delegates = [NSMutableArray new];
	}
	
	[self.delegates addObject:delegate];
}

+ (void)addNewPortraitConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	for(NSLayoutConstraint *constraint in constraintsArray){
		[layoutManager.portraitConstraintsArray addObject:constraint];
	}
	
	if(![layoutManager isLandscape]){
		[NSLayoutConstraint activateConstraints:constraintsArray];
	}
}

+ (void)addNewLandscapeConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	for(NSLayoutConstraint *constraint in constraintsArray){
		[layoutManager.landscapeConstraintsArray addObject:constraint];
	}
	
	if([layoutManager isLandscape]){
		[NSLayoutConstraint activateConstraints:constraintsArray];
	}
}

+ (void)removeAllConstraintsRelatedToView:(UIView*)view {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	NSArray<NSMutableArray*> *arraysToMutate = @[ layoutManager.portraitConstraintsArray, layoutManager.landscapeConstraintsArray ];
	
	for(NSMutableArray *mutatingArray in arraysToMutate){
		NSMutableArray *oldConstraintsArray = [NSMutableArray arrayWithArray:mutatingArray];
		for(NSLayoutConstraint *constraint in oldConstraintsArray){
			if(constraint.firstItem == view || constraint.secondItem == view){
				constraint.active = NO;
				[mutatingArray removeObject:constraint];
			}
		}
	}
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
	
	NSLog(@"Swapping out %ld/%ld constraints...", self.portraitConstraintsArray.count, self.landscapeConstraintsArray.count);
	
	[NSLayoutConstraint deactivateConstraints:self.isLandscape ? self.portraitConstraintsArray : self.landscapeConstraintsArray];
	[NSLayoutConstraint activateConstraints:self.isLandscape ? self.landscapeConstraintsArray : self.portraitConstraintsArray];
	
	NSLog(@"Swapped, now animating.");
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	for(id<LMLayoutChangeDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(rootViewWillTransitionToSize:withTransitionCoordinator:)]){
			[delegate rootViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
		}
	}
	
//	BOOL willBeLandscape = size.width > size.height;
//	
//	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		
//		NSLog(@"Swapping out constraints...");
//		
//		[NSLayoutConstraint deactivateConstraints:willBeLandscape ? self.portraitConstraintsArray : self.landscapeConstraintsArray];
//		[NSLayoutConstraint activateConstraints:willBeLandscape ? self.landscapeConstraintsArray : self.portraitConstraintsArray];
//		
//		NSLog(@"Swapped, now animating.");
//		
//	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		NSLog(@"Done.");
//	}];
}

@end
