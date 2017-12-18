//
//  LMSectionHeaderView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSectionHeaderView.h"
#import "LMLabel.h"
#import "LMAppIcon.h"

@interface LMSectionHeaderView()

/**
 Whether or not the views subviews have been lain out.
 */
@property BOOL hasDoneLayoutSubviews;

/**
 The background view for the icon view below.
 */
@property UIView *sectionHeaderIconImageBackgroundView;

/**
 The image view for the icon which goes on the left side.
 */
@property UIImageView *sectionHeaderIconImageView;

/**
 The header label which goes to the right of the icon.
 */
@property LMLabel *sectionHeaderLabel;

/**
 The title label which goes at the very top. Is only displayed if the header view has space for it.
 */
@property LMLabel *titleLabel;

@end

@implementation LMSectionHeaderView

@synthesize title = _title;
@synthesize sectionHeaderTitle = _sectionHeaderTitle;
@synthesize icon = _icon;

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		self.sectionHeaderBackgroundView = [UIView newAutoLayoutView]; //So the X button can pin itself to this
	}
	return self;
}

- (NSString*)title {
	return _title;
}

- (void)setTitle:(NSString *)title {
	_title = title;
	
	if(self.titleLabel){
		self.titleLabel.text = title;
	}
}

- (NSString*)sectionHeaderTitle {
	return _sectionHeaderTitle;
}

- (void)setSectionHeaderTitle:(NSString *)sectionHeaderTitle {
	_sectionHeaderTitle = sectionHeaderTitle;
	
	if(self.sectionHeaderLabel){		
		self.sectionHeaderLabel.text = sectionHeaderTitle;
	}
}

- (UIImage*)icon {
	return _icon;
}

- (void)setIcon:(UIImage *)icon {
	_icon = icon;
	
	if(self.sectionHeaderIconImageView){
		self.sectionHeaderIconImageView.image = icon;
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.hasDoneLayoutSubviews){
		self.hasDoneLayoutSubviews = YES;
		
		self.backgroundColor = [UIColor whiteColor];
		
		if(self.heightFactorial < 0.01){
			self.heightFactorial = 1.0;
		}
		
//		NSLog(@"Height factorial is %f", self.heightFactorial);
		
//		self.sectionHeaderBackgroundView.backgroundColor = [UIColor greenColor];
		[self addSubview:self.sectionHeaderBackgroundView];
		
		[self.sectionHeaderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.sectionHeaderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.sectionHeaderBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.sectionHeaderBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:self.heightFactorial];
		
		
		self.sectionHeaderIconImageBackgroundView = [UIView newAutoLayoutView];
//		self.sectionHeaderIconImageBackgroundView.backgroundColor = [UIColor orangeColor];
		[self.sectionHeaderBackgroundView addSubview:self.sectionHeaderIconImageBackgroundView];
		
		[self.sectionHeaderIconImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
		[self.sectionHeaderIconImageBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.sectionHeaderIconImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sectionHeaderBackgroundView];
		[self.sectionHeaderIconImageBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.sectionHeaderBackgroundView];
		
		
		self.sectionHeaderIconImageView = [UIImageView newAutoLayoutView];
//		self.sectionHeaderIconImageView.backgroundColor = [UIColor yellowColor];
		self.sectionHeaderIconImageView.image = self.icon;
		[self.sectionHeaderIconImageBackgroundView addSubview:self.sectionHeaderIconImageView];
		
		[self.sectionHeaderIconImageView autoCentreInSuperview];
		[self.sectionHeaderIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sectionHeaderBackgroundView withMultiplier:(2.0/4.0)];
		[self.sectionHeaderIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.sectionHeaderBackgroundView withMultiplier:(2.0/4.0)];
		
		self.sectionHeaderLabel = [LMLabel newAutoLayoutView];
		self.sectionHeaderLabel.text = self.sectionHeaderTitle ? self.sectionHeaderTitle : NSLocalizedString(@"Unnamed Section", nil);
		self.sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50];
//		self.sectionHeaderLabel.backgroundColor = [UIColor cyanColor];
		[self.sectionHeaderBackgroundView addSubview:self.sectionHeaderLabel];
		
		[self.sectionHeaderLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sectionHeaderIconImageBackgroundView withOffset:0];
		[self.sectionHeaderLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
		[self.sectionHeaderLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.sectionHeaderLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sectionHeaderIconImageView withMultiplier:(8.5/10.0)];
		
		if(self.xIconTapSelector){
			UIImageView *xIconView = [UIImageView newAutoLayoutView];
			xIconView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconXCross]];
			xIconView.contentMode = UIViewContentModeScaleAspectFit;
			xIconView.userInteractionEnabled = YES;
			[self addSubview:xIconView];
			
			[xIconView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self withOffset:-(0.05*self.frame.size.width)];
			[xIconView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:(0.10*self.frame.size.width)];
			[xIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight
								   ofView:self.sectionHeaderBackgroundView withMultiplier:(1.5/5.0)];
			[xIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight
								   ofView:self.sectionHeaderBackgroundView withMultiplier:(1.5/5.0)];
						
			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self.superview action:self.xIconTapSelector];
			[xIconView addGestureRecognizer:tapGesture];
		}
		
//		if(self.heightFactorial < 1.0){
//			self.titleLabel = [LMLabel newAutoLayoutView];
//			self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0f];
//			self.titleLabel.text = self.title;
//	//		self.titleLabel.backgroundColor = [UIColor cyanColor];
//			[self addSubview:self.titleLabel];
//			
//			[self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.sectionHeaderIconImageView];
//			[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
//			[self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.sectionHeaderLabel];
//			[self.titleLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sectionHeaderBackgroundView withOffset:-10];
//		}
	}
}

@end
