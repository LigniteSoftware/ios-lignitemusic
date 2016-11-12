//
//  TestingTableViewCell.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <PureLayout/PureLayout.h>
#import "LMTableViewCell.h"

@interface LMTableViewCell()

@property NSLayoutConstraint *heightGuideConstraint;

@end

@implementation LMTableViewCell

//      Too laggy
//
//@synthesize subview = _subview;
//
//- (id)subview {
//	return _subview;
//}
//
//- (void)setSubview:(id)subview {
//	_subview = subview;
//	
//	UIView *cellSubview = self.subview;
//	
//	[self.contentView addSubview:cellSubview];
//	
//	//		self.contentView.backgroundColor = [UIColor redColor];
//	
//	[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
//		[cellSubview autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
//	}];
//	
//	[cellSubview autoPinEdgesToSuperviewEdges];
//}

- (void)updateConstraints {
	if (!self.didSetupConstraints && self.subview) {
		self.didSetupConstraints = YES;
		
		//http://stackoverflow.com/questions/39104846/uitableviewcell-animate-height-issue-in-ios-10
		UIView *heightGuide = [[UIView alloc] init];
		heightGuide.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:heightGuide];
		[heightGuide addConstraint:({
			self.heightGuideConstraint = [NSLayoutConstraint constraintWithItem:heightGuide attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:0.0f];
		})];
		[self.contentView addConstraint:({
			[NSLayoutConstraint constraintWithItem:heightGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
		})];
		
		UIView *anotherView = [[UIView alloc] init];
		anotherView.translatesAutoresizingMaskIntoConstraints = NO;
		anotherView.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:anotherView];
		[anotherView addConstraint:({
			[NSLayoutConstraint constraintWithItem:anotherView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:20.0f];
		})];
		[self.contentView addConstraint:({
			[NSLayoutConstraint constraintWithItem:anotherView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
		})];
		[self.contentView addConstraint:({
			[NSLayoutConstraint constraintWithItem:anotherView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:heightGuide attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
		})];
		[self.contentView addConstraint:({
			[NSLayoutConstraint constraintWithItem:anotherView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
		})];
		
		UIView *cellSubview = self.subview;
		
		[self.contentView addSubview:cellSubview];
		
//		self.contentView.backgroundColor = [UIColor redColor];
		
		[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
			[cellSubview autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
		}];
		
		[cellSubview autoPinEdgesToSuperviewEdges];
		
		if(self.index != 0){
//			NSLog(@"Setup %d", self.index);
		}
	}
	
	[super updateConstraints];
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	
	if (self.window) {
		[UIView animateWithDuration:0.3 animations:^{
			self.heightGuideConstraint.constant = frame.size.height;
			[self.contentView layoutIfNeeded];
		}];
		
	} else {
		self.heightGuideConstraint.constant = frame.size.height;
	}
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
