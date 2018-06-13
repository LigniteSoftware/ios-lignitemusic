//
//  LMQueueViewSeparator.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-12.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMQueueViewSeparator.h"
#import "LMColour.h"

@interface LMQueueViewSeparator()

/**
 The actual separator line.
 */
@property UIView *separatorLineView;

@end

@implementation LMQueueViewSeparator

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self){
		self.backgroundColor = [UIColor whiteColor];
		
		CGRect lineFrame = CGRectMake(20, (frame.size.height / 2.0) - 1, frame.size.width - 40, 2);
		
		self.separatorLineView = [[UIView alloc]initWithFrame:lineFrame];
		self.separatorLineView.backgroundColor = [LMColour superLightGreyColour];
		[self addSubview:self.separatorLineView];
	}
	return self;
}

@end
