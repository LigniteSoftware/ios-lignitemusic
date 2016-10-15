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

@interface LMListEntry()

@property id delegate;

@property UIView *contentView;

@property UIView *iconBackgroundView;
@property UIImageView *iconView;
@property LMLabel *titleLabel, *subtitleLabel;

@property BOOL highlighted;

@end

@implementation LMListEntry

- (void)reloadContents {
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	self.titleLabel.text = title;
	self.subtitleLabel.text = subtitle;
	self.iconView.image = icon;
}

- (void)changeHighlightStatus:(BOOL)highlighted animated:(BOOL)animated {
	if(self.highlighted && highlighted){
		return;
	}
	
	self.highlighted = highlighted;
	
	if(animated){
		[UIView animateWithDuration:0.2 animations:^{
			if(highlighted){
				self.contentView.backgroundColor = [self.delegate tapColourForListEntry:self];
				self.titleLabel.textColor = [UIColor whiteColor];
				self.subtitleLabel.textColor = [UIColor whiteColor];
			}
			else{
				self.contentView.backgroundColor = [UIColor clearColor];
				self.titleLabel.textColor = [UIColor blackColor];
				self.subtitleLabel.textColor = [UIColor blackColor];
			}
		}];
	}
	else{
		if(highlighted){
			self.contentView.backgroundColor = [self.delegate tapColourForListEntry:self];
			self.titleLabel.textColor = [UIColor whiteColor];
			self.subtitleLabel.textColor = [UIColor whiteColor];
		}
		else{
			self.contentView.backgroundColor = [UIColor clearColor];
			self.titleLabel.textColor = [UIColor blackColor];
			self.subtitleLabel.textColor = [UIColor blackColor];
		}
	}
}

- (void)tappedView {
	[self.delegate tappedListEntry:self];
}

- (void)setup {
	self.contentView = [UIView newAutoLayoutView];
	self.contentView.clipsToBounds = NO;
	self.contentView.layer.masksToBounds = NO;
	self.contentView.layer.cornerRadius = 8;
	[self addSubview:self.contentView];
	
	[self.contentView autoCenterInSuperview];
	[self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.95];
	[self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.9];
	
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	
	if(icon){
		self.iconBackgroundView = [UIView newAutoLayoutView];
		self.iconBackgroundView.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:self.iconBackgroundView];
		
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.iconBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.iconBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView];
		[self.iconBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.contentView];
		
		self.iconView = [[UIImageView alloc]initWithImage:icon];
		self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.iconBackgroundView addSubview:self.iconView];
		
		[self.iconView autoCenterInSuperview];
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.iconBackgroundView withMultiplier:0.8];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.iconBackgroundView withMultiplier:0.8];
	}
	
	NSMutableArray *titleConstraints = [[NSMutableArray alloc]init];
	
	self.titleLabel = [[LMLabel alloc]init];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.titleLabel.text = title;
	self.titleLabel.textColor = [UIColor blackColor];
	self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	if(title){
		[self.contentView addSubview:self.titleLabel];
		
		NSLayoutConstraint *heightConstraint = [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0f/3.0f)];
		NSLayoutConstraint *leadingConstraint = [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:icon ? ALEdgeTrailing : ALEdgeLeading ofView:icon ? self.iconBackgroundView : self.contentView withOffset:icon ? 0 : 10];
		NSLayoutConstraint *trailingConstraint = [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.contentView withOffset:-10.0];
		NSLayoutConstraint *centerConstraint = [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.contentView];
		
		[titleConstraints addObject:heightConstraint];
		[titleConstraints addObject:leadingConstraint];
		[titleConstraints addObject:trailingConstraint];
		[titleConstraints addObject:centerConstraint];
	}
	
	self.subtitleLabel = [[LMLabel alloc]init];
	self.subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40.0f];
	self.subtitleLabel.text = subtitle;
	self.subtitleLabel.textColor = [UIColor blackColor];
	self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
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
	
	UITapGestureRecognizer *tappedViewRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedView)];
	[self.contentView addGestureRecognizer:tappedViewRecognizer];
}

- (id)initWithDelegate:(id)delegate {
	self = [super init];
	//self.backgroundColor = [UIColor redColor];
	if(self){
		self.delegate = delegate;
	}
	else{
		NSLog(@"Failed to create LMListEntry!");
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
