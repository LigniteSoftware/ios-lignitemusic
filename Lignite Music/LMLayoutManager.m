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
 The arrays of constraints.
 */
@property (strong) NSMutableArray<NSLayoutConstraint*> *portraitConstraintsArray, *landscapeConstraintsArray, *iPadConstraintsArray;

/**
 The array of constraints in which are used for all views which don't have explicit iPad constraints applied to them.
 */
@property NSMutableArray *portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray;

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
		sharedLayoutManager.iPadConstraintsArray = [NSMutableArray new];
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
	
	if([layoutManager currentLayoutClass] == LMLayoutClassPortrait){
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

+ (void)addNewiPadConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	for(NSLayoutConstraint *constraint in constraintsArray){
		[layoutManager.iPadConstraintsArray addObject:constraint];
	}
	
	if([LMLayoutManager isiPad]){
		[NSLayoutConstraint activateConstraints:constraintsArray];
	}
}

+ (void)recursivelyRemoveAllConstraintsForViewAndItsSubviews:(UIView*)view {	
	[LMLayoutManager removeAllConstraintsRelatedToView:view];
	
	for(UIView *subview in view.subviews){
		[self recursivelyRemoveAllConstraintsForViewAndItsSubviews:subview];
	}
}

+ (void)removeAllConstraintsRelatedToView:(UIView*)view {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	NSArray<NSMutableArray*> *arraysToMutate = @[ layoutManager.portraitConstraintsArray, layoutManager.landscapeConstraintsArray, layoutManager.iPadConstraintsArray ];
	
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
//	return self.size.width > self.size.height;
}

+ (BOOL)isiPad {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	return [layoutManager currentLayoutClass] == LMLayoutClassiPad;
}

- (LMLayoutClass)currentLayoutClass {
	NSAssert(!CGSizeEqualToSize(self.size, CGSizeZero), @"Trait collection is nil and therefore the current layout class cannot be accessed!");
	
//	NSLog(@"Shitpost %ld %ld", self.traitCollection.horizontalSizeClass, self.traitCollection.verticalSizeClass);
	
	if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular){
		
		return LMLayoutClassiPad;
	}
	
	if(   (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
	   || (self.traitCollection.horizontalSizeClass == self.traitCollection.verticalSizeClass)) {
		
		return LMLayoutClassLandscape;
	}
	
	return LMLayoutClassPortrait;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	for(id<LMLayoutChangeDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(traitCollectionDidChange:)]){
			[delegate traitCollectionDidChange:previousTraitCollection];
		}
	}
	
	NSLog(@"Swapping out %ld/%ld/%ld constraints...", (unsigned long)self.portraitConstraintsArray.count, (unsigned long)self.landscapeConstraintsArray.count, (unsigned long)self.iPadConstraintsArray.count);
	
	if([LMLayoutManager isiPad]){
		[NSLayoutConstraint deactivateConstraints:self.portraitConstraintsArray];
		[NSLayoutConstraint deactivateConstraints:self.landscapeConstraintsArray];
		
		NSMutableArray<UIView*> *viewsWhichHaveiPadConstraints = [NSMutableArray new];
		for(NSLayoutConstraint *constraint in self.iPadConstraintsArray){
			if(![viewsWhichHaveiPadConstraints containsObject:constraint.firstItem]){
				[viewsWhichHaveiPadConstraints addObject:constraint.firstItem];
			}
		}
		
		NSMutableArray *portraitConstraintsToUseInPlaceOfMissingiPadConstraints = [NSMutableArray new];
		for(NSLayoutConstraint *constraint in self.portraitConstraintsArray){
			if(![viewsWhichHaveiPadConstraints containsObject:constraint.firstItem]){
				[portraitConstraintsToUseInPlaceOfMissingiPadConstraints addObject:constraint];
			}
		}
		
		self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray = portraitConstraintsToUseInPlaceOfMissingiPadConstraints;
		
		NSLog(@"%ld portrait in place constraints", (unsigned long)self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray.count);
		
		[NSLayoutConstraint activateConstraints:self.iPadConstraintsArray];
		[NSLayoutConstraint activateConstraints:self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray];
	}
	else{
		if(self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray){
			[NSLayoutConstraint deactivateConstraints:self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray];
			[NSLayoutConstraint deactivateConstraints:self.iPadConstraintsArray];
			
			self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray = nil;
		}
		[NSLayoutConstraint deactivateConstraints:self.isLandscape ? self.portraitConstraintsArray : self.landscapeConstraintsArray];
		[NSLayoutConstraint activateConstraints:self.isLandscape ? self.landscapeConstraintsArray : self.portraitConstraintsArray];
	}
	
	NSLog(@"Swapped, now animating.");
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	self.size = size;
	
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
