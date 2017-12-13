//
//  LMThemeView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/13/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMThemeView.h"

@interface LMThemeView()



@end

@implementation LMThemeView

- (void)layoutSubviews {
	[super layoutSubviews];

	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor orangeColor];
	}
}

@end
