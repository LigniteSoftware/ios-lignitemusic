//
//  LMSectionHeaderView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMSectionHeaderView : UIView

/**
 The title which goes on the top if there's enough room.
 */
@property NSString *title;

/**
 The section's header title that goes beside the icon.
 */
@property NSString *sectionHeaderTitle;

/**
 The icon which goes on the left side.
 */
@property UIImage *icon;

/**
 The factorial of total space to take up within the given superview. Automatically pinned to the bottom.
 */
@property CGFloat heightFactorial;

/**
 The background view for the section header's actual content (icon and section title).
 */
@property UIView *sectionHeaderBackgroundView;

/**
 The selector to call when the X icon is tapped. If not set, no X icon will appear.
 */
@property SEL xIconTapSelector;

@end
