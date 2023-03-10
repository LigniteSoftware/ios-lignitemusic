//
//  LMButton.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMColour.h"
#import "LMView.h"

@class LMButton;

@protocol LMButtonDelegate <NSObject>
@required
- (void)clickedButton:(LMButton*)button;
@end

@interface LMButton : LMView

@property (nonatomic, assign) id <LMButtonDelegate> delegate;
@property BOOL heightIsSmaller;
@property BOOL roundedCorners;
@property LMColour *borderColour;

@property NSString *ligniteAccessibilityLabel;
@property NSString *ligniteAccessibilityHint;

- (void)reloadBorder;
- (void)setImage:(UIImage*)newImage;
- (void)setColour:(UIColor*)newColour;
- (void)setupWithImageMultiplier:(CGFloat)imageMultiplier;

@end
