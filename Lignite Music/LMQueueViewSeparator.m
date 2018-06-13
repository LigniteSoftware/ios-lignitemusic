//
//  LMQueueViewSeparator.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-12.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMQueueViewSeparatorLayoutAttributes.h"
#import "LMQueueViewSeparator.h"
#import "LMColour.h"

@interface LMQueueViewSeparator()

/**
 The actual separator line.
 */
@property UIView *separatorLineView;

@end

@implementation LMQueueViewSeparator

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
	if(self.separatorLineView){
		LMQueueViewSeparatorLayoutAttributes *queueViewAttributes = (LMQueueViewSeparatorLayoutAttributes*)layoutAttributes;
		CGRect lineFrame = CGRectMake(20, (self.frame.size.height / 2.0) - 1 + (queueViewAttributes.additionalOffset / 2.0), self.frame.size.width - 40, 2);
		
//		self.backgroundColor = queueViewAttributes.isLastRow ? [UIColor orangeColor] : [UIColor whiteColor];
		
		self.separatorLineView.hidden = queueViewAttributes.isOnlyItem || queueViewAttributes.isLastRow;
		self.separatorLineView.frame = lineFrame;
		
		self.hidden = queueViewAttributes.hidePlease;
	}
}

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
