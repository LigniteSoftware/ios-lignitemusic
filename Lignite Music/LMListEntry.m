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

@interface LMListEntry()<UIGestureRecognizerDelegate, MGSwipeTableCellDelegate>

@property UIView *iconBackgroundView;
@property UIImageView *iconView;
@property LMLabel *leftTextLabel;
@property LMLabel *titleLabel, *subtitleLabel;

@property BOOL highlighted;
@property BOOL imageIsInverted;

@property BOOL setupConstraints;

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
	
	self.titleLabel.text = title ? title : @"nil title";
	self.subtitleLabel.text = subtitle ? subtitle : @"";
	self.iconView.image = self.imageIsInverted ? [LMAppIcon invertImage:icon] : icon;
	self.leftTextLabel.text = leftText ? leftText : @"what";
	
	if([self.delegate respondsToSelector:@selector(rightViewForListEntry:)] && self.rightViewBackgroundView){
		for(UIView *subview in self.rightViewBackgroundView.subviews){
			[subview removeFromSuperview];
		}
		
		UIView *rightView = [self.delegate rightViewForListEntry:self];
		[self.rightViewBackgroundView addSubview:rightView];
		[rightView autoPinEdgesToSuperviewEdges];
	}
}

- (void)changeHighlightStatus:(BOOL)highlighted animated:(BOOL)animated {
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

- (BOOL)swipeTableCell:(MGSwipeTableCell*)cell canSwipe:(MGSwipeDirection)direction {
	if(MGSwipeDirectionLeftToRight){
		return NO;
	}
	return YES;
}

- (NSArray*)swipeTableCell:(MGSwipeTableCell*)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings*)swipeSettings expansionSettings:(MGSwipeExpansionSettings*)expansionSettings {
	
	BOOL isRightToLeftSwipe = direction == MGSwipeDirectionRightToLeft;
	
	swipeSettings.transition = MGSwipeTransitionClipCenter;
	swipeSettings.keepButtonsSwiped = YES;

	expansionSettings.buttonIndex = 0;
	expansionSettings.threshold = 1.5;
	expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
	expansionSettings.expansionColor = isRightToLeftSwipe ? self.rightButtonExpansionColour : self.leftButtonExpansionColour;
	expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunctionCubicOut;
	expansionSettings.fillOnTrigger = NO;

	return isRightToLeftSwipe ? self.rightButtons : self.leftButtons;
}

- (void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
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

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(self.setupConstraints){
		return;
	}
	
	MGSwipeTableCell * cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"test%d", rand()]];
	
	cell.backgroundColor = [UIColor clearColor];
	cell.delegate = self; //optional
	cell.clipsToBounds = YES;
	
	[self addSubview:cell];
	[cell autoPinEdgesToSuperviewEdges];
	
	
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
	
	self.contentView = [UIView newAutoLayoutView];
	self.contentView.clipsToBounds = NO;
	self.contentView.layer.masksToBounds = NO;
	self.contentView.layer.cornerRadius = 8;
//	self.contentView.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:0.4];
	[cell.contentView addSubview:self.contentView];
	
	if(containsRightView){
		[self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:self.contentViewHeightMultiplier];
		[self.contentView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		[self.contentView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.rightViewBackgroundView];
	}
	else{
		[self.contentView autoCenterInSuperview];
		[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:self.contentViewHeightMultiplier];
		[self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:self.stretchAcrossWidth ? 1.0 : 0.9];
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
		
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.stretchAcrossWidth ? 0 : 10];
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
			[self.iconView autoCenterInSuperview];
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
	
	
	NSMutableArray *titleConstraints = [[NSMutableArray alloc]init];
	
	self.titleLabel = [LMLabel newAutoLayoutView];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.titleLabel.text = title;
	self.titleLabel.textColor = [UIColor blackColor];
	if(title){
		[self.contentView addSubview:self.titleLabel];
		
		NSLayoutConstraint *heightConstraint = [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0f/3.0f)];
		NSLayoutConstraint *leadingConstraint = [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:willHaveAnIcon ? ALEdgeTrailing : ALEdgeLeading ofView:willHaveAnIcon ? self.iconBackgroundView : self.contentView withOffset:willHaveAnIcon ? (self.isLabelBased ? -20 : 4) : 10];
		NSLayoutConstraint *trailingConstraint = [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.contentView withOffset:-10.0];
		NSLayoutConstraint *centerConstraint = [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.contentView];
		
		[titleConstraints addObject:heightConstraint];
		[titleConstraints addObject:leadingConstraint];
		[titleConstraints addObject:trailingConstraint];
		[titleConstraints addObject:centerConstraint];
	}
	
	self.subtitleLabel = [LMLabel newAutoLayoutView];
	self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.subtitleLabel.text = subtitle ? subtitle : @"";
	self.subtitleLabel.textColor = [UIColor blackColor];
	if(subtitle){
		[self.contentView addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0f/4.0f)];
		[self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
		
		for(int i = 0; i < titleConstraints.count; i++){
			NSLayoutConstraint *constraint = [titleConstraints objectAtIndex:i];
			if(constraint.firstAttribute == NSLayoutAttributeCenterY){
				[titleConstraints removeObject:constraint];
				[self.contentView removeConstraint:constraint];
				break;
			}
		}
				
		NSLayoutConstraint *titleTopConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			  attribute:NSLayoutAttributeBottom
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self.contentView
																			  attribute:NSLayoutAttributeCenterY
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
	
	[self changeHighlightStatus:self.highlighted animated:NO];
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
		self.rightButtons = @[];
		self.leftButtons = @[];
		
		self.rightButtonExpansionColour = [UIColor colorWithRed:33/255.0 green:175/255.0 blue:67/255.0 alpha:1.0];
		self.leftButtonExpansionColour = [UIColor colorWithRed:33/255.0 green:175/255.0 blue:67/255.0 alpha:1.0];
		
		self.roundedCorners = YES;
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
