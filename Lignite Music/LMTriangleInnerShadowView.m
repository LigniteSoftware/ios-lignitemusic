//
//  LMTriangleInnerShadowView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMTriangleInnerShadowView.h"

@implementation LMTriangleInnerShadowView

- (void)drawInnerShadowInContext:(CGContextRef)context
						withPath:(CGPathRef)path
					 shadowColor:(CGColorRef)shadowColor
						  offset:(CGSize)offset
					  blurRadius:(CGFloat)blurRadius {
	
	CGContextSaveGState(context);
	
	CGContextAddPath(context, path);
	CGContextClip(context);
	
	CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);
	
	CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
	CGContextBeginTransparencyLayer(context, NULL);
	CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
	CGContextSetBlendMode(context, kCGBlendModeSourceOut);
	CGContextSetFillColorWithColor(context, opaqueShadowColor);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGContextEndTransparencyLayer(context);
	
	CGContextRestoreGState(context);
	
	CGColorRelease(opaqueShadowColor);
}

- (UIBezierPath*)shadowpath {
	UIBezierPath *path = [UIBezierPath new];
	
	[path moveToPoint:(CGPoint){ self.frame.size.width/2, 0 }];
	[path addLineToPoint:(CGPoint){ self.frame.size.width + 20, self.frame.size.height + 10 }];
	[path addLineToPoint:(CGPoint){ -20, self.frame.size.height + 10}];
//	[path addLineToPoint:(CGPoint){ self.frame.size.width/2, 0}];
//	[path addLineToPoint:(CGPoint){ 0, -10}];
//	[path addLineToPoint:(CGPoint){ 0, self.frame.size.height}];
	//	[path addLineToPoint:(CGPoint){ -self.superview.frame.size.width/2, self.frame.size.height + 10 }];
	//	[path addLineToPoint:(CGPoint){ self.frame.size.width, self.frame.size.height }];
	
	[path closePath];
	
	return path;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	NSLog(@"%@", NSStringFromCGRect(self.frame));
	
	if(true){
		[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self shadowpath].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
