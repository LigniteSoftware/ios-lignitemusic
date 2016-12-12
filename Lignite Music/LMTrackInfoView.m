//
//  LMTrackInfoView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTrackInfoView.h"

@interface LMTrackInfoView()

@end

@implementation LMTrackInfoView

- (void)layoutSubviews {
//	self.backgroundColor = [UIColor yellowColor];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.titleLabel = [MarqueeLabel newAutoLayoutView];
		self.artistLabel = [MarqueeLabel newAutoLayoutView];
		self.albumLabel = [MarqueeLabel newAutoLayoutView];
		
	//	self.titleLabel.layoutMargins = UIEdgeInsetsMake(0, -4, 0, -4);
		
		CGFloat heightMultipliers[] = {
			(1.0/2.0), (1.0/4.0), (1.0/5.0)
		};
		NSArray *labels = @[
			self.titleLabel, self.artistLabel, self.albumLabel
		];
		
		for(int i = 0; i < labels.count; i++){
			BOOL isFirst = (i == 0);
			
			MarqueeLabel *label = [labels objectAtIndex:i];
			MarqueeLabel *previousLabel = isFirst ? [labels objectAtIndex:0] : [labels objectAtIndex:i-1];
			
			label.fadeLength = 10;
			label.leadingBuffer = 6;
			label.trailingBuffer = label.leadingBuffer;
			
//			label.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
			label.font = [LMMarqueeLabel fontToFitHeight:self.frame.size.height*heightMultipliers[i]];
			label.text = [NSString stringWithFormat:@"Hey %d", i];
			label.textAlignment = self.textAlignment;
			NSLog(@"%@ insets", NSStringFromUIEdgeInsets(label.layoutMargins));
			[self addSubview:label];
			
			[label autoPinEdge:ALEdgeTop toEdge:isFirst ? ALEdgeTop : ALEdgeBottom ofView:isFirst ? self : previousLabel withOffset:isFirst ? -label.layoutMargins.top : 0];
			[label autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
			[label autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
			[label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
			[label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
		}
	}
		
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
