//
//  LMView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@interface LMView()
//<LMLayoutChangeDelegate>

//@property (strong) NSMutableArray<NSLayoutConstraint*> *portraitConstraints;
//
//@property (strong) NSMutableArray<NSLayoutConstraint*> *landscapeConstraints;
//
//@property LMLayoutManager *layoutManager;

@end

@implementation LMView
//
//- (instancetype)init {
//	self = [super init];
//	if(self) {
//		self.layoutManager = [LMLayoutManager sharedLayoutManager];
//		
//		self.lands8capeConstraints = [NSMutableArray new];
//		self.portraitConstraints = [NSMutableArray new];
//		
//		self.settingLayoutClass = LMLayoutClassAll;
//		
////		[self.layoutManager addDelegate:self];
//	}
//	return self;
//}
//
//- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		BOOL isNowLandscape = size.width > size.height;
//		
//		if(self.landscapeConstraints.count == 0 && self.portraitConstraints.count == 0){ //No specific constraints have been defined, and that's ok. Leave it alone.
//			return;
//		}
//		
//		NSLog(@"Rotating %p...", self);
//		
//		[NSLayoutConstraint deactivateConstraints:isNowLandscape ? self.portraitConstraints : self.landscapeConstraints];
//		[NSLayoutConstraint activateConstraints:isNowLandscape ? self.landscapeConstraints : self.portraitConstraints];
//		
//		[self layoutIfNeeded];
//	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { /* Completion code here, if you wish */ }];
//}

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

//- (void)addConstraint:(NSLayoutConstraint *)constraint {
////	NSLog(@"Add constraint %@", NSStringFromCGRect(self.frame));
//	
//	if(self.settingLayoutClass != LMLayoutClassLandscape){
//		[super addConstraint:constraint];
//	}
//	
////	if(self.settingLayoutClass != LMLayoutClassAll){
////		(self.settingLayoutClass == LMLayoutClassPortrait) ? [self.portraitConstraints addObject:constraint] : [self.landscapeConstraints addObject:constraint];
////	}
//}

@end
