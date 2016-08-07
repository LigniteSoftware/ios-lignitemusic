//
//  LMProgressCircle.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMProgressCircleView.h"
#import "LMExtras.h"

@implementation LMProgressCircleView

- (id)init {
    self = [super init];
    if(self){
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)reload {
    //NSLog(@"Reloading circle display %f", self.currentValue);
    //[self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    int smallerFactor = MIN(rect.size.width, rect.size.height);
    //int progressBarThickness = self.thickness;

    CGFloat theHalf = rect.size.width/2;
    //CGFloat lineWidth = smallerFactor/2;
    //CGFloat radius = smallerFactor/4 - progressBarThickness;
    CGFloat centerX = theHalf;
    CGFloat centerY = rect.size.height/2;
    
    //CGRect circleRect = CGRectMake(centerX-(radius*2), centerY-(radius*2), radius*4, radius*4);
    CGRect fadedRect = CGRectMake(centerX-(smallerFactor/2), centerY-(smallerFactor/2), smallerFactor, smallerFactor);
    
    float startAngle = - M_PI_2;
    float endAngle = 0.0f;
    float percent = self.currentValue/self.maxValue;
    endAngle = startAngle + (M_PI * 2)*percent;

    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.25);
    CGContextFillEllipseInRect(context, fadedRect);
    
    /*
    CGContextAddArc(context, centerX, centerY, radius, startAngle, endAngle, false);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, lineWidth);
    CGContextStrokePath(context);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextFillEllipseInRect(context, circleRect);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.05);
    CGContextFillEllipseInRect(context, circleRect);
    */
     
    
//    CGRect albumCircle = CGRectMake(centerX-self.albumRadius, centerY-self.albumRadius, self.albumRadius*2, self.albumRadius*2);
//    //CGRect albumCircle = CGRectMake(35, 35, 222, 222);
//    CGContextSetBlendMode(context, kCGBlendModeClear);
//    //CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
////    NSLog(@"drawing radius %@", NSStringFromCGRect(albumCircle));
//    CGContextFillEllipseInRect(context, albumCircle);
}

@end
