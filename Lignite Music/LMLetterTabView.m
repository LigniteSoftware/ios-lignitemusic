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
#import "LMColour.h"

@interface LMLetterTabView()<LMLetterTabDelegate, UIGestureRecognizerDelegate>

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

- (void)selectLetterGesture:(UIGestureRecognizer*)panGestureRecognizer {
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
		
		[self alertDelegateOfNewLetter:letter];
		[self setLetterLabelLifted:labelTapped withAnimationStyle:LMLetterTabLiftAnimationStyleBounce];
		
		[self.selectionFeedbackGenerator selectionChanged];
		
		self.selectionFeedbackGenerator = nil;
	}
	else{
		if(self.letterScrollView.scrollEnabled){
			return;
		}
		
		if(panGestureRecognizer.state != UIGestureRecognizerStateEnded){
			CGPoint pointInLetterScrollView = [panGestureRecognizer locationInView:self.letterScrollView];
			CGPoint pointInView = [panGestureRecognizer locationInView:self];
			
			float xPointInLetterScrollView = pointInLetterScrollView.x;
			float xPointInView = pointInView.x;
			
			for(UIView *subview in self.letterScrollView.subviews) {
				CGFloat xPointOfSubview = subview.frame.origin.x;
				CGFloat widthOfSubview = subview.frame.size.width;
				
				if(xPointInLetterScrollView >= xPointOfSubview && xPointInLetterScrollView < (xPointOfSubview+widthOfSubview)){
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
			
			CGFloat factor = self.frame.size.width/10;
			CGFloat rightFactor = factor * 9;
			
			CGPoint contentOffset = self.letterScrollView.contentOffset;
			
			if(xPointInView > rightFactor) {
				CGPoint newContentOffset = CGPointMake(contentOffset.x + xPointInView-rightFactor, contentOffset.y);
				
				if(newContentOffset.x < (self.letterScrollView.contentSize.width-rightFactor)){
					[self.letterScrollView setContentOffset:newContentOffset animated:NO];
				}
			}
			else if(xPointInView < factor){
				CGPoint newContentOffset = CGPointMake(contentOffset.x - (factor-xPointInView), contentOffset.y);
				
				if(newContentOffset.x >= -factor){
					[self.letterScrollView setContentOffset:newContentOffset animated:NO];
				}
			}
		}
		else if(self.currentLetterLabelLifted){
			[self setLetterLabelLifted:self.currentLetterLabelLifted withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
		}
	}
}

- (void)longPress:(UILongPressGestureRecognizer*)longPressGestureRecognizer {
	switch(longPressGestureRecognizer.state){
		case UIGestureRecognizerStateBegan:
			self.letterScrollView.scrollEnabled = NO;
			
			[self selectLetterGesture:longPressGestureRecognizer];
			
			break;
		case UIGestureRecognizerStateEnded:
			self.letterScrollView.scrollEnabled = YES;
			
			[self setLetterLabelLifted:self.currentLetterLabelLifted withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
			
			self.previousLetter = @"";
			break;
			
		default: break;
	}
}

- (void)letterSelected:(NSString *)letter {
//	NSLog(@"Letter selected %@", letter);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	
//	NSString *class = [[gestureRecognizer class] description];
//	NSString *otherClass = [[otherGestureRecognizer class] description];
//	
//	NSLog(@"%@ should work with %@?", class, otherClass);
	
	return YES;
}

- (void)layoutSubviews {
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
		self.letterScrollView.backgroundColor = [LMColour ligniteRedColour];
		self.letterScrollView.scrollEnabled = YES;
		self.letterScrollView.layer.masksToBounds = NO;
		[self addSubview:self.letterScrollView];
		
		[self.letterScrollView autoPinEdgesToSuperviewEdges];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(selectLetterGesture:)];
		panGesture.delegate = self;
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
			letterLabel.backgroundColor = [UIColor whiteColor];
			letterLabel.userInteractionEnabled = YES;
			letterLabel.layer.masksToBounds = YES;
			letterLabel.layer.cornerRadius = 3;
			[self.letterScrollView addSubview:letterLabel];

			[self.letterScrollView addConstraint:[NSLayoutConstraint constraintWithItem:letterLabel
																			  attribute:NSLayoutAttributeCenterY
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self.letterScrollView
																			  attribute:NSLayoutAttributeCenterY
																			 multiplier:1.0
																			   constant:0]];
			[letterLabel autoPinEdge:ALEdgeLeading toEdge:firstIndex ? ALEdgeLeading : ALEdgeTrailing ofView:viewToAttachTo withOffset:self.frame.size.width*0.02];
			[letterLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.05];
			
			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(selectLetterGesture:)];
			[letterLabel addGestureRecognizer:tapGesture];
			
			UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
			longPressGesture.minimumPressDuration = 0.10;
			[letterLabel addGestureRecognizer:longPressGesture];
			
			[self.letterViewsArray addObject:letterLabel];
		}
	}
}

@end
