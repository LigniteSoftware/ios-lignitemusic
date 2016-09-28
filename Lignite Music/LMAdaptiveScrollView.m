//
//  LMAdaptiveScrollView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMAdaptiveScrollView.h"

@interface LMAdaptiveScrollView () <UIScrollViewDelegate>

@property CGRect representativeFrame;

@end


@implementation LMAdaptiveScrollView

/**
 Reloads album items on the screen.
 
 Up to 4 album items are actually on the UIScrollLayer at once, the rest are removed from their superview until needed.
 */
- (void)reloadSubviews {
	//If the album item frame which dictates the general size album items should be scaled by doesn't exist, set it up.
	if(self.representativeFrame.size.width == 0){
		UIView *item = [self.subviewArray objectAtIndex:0];
		self.representativeFrame = item.frame;
	}
	
	//The visible frame is what's visible on the screen of the UIScrollView. Its height is the same as the total height for the UIScrollView.
	CGRect visibleFrame = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.contentOffset.x + self.bounds.size.width, self.bounds.size.height);
	
	int amountOfItems = 0;
	//Calculate the total amount of space that has been viewed and is being viewed.
	float totalSpace = (visibleFrame.origin.y + visibleFrame.size.height);
	//Calculate the amount of items that are in frame and above it (scrolled past) by subtracting each from the total space.
	while(totalSpace > 0){
		totalSpace -= (self.frame.size.height*(0.4+0.1));
		amountOfItems++;
	}
	
	//The amount of items that are drawn should be equal to the amount that are available to be seen on the screen plus two to ensure that the user does not see the items being hidden.
	uint8_t totalAmountOfItemsToDraw = (self.bounds.size.height/self.representativeFrame.size.height)+2;
	
	int8_t itemsDrawn = 0;
	//Determines whether or not an item is in view, and if it is, adds it to the root UIScrollView if it is not already there.
	while(itemsDrawn < totalAmountOfItemsToDraw && amountOfItems > 0){
		int itemToDraw = (amountOfItems-itemsDrawn)-1;
		if(itemToDraw < 0 || itemToDraw >= self.subviewArray.count){
			itemsDrawn = totalAmountOfItemsToDraw;
			break;
		}
		UIView *item = [self.subviewArray objectAtIndex:itemToDraw];
		if(![item isDescendantOfView:self]){
			if(self.subviewDelegate){
				[self.subviewDelegate prepareSubview:item forIndex:itemToDraw];
			}
		}
		itemsDrawn++;
	}
	
	int amountOfItemsAbove = (amountOfItems-itemsDrawn)+1;
	//Based on the amount of items above the current frame (scrolled past), remove all of those items from their superviews.
	while(amountOfItemsAbove > 0){
		UIView *item = [self.subviewArray objectAtIndex:amountOfItemsAbove-1];
		if([item isDescendantOfView:self]){
			[item removeFromSuperview];
		}
		amountOfItemsAbove--;
	}
	
	int amountOfItemsBelow = ((int)self.subviewArray.count-amountOfItems);
	//Based on the amount of items below the current frame (not yet scrolled past), remove all of those items from their superviews.
	while(amountOfItemsBelow > 0){
		UIView *item = [self.subviewArray objectAtIndex:amountOfItems+amountOfItemsBelow-1];
		if([item isDescendantOfView:self]){
			[item removeFromSuperview];
		}
		amountOfItemsBelow--;
	}
}


/**
 When the UIScrollView updates, this is called.
 
 @param scrollView The UIScrollView which updated.
 */
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	NSLog(@"Hey");
//	[self reloadSubviews];
//}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self reloadSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
