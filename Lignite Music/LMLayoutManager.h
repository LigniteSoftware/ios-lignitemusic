//
//  LMLayoutManager.h
//  Landscape
//
//  Created by Edwin Finch on 4/19/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LMLayoutManager;

@protocol LMLayoutChangeDelegate <NSObject>
@optional

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator;

@end

@interface LMLayoutManager : NSObject

typedef NS_ENUM(NSInteger, LMLayoutClass) {
	LMLayoutClassAll        = 0,
	LMLayoutClassPortrait   = 1,
	LMLayoutClassLandscape  = 2,
};

@property (readonly) LMLayoutClass currentLayoutClass;
@property UITraitCollection *traitCollection;
@property CGSize size;

- (BOOL)isLandscape;
+ (LMLayoutManager*)sharedLayoutManager;
- (void)addDelegate:(id<LMLayoutChangeDelegate>)delegate;
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator;
+ (void)addNewPortraitConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray;
+ (void)addNewLandscapeConstraints:(NSArray<NSLayoutConstraint*>*)constraintsArray;

@end
