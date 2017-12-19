//
//  LMWarning.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWarning.h"
#import "LMThemeEngine.h"

@implementation LMWarning

- (LMColour*)colour {
	switch(self.priority){
		case LMWarningPriorityLow:
			return (LMColour*)[LMColour superLightGreyColour];
		case LMWarningPriorityHigh:
		case LMWarningPrioritySevere:
			return [LMThemeEngine mainColourForTheme:LMThemeDefault];
	}
}

+ (LMWarning*)warningWithText:(NSString*)text priority:(LMWarningPriority)priority {
	LMWarning *warning = [LMWarning new];
	
	warning.text = text;
	warning.priority = priority;
	
	return warning;
}

@end
