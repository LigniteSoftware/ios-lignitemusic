//
//  LMButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMButton.h"
#import "LMExtras.h"

@interface LMButton()

@property UIImageView *imageView;

@end

@implementation LMButton

- (void)logFrame{
    NSLog(@"The current frame for %@ is %@.", self, NSStringFromCGRect(self.frame));
}

/*
 Sets the view up with all required constraints.
 */
- (void)setupWithImageMultiplier:(float)imageMultiplier {
    self.backgroundColor = [UIColor clearColor];
    
    self.imageView = [[UIImageView alloc]init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
	
	//Align image view to center of frame's X coordinate
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterY
													multiplier:1.0
													  constant:0]];
	
	//Set the width equal to half the image view's width
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:imageMultiplier
													  constant:0]];
	
	//Set the height equal to half the width
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:imageMultiplier
													  constant:0]];
	
	
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];
    
    //Add centering X constraint
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
    
    //Add constraint that aligns the titleview to come after the imageview
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView]-12-[titleView]"
                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                 metrics:nil
                                                                   views:@{@"imageView":self.imageView, @"titleView":self.titleLabel}]];
    
    //Add the click recognizer for actions
    UITapGestureRecognizer *clickedRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonClicked)];
    [self addGestureRecognizer:clickedRecognizer];
}

/*
 Set title
 */
- (void)setTitle:(NSString*)newTitle {
    self.titleLabel.text = newTitle;
}

- (void)setImage:(UIImage*)newImage{
	self.imageView.image = newImage;
}

/*
 Reacts when button is clicked
 */
- (void)buttonClicked {
    if(self.delegate){
        [self.delegate clickedButton:self];
    }
    /*
    [UIView animateWithDuration:0.05 animations:^{
        //Fade to black
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    } completion:^(BOOL finished) {
        //Fade in
        [UIView animateWithDuration:0.05 animations:^{
            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        }];
    }];
     */
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
	
	UIColor *color = LIGNITE_RED;
    CGContextSetFillColorWithColor(ctx, color.CGColor);

	CGRect circleRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    CGContextFillEllipseInRect(ctx, circleRect);
}


@end
