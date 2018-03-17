//
//  LMButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMButton.h"
#import "LMColour.h"

@interface LMButton()

@property UIImageView *imageView;
@property UIView *imageBackgroundView, *textBackgroundView;

@end

@implementation LMButton

@synthesize borderColour = _borderColour;
@synthesize ligniteAccessibilityLabel = _ligniteAccessibilityLabel;
@synthesize ligniteAccessibilityHint = _ligniteAccessibilityHint;

- (void)logFrame{
    NSLog(@"The current frame for %@ is %@.", self, NSStringFromCGRect(self.frame));
}

- (void)layoutSubviews {
	self.imageBackgroundView.layer.cornerRadius = self.roundedCorners ? self.frame.size.width/2 : 6;
	self.imageBackgroundView.layer.masksToBounds = YES;
	self.imageBackgroundView.clipsToBounds = YES;
	
	[self reloadBorder];
	
	[super layoutSubviews];
}

- (void)setLigniteAccessibilityLabel:(NSString *)ligniteAccessibilityLabel {
	_ligniteAccessibilityLabel = ligniteAccessibilityLabel;
	
	self.imageBackgroundView.isAccessibilityElement = YES;
	self.imageBackgroundView.accessibilityLabel = ligniteAccessibilityLabel;
}

- (NSString*)ligniteAccessibilityLabel {
	return _ligniteAccessibilityLabel;
}

- (void)setLigniteAccessibilityHint:(NSString *)ligniteAccessibilityHint {
	_ligniteAccessibilityHint = ligniteAccessibilityHint;
	
	self.imageBackgroundView.isAccessibilityElement = YES;
	self.imageBackgroundView.accessibilityHint = ligniteAccessibilityHint;
}

- (NSString*)ligniteAccessibilityHint {
	return _ligniteAccessibilityHint;
}

- (void)setBorderColour:(LMColour *)borderColour {
	_borderColour = borderColour;
	
	[self reloadBorder];
}

- (LMColour*)borderColour {
	return _borderColour;
}

- (void)reloadBorder {
	if(self.borderColour){
		self.imageBackgroundView.layer.borderWidth = 1.5f;
		self.imageBackgroundView.layer.borderColor = self.borderColour.CGColor;
	}
}

/*
 Sets the view up with all required constraints.
 */
- (void)setupWithImageMultiplier:(CGFloat)imageMultiplier {
//    self.backgroundColor = [UIColor blueColor];
	
	self.imageBackgroundView = [UIView new];
	self.imageBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	self.imageBackgroundView.backgroundColor = [LMColour mainColour];
	
	if(_ligniteAccessibilityLabel || _ligniteAccessibilityHint){
		self.imageBackgroundView.isAccessibilityElement = YES;
		self.imageBackgroundView.accessibilityLabel = _ligniteAccessibilityLabel;
		self.imageBackgroundView.accessibilityHint = _ligniteAccessibilityHint;
	}
	
	[self addSubview:self.imageBackgroundView];
	
	[self.imageBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.imageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
	//[self.imageBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.titleLabel];
	[self.imageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self];
	[self.imageBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	
	self.imageView = [[UIImageView alloc]init];
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.imageView.clipsToBounds = YES;
//	self.imageView.backgroundColor = [UIColor orangeColor];
	[self.imageBackgroundView addSubview:self.imageView];
	
	[self.imageView autoCentreInSuperview];
	[self.imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.imageBackgroundView withMultiplier:imageMultiplier];
	[self.imageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imageBackgroundView withMultiplier:imageMultiplier];
	
    //Add the click recognizer for actions
    UITapGestureRecognizer *clickedRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonClicked)];
    [self addGestureRecognizer:clickedRecognizer];
}

- (void)setImage:(UIImage*)newImage{
	self.imageView.image = newImage;
}

- (void)setColour:(UIColor*)newColour{
	self.imageBackgroundView.backgroundColor = newColour;
	
	//self.imageBackgroundView.backgroundColor = newColour;
	//[self setNeedsDisplay];
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

//- (void)drawRect:(CGRect)rect {
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//	
//	UIColor *color = self.buttonColour ? self.buttonColour : LIGNITE_RED;
//    CGContextSetFillColorWithColor(ctx, color.CGColor);
//
//	CGRect circleRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
//    CGContextFillEllipseInRect(ctx, circleRect);
//}


@end
