//
//  LMListEntry.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/29/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMListEntry.h"
#import "LMLabel.h"

@interface LMListEntry()

@property id delegate;

@property UIImageView *iconView;
@property LMLabel *titleLabel, *subtitleLabel;

@end

@implementation LMListEntry

- (void)setup {
	UIImage *icon = [self.delegate iconForListEntry:self];
	NSString *title = [self.delegate titleForListEntry:self];
	NSString *subtitle = [self.delegate subtitleForListEntry:self];
	
	self.iconView = [[UIImageView alloc]initWithImage:icon];
	self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
	if(icon){
		[self addSubview:self.iconView];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconView
														 attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeCenterY
														multiplier:1.0
														  constant:0]];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconView
														 attribute:NSLayoutAttributeLeading
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeLeading
														multiplier:1.0
														  constant:0]];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconView
														 attribute:NSLayoutAttributeWidth
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeHeight
														multiplier:0.8
														  constant:0]];
		
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconView
														 attribute:NSLayoutAttributeHeight
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeHeight
														multiplier:0.8
														  constant:0]];
	}
	
	NSMutableArray *titleConstraints = [[NSMutableArray alloc]init];
	
	self.titleLabel = [[LMLabel alloc]init];
	self.titleLabel.text = title;
	self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	if(title){
		[self addSubview:self.titleLabel];
		
		NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			attribute:NSLayoutAttributeHeight
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self
																			attribute:NSLayoutAttributeHeight
																		   multiplier:(1/3)
																			 constant:0];
		[titleConstraints addObject:heightConstraint];
		
		[self addConstraint:heightConstraint];
		
		NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			 attribute:NSLayoutAttributeLeading
																			 relatedBy:NSLayoutRelationEqual
																				toItem:icon ? self.iconView : self
																			 attribute:NSLayoutAttributeLeading
																			multiplier:1.0
																			  constant:0];
		[titleConstraints addObject:leadingConstraint];
		
		[self addConstraint:leadingConstraint];
		
		NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			 attribute:NSLayoutAttributeTrailing
																			 relatedBy:NSLayoutRelationEqual
																				toItem:self
																			 attribute:NSLayoutAttributeTrailing
																			multiplier:1.0
																			  constant:0];
		[titleConstraints addObject:trailingConstraint];
		
		[self addConstraint:trailingConstraint];
		
		NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			attribute:NSLayoutAttributeCenterY
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self
																			attribute:NSLayoutAttributeCenterY
																		   multiplier:1.0
																			 constant:0];
		[titleConstraints addObject:centerConstraint];

		[self addConstraint:centerConstraint];
	}
	
	self.subtitleLabel = [[LMLabel alloc]init];
	self.subtitleLabel.text = subtitle;
	self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	if(subtitle){
		[self addSubview:self.subtitleLabel];
		
		NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
																			attribute:NSLayoutAttributeHeight
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self
																			attribute:NSLayoutAttributeHeight
																		   multiplier:(1/4)
																			 constant:0];
		[self addConstraint:heightConstraint];
		
		NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
																			 attribute:NSLayoutAttributeLeading
																			 relatedBy:NSLayoutRelationEqual
																				toItem:self.titleLabel
																			 attribute:NSLayoutAttributeLeading
																			multiplier:1.0
																			  constant:0];
		[self addConstraint:leadingConstraint];
		
		NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
																			  attribute:NSLayoutAttributeTrailing
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self.titleLabel
																			  attribute:NSLayoutAttributeTrailing
																			 multiplier:1.0
																			   constant:0];
		[self addConstraint:trailingConstraint];
		
		NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
																			attribute:NSLayoutAttributeTop
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self.titleLabel
																			attribute:NSLayoutAttributeBottom
																		   multiplier:1.0
																			 constant:0];
		[self addConstraint:topConstraint];
		
		for(int i = 0; i < titleConstraints.count; i++){
			NSLayoutConstraint *constraint = [titleConstraints objectAtIndex:i];
			if(constraint.firstAttribute == NSLayoutAttributeCenterY){
				[titleConstraints removeObject:constraint];
				[self removeConstraint:constraint];
				break;
			}
		}
		
		NSLayoutConstraint *titleTopConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																			  attribute:NSLayoutAttributeTop
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:self
																			  attribute:NSLayoutAttributeTop
																			 multiplier:1.0
																			   constant:0];
		[self addConstraint:titleTopConstraint];
	}
}

- (id)initWithDelegate:(id)delegate {
	self = [super init];
	self.backgroundColor = [UIColor redColor];
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
