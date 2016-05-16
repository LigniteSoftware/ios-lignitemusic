//
//  LMButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMButton.h"

@interface LMButton()

@property UILabel *titleLabel;
@property UIImageView *imageView;

@end

@implementation LMButton

- (void)logFrame{
    NSLog(@"The current frame for %@ is %@.", self, NSStringFromCGRect(self.frame));
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    NSLog(@"Moving to superview %@, with a current frame of %@.", newSuperview, NSStringFromCGRect(self.frame));
}

/*
 Sets the view up with the title and image as well as root frame.
 */
- (void)setupWithTitle:(NSString*)title withImage:(UIImage*)image {
    self.backgroundColor = [UIColor greenColor];
    
    /*
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.frame.size.height/3 * 2, self.frame.size.width, self.frame.size.width/3)];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:14.0f];
    [self addSubview:self.titleLabel];
    
    uint8_t padding = 14;
    uint16_t diameter = self.frame.size.width-(padding*2);
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(padding, padding, diameter, diameter)];
    self.imageView.image = image;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
    
    self.layer.masksToBounds = NO;
    self.layer.cornerRadius = 7.0;
    self.layer.borderWidth = 0.0;
     */
    
    self.imageView = [[UIImageView alloc]initWithImage:image];
    self.imageView.backgroundColor = [UIColor blueColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0];
    
    //Add constraint to image view that aligns it to the X center of the button's total area
    [self addConstraint:centerXConstraint];
    
    //Add constraint to image view that aligns it to the Y center of the button's total area
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];
    
    //Add constraint to the image view that fits it within the view's width, the padding being standard
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[imageView]-|"
                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:nil
                                                                   views:@{@"imageView":self.imageView}]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:0.5
                                                      constant:0]];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.text = title;
    self.titleLabel.backgroundColor = [UIColor purpleColor];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];
    
    //Add centering X constraint
    [self addConstraint:centerXConstraint];
    
    //Add constraint that aligns the titleview to come after the imageview
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView]-[titleView]"
                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                 metrics:nil
                                                                   views:@{@"imageView":self.imageView, @"titleView":self.titleLabel}]];
    
    //Add the click recognizer for actions
    UITapGestureRecognizer *clickedRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonClicked)];
    [self addGestureRecognizer:clickedRecognizer];
    
    NSLog(@"Setup complete.");
}

/*
 Set title
 */
- (void)setTitle:(NSString*)newTitle {
    self.titleLabel.text = newTitle;
}

/*
 Reacts when button is clicked
 */
- (void)buttonClicked {
    if(self.delegate){
        [self.delegate clickedButton:self];
    }
    [UIView animateWithDuration:0.05 animations:^{
        //Fade to black
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    } completion:^(BOOL finished) {
        //Fade in
        [UIView animateWithDuration:0.05 animations:^{
            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        }];
    }];
}

/*
 Update all views with the new root frame
 */
- (void)updateWithFrame:(CGRect)newFrame {
    self.frame = newFrame;
    [UIView animateWithDuration:0.3 animations:^{
        self.titleLabel.frame = CGRectMake(0, self.frame.size.height/3 * 2, self.frame.size.width, self.frame.size.width/3);
        self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/3 * 2);
    }];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSLog(@"Drawing context...");
    
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1.0);
    uint8_t thickness = 1;
    CGContextSetLineWidth(ctx, thickness);
    int centerY = self.frame.size.height/2;
    uint16_t diameter = self.frame.size.width;
    int padding = thickness*2;
    CGRect circleRect = CGRectMake(padding, centerY-(diameter/2), diameter-padding*2, diameter-padding*2);
    CGContextFillEllipseInRect(ctx, circleRect);
}


@end
