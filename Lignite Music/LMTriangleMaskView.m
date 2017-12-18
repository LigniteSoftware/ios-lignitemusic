//
//  LMTriangleMaskView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTriangleMaskView.h"

@interface LMTriangleMaskView()

@property BOOL hasSetConstraints;

@end

@implementation LMTriangleMaskView

- (UIBezierPath*)path {
	UIBezierPath *path = [UIBezierPath new];
	switch(self.maskDirection){
		case LMTriangleMaskDirectionUpwards:
			[path moveToPoint:(CGPoint){0, self.frame.size.height}];
			[path addLineToPoint:(CGPoint){self.frame.size.width/2, 0}];
			[path addLineToPoint:(CGPoint){self.frame.size.width, self.frame.size.height}];
			break;
		case LMTriangleMaskDirectionRight:
			[path moveToPoint:(CGPoint){0, 0}];
			[path addLineToPoint:(CGPoint){self.frame.size.width, self.frame.size.height/2}];
			[path addLineToPoint:(CGPoint){0, self.frame.size.height}];
			break;
		case LMTriangleMaskDirectionDownwards:
			[path moveToPoint:(CGPoint){0, 0}];
			[path addLineToPoint:(CGPoint){self.frame.size.width/2, self.frame.size.height}];
			[path addLineToPoint:(CGPoint){self.frame.size.width, 0}];
			break;
		case LMTriangleMaskDirectionLeft:
			[path moveToPoint:(CGPoint){self.frame.size.width, 0}];
			[path addLineToPoint:(CGPoint){0, self.frame.size.height/2}];
			[path addLineToPoint:(CGPoint){self.frame.size.width, self.frame.size.height}];
			break;
	}
	
	//	[path addLineToPoint:(CGPoint){0, 0}];
	[path closePath];
	return path;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.backgroundColor = self.triangleColour;
	
	self.clipsToBounds = YES;
	
	if(self.bounds.size.height == 0){
		return;
	}
	else{
		// Build a triangular path
		UIBezierPath *path = [self path];
		
		// Create a CAShapeLayer with this triangular path
		// Same size as the original imageView
		CAShapeLayer *mask = [CAShapeLayer new];
		mask.frame = self.bounds;
		mask.path = path.CGPath;
		
		// Mask the imageView's layer with this shape
		self.layer.mask = mask;
	}
}

- (void)setup {
	if(!self.hasSetConstraints){
		[self autoCentreInSuperview];
		[self autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.superview];
		[self autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.superview];
		
		self.hasSetConstraints = YES;
	}
}

//- (void)drawInnerShadowInContext:(CGContextRef)context
//						withPath:(CGPathRef)path
//					 shadowColor:(CGColorRef)shadowColor
//						  offset:(CGSize)offset
//					  blurRadius:(CGFloat)blurRadius {
//	
//	CGContextSaveGState(context);
//	
//	CGContextAddPath(context, path);
//	CGContextClip(context);
//	
//	CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);
//	
//	CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
//	CGContextBeginTransparencyLayer(context, NULL);
//	CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
//	CGContextSetBlendMode(context, kCGBlendModeSourceOut);
//	CGContextSetFillColorWithColor(context, opaqueShadowColor);
//	CGContextAddPath(context, path);
//	CGContextFillPath(context);
//	CGContextEndTransparencyLayer(context);
//	
//	CGContextRestoreGState(context);
//	
//	CGColorRelease(opaqueShadowColor);
//}
//
//- (UIBezierPath*)shadowpath {
//	UIBezierPath *path = [UIBezierPath new];
//	
//	[path moveToPoint:(CGPoint){ self.frame.size.width/2, 0 }];
//	[path addLineToPoint:(CGPoint){ self.frame.size.width, self.frame.size.height }];
//	[path addLineToPoint:(CGPoint){ self.frame.size.width, -10}];
//	[path addLineToPoint:(CGPoint){ 0, -10}];
//	[path addLineToPoint:(CGPoint){ 0, self.frame.size.height}];
////	[path addLineToPoint:(CGPoint){ -self.superview.frame.size.width/2, self.frame.size.height + 10 }];
////	[path addLineToPoint:(CGPoint){ self.frame.size.width, self.frame.size.height }];
//	
//	[path closePath];
//	
//	return path;
//}
//
//- (void)drawRect:(CGRect)rect {
//	[super drawRect:rect];
//	
//	NSLog(@"%@", NSStringFromCGRect(self.frame));
//	
//	if(true){
//		[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self shadowpath].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
//	}
//}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//	[super drawRect:rect];
//	
//	[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self path].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
//    // Drawing code
//}


@end
