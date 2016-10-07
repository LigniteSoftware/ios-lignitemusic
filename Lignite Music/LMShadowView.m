//
//  LMShadowView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/3/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMShadowView.h"

@implementation LMShadowView

- (id)init {
	self = [super init];
	if(self){
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.backgroundColor = [UIColor whiteColor];
		self.layer.shadowColor = [UIColor blackColor].CGColor;
		self.layer.shadowOpacity = 0.75f;
		self.layer.shadowOffset = CGSizeMake(0, 0);
		self.layer.masksToBounds = NO;
	}
	else{
		NSLog(@"Failed to create LMShadowView!");
	}
	return self;
}

- (void)updateConstraints {
	self.layer.shadowRadius = 30;
	
	[super updateConstraints];
}

//TODO: Fix shadow shit

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
