//
//  LMRestorableNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMRestorableNavigationController.h"
#import "LMPlaylistEditorViewController.h"

#define LMRestorableNavigationControllerRestorationKeyNavigationBarHidden @"LMRestorableNavigationControllerRestorationKeyNavigationBarHidden"

@interface LMRestorableNavigationController() <UIViewControllerRestoration>

@end

@implementation LMRestorableNavigationController

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	[self setNavigationBarHidden:[coder decodeBoolForKey:LMRestorableNavigationControllerRestorationKeyNavigationBarHidden]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
	
	[coder encodeBool:self.navigationBarHidden forKey:LMRestorableNavigationControllerRestorationKeyNavigationBarHidden];
}

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
	
	LMRestorableNavigationController *restorableNavigationController = [self new];
	
	[restorableNavigationController setNavigationBarHidden:YES];
	
	return restorableNavigationController;
}

@end


