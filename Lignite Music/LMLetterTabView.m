//
//  LMLetterTabView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLetterTabView.h"
#import "LMLabel.h"
#import "LMScrollView.h"

@interface LMLetterTabView()

/**
 The scroll view for the letter views.
 */
@property LMScrollView *letterScrollView;

/**
 The array of letter views.
 */
@property NSMutableArray *letterViewsArray;

@end

@implementation LMLetterTabView

- (void)layoutSubviews {
	NSLog(@"AIJShdkjandf");
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor cyanColor];
		
		NSMutableArray *testArray = [NSMutableArray new];
		
		NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		for(int i = 0; i < letters.length; i++){
			NSString *letter = [NSString stringWithFormat: @"%C", [letters characterAtIndex:i]];
			[testArray addObject:letter];
		}
		
		self.lettersArray = [NSArray arrayWithArray:testArray];
		
		self.letterViewsArray = [NSMutableArray new];
		
		self.letterScrollView = [LMScrollView newAutoLayoutView];
		self.letterScrollView.adaptForWidth = YES;
		self.letterScrollView.backgroundColor = [UIColor orangeColor];
		[self addSubview:self.letterScrollView];
		
		[self.letterScrollView autoPinEdgesToSuperviewEdges];
		
		for(int i = 0; i < self.lettersArray.count; i++){
			BOOL firstIndex = (i == 0);
			
			NSString *letter = [self.lettersArray objectAtIndex:i];
			
			UIView *viewToAttachTo = firstIndex ? self.letterScrollView : [self.letterViewsArray objectAtIndex:i-1];
			
			UILabel *letterLabel = [UILabel newAutoLayoutView];
			letterLabel.text = letter;
			letterLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.frame.size.width*0.05];
			letterLabel.textColor = [UIColor blackColor];
			letterLabel.textAlignment = NSTextAlignmentCenter;
			letterLabel.backgroundColor = [UIColor yellowColor];
			[self.letterScrollView addSubview:letterLabel];
			
			[letterLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[letterLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			[letterLabel autoPinEdge:ALEdgeLeading toEdge:firstIndex ? ALEdgeLeading : ALEdgeTrailing ofView:viewToAttachTo withOffset:self.frame.size.width*0.03];
//			[letterLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.04];
			
			[self.letterViewsArray addObject:letterLabel];
		}
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
