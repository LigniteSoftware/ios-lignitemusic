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

- (void)updateWithFrame:(CGRect)newFrame;
- (void)setTitle:(NSString*)newTitle;
- (void)setupWithTitle:(NSString*)title withImage:(UIImage*)image;

@end