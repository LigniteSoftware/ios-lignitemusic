//
//  LMMusicPickerNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMMusicPickerNavigationController.h"
#import "LMMusicPickerController.h"

@interface LMMusicPickerNavigationController() <UIViewControllerRestoration>



@end

@implementation LMMusicPickerNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
	self = [super initWithRootViewController:rootViewController];
	if(self){
//		self.restorationIdentifier = [[self class] description];
//		self.restorationClass = [self class];
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if(self){
//		self.restorationIdentifier = [[self class] description];
//		self.restorationClass = [self class];
	}
	return self;
}

+ (nullable UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray*)identifierComponents coder:(NSCoder*)coder {
	LMMusicPickerController *musicPickerController = [LMMusicPickerController new];
	LMMusicPickerNavigationController *navigation = [[LMMusicPickerNavigationController alloc] initWithRootViewController:musicPickerController];
	
	NSLog(@"view controller nav controller path %@", identifierComponents);
	
	return navigation;
}

@end
