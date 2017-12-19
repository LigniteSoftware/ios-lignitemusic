//
//  LMWarningManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMWarningManager.h"

@interface LMWarningManager()

/**
 The array of warnings.
 */
@property NSMutableArray<LMWarning*> *warningsArray;

@end

@implementation LMWarningManager

- (void)reloadWarningBar {
	LMWarning *warningWithHighestPriority = (self.warningsArray.count == 0) ? nil : [self.warningsArray firstObject];
	
	for(LMWarning *warning in self.warningsArray){
		if(warning.priority > warningWithHighestPriority.priority){
			warningWithHighestPriority = warning;
		}
	}
	
	[self.warningBar setWarning:warningWithHighestPriority];
}

- (void)addWarning:(LMWarning*)warning {
	[self.warningsArray addObject:warning];
	
	[self reloadWarningBar];
}

- (void)removeWarning:(LMWarning*)warning {
	[self.warningsArray removeObject:warning];
	
	[self reloadWarningBar];
}

+ (instancetype)sharedWarningManager {
	static LMWarningManager *sharedWarningManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedWarningManager = [self new];
		sharedWarningManager.warningBar = [LMWarningBarView newAutoLayoutView];
		sharedWarningManager.warningsArray = [NSMutableArray new];
	});
	return sharedWarningManager;
}

@end
