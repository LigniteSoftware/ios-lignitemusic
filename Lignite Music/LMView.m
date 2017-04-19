//
//  LMView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMView.h"

@interface LMView()

@property (strong) NSMutableArray<NSLayoutConstraint*> *portraitConstraints;

@property (strong) NSMutableArray<NSLayoutConstraint*> *landscapeConstraints;

@end

@implementation LMView

- (instancetype)init {
	self = [super init];
	if(self) {
		NSLog(@"Reset");
		self.landscapeConstraints = [NSMutableArray new];
		self.portraitConstraints = [NSMutableArray new];
	}
	return self;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		BOOL isNowLandscape = size.width > size.height;
		
		if(self.landscapeConstraints.count == 0){ //No landscape constraints have been defined, and that's ok. Leave it alone.
			return;
		}
		
		NSLog(@"Rotating %p...", self);
		
		[self removeConstraints:isNowLandscape ? self.portraitConstraints : self.landscapeConstraints];
		[self addConstraints:isNowLandscape ? self.landscapeConstraints : self.portraitConstraints];
		
		[self layoutIfNeeded];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { /* Completion code here, if you wish */ }];
}

@end
