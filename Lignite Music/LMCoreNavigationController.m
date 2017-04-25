//
//  LMCoreNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-26.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCoreNavigationController.h"

@interface LMCoreNavigationController ()

@end

@implementation LMCoreNavigationController


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if(self){
		self.rootView = [LMView newAutoLayoutView];
		self.rootView.userInteractionEnabled = NO;
//		self.rootView.backgroundColor = [UIColor orangeColor];
		[self.view addSubview:self.rootView];
		
		[self.rootView autoPinEdgesToSuperviewEdges];
	}
	
	return self;
}

@end
