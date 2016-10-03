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

@property BOOL didSetupConstraints;

@end

@implementation LMTableViewCell

- (void)updateConstraints {
	NSLog(@"Sup dude %d", self.didSetupConstraints);
	if (!self.didSetupConstraints && self.subview) {
		UIView *cellSubview = self.subview;
		
		[self.contentView addSubview:cellSubview];
		
		[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
			[cellSubview autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
		}];

		[cellSubview autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[cellSubview autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[cellSubview autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
		[cellSubview autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
		
//		self.mediaItem = [(MPMediaItemCollection*)[self.everything.collections objectAtIndex:(rand() % 50)] representativeItem];
//		
//		self.item = [[LMAlbumViewItem alloc]initWithMediaItem:self.mediaItem];
//		[self.contentView addSubview:self.item];
//		
//		self.reallyBigUIView = [UIView newAutoLayoutView];
//		self.reallyBigUIView.backgroundColor = [UIColor blueColor];
//		[self.contentView addSubview:self.reallyBigUIView];
//
//		[NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
//			[self.item autoSetContentCompressionResistancePriorityForAxis:ALAxisVertical];
//		}];
//		
//		[self.item autoPinEdgeToSuperviewEdge:ALEdgeTop];
//		[self.item autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//		[self.item autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
//		[self.item autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
//		
//		[self.item setupWithAlbumCount:10 andDelegate:self];
		
		self.didSetupConstraints = YES;
		
		NSLog(@"Loaded");
	}
	
	[super updateConstraints];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
