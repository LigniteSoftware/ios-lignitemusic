//
//  LMPlaylistNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMRestorableNavigationController.h"
#import "LMPlaylistEditorViewController.h"

@interface LMRestorableNavigationController() <UIViewControllerRestoration>

@end

@implementation LMRestorableNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
	self = [super initWithRootViewController:rootViewController];
	if(self){
		self.restorationIdentifier = [[self class] description];
		self.restorationClass = [self class];
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.restorationIdentifier = [[self class] description];
		self.restorationClass = [self class];
	}
	return self;
}

+ (nullable UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray*)identifierComponents coder:(NSCoder*)coder {
	NSLog(@"Restorable nav controller path %@", identifierComponents);
	
	return [self new];
}

@end
