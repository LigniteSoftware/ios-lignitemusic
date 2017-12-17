//
//  LMEnhancedPlaylistNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMEnhancedPlaylistNavigationController.h"
#import "LMEnhancedPlaylistEditorViewController.h"

@interface LMEnhancedPlaylistNavigationController() <UIViewControllerRestoration>

@end

@implementation LMEnhancedPlaylistNavigationController

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
	LMEnhancedPlaylistEditorViewController *enhancedPlaylistViewController = [LMEnhancedPlaylistEditorViewController new];
	LMEnhancedPlaylistNavigationController *navigation = [[LMEnhancedPlaylistNavigationController alloc] initWithRootViewController:enhancedPlaylistViewController];
	
	NSLog(@"enhanced playlist nav controller path %@", identifierComponents);
	
	return navigation;
}

@end

