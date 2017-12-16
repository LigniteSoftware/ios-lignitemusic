//
//  LMPlaylistNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMPlaylistNavigationController.h"
#import "LMPlaylistEditorViewController.h"

@interface LMPlaylistNavigationController() <UIViewControllerRestoration>

@end

@implementation LMPlaylistNavigationController

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
	LMPlaylistEditorViewController *playlistViewController = [LMPlaylistEditorViewController new];
	LMPlaylistNavigationController *navigation = [[LMPlaylistNavigationController alloc] initWithRootViewController:playlistViewController];
	
	NSLog(@"playlist nav controller path %@", identifierComponents);
	
	return navigation;
}

@end
