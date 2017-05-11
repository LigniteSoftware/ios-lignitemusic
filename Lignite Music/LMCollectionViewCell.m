//
//  LMCollectionViewCell.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMCollectionViewCell.h"

@implementation LMCollectionViewCell

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
	NSLog(@"Bitch");
	
	[super applyLayoutAttributes:layoutAttributes];
	[self layoutIfNeeded];
}

//- (void)layoutSubviews {
//	[super layoutSubviews];
//	self.backgroundColor = [UIColor orangeColor];
//}

@end
