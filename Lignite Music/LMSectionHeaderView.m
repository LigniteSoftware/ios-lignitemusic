//
//  LMSectionHeaderView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSectionHeaderView.h"

@interface LMSectionHeaderView()

/**
 Whether or not the views subviews have been lain out.
 */
@property BOOL hasDoneLayoutSubviews;

/**
 The image view for the icon which goes on the left side.
 */
@property UIImageView *iconImageView;

/**
 The header label which goes to the right of the icon.
 */
@property UILabel *sectionHeaderLabel;

/**
 The title label which goes at the very top. Is only displayed if the header view has space for it.
 */
@property UILabel *titleLabel;

@end

@implementation LMSectionHeaderView

- (void)layoutSubviews {
	[super layoutSubviews];
	if(!self.hasDoneLayoutSubviews){
		self.hasDoneLayoutSubviews = YES;
		
		self.backgroundColor = [UIColor redColor];
	}
}

@end
