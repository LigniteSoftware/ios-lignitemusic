//
//  LMButton.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMButton;

@protocol LMButtonDelegate <NSObject>
@required
- (void)clickedButton:(LMButton*)button;
@end

@interface LMButton : UIView

@property (nonatomic, assign) id <LMButtonDelegate> delegate;
@property BOOL heightIsSmaller;

- (void)setImage:(UIImage*)newImage;
- (UIColor*)getColor:(LMButton*)button;
- (void)setColour:(UIColor*)newColour;
- (void)setupWithImageMultiplier:(float)imageMultiplier;

@end
