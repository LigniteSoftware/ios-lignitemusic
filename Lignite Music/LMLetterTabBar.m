//
//  LMLetterTabView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLetterTabBar.h"
#import "LMLabel.h"
#import "LMScrollView.h"
#import "LMColour.h"
#import "NSTimer+Blocks.h"

@interface LMLetterTabBar()<UIGestureRecognizerDelegate, LMLayoutChangeDelegate, UIScrollViewDelegate>

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

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

@end

@implementation LMLetterTabBar

@synthesize lettersDictionary = _lettersDictionary;

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
		BOOL isLandscape = (size.width > size.height);
		if([LMLayoutManager isiPad]){
			isLandscape = NO;
		}
		
		for(UILabel *label in self.letterViewsArray){
			label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(isLandscape ? self.frame.size.width : self.frame.size.height
																		   )/2.25]; //.50 for W;
			self.letterScrollView.adaptForWidth = !isLandscape;
			[self.letterScrollView reload];
		}
		
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		//Nothing...
		
		[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
			BOOL isLandscape = (size.width > size.height);
			if([LMLayoutManager isiPad]){
				isLandscape = NO;
			}
			
			for(UILabel *label in self.letterViewsArray){
				label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(isLandscape ? self.frame.size.width : self.frame.size.height
																			   )/2.25]; //.50 for W;
				self.letterScrollView.adaptForWidth = !isLandscape;
				[self.letterScrollView reload];
			}
		} repeats:NO];
	}];
}

- (void)setLettersDictionary:(NSDictionary *)lettersDictionary {
	_lettersDictionary = lettersDictionary;
	
	//Reload the view's contents
	if(self.didLayoutConstraints){
		for(NSUInteger i = 0; i < self.letterViewsArray.count; i++){
			LMView *letterView = [self.letterViewsArray objectAtIndex:i];
			
			[LMLayoutManager removeAllConstraintsRelatedToView:letterView];
			
			letterView.hidden = YES;
			[letterView removeFromSuperview];
		}
		
		self.letterScrollView.hidden = YES;
		[self.letterScrollView removeFromSuperview];
		
		self.didLayoutConstraints = NO;
		
		[self layoutSubviews];
	}
}

- (NSDictionary*)lettersDictionary {
//	NSMutableDictionary *fixedLettersDictionary = [NSMutableDictionary new];
//	NSString *lettersinset = @"#?ABCDEFGHIJKLMNOPQRSTUVWXYZ";
//	for(int i = 0; i < lettersinset.length; i++){
//		NSString *letter = [NSString stringWithFormat: @"%C", [lettersinset characterAtIndex:i]];
//		[fixedLettersDictionary setObject:@(i) forKey:letter];
//	}
//	
//	return fixedLettersDictionary;
	
	return _lettersDictionary;
}

/**
 Alerts the delegate of a new letter change, should one have occurred.

 @param newLetter The new letter selected.
 @return Whether or not the new letter was actually new or if it was the same as previous. NO if the latter.
 */
- (BOOL)alertDelegateOfNewLetter:(NSString*)newLetter {
	BOOL isNewLetter = ![newLetter isEqualToString:self.previousLetter];
	
	if(isNewLetter){
		[self.delegate letterSelected:newLetter atIndex:[[self.lettersDictionary objectForKey:newLetter] unsignedIntegerValue]];
	}
	
	self.previousLetter = newLetter;
	
	return isNewLetter;
}

- (void)setLetterLabelLifted:(UILabel*)letterLabel withAnimationStyle:(LMLetterTabLiftAnimationStyle)animationStyle {
//	if([LMLayoutManager isiPad]){
//		return;
//	}
	
	NSLayoutConstraint *centerYConstraint = nil;
	
	for(NSLayoutConstraint *constraint in self.letterScrollView.constraints){
		BOOL isProperConstraint = self.layoutManager.isLandscape ?
			constraint.firstAttribute == NSLayoutAttributeCenterX && constraint.firstItem == letterLabel
			: constraint.firstAttribute == NSLayoutAttributeCenterY && constraint.firstItem == letterLabel;
		
		if(isProperConstraint){
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
			[NSTimer scheduledTimerWithTimeInterval:0.1 block:^() {
				[self setLetterLabelLifted:letterLabel withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
			} repeats:NO];
		}
	}];
	
	NSLog(@"Lifting %@", letterLabel.text);
	
	self.currentLetterLabelLifted = letterLabel;
}

- (void)resetContentOffsetIfNeeded {
	if(self.layoutManager.isLandscape){
		if(self.letterScrollView.contentOffset.y < 0){
			[self.letterScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
		}
		else if(self.letterScrollView.contentOffset.y > self.letterScrollView.contentSize.height-self.letterScrollView.frame.size.height){
			[self.letterScrollView setContentOffset:CGPointMake(0, self.letterScrollView.contentSize.height-self.letterScrollView.frame.size.height) animated:YES];
		}
	}
	else{
		if(self.letterScrollView.contentOffset.x < 0){
			[self.letterScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
		}
		else if(self.letterScrollView.contentOffset.x > self.letterScrollView.contentSize.width-self.letterScrollView.frame.size.width){
			[self.letterScrollView setContentOffset:CGPointMake(self.letterScrollView.contentSize.width-self.letterScrollView.frame.size.width, 0) animated:YES];
		}
	}
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
			UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer*)panGestureRecognizer;
			CGPoint translation = [recognizer translationInView:recognizer.view];
			if(translation.y > self.frame.size.height*2){
				[self.delegate swipeDownGestureOccurredOnLetterTabBar];
			}
			return;
		}
		
		if(panGestureRecognizer.state != UIGestureRecognizerStateEnded){
			CGPoint pointInLetterScrollView = [panGestureRecognizer locationInView:self.letterScrollView];
			CGPoint pointInView = [panGestureRecognizer locationInView:self];
			
			float xPointInLetterScrollView = self.layoutManager.isLandscape ? pointInLetterScrollView.y : pointInLetterScrollView.x;
			float xPointInView = self.layoutManager.isLandscape ? pointInView.y : pointInView.x;
			
			for(LMView *subview in self.letterScrollView.subviews) {
				if(![[[subview class] description] isEqualToString:@"UILabel"]){ //Idk how the fuck a UIImageView has snuck into our scroll view though I don't got the time to fix it so this quick patch does the job
					break;
				}
				
				CGFloat xPointOfSubview = self.layoutManager.isLandscape ? subview.frame.origin.y : subview.frame.origin.x;
				CGFloat widthOfSubview = self.layoutManager.isLandscape ? subview.frame.size.height : subview.frame.size.width;
				
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
			
			CGFloat factor = (self.layoutManager.isLandscape ? self.frame.size.height : self.frame.size.width)/10;
			CGFloat rightFactor = factor * 9;
			
			CGPoint contentOffset = self.letterScrollView.contentOffset;
			
			if(xPointInView > rightFactor) {
				CGPoint newContentOffset = self.layoutManager.isLandscape ? CGPointMake(contentOffset.x, contentOffset.y + xPointInView - rightFactor)
											: CGPointMake(contentOffset.x + xPointInView - rightFactor, contentOffset.y);
				
				CGFloat adjustedWidth = self.layoutManager.isLandscape ? self.letterScrollView.contentSize.height-self.frame.size.height : self.letterScrollView.contentSize.width-self.frame.size.width;
				
				if((self.layoutManager.isLandscape ? newContentOffset.y : newContentOffset.x) < (adjustedWidth)){
					[self.letterScrollView setContentOffset:newContentOffset animated:NO];
				}
			}
			else if(xPointInView < factor){
				CGPoint newContentOffset = self.layoutManager.isLandscape ? CGPointMake(contentOffset.x, contentOffset.y + xPointInView - factor)
											: CGPointMake(contentOffset.x - factor - xPointInView, contentOffset.y);
				
				if((self.layoutManager.isLandscape ? newContentOffset.y : newContentOffset.x) >= 0){
					[self.letterScrollView setContentOffset:newContentOffset animated:NO];
				}
			}
		}
		else{
			if(self.currentLetterLabelLifted){
				[self setLetterLabelLifted:self.currentLetterLabelLifted withAnimationStyle:LMLetterTabLiftAnimationStyleNoLift];
			}
			
			[self resetContentOffsetIfNeeded];
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
			
			[self resetContentOffsetIfNeeded];
			break;
			
		default: break;
	}
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
		self.didLayoutConstraints = YES;
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
		
		self.layer.masksToBounds = NO;
		self.clipsToBounds = [LMLayoutManager isiPad];
		
		self.backgroundColor = [UIColor whiteColor];
		
//		self.lettersArray = [NSArray arrayWithArray:testArray];
		
		self.letterViewsArray = [NSMutableArray new];
		
		self.letterScrollView = [LMScrollView newAutoLayoutView];
		self.letterScrollView.adaptForWidth = !self.layoutManager.isLandscape;
//		self.letterScrollView.backgroundColor = [UIColor purpleColor];
		self.letterScrollView.delegate = self;
		self.letterScrollView.scrollEnabled = YES;
		self.letterScrollView.layer.masksToBounds = NO;
		self.letterScrollView.showsHorizontalScrollIndicator = NO;
		[self addSubview:self.letterScrollView];
		
		[self.letterScrollView autoPinEdgesToSuperviewEdges];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(selectLetterGesture:)];
		panGesture.delegate = self;
		[self.letterScrollView addGestureRecognizer:panGesture];
		
		NSArray *letters = self.lettersDictionary.allKeys;
		letters = [letters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES]]];
				
		//Adjust array so question mark is at the back
		if(self.lettersDictionary && letters.count > 0){
			NSMutableArray *adjustedArray = [NSMutableArray arrayWithArray:letters];
			NSString *questionMark = [letters objectAtIndex:1];
			[adjustedArray removeObjectAtIndex:1];
			[adjustedArray insertObject:questionMark atIndex:adjustedArray.count];
			letters = [NSArray arrayWithArray:adjustedArray];
		}
		
		for(int i = 0; i < letters.count; i++){
			BOOL firstIndex = (i == 0);
			
			NSString *letter = [letters objectAtIndex:i];
			
			LMView *viewToAttachTo = firstIndex ? self.letterScrollView : [self.letterViewsArray lastObject];
			
			UILabel *letterLabel = [UILabel newAutoLayoutView];
			letterLabel.text = letter;
			letterLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(self.layoutManager.isLandscape ? self.frame.size.width : self.frame.size.height)/2.25]; //.50 for W
			letterLabel.textColor = [UIColor blackColor];
			letterLabel.textAlignment = NSTextAlignmentCenter;
			letterLabel.backgroundColor = [UIColor whiteColor];
			letterLabel.userInteractionEnabled = YES;
			letterLabel.layer.masksToBounds = YES;
			letterLabel.layer.cornerRadius = 3;
			[self.letterScrollView addSubview:letterLabel];

			NSArray *letterLabelPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[letterLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				[letterLabel autoPinEdge:ALEdgeLeading toEdge:firstIndex ? ALEdgeLeading : ALEdgeTrailing ofView:viewToAttachTo withOffset:self.frame.size.width*0.01];
				[letterLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.letterScrollView withMultiplier:0.06];
				[letterLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.letterScrollView];
			}];
			[LMLayoutManager addNewPortraitConstraints:letterLabelPortraitConstraints];
			
			NSArray *letterLabelLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
				[letterLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
				[letterLabel autoPinEdge:ALEdgeTop toEdge:firstIndex ? ALEdgeTop : ALEdgeBottom ofView:viewToAttachTo withOffset:self.frame.size.width*0.01];
				[letterLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.letterScrollView withMultiplier:0.95];
				[letterLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.letterScrollView withMultiplier:0.06];
			}];
			[LMLayoutManager addNewLandscapeConstraints:letterLabelLandscapeConstraints];
			
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
