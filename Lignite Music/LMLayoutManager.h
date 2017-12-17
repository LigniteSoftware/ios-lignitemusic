//
//  LMLayoutManager.h
//  Landscape
//
//  Created by Edwin Finch on 4/19/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define LMCollectionViewItemsPerRowSettingsKey @"LMCollectionViewItemsPerRowSettingsKey"

@class LMLayoutManager;

@protocol LMLayoutChangeDelegate <NSObject>
@optional

/**
 The trait collection changed.

 @param previousTraitCollection The trait collection that dominated before the change.
 */
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;

/**
 The window view will transition to its new size due to rotation.

 @param size The new size of the window.
 @param coordinator The coordinator that is coordinating coordinations of coordinate cordinaldordinals.
 */
- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator;

@end

@interface LMLayoutManager : NSObject

typedef NS_ENUM(NSInteger, LMLayoutClass) {
	LMLayoutClassPortrait   = 0,
	LMLayoutClassLandscape  = 1,
	LMLayoutClassiPad       = 2
};

typedef NS_ENUM(NSInteger, LMScreenSizeClass) {
	LMScreenSizeClassPhone     = 0,
	LMScreenSizeClassiPadMini  = 1,
	LMScreenSizeClassiPadAir   = 2,
	LMScreenSizeClassiPadPro   = 3
};

@property (readonly) LMLayoutClass currentLayoutClass;
@property UITraitCollection *traitCollection;
@property CGSize size;

- (BOOL)isLandscape;
+ (BOOL)isExtraSmall;
+ (BOOL)isLandscape;
+ (BOOL)isLandscapeiPad;
+ (BOOL)isiPad;
+ (BOOL)isiPhoneX;
+ (NSInteger)amountOfCollectionViewItemsPerRow;
+ (NSInteger)amountOfCollectionViewItemsPerRowForScreenSizeClass:(LMScreenSizeClass)screenSizeClass isLandscape:(BOOL)isLandscape;
+ (LMLayoutManager*)sharedLayoutManager;
- (void)addDelegate:(id<LMLayoutChangeDelegate>)delegate;
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator;
+ (void)addNewPortraitConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray;
+ (void)addNewLandscapeConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray;
+ (void)addNewiPadConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray;
+ (void)removeAllConstraintsRelatedToView:(UIView*)view;
+ (void)recursivelyRemoveAllConstraintsForViewAndItsSubviews:(UIView*)view;

@end
