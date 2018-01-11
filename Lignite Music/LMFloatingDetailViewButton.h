//
//  LMFloatingDetailViewButton.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/11/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMAppIcon.h"

typedef NS_ENUM(NSInteger, LMFloatingDetailViewControlButtonType){
	LMFloatingDetailViewControlButtonTypeClose = 0,
	LMFloatingDetailViewControlButtonTypeShuffle,
	LMFloatingDetailViewControlButtonTypeBack
};

@class LMFloatingDetailViewButton;

@protocol LMFloatingDetailViewButtonDelegate <NSObject>

/**
 The floating detail view button was tapped.

 @param button The button that was tapped.
 */
- (void)floatingDetailViewButtonTapped:(LMFloatingDetailViewButton*)button;

@end

@interface LMFloatingDetailViewButton : LMView

/**
 The delegate.
 */
@property id<LMFloatingDetailViewButtonDelegate> delegate;

/**
 The type of button.
 */
@property LMFloatingDetailViewControlButtonType type;

@end
