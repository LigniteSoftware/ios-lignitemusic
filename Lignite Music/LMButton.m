//
//  LMButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButton.h"
#import "LMExtras.h"

@interface LMButton()

@property UIImageView *imageView;
@property UIView *imageBackgroundView, *textBackgroundView;
@property UIColor *buttonColour;

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
	
	self.imageBackgroundView = [UIView new];
	self.imageBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	//self.imageBackgroundView.backgroundColor = [UIColor greenColor];
	[self addSubview:self.imageBackgroundView];
	
	[self.imageBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.imageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	[self.imageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
	[self.imageBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
    
    self.imageView = [[UIImageView alloc]init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.clipsToBounds = YES;
    [self.imageBackgroundView addSubview:self.imageView];
	
	[self.imageView autoCenterInSuperview];
	[self.imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.imageBackgroundView withMultiplier:imageMultiplier];
	[self.imageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imageBackgroundView withMultiplier:imageMultiplier];
	
	self.textBackgroundView = [UIView new];
	self.textBackgroundView.backgroundColor = [UIColor redColor];
	self.textBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.textBackgroundView];
	
	[self.textBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imageBackgroundView];
	[self.textBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.textBackgroundView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
	
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
	self.titleLabel.numberOfLines = 0;
	self.titleLabel.adjustsFontSizeToFitWidth = YES;
	self.titleLabel.minimumScaleFactor = 0;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textBackgroundView addSubview:self.titleLabel];
	
	[self.titleLabel autoCenterInSuperview];
	
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

- (void)setColour:(UIColor*)newColour{
	self.buttonColour = newColour;
	[self setNeedsDisplay];
}

/*
 Reacts when button is clicked
 */
- (void)buttonClicked {
    if(self.delegate){
        [self.delegate clickedButton:self];
    }
	
//    [UIView animateWithDuration:0.05 animations:^{
//        //Fade to black
//        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
//    } completion:^(BOOL finished) {
//        //Fade in
//        [UIView animateWithDuration:0.05 animations:^{
//            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
//        }];
//    }];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	UIColor *color = self.buttonColour ? self.buttonColour : LIGNITE_RED;
    CGContextSetFillColorWithColor(ctx, color.CGColor);

	CGRect circleRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    CGContextFillEllipseInRect(ctx, circleRect);
}


@end
