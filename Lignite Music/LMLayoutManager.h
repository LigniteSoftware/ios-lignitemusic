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

/**
 The layout class of the device defines what kind of layout applies to this device. iPad only has one layout class.

 - LMLayoutClassPortrait: Handheld, portrait.
 - LMLayoutClassLandscape: Handheld, landscape.
 - LMLayoutClassiPad: iPad, both orientations.
 */
typedef NS_ENUM(NSInteger, LMLayoutClass) {
	LMLayoutClassPortrait   = 0,
	LMLayoutClassLandscape  = 1,
	LMLayoutClassiPad       = 2
};

/**
 The screen size class for specifying exactly the kind of layout that should be applied.

 - LMScreenSizeClassPhone: A phone or iPod.
 - LMScreenSizeClassiPadMini: An iPad Mini.
 - LMScreenSizeClassiPadAir: An iPad Air/normal sized iPad of 25cm.
 - LMScreenSizeClassiPadPro: An iPad pro, 33cm.
 */
typedef NS_ENUM(NSInteger, LMScreenSizeClass) {
	LMScreenSizeClassPhone     = 0,
	LMScreenSizeClassiPadMini  = 1,
	LMScreenSizeClassiPadAir   = 2,
	LMScreenSizeClassiPadPro   = 3
};

/**
 If the device is one with a notch, such as the iPhone X, LMNotchPosition is the position of the notch relative to the current screen orientation.

 - LMNotchPositionTop: The top of the screen.
 - LMNotchPositionLeft: The left side of the screen.
 - LMNotchPositionRight: The right side of the screen.
 - LMNotchPositionBottom: The bottom of the screen.
 */
typedef NS_ENUM(NSInteger, LMNotchPosition) {
	LMNotchPositionTop    = 0,
	LMNotchPositionLeft   = 1,
	LMNotchPositionRight  = 2,
	LMNotchPositionBottom = 3
};

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

/**
 The notch position changed. This will only ever be called if the device has a notch (such as the iPhone X).

 @param notchPosition The new notch position, relative to the new orientation.
 */
- (void)notchPositionChanged:(LMNotchPosition)notchPosition;

@end

@interface LMLayoutManager : NSObject

@property (readonly) LMLayoutClass currentLayoutClass;
@property UITraitCollection *traitCollection;
@property CGSize size;

- (BOOL)isLandscape;
+ (BOOL)isExtraSmall;
+ (BOOL)isLandscape;
+ (BOOL)isLandscapeiPad;
+ (BOOL)isiPad;
+ (BOOL)isiPhoneX;
+ (LMNotchPosition)notchPosition;
- (void)adjustRootViewSubviewsForLandscapeNavigationBar:(UIView*)rootView;
- (void)adjustRootViewSubviewsForLandscapeNavigationBar:(UIView*)rootView withAdditionalOffset:(CGFloat)additionalOffset;
+ (CGFloat)listEntryHeightFactorial;
+ (CGFloat)standardListEntryHeight;
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
