//
//  LMTrackInfoView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMarqueeLabel.h"
#import "LMTrackInfoView.h"

@interface LMTrackInfoView()

@property MarqueeLabel *titleLabel, *artistLabel, *albumLabel;

@end

@implementation LMTrackInfoView

- (void)setupWithTextAlignment:(NSTextAlignment)textAlignment {
//	self.backgroundColor = [UIColor yellowColor];
	
	self.titleLabel = [[LMMarqueeLabel alloc]init];
	self.artistLabel = [[LMMarqueeLabel alloc]init];
	self.albumLabel = [[LMMarqueeLabel alloc]init];
	
	float heightMultipliers[] = {
		(1.0/2.0), (1.0/4.0), (1.0/5.0)
	};
	NSArray *labels = @[
		self.titleLabel, self.artistLabel, self.albumLabel
	];
	
	for(int i = 0; i < labels.count; i++){
		BOOL isFirst = (i == 0);
		
		LMMarqueeLabel *label = [labels objectAtIndex:i];
		LMMarqueeLabel *previousLabel = isFirst ? [labels objectAtIndex:0] : [labels objectAtIndex:i-1];
		
//		label.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
		label.translatesAutoresizingMaskIntoConstraints = NO;
		label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:60.0f];
		label.text = [NSString stringWithFormat:@"Hey %d", i];
		label.textAlignment = textAlignment;
		[self addSubview:label];
		
		[label autoPinEdge:ALEdgeTop toEdge:isFirst ? ALEdgeTop : ALEdgeBottom ofView:isFirst ? self : previousLabel];
		[label autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[label autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		[label autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:heightMultipliers[i]];
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
