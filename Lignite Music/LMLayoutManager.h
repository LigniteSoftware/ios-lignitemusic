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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
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
+ (BOOL)isLandscape;
+ (BOOL)isLandscapeiPad;
+ (BOOL)isiPad;
+ (NSInteger)amountOfCollectionViewItemsPerRow;
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
