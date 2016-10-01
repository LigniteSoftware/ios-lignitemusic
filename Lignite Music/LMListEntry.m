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

@property UIImageView *iconView;
@property LMLabel *titleLabel, *subtitleLabel;

@end

@implementation LMListEntry

- (void)changeHighlightStatus:(BOOL)highlighted {
	[UIView animateWithDuration:0.2 animations:^{
		if(highlighted){
			self.backgroundColor = [self.delegate tapColourForListEntry:self];
			self.titleLabel.textColor = [UIColor whiteColor];
			self.subtitleLabel.textColor = [UIColor whiteColor];
		}
		else{
			self.backgroundColor = [UIColor clearColor];
			self.titleLabel.textColor = [UIColor blackColor];
			self.subtitleLabel.textColor = [UIColor blackColor];
		}
	}];
}

- (void)tappedView {
	[self.delegate tappedListEntry:self];
}

- (void)setup {
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	
	self.iconView = [[UIImageView alloc]initWithImage:icon];
	self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
	if(icon){
		[self addSubview:self.iconView];
		
		[self.iconView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self];
		[self.iconView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self withMultiplier:0.8];
		[self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.8];
	}
	
	NSMutableArray *titleConstraints = [[NSMutableArray alloc]init];
	
	self.titleLabel = [[LMLabel alloc]init];
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	self.titleLabel.text = title;
	self.titleLabel.textColor = [UIColor blackColor];
	self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	if(title){
		[self addSubview:self.titleLabel];
		
		NSLayoutConstraint *heightConstraint = [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0f/3.0f)];
		NSLayoutConstraint *leadingConstraint = [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:icon ? self.iconView : self withOffset:10];
		NSLayoutConstraint *trailingConstraint = [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		NSLayoutConstraint *centerConstraint = [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self];
		
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
		[self addSubview:self.subtitleLabel];
		
		[self.subtitleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0f/4.0f)];
		[self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
		[self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
		
		for(int i = 0; i < titleConstraints.count; i++){
			NSLayoutConstraint *constraint = [titleConstraints objectAtIndex:i];
			if(constraint.firstAttribute == NSLayoutAttributeCenterY){
				[titleConstraints removeObject:constraint];
				[self removeConstraint:constraint];
				break;
			}
		}
				
		NSLayoutConstraint *titleTopConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			  attribute:NSLayoutAttributeBottom
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self
																			  attribute:NSLayoutAttributeCenterY
																			 multiplier:1.0
																			   constant:0];
		[self addConstraint:titleTopConstraint];
	}
	
	self.clipsToBounds = NO;
	self.layer.masksToBounds = NO;
	self.layer.cornerRadius = 8;
	self.userInteractionEnabled = YES;
	
	UITapGestureRecognizer *tappedViewRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedView)];
	[self addGestureRecognizer:tappedViewRecognizer];
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
