//
//  LMAdaptiveScrollView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAdaptiveScrollView.h"
#import "LMExtras.h"

@interface LMAdaptiveScrollView () <UIScrollViewDelegate>

@property NSMutableArray *loadedSubviewArray;
@property float calculatedFactorial;

@end


@implementation LMAdaptiveScrollView


/**
 Gets the height factorial relative to the window for the scroll view.

 @return The height factorial.
 */
- (float)heightFactorialRelativeToWindow {
	float window_height_factorial = [self.subviewDelegate sizingFactorialRelativeToWindowForAdaptiveScrollView:self height:YES];
	float height_factorial = ((WINDOW_FRAME.size.height/self.frame.size.height)*window_height_factorial);
	
	return height_factorial;
}


/**
 Reloads the content size based on the index provided to it, usually being the highest index.

 @param index The index to base its content size off of.
 */
- (void)reloadContentSizeWithIndex:(NSUInteger)index {
	float height_factorial = self.calculatedFactorial;
	float top_spacing = [self.subviewDelegate topSpacingForAdaptiveScrollView:self];
	
	CGSize newContentSize = CGSizeMake(self.frame.size.width,
									   self.frame.size.height
									   *(height_factorial+(height_factorial/4))*(index+1)+top_spacing);
	[self setContentSize:newContentSize];
}


/**
 Prepares a subview internally with its required constraints to fit inside of the adaptive scroll view.

 @param rawSubview The subview to prepare.
 @param index      The index of that subview within the scroll view.
 */
- (void)prepareSubview:(id)rawSubview forIndex:(NSUInteger)index {
	//We need to tell the delegate whether or not this subview has been loaded before so it can determine
	//whether or not to load its constraints since they are never retracted.
	if(!self.loadedSubviewArray){
		self.loadedSubviewArray = [NSMutableArray new];
		for(int i = 0; i < self.subviewArray.count; i++){
			[self.loadedSubviewArray addObject:@(0)];
		}
	}
	BOOL alreadyLoadedSubview = [[self.loadedSubviewArray objectAtIndex:index] isEqual:@(1)];
	
	UIView *subview = (UIView*)rawSubview;
	subview.hidden = NO;
	if(!alreadyLoadedSubview){
		[self.loadedSubviewArray setObject:@(1) atIndexedSubscript:index];
		
		float height_factorial = self.calculatedFactorial;
		float top_spacing = [self.subviewDelegate topSpacingForAdaptiveScrollView:self];
		
		subview.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self addSubview:subview];
		
		[subview autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
		
		[subview autoPinEdge:ALEdgeTop toEdge:ALEdgeTop
					  ofView:self
				  withOffset:self.frame.size.height*(height_factorial+(height_factorial/4))*index+top_spacing];
		
		[subview autoMatchDimension:ALDimensionWidth
						toDimension:ALDimensionWidth
							 ofView:self
					 withMultiplier:[self.subviewDelegate sizingFactorialRelativeToWindowForAdaptiveScrollView:self height:NO]];
		
		[subview autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:height_factorial];
		
		if([self.subviewDelegate dividerForAdaptiveScrollView:self] && (index != self.subviewArray.count-1)){
			UIView *dividerView = [UIView new];
			dividerView.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
			dividerView.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:dividerView];
			
			uint8_t dividerHeight = 1;
			
			[dividerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom
							  ofView:subview
						  withOffset:((self.frame.size.height*(height_factorial/4))/2)-(dividerHeight/2)];
			
			[dividerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:subview];
			[self addConstraint:[NSLayoutConstraint constraintWithItem:dividerView
															 attribute:NSLayoutAttributeHeight
															 relatedBy:NSLayoutRelationEqual
																toItem:subview
															 attribute:NSLayoutAttributeHeight
															multiplier:0.0
															  constant:dividerHeight]];
			[dividerView autoAlignAxis:ALAxisVertical toSameAxisOfView:subview];
		}
	}
	
	NSLog(@"Sending to delegate (%lu)", (unsigned long)index);
	
	//Let the delegate know that internally the subview is prepared and let it handle the rest of the process.
	[self.subviewDelegate prepareSubview:rawSubview forIndex:index subviewPreviouslyLoaded:alreadyLoadedSubview];
}

/**
 Reloads the subviews which are displayed on the screen.
 
 The amount of items that will be displayed are the amount of items which will fit within the visible frame plus a couple extra to ensure the user does not see the views being hidden.
 */
- (void)reloadSubviews {
	//The visible frame is what's visible on the screen of the UIScrollView. Its height is the same as the total height for the UIScrollView.
	CGRect visibleFrame = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.contentOffset.x + self.bounds.size.width, self.bounds.size.height);
	
	int amountOfItems = 0;
	//Calculate the total amount of space that has been viewed and is being viewed.
	float totalSpace = (visibleFrame.origin.y + visibleFrame.size.height);
	float heightFactorial = self.calculatedFactorial;
	//Calculate the amount of items that are in frame and above it (scrolled past) by subtracting each from the total space.
	while(totalSpace > 0){
		totalSpace -= (self.frame.size.height*(heightFactorial+(heightFactorial/4)));
		amountOfItems++;
	}
	
	//The amount of items that are drawn should be equal to the amount that are available to be seen on the screen plus two to ensure that the user does not see the items being hidden.
	uint8_t totalAmountOfItemsToDraw = (self.bounds.size.height/(self.frame.size.height*heightFactorial))+2;
	
	int8_t itemsDrawn = 0;
	//Determines whether or not an item is in view, and if it is, adds it to the root UIScrollView if it is not already there.
	while(itemsDrawn < totalAmountOfItemsToDraw && amountOfItems > 0){
		int itemToDraw = (amountOfItems-itemsDrawn)-1;
		if(itemToDraw < 0 || itemToDraw >= self.subviewArray.count){
			itemsDrawn = totalAmountOfItemsToDraw;
			break;
		}
		UIView *item = [self.subviewArray objectAtIndex:itemToDraw];
		if(item.hidden){
			if(self.subviewDelegate){
				[self prepareSubview:item forIndex:itemToDraw];
			}
		}
		itemsDrawn++;
	}
	
	int amountOfItemsAbove = (amountOfItems-itemsDrawn)-1;
	//Based on the amount of items above the current frame (scrolled past), remove all of those items from their superviews.
	while(amountOfItemsAbove > 0){
		UIView *item = [self.subviewArray objectAtIndex:amountOfItemsAbove-1];
		if(!item.hidden){
			item.hidden = YES;
		}
		amountOfItemsAbove--;
	}
	
	int amountOfItemsBelow = ((int)self.subviewArray.count-amountOfItems);
	//Based on the amount of items below the current frame (not yet scrolled past), remove all of those items from their superviews.
	while(amountOfItemsBelow > 0){
		UIView *item = [self.subviewArray objectAtIndex:amountOfItems+amountOfItemsBelow-1];
		if(!item.hidden){
			item.hidden = YES;
		}
		amountOfItemsBelow--;
	}
}


/**
 When the UIScrollView updates, this is called.
 
 @param scrollView The UIScrollView which updated.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	//NSLog(@"Hey");
	[self reloadSubviews];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	//NSLog(@"Done");
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.delegate = self;
	
	if(self.frame.size.height > 0){
		self.calculatedFactorial = [self heightFactorialRelativeToWindow];
		[self reloadContentSizeWithIndex:self.subviewArray.count-1];
	}
	
	if(!self.loadedSubviewArray){
		for(int i = 0; i < self.subviewArray.count; i++){
			[self prepareSubview:[self.subviewArray objectAtIndex:i] forIndex:i];
		}
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//	[super drawRect:rect];
//}

@end
