//
//  LMLayoutManager.m
//  Landscape
//
//  Created by Edwin Finch on 4/19/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <sys/utsname.h>

#import "LMLayoutManager.h"

#import "LMMiniPlayerCoreView.h"
#import "LMGuideViewPagerController.h"
#import "LMGuideViewController.h"
#import "LMTitleView.h"
#import "LMButtonNavigationBar.h"
#import "LMSourceSelectorView.h"
#import "LMNowPlayingView.h"
#import "LMSectionTableView.h"
#import "LMSearchViewController.h"
#import "LMTutorialView.h"
#import "LMAlertView.h"
#import "LMFeedbackViewController.h"
#import "LMCreditsViewController.h"
#import "LMTrackInfoView.h"
#import "LMProgressSlider.h"
#import "LMBrowsingDetailView.h"

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
	
	[layoutManager.portraitConstraintsArray addObjectsFromArray:constraintsArray];
//	NSLog(@"%ld shits", layoutManager.portraitConstraintsArray.count);
	
	if(![layoutManager isLandscape]){ //Add the constraints even if iPad. If iPad constraints are added later, these constraints are removed.
		[NSLayoutConstraint activateConstraints:constraintsArray];
	}
}

+ (void)addNewLandscapeConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	[layoutManager.landscapeConstraintsArray addObjectsFromArray:constraintsArray];
	
	if([layoutManager isLandscape]){
		[NSLayoutConstraint activateConstraints:constraintsArray];
	}
}

+ (void)addNewiPadConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	
	[layoutManager.iPadConstraintsArray addObjectsFromArray:constraintsArray];
	
	if([LMLayoutManager isiPad]){
		NSMutableArray *constraintsToRemove = [NSMutableArray new];
		for(NSLayoutConstraint *iPadConstraint in constraintsArray){
			for(NSLayoutConstraint *portraitConstraint in layoutManager.portraitConstraintsArray){
				if([portraitConstraint.firstItem isEqual:iPadConstraint.firstItem]){
					[constraintsToRemove addObject:portraitConstraint];
				}
			}
		}
		
		[NSLayoutConstraint deactivateConstraints:constraintsToRemove];
		[layoutManager.portraitConstraintsArray removeObjectsInArray:constraintsToRemove];
		
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

+ (BOOL)isLandscape {
	return [LMLayoutManager sharedLayoutManager].isLandscape;
}

+ (BOOL)isLandscapeiPad {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	if(![LMLayoutManager isiPad]){
		return NO;
	}
	
	return layoutManager.size.width > layoutManager.size.height;
}

+ (BOOL)isiPad {
	LMLayoutManager *layoutManager = [LMLayoutManager sharedLayoutManager];
	return [layoutManager currentLayoutClass] == LMLayoutClassiPad;
}

+ (NSString*)deviceName {
	struct utsname systemInfo;
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine
							  encoding:NSUTF8StringEncoding];
}

+ (LMScreenSizeClass)screenSizeClass {
	NSString *deviceName = [LMLayoutManager deviceName];
	
	NSArray *iPadMiniDeviceNames = @[
									 // iPad Mini
									 @"iPad2,5", // - Wifi (model A1432)
									 @"iPad2,6", // - Wifi + Cellular (model  A1454)
									 @"iPad2,7", // - Wifi + Cellular (model  A1455)
									 
									 // iPad Mini 2
									 @"iPad4,4", // - Wifi (model A1489)
									 @"iPad4,5", // - Wifi + Cellular (model A1490)
									 @"iPad4,6", // - Wifi + Cellular (model A1491)
									 
									 // iPad Mini 3
									 @"iPad4,7", // - Wifi (model A1599)
									 @"iPad4,8", // - Wifi + Cellular (model A1600)
									 @"iPad4,9", // - Wifi + Cellular (model A1601)
									 
									 // iPad Mini 4
									 @"iPad5,1", // - Wifi (model A1538)
									 @"iPad5,2", // - Wifi + Cellular (model A1550)
									 ];
	
	NSArray *iPadAirOrRegularDeviceNames = @[
											 //iPad 2
											 @"iPad2,1", // - Wifi (model A1395)
											 @"iPad2,2", // - GSM (model A1396)
											 @"iPad2,3", // - 3G (model A1397)
											 @"iPad2,4", // - Wifi (model A1395)
											 
											 //iPad 3
											 @"iPad3,1", // - Wifi (model A1416)
											 @"iPad3,2", // - Wifi + Cellular (model  A1403)
											 @"iPad3,3", // - Wifi + Cellular (model  A1430)
											 
											 //iPad 4
											 @"iPad3,4", // - Wifi (model A1458)
											 @"iPad3,5", // - Wifi + Cellular (model  A1459)
											 @"iPad3,6", // - Wifi + Cellular (model  A1460)
											 
											 //iPad AIR
											 @"iPad4,1", // - Wifi (model A1474)
											 @"iPad4,2", // - Wifi + Cellular (model A1475)
											 @"iPad4,3", // - Wifi + Cellular (model A1476)
											 
											 //iPad AIR 2
											 @"iPad5,3", // - Wifi (model A1566)
											 @"iPad5,4", // - Wifi + Cellular (model A1567)
											 
											 //iPad PRO 9.7"
											 @"iPad6,7", // - Wifi (model A1584)
											 @"iPad6,8", // - Wifi + Cellular (model A1652)
									 ];
	
	NSArray *iPadProDeviceNames = @[
									// iPad PRO 12.9"
									@"iPad6,3", // - Wifi (model A1673)
									@"iPad6,4", // - Wifi + Cellular (model A1674)
									@"iPad6,4", // - Wifi + Cellular (model A1675)
									 ];
	
	if([iPadMiniDeviceNames containsObject:deviceName]){
		return LMScreenSizeClassiPadMini;
	}
	else if([iPadAirOrRegularDeviceNames containsObject:deviceName]){
		return LMScreenSizeClassiPadAir;
	}
	else if([iPadProDeviceNames containsObject:deviceName]){
		return LMScreenSizeClassiPadPro;
	}
	
	return LMScreenSizeClassPhone;
}

+ (NSInteger)amountOfCollectionViewItemsPerRowForScreenSizeClass:(LMScreenSizeClass)screenSizeClass isLandscape:(BOOL)isLandscape {
	BOOL columnLoverMode = NO;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMCollectionViewItemsPerRowSettingsKey]) {
		columnLoverMode = [userDefaults integerForKey:LMCollectionViewItemsPerRowSettingsKey];
	}
	
	if(isLandscape){
		if(columnLoverMode){
			switch(screenSizeClass){
				case LMScreenSizeClassPhone: {
					return 5;
				}
				case LMScreenSizeClassiPadMini: {
					return 6;
				}
				case LMScreenSizeClassiPadAir: {
					return 9;
				}
				case LMScreenSizeClassiPadPro: {
					return 11;
				}
			}
		}
		//Not column lover mode
		else{
			switch(screenSizeClass){
				case LMScreenSizeClassPhone: {
					return 4;
				}
				case LMScreenSizeClassiPadMini: {
					return 5;
				}
				case LMScreenSizeClassiPadAir: {
					return 8;
				}
				case LMScreenSizeClassiPadPro: {
					return 10;
				}
			}
		}
	}
	else{
		if(columnLoverMode){
			switch(screenSizeClass){
				case LMScreenSizeClassPhone: {
					return 3;
				}
				case LMScreenSizeClassiPadMini: {
					return 5;
				}
				case LMScreenSizeClassiPadAir: {
					return 7;
				}
				case LMScreenSizeClassiPadPro: {
					return 9;
				}
			}
		}
		//Not column lover mode
		else{
			switch(screenSizeClass){
				case LMScreenSizeClassPhone: {
					return 2;
				}
				case LMScreenSizeClassiPadMini: {
					return 4;
				}
				case LMScreenSizeClassiPadAir: {
					return 6;
				}
				case LMScreenSizeClassiPadPro: {
					return 8;
				}
			}
		}
	}
	return 2;
}

+ (NSInteger)amountOfCollectionViewItemsPerRow {
	BOOL isLandscape = [LMLayoutManager isLandscape] || [LMLayoutManager isLandscapeiPad];
	
	return [LMLayoutManager amountOfCollectionViewItemsPerRowForScreenSizeClass:[LMLayoutManager screenSizeClass] isLandscape:isLandscape];
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
		
		NSLog(@"%ld (of %ld) portrait in place constraints", (unsigned long)self.portraitConstraintsBeingUsedInPlaceOfMissingiPadConstraintsArray.count, (unsigned long)self.portraitConstraintsArray);
		
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
	
	NSLog(@"Swapped constraints, now animating.");
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	self.size = size;
	
	//	NSArray *approvedClasses = @[
	//								 [LMMiniPlayerCoreView class], [LMGuideViewPagerController class], [LMGuideViewController class], [LMTitleView class], [LMButtonNavigationBar class], [LMSourceSelectorView class], [LMNowPlayingView class], [LMSectionTableView class], [LMSearchViewController class], [LMLetterTabBar class], [LMTutorialView class], [LMAlertView class], [LMFeedbackViewController class], [LMCreditsViewController class], [LMBrowsingBar class], [LMTrackInfoView class],
	//								 [LMProgressSlider class], [LMBrowsingDetailView class]
	//								 ];
	
	for(id<LMLayoutChangeDelegate>delegate in self.delegates){
		if([delegate respondsToSelector:@selector(rootViewWillTransitionToSize:withTransitionCoordinator:)]){
			//			Class class = [delegate class];
			//
			//			if([approvedClasses containsObject:class]){
			//				NSLog(@"%@ IS approved, pinging", [class description]);
			[delegate rootViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
			//			}
			//			else{
			//				NSLog(@"%@ is not an approved class for rotation", [class description]);
			//			}
		}
	}
}

@end
