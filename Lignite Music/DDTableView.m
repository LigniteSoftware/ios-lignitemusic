
//  DDTableView.m
//  ReorderTest
//
//  Created by Edwin Finch on 10/13/17.
//  Copyright © 2017 Techno-Magic. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DDTableView.h"

@interface DDTableView()<UIGestureRecognizerDelegate>

@property UILongPressGestureRecognizer *longPressGestureRecognizer;
@property NSIndexPath *initialIndexPath;
@property NSIndexPath *currentLocationIndexPath;
@property UIView *draggingView;
@property CGFloat scrollRate;
@property CADisplayLink *scrollDisplayLink;
@property id feedbackGenerator;
@property CGFloat previousGestureVerticalPosition;
@property CFTimeInterval minimumPressDuration;

@end

@implementation DDTableView

@synthesize longPressReorderEnabled = _longPressReorderEnabled;
@synthesize minimumPressDuration = _minimumPressDuration;

/* Begin synthesized variables. */

- (BOOL)longPressReorderEnabled {
	return self.longPressGestureRecognizer.enabled;
}

- (void)setLongPressReorderEnabled:(BOOL)longPressReorderEnabled {
	self.longPressGestureRecognizer.enabled = longPressReorderEnabled;
}

- (CFTimeInterval)minimumPressDuration {
	return self.longPressGestureRecognizer.minimumPressDuration;
}

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration {
	self.longPressGestureRecognizer.minimumPressDuration = minimumPressDuration;
}

/* End synthesized variables. */

/* Begin initialization overrides. */

- (instancetype)init {
	self = [super init];
	
	self.frame = CGRectZero;
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	self = [super initWithFrame:frame style:style];
	
	[self initialize];
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	[self initialize];
	
	return self;
}


- (void)initialize {
	self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(_longPress:)];
	[self addGestureRecognizer:self.longPressGestureRecognizer];
	
	self.userInteractionEnabled = YES;
	
	self.estimatedRowHeight = 0;
	self.estimatedSectionHeaderHeight = 0;
	self.estimatedSectionFooterHeight = 0;
	
	NSLog(@"Initialized gesture: %d", self.longPressReorderEnabled);
}

/* End initialization overrides. */

/* Begin gesture recognizer code. */

- (BOOL)canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	return [self.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)] ? [self.dataSource tableView:self canMoveRowAtIndexPath:indexPath] : YES;
}

- (void)cancelGesture {
	self.longPressGestureRecognizer.enabled = NO;
	self.longPressGestureRecognizer.enabled = YES;
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//	return YES;
//}

- (void)_longPress:(UILongPressGestureRecognizer*)gesture {
	CGPoint location = [gesture locationInView:self];
	NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
	
	NSInteger sections = [self numberOfSections];
	NSInteger rows = 0;
	for(NSInteger i = 0; i < sections; i++){
		rows += [self numberOfRowsInSection:i];
	}
	
	
	// Get out of here if the long press was not on a valid row or our table is empty
	// or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row.
	if((rows == 0) ||
		((gesture.state == UIGestureRecognizerStateBegan) && (indexPath == nil)) ||
		((gesture.state == UIGestureRecognizerStateEnded) && (self.currentLocationIndexPath == nil)) ||
		((gesture.state == UIGestureRecognizerStateBegan) && ![self canMoveRowAtIndexPath:indexPath])) {
	
		[self cancelGesture];
	}
	
	// Started.
	if(gesture.state == UIGestureRecognizerStateBegan){
		[self hapticFeedbackSetup];
		[self hapticFeedbackSelectionChanged];
		self.previousGestureVerticalPosition = location.y;
		
		if(indexPath){
			UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
			if(cell){
				[cell setSelected:NO animated:NO];
				[cell setHighlighted:NO animated:NO];
				
				// Create the view that will be dragged around the screen.
				if(self.draggingView == nil) {
					if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:draggingCell:atIndexPath:)]){
						cell = [self.longPressReorderDelegate tableView:self draggingCell:cell atIndexPath:indexPath];
					}
					
					// Make an image from the pressed table view cell.
					UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0.0);
					[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
					UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					
					self.draggingView = [[UIImageView alloc]initWithImage:cellImage];
					if(self.draggingView){
						[self addSubview:self.draggingView];
						CGRect rect = [self rectForRowAtIndexPath:indexPath];
//						self.draggingView.frame = CGRectOffset(rect, rect.origin.x, rect.origin.y);
						self.draggingView.frame = rect;
						
						[UIView beginAnimations:@"LongPressReorder-ShowDraggingView" context:nil];
						if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:showDraggingView:atIndexPath:)]){
							[self.longPressReorderDelegate tableView:self showDraggingView:self.draggingView atIndexPath:indexPath];
						}
						[UIView commitAnimations];
						
						// Add drop shadow to image and lower opacity.
						self.draggingView.layer.masksToBounds = NO;
						self.draggingView.layer.shadowColor = [UIColor blackColor].CGColor;
						self.draggingView.layer.shadowOffset = CGSizeZero;
						self.draggingView.layer.shadowRadius = 4.0;
						self.draggingView.layer.shadowOpacity = 0.7;
						self.draggingView.layer.opacity = 0.85;
						
						// Zoom image towards user.
						[UIView beginAnimations:@"LongPressReorder-Zoom" context:nil];
						self.draggingView.transform = CGAffineTransformMakeScale(1.1, 1.1);
						self.draggingView.center = CGPointMake(self.center.x, [self newYCenterForDraggingView:self.draggingView withLocation:location]);
						[UIView commitAnimations];
					}
				}
				
				cell.hidden = YES;
				self.currentLocationIndexPath = indexPath;
				self.initialIndexPath = indexPath;
				
				// Enable scrolling for cell.
				self.scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_scrollTableWithCell:)];
				[self.scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
			}
		}
	}
	else if(gesture.state == UIGestureRecognizerStateChanged){
		if(self.draggingView){
			if(self.visibleCells.count < 1){
				return;
			}
			self.draggingView.center = CGPointMake([self.visibleCells objectAtIndex:0].center.x, [self newYCenterForDraggingView:self.draggingView withLocation:location]);
			NSLog(@"Center %@", NSStringFromCGPoint(self.draggingView.center));
			if(location.y != self.previousGestureVerticalPosition){
				if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:draggingGestureChanged:)]){
					[self.longPressReorderDelegate tableView:self draggingGestureChanged:gesture];
				}
				self.previousGestureVerticalPosition = location.y;
			}
			
			//Lost in translation part about setting it anyway even if it wasn't set in the past?
//			if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:draggingGestureChanged:)]){
//				[self.longPressReorderDelegate tableView:self draggingGestureChanged:gesture];
//			}
//			self.previousGestureVerticalPosition = location.y;
		}
		
		UIEdgeInsets inset = self.contentInset;
		if(@available(iOS 11, *)){
			inset = self.adjustedContentInset;
		}
		
		CGRect rect = self.bounds;
		// Adjust rect for content inset, as we will use it below for calculating scroll zones.
		rect.size.height -= inset.top;
		
		[self updateCurrentLocationForGesture:gesture];
		
		// Tell us if we should scroll, and in which direction.
		CGFloat scrollZoneHeight = rect.size.height / 6.0;
		CGFloat bottomScrollBeginning = self.contentOffset.y + inset.top + rect.size.height - scrollZoneHeight;
		CGFloat topScrollBeginning = self.contentOffset.y + inset.top  + scrollZoneHeight;
		
		// We're in the bottom zone.
		if(location.y >= bottomScrollBeginning){
			self.scrollRate = (double)(location.y - bottomScrollBeginning) / (double)(scrollZoneHeight);
		}
		// We're in the top zone.
		else if(location.y <= topScrollBeginning){
			self.scrollRate = (double)(location.y - topScrollBeginning) / (double)(scrollZoneHeight);
		}
		else{
			self.scrollRate = 0.0;
		}
	}
	else if((gesture.state == UIGestureRecognizerStateEnded)
			|| (gesture.state == UIGestureRecognizerStateCancelled)
			|| (gesture.state == UIGestureRecognizerStateFailed)){
		
		// Clear previously cached gesture location.
		self.previousGestureVerticalPosition = -1;
		
		// Remove scrolling CADisplayLink.
		if(self.scrollDisplayLink){
			[self.scrollDisplayLink invalidate];
			self.scrollDisplayLink = nil;
			self.scrollRate = 0.0f;
		}
		
		// Animate the drag view to the newly hovered cell.
		[UIView animateWithDuration:0.3 animations:^{
			if(self.draggingView && self.currentLocationIndexPath){
				[UIView beginAnimations:@"LongPressReorder-HideDraggingView" context:nil];
				if([self.longPressReorderDelegate respondsToSelector:@selector(tableView:hideDraggingView:atIndexPath:)]){
					[self.longPressReorderDelegate tableView:self hideDraggingView:self.draggingView atIndexPath:self.currentLocationIndexPath];
				}
				[UIView commitAnimations];
				
				CGRect rect = [self rectForRowAtIndexPath:self.currentLocationIndexPath];
				self.draggingView.transform = CGAffineTransformIdentity;
				self.draggingView.frame = CGRectOffset(self.draggingView.bounds, rect.origin.x, rect.origin.y);
				
				NSLog(@"Center end %@", NSStringFromCGPoint(self.draggingView.center));
			}
		} completion:^(BOOL finished) {
			if(self.draggingView){
				[self.draggingView removeFromSuperview];
			}
			
			// Reload the rows that were affected just to be safe.
			if(self.indexPathsForVisibleRows){
				[self reloadRowsAtIndexPaths:self.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
			}
			
			self.currentLocationIndexPath = nil;
			self.draggingView = nil;
			
			[self hapticFeedbackSelectionChanged];
			[self hapticFeedbackFinalize];
		}];
	}
}

- (void)updateCurrentLocationForGesture:(UILongPressGestureRecognizer*)gesture {
	CGPoint location = [gesture locationInView:self];
	NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
	
	if(self.initialIndexPath){
		if([self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]){
			indexPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:self.initialIndexPath toProposedIndexPath:indexPath];
		}
	}
	
	NSIndexPath *currentLocationIndexPath = self.currentLocationIndexPath;
	CGFloat oldHeight = [self rectForRowAtIndexPath:currentLocationIndexPath].size.height;
	CGFloat newHeight = [self rectForRowAtIndexPath:indexPath].size.height;
	
	UITableViewCell *cell = [self cellForRowAtIndexPath:currentLocationIndexPath];
	if(cell){
		[cell setSelected:NO animated:NO];
		[cell setHighlighted:NO animated:NO];
		cell.hidden = YES;
	}
	
	if((![indexPath isEqual:currentLocationIndexPath])
	   && ([gesture locationInView:[self cellForRowAtIndexPath:indexPath]].y > (newHeight - oldHeight))
	   && [self canMoveRowAtIndexPath:indexPath]){
		
		[self beginUpdates];
		[self moveRowAtIndexPath:currentLocationIndexPath toIndexPath:indexPath];
		[self moveRowAtIndexPath:indexPath toIndexPath:currentLocationIndexPath];
		if([self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
			[self.dataSource tableView:self moveRowAtIndexPath:currentLocationIndexPath toIndexPath:indexPath];
			[self.dataSource tableView:self moveRowAtIndexPath:indexPath toIndexPath:currentLocationIndexPath];
		}
		self.currentLocationIndexPath = indexPath;
		[self endUpdates];
		
		[self hapticFeedbackSelectionChanged];
	}
}

- (void)_scrollTableWithCell:(CADisplayLink*)sender {
	UILongPressGestureRecognizer *gesture = self.longPressGestureRecognizer;
	if(!gesture){
		return;
	}
	
	CGPoint location = [gesture locationInView:self];
	if(isnan(location.x) || isnan(location.y)){ // Explicitly check for out-of-bound touch.
		return;
	}
	
	CGFloat yOffset = self.contentOffset.y + (self.scrollRate * 10.0);
	CGPoint newOffset = CGPointMake(self.contentOffset.x, yOffset);
	
	UIEdgeInsets inset = self.contentInset;
	if(@available(iOS 11, *)){
		inset = self.adjustedContentInset;
	}
	
	if(newOffset.y < -inset.top){
		newOffset.y = -inset.top;
	}
	else if((self.contentSize.height + inset.bottom) < self.frame.size.height){
		newOffset = self.contentOffset;
	}
	else if(newOffset.y > ((self.contentSize.height + inset.bottom) - self.frame.size.height)){
		newOffset.y = (self.contentSize.height + inset.bottom) - self.frame.size.height;
	}
	
//	NSLog(@"Setting offset to %@", NSStringFromCGPoint(newOffset));
	
	self.contentOffset = newOffset;
	
	if(self.draggingView){
		if(self.visibleCells.count > 0){
			self.draggingView.center = CGPointMake([self.visibleCells objectAtIndex:0].center.x, [self newYCenterForDraggingView:self.draggingView withLocation:location]);
		}
	}
	
	[self updateCurrentLocationForGesture:gesture];
}

- (CGFloat)newYCenterForDraggingView:(UIView*)draggingView withLocation:(CGPoint)location {
	CGFloat cellCenter = draggingView.frame.size.height / 2.0;
	CGFloat bottomBound = self.contentSize.height - cellCenter;
	
	if(location.y < cellCenter){
		NSLog(@"Cell center");
		return cellCenter;
	}
	else if(location.y > bottomBound){
		NSLog(@"Bottom bound");
		return bottomBound;
	}
	
//	NSLog(@"Y loc");
	return location.y;
}

/* End gesture recognizer code. */

/* Begin haptics code. */

- (void)hapticFeedbackSetup {
	if(@available(iOS 10, *)){
		UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
		[feedbackGenerator prepare];
		
		self.feedbackGenerator = feedbackGenerator;
	}
}

- (void)hapticFeedbackSelectionChanged {
	if(@available(iOS 10, *)){
		if(self.feedbackGenerator){
			UISelectionFeedbackGenerator *feedbackGenerator = self.feedbackGenerator;
			[feedbackGenerator selectionChanged];
			[feedbackGenerator prepare];
		}
	}
}

- (void)hapticFeedbackFinalize {
	if(@available(iOS 10, *)){
		self.feedbackGenerator = nil;
	}
}

/* End haptics code. */



@end
