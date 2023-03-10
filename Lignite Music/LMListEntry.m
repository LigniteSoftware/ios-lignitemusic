//
//  LMListEntry.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/29/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMListEntry.h"
#import "LMLabel.h"
#import "LMAppIcon.h"
#import "LMColour.h"
#import "LMLayoutManager.h"
#import "LMQueueViewFlowLayout.h"

@interface LMListEntry()<UIGestureRecognizerDelegate, MGSwipeTableCellDelegate>

@property UIView *iconBackgroundView;
@property UIImageView *iconView;
@property LMLabel *leftTextLabel;
@property LMLabel *titleLabel, *subtitleLabel;

@property UIView *textView;

@property BOOL imageIsInverted;

@property BOOL setupConstraints;

@property MGSwipeTableCell *tableCell;

/**
 The background view to the view that will go on the right if the delegate responds to the corresponding function.
 */
@property UIView *rightViewBackgroundView;

@end

@implementation LMListEntry

- (void)reloadContents {
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	NSString *leftText = @"";
	if([self.delegate respondsToSelector:@selector(textForListEntry:)]){
		leftText = [self.delegate textForListEntry:self];
	}
	
	self.titleLabel.text = title ? title : NSLocalizedString(@"InternalErrorOccurred_Short", nil);
	self.subtitleLabel.text = subtitle ? subtitle : @"";
	self.iconView.image = self.imageIsInverted ? [LMAppIcon invertImage:icon] : icon;
	self.leftTextLabel.text = leftText ? leftText : NSLocalizedString(@"InternalErrorOccurred_Short", nil);
	
	if([self.delegate respondsToSelector:@selector(rightViewForListEntry:)] && self.rightViewBackgroundView){
		for(UIView *subview in self.rightViewBackgroundView.subviews){
			[subview removeFromSuperview];
		}
		
		UIView *rightView = [self.delegate rightViewForListEntry:self];
		[self.rightViewBackgroundView addSubview:rightView];
		[rightView autoPinEdgesToSuperviewEdges];
	}
	
	[self setAsHighlighted:self.highlighted animated:NO];
	
	if([self swipeButtonsEnabled]){
		[self.tableCell refreshButtons:YES];
	}
}

- (void)setAsHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	self.highlighted = highlighted;
	
//	NSLog(@"List entry with collectionIndex %ld highlighted %d, image is inverted %d, invert on highlight %d", self.collectionIndex, self.highlighted, self.imageIsInverted, self.invertIconOnHighlight);
	
	[UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
		self.contentView.backgroundColor = highlighted ? [self.delegate tapColourForListEntry:self] : [UIColor clearColor];
		if(!self.keepTextColoursTheSame){
			self.titleLabel.textColor = highlighted ? [UIColor whiteColor] : [UIColor blackColor];
			self.subtitleLabel.textColor = highlighted ? [UIColor whiteColor] : [UIColor blackColor];
			self.leftTextLabel.textColor = highlighted ? [UIColor whiteColor] : [UIColor lightGrayColor];
		}
//		self.leftTextLabel.textColor = highlighted ? [UIColor whiteColor] : [UIColor blackColor];
		if(self.iconView.image && self.invertIconOnHighlight){
			if(!self.imageIsInverted && self.highlighted){
				self.iconView.image = [LMAppIcon invertImage:self.iconView.image];
				self.imageIsInverted = YES;
			}
			if(self.imageIsInverted && !self.highlighted){
				self.iconView.image = [LMAppIcon invertImage:self.iconView.image];
				self.imageIsInverted = NO;
			}
		}
	}];
}

- (void)tappedView {
	[self.delegate tappedListEntry:self];
}

#pragma mark Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point {
//	if(MGSwipeDirectionLeftToRight){
//		return NO;
//	}
	return YES;
}

- (BOOL)swipeButtonsEnabled {
	BOOL subscribedToSwipeButtonsFunction = [self.delegate respondsToSelector:@selector(swipeButtonsForListEntry:rightSide:)];
	BOOL subscribedToSwipeColoursFunction = [self.delegate respondsToSelector:@selector(swipeButtonColourForListEntry:rightSide:)];
	
	if(subscribedToSwipeButtonsFunction || subscribedToSwipeColoursFunction){
		BOOL subscribedToBothSwipeButtonDelegateFunctions = subscribedToSwipeButtonsFunction &&  subscribedToSwipeColoursFunction;
		
		NSAssert(subscribedToBothSwipeButtonDelegateFunctions, @"You cannot be subscribed to only one swipeButtons function, you must provide both, sorry.");
		
		return subscribedToBothSwipeButtonDelegateFunctions;
	}
	
	return NO;
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings*)swipeSettings expansionSettings:(MGSwipeExpansionSettings*)expansionSettings {
	
//	NSLog(@"selection style %d", (int)cell.selectionStyle);
	
//	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	BOOL isRightToLeftSwipe = (direction == MGSwipeDirectionRightToLeft);
	
	UIColor *expansionColour = nil;
	NSArray *buttons = nil;
	if([self swipeButtonsEnabled]){
		expansionColour = [self.delegate swipeButtonColourForListEntry:self rightSide:isRightToLeftSwipe];
		buttons = [self.delegate swipeButtonsForListEntry:self rightSide:isRightToLeftSwipe];
	}
	
	swipeSettings.transition = MGSwipeTransitionClipCenter;
	swipeSettings.keepButtonsSwiped = YES;
	swipeSettings.expandLastButtonBySafeAreaInsets = NO;
	swipeSettings.topMargin = 2.0f;
	swipeSettings.bottomMargin = 2.0f;

	expansionSettings.buttonIndex = 0;
	expansionSettings.threshold = 1.5;
	expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
	expansionSettings.expansionColor = expansionColour;
	expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunctionCubicOut;
	expansionSettings.fillOnTrigger = NO;
	
	
//	if(expansionColour || buttons){
//		NSLog(@"Whatagdhtt %@ %@", expansionColour, buttons);
//	}

	return buttons;
}

- (void)swipeTableCell:(MGSwipeTableCell*)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
	NSString * str;
	switch (state) {
		case MGSwipeStateNone: str = @"None"; break;
		case MGSwipeStateSwippingLeftToRight: str = @"SwippingLeftToRight"; break;
		case MGSwipeStateSwippingRightToLeft: str = @"SwippingRightToLeft"; break;
		case MGSwipeStateExpandingLeftToRight: str = @"ExpandingLeftToRight"; break;
		case MGSwipeStateExpandingRightToLeft: str = @"ExpandingRightToLeft"; break;
	}
	
	NSLog(@"Swipe state: %@ ::: Gesture: %@", str, gestureIsActive ? @"Active" : @"Ended");
}

- (void)resetSwipeButtons:(BOOL)animated {
	if(self.tableCell.swipeState != MGSwipeStateNone){
		[self.tableCell hideSwipeAnimated:animated];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	BOOL firstSection = (self.indexPath.section == 0);
	NSLayoutConstraint *constraintToUse = firstSection ? self.bottomConstraint : self.topConstraint;
	
	if(self.enforceStandardListEntryHeight){
		if(floorf(self.frame.size.height) < floorf(LMLayoutManager.standardListEntryHeight)){
			NSLog(@"Is less than (%f) standard %f", self.frame.size.height, LMLayoutManager.standardListEntryHeight);
			constraintToUse.constant = 0.0f;
		}
		else if(floorf(self.frame.size.height) > floorf(LMLayoutManager.standardListEntryHeight)){
			NSLog(@"Is more than (%f)", self.frame.size.height);
			constraintToUse.constant = (firstSection ? -1 : 1) * QUEUE_NEAR_HEADER_ENTRY_SPACING;
		}
	}
//	else{
//		if(self.enforceStandardListEntryHeight
//		   && (self.frame.size.height > LMLayoutManager.standardListEntryHeight)){
//
//			constraintToUse.constant = (firstSection ? -1 : 1) * QUEUE_NEAR_HEADER_ENTRY_SPACING;
//		}
//		else if((self.topConstraint.constant != 0)
//				&& self.enforceStandardListEntryHeight
//				&& ((self.frame.size.height + fabs(constraintToUse.constant)) < LMLayoutManager.standardListEntryHeight)){
//
//			constraintToUse.constant = 0.0f;
//		}
//	}
	
	
	if(self.setupConstraints){
		return;
	}
	
	MGSwipeTableCell *cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle
													  reuseIdentifier:[NSString stringWithFormat:@"test%d", rand()]];
	
	cell.backgroundColor = [UIColor clearColor];
	cell.delegate = self; //Optional, apparently
	cell.clipsToBounds = YES;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	[self addSubview:cell];
	[cell autoPinEdgesToSuperviewEdges];
	self.tableCell = cell;
	
	
	self.setupConstraints = YES;
	
	if(self.iconInsetMultiplier < 0.01){
		self.iconInsetMultiplier = 0.8;
	}
	if(self.iconPaddingMultiplier < 0.01){
		self.iconPaddingMultiplier = 1.0;
	}
	if(self.contentViewHeightMultiplier < 0.01){
		self.contentViewHeightMultiplier = 0.95;
	}
	if(self.titleLabelHeightMultipler < 0.01){
		self.titleLabelHeightMultipler = (1.0/3.0);
	}
	
	if(self.isLabelBased){
		self.iconPaddingMultiplier = 0.75;
	}
	
	BOOL containsRightView = [self.delegate respondsToSelector:@selector(rightViewForListEntry:)];
	if(containsRightView){
		containsRightView = ([self.delegate rightViewForListEntry:self] == nil) ? NO : YES;
	}
	
	if(containsRightView){
		self.rightViewBackgroundView = [UIView newAutoLayoutView];
		[cell.contentView addSubview:self.rightViewBackgroundView];
		
		[self.rightViewBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-(self.stretchAcrossWidth ? 0 : 15)];
		[self.rightViewBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
		[self.rightViewBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		[self.rightViewBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/2.2)];
		
		UIView *rightView = [self.delegate rightViewForListEntry:self];
		
		[self.rightViewBackgroundView addSubview:rightView];
		[rightView autoPinEdgesToSuperviewEdges];
	}
	
	//Initialised in init
	self.contentView.clipsToBounds = NO;
	self.contentView.layer.masksToBounds = NO;
	self.contentView.layer.cornerRadius = 8;
//	self.contentView.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:0.4];
	[cell.contentView addSubview:self.contentView];
	
	if(containsRightView){
		[self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
		[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:self.contentViewHeightMultiplier];
		[self.contentView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		[self.contentView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightViewBackgroundView];
	}
	else{
		[self.contentView autoCentreInSuperview];
		[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:self.contentViewHeightMultiplier];
		[self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self].constant = self.stretchAcrossWidth ? 0 : -40;
	}
	
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	
	if(!title){
		title = @"";
	}
	
	BOOL willHaveAnIcon = (icon != nil) || self.iPromiseIWillHaveAnIconForYouSoon;
	
	if(self.isLabelBased){
		willHaveAnIcon = NO;
	}
	
	if(willHaveAnIcon){
		self.iconBackgroundView = [UIView newAutoLayoutView];
		self.iconBackgroundView.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:self.iconBackgroundView];
		
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.stretchAcrossWidth ? 0 : 0];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.iconBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:self.iconPaddingMultiplier];
		[self.iconBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView];
		
		self.iconView = [UIImageView newAutoLayoutView];
		self.iconView.image = icon;
		self.iconView.layer.masksToBounds = self.roundedCorners;
		self.iconView.layer.cornerRadius = 6.0f;
		[self.iconBackgroundView addSubview:self.iconView];
		
		if(self.alignIconToLeft){
			[self.iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[self.iconView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		}
		else{
			[self.iconView autoCentreInSuperview];
		}
			
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.iconBackgroundView withMultiplier:self.iconInsetMultiplier];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.iconBackgroundView withMultiplier:self.iconInsetMultiplier];
	}
	
	
	if(self.isLabelBased){
		willHaveAnIcon = YES;
		
		self.iconBackgroundView = [UIView newAutoLayoutView];
		self.iconBackgroundView.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:self.iconBackgroundView];
		
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.iconBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView];
		[self.iconBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:self.iconPaddingMultiplier];
	
		
		self.leftTextLabel = [LMLabel newAutoLayoutView];
		self.leftTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		self.leftTextLabel.text = [NSString stringWithFormat:@"%ld", self.collectionIndex + 1];
		self.leftTextLabel.textColor = [UIColor lightGrayColor];
		self.leftTextLabel.textAlignment = NSTextAlignmentRight;
//		self.leftTextLabel.backgroundColor = [UIColor redColor];
		[self.iconBackgroundView addSubview:self.leftTextLabel];
	}
	
	
	self.textView = [UIView newAutoLayoutView];
//	self.textView.backgroundColor = [UIColor orangeColor];
	[self.contentView addSubview:self.textView];
	
	[self.textView autoPinEdge:ALEdgeLeading toEdge:willHaveAnIcon ? ALEdgeTrailing : ALEdgeLeading ofView:willHaveAnIcon ? self.iconBackgroundView : self.contentView withOffset:willHaveAnIcon ? (self.isLabelBased ? -20 : 4) : 10];
	[self.textView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.textView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	
	
	NSMutableArray *titleConstraints = [[NSMutableArray alloc]init];
	
	self.titleLabel = [LMLabel newAutoLayoutView];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.titleLabel.text = title;
	self.titleLabel.textColor = [UIColor blackColor];
	if(title){
		[self.textView addSubview:self.titleLabel];
		
		NSLayoutConstraint *heightConstraint = [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:self.titleLabelHeightMultipler];
		NSLayoutConstraint *leadingConstraint = [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		NSLayoutConstraint *trailingConstraint = [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.textView withOffset:-10.0];
		NSLayoutConstraint *centreConstraint = [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.textView];
		
		[titleConstraints addObject:heightConstraint];
		[titleConstraints addObject:leadingConstraint];
		[titleConstraints addObject:trailingConstraint];
		[titleConstraints addObject:centreConstraint];
	}
	
	self.subtitleLabel = [LMLabel newAutoLayoutView];
	self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.subtitleLabel.text = subtitle ? subtitle : @"";
	self.subtitleLabel.textColor = [UIColor blackColor];
	if(subtitle){
		[self.textView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0f/4.0f)];
		[self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		for(int i = 0; i < titleConstraints.count; i++){
			NSLayoutConstraint *constraint = [titleConstraints objectAtIndex:i];
			if(constraint.firstAttribute == NSLayoutAttributeCenterY){
				[titleConstraints removeObject:constraint];
				[self.textView removeConstraint:constraint];
				break;
			}
		}
				
		NSLayoutConstraint *titleTopConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			  attribute:NSLayoutAttributeTop
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self.textView
																			  attribute:NSLayoutAttributeTop
																			 multiplier:1.0
																			   constant:0];
		[self.contentView addConstraint:titleTopConstraint];
	}
	
	if(self.isLabelBased){
		[self.leftTextLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.titleLabel];
		[self.leftTextLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleLabel withMultiplier:(4.0/4.0)];
		[self.leftTextLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.titleLabel withOffset:-7.5];
	}
	
	UITapGestureRecognizer *tappedViewRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedView)];
	[self addGestureRecognizer:tappedViewRecognizer];
	
	[self setAsHighlighted:self.highlighted animated:NO];
}

- (id)initWithDelegate:(id)delegate {
	self = [super initForAutoLayout];
	//self.backgroundColor = [UIColor redColor];
	if(self){
		self.delegate = delegate;
	}
	else{
		NSLog(@"Failed to create LMListEntry!");
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.roundedCorners = YES;
		self.contentView = [UIView newAutoLayoutView];
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
