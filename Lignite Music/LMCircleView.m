//
//  LMCircleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCircleView.h"

@implementation LMCircleView

- (void)layoutSubviews {
	self.layer.cornerRadius = self.frame.size.height/2;
	self.layer.masksToBounds = YES;
}

@end
