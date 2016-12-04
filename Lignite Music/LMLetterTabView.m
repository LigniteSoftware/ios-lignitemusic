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

@interface LMLetterTabView()<LMLetterTabDelegate>

/**
 The scroll view for the letter views.
 */
@property LMScrollView *letterScrollView;

/**
 The array of letter views.
 */
@property NSMutableArray *letterViewsArray;

/**
 The previous letter which was selected.
 */
@property NSString *previousLetter;

/**
 The current letter label which is lifted up for effect.
 */
@property UILabel *currentLetterLabelLifted;

/**
 The selection feedback generator for heptic feedback.
 */
@property UISelectionFeedbackGenerator *selectionFeedbackGenerator;

@end

@implementation LMLetterTabView

/**
 Alerts the delegate of a new letter change, should one have occurred.

 @param newLetter The new letter selected.
 @return Whether or not the new letter was actually new or if it was the same as previous. NO if the latter.
 */
- (BOOL)alertDelegateOfNewLetter:(NSString*)newLetter {
	BOOL isNewLetter = ![newLetter isEqualToString:self.previousLetter];
	
	if(isNewLetter){
		[self.delegate letterSelected:newLetter];
	}
	
	self.previousLetter = newLetter;
	
	return isNewLetter;
}

- (void)setLetterLabelLifted:(UILabel*)letterLabel withAnimationStyle:(LMLetterTabLiftAnimationStyle)animationStyle {
	NSLayoutConstraint *centerYConstraint = nil;
	
	for(NSLayoutConstraint *constraint in self.letterScrollView.constraints){
		if(constraint.firstAttribute == NSLayoutAttributeCenterY && constraint.firstItem == letterLabel){
			centerYConstraint = constraint;
		}
	}
	[self.letterScrollView layoutIfNeeded];
	
	centerYConstraint.constant = (animationStyle != LMLetterTabLiftAnimationStyleNoLift) ? -50 : 0;
	
	if(self.currentLetterLabelLifted && (animationStyle != LMLetterTabLiftAnimationStyleNoLift)){
		[self setLetterLabelLifted:self.currentLetterLabelLifted withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
	}
	
	[UIView animateWithDuration:0.1 animations:^{
		[self.letterScrollView layoutIfNeeded];
	} completion:^(BOOL finished) {
		if(finished && (animationStyle == LMLetterTabLiftAnimationStyleBounce)){
			[NSTimer scheduledTimerWithTimeInterval:0.1 repeats:NO block:^(NSTimer * _Nonnull timer) {
				[self setLetterLabelLifted:letterLabel withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
			}];
		}
	}];
	
	self.currentLetterLabelLifted = letterLabel;
}

- (void)pan:(UIGestureRecognizer*)panGestureRecognizer {
	BOOL isTapGesture = [[[panGestureRecognizer class] description] isEqualToString:@"UITapGestureRecognizer"];
	
	if(isTapGesture){
		self.selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
		[self.selectionFeedbackGenerator prepare];
	}
	else{
		switch(panGestureRecognizer.state){
			case UIGestureRecognizerStateBegan: {
				self.selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
				
				[self.selectionFeedbackGenerator prepare];
				break;
			}
			case UIGestureRecognizerStateFailed:
			case UIGestureRecognizerStateCancelled:
			case UIGestureRecognizerStateEnded: {
				self.selectionFeedbackGenerator = nil;
			}
			default: {
				break;
			}
		}
	}
	
	if(isTapGesture){
		UILabel *labelTapped = (UILabel*)panGestureRecognizer.view;
		NSString *letter = labelTapped.text;
		
		CGPoint point = [panGestureRecognizer locationInView:self];
		NSLog(@"%@", NSStringFromCGPoint(point));
		
		[self alertDelegateOfNewLetter:letter];
		[self setLetterLabelLifted:labelTapped withAnimationStyle:LMLetterTabLiftAnimationStyleBounce];
		
		[self.selectionFeedbackGenerator selectionChanged];
		
		self.selectionFeedbackGenerator = nil;
	}
	else{
		if(panGestureRecognizer.state != UIGestureRecognizerStateEnded){
			CGPoint pointInView = [panGestureRecognizer locationInView:self];
			
			float xPointInView = pointInView.x;
			
			for(UIView *subview in panGestureRecognizer.view.subviews) {
				CGFloat xPointOfSubview = subview.frame.origin.x;
				CGFloat widthOfSubview = subview.frame.size.width;
				
				if(xPointInView >= xPointOfSubview && xPointInView < (xPointOfSubview+widthOfSubview)){
					UILabel *label = (UILabel*)subview;
					NSString *letter = label.text;
					
					BOOL isNewLetter = [self alertDelegateOfNewLetter:letter];
					if(isNewLetter){
						[self.selectionFeedbackGenerator selectionChanged];
						[self.selectionFeedbackGenerator prepare];
						
						[self setLetterLabelLifted:label withAnimationStyle:LMLetterTabLiftAnimationStyleLiftUp];
						
						break;
					}
				}
			}
		}
		else if(self.currentLetterLabelLifted){
			[self setLetterLabelLifted:self.currentLetterLabelLifted withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
		}
	}
}

- (void)letterSelected:(NSString *)letter {
	NSLog(@"Letter selected %@", letter);
}

//- (void)longPress:(UILongPressGestureRecognizer*)longPressGesture {
//	NSLog(@"Long press %@", longPressGesture.view);
//}

- (void)layoutSubviews {
	NSLog(@"AIJShdkjandf");
	if(!self.didLayoutConstraints){
		self.delegate = self;
		
		self.didLayoutConstraints = YES;
		
		self.layer.masksToBounds = NO;
		
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
		self.letterScrollView.scrollEnabled = NO;
		self.letterScrollView.layer.masksToBounds = NO;
		[self addSubview:self.letterScrollView];
		
		[self.letterScrollView autoPinEdgesToSuperviewEdges];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
		[self.letterScrollView addGestureRecognizer:panGesture];
		
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
			letterLabel.userInteractionEnabled = YES;
			[self.letterScrollView addSubview:letterLabel];

//			[letterLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
			[self.letterScrollView addConstraint:[NSLayoutConstraint constraintWithItem:letterLabel
																			  attribute:NSLayoutAttributeCenterY
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self.letterScrollView
																			  attribute:NSLayoutAttributeCenterY
																			 multiplier:1.0
																			   constant:0]];
			[letterLabel autoPinEdge:ALEdgeLeading toEdge:firstIndex ? ALEdgeLeading : ALEdgeTrailing ofView:viewToAttachTo withOffset:self.frame.size.width*0.02];
			[letterLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.05];
			
//			UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
//			[letterLabel addGestureRecognizer:longPressGesture];
			
			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
			[letterLabel addGestureRecognizer:tapGesture];
			
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
