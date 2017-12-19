//
//  LMWarningBarView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMWarningBarView.h"
#import "MarqueeLabel.h"
#import "LMColour.h"

@interface LMWarningBarView()

/**
 The warning that is currently being displayed.
 */
@property LMWarning *displayingWarning;

/**
 The warning which the label goes on.
 */
@property MarqueeLabel *label;

@end

@implementation LMWarningBarView

- (CGFloat)recommendedFontSize {
	if(!self.displayingWarning){
		return 0.0f;
	}
	switch(self.displayingWarning.priority){
		case LMWarningPriorityLow:
		case LMWarningPriorityHigh:
			return 16.0f;
		case LMWarningPrioritySevere:
			return 40.0f;
	}
}

- (UIFont*)recommendedFont {
	return [UIFont fontWithName:@"HelveticaNeue-Light" size:[self recommendedFontSize]];
}

- (LMColour*)recommendedTextColour {
	if(!self.displayingWarning || (self.displayingWarning.priority == LMWarningPriorityLow)){
		return [LMColour blackColour];
	}
	
	return [LMColour whiteColour];
}

- (void)setWarning:(LMWarning*)warning {
	self.displayingWarning = warning;
	
	self.backgroundColor = warning.colour;
	self.label.font = [self recommendedFont];
	self.label.textColor = [self recommendedTextColour];
	self.label.text = self.displayingWarning ? self.displayingWarning.text : @"";
	
	NSLayoutConstraint *heightConstraint = nil;
	for(NSLayoutConstraint *constraint in self.constraints){
		if(constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeHeight){
			heightConstraint = constraint;
			break;
		}
	}
	
	CGFloat warningHeight = warning ? 34.0f : 0.0f;
	if(warning.priority == LMWarningPrioritySevere){
		warningHeight = 70.0f;
	}
	
	[self.superview layoutIfNeeded];
	
	heightConstraint.constant = warningHeight;
	
	[UIView animateWithDuration:0.4 animations:^{
		[self.superview layoutIfNeeded];
	}];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		if(self.displayingWarning){
			self.backgroundColor = self.displayingWarning.colour;
		}
		
		self.label = [MarqueeLabel newAutoLayoutView];
		self.label.fadeLength = 10;
		self.label.leadingBuffer = 10;
		self.label.trailingBuffer = 10;
		self.label.font = [self recommendedFont];
		self.label.text = self.displayingWarning ? self.displayingWarning.text : @"";
		self.label.textAlignment = NSTextAlignmentCenter;
		self.label.textColor = [self recommendedTextColour];
		self.label.labelize = NO;
		[self addSubview:self.label];

		[self.label autoPinEdgesToSuperviewEdges];
	}
}

@end
