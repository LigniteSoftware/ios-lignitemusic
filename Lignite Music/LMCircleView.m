//
//  LMCircleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCircleView.h"

@interface LMCircleView()

@property UIView *shadowView;
@property UIView *circleView;

@end

@implementation LMCircleView

- (void)layoutSubviews {
	BOOL layoutSuperview = NO;
	
	if(!self.shadowView){
		self.shadowView = [UIView newAutoLayoutView];
		[self addSubview:self.shadowView];
		
		self.shadowView.backgroundColor = [UIColor clearColor];
		self.shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.shadowView.layer.shadowOpacity = 0.25;
		self.shadowView.layer.shadowRadius = self.frame.size.height/15;
		self.shadowRadius = self.shadowView.layer.shadowRadius;
		layoutSuperview = YES;
		self.shadowView.layer.shadowOffset = CGSizeMake(0, self.shadowView.layer.shadowRadius/2);
		self.shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.frame.size.height/2].CGPath;
	}
	
	if(!self.circleView){
		self.circleView = [UIView newAutoLayoutView];
		self.circleView.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.circleView];
		[self.circleView autoCenterInSuperview];
		[self.circleView autoPinEdgesToSuperviewEdges];
		
		self.circleView.layer.cornerRadius = self.frame.size.height/2;
		self.circleView.layer.masksToBounds = YES;
	}
	
	if(layoutSuperview){
		[self.superview setNeedsLayout];
		[self.superview layoutIfNeeded];
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
