//
//  LMWarning.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LMColour.h"

/**
 The warning priority tells the system how important this warning is. The system will handle the chance that the warning gets displayed based on its priority, with severe being crucial.

 - LMWarningPriorityLow: The priority is low, this is more of an "in case you wanted to know" warning. Colour will be a very light grey.
 - LMWarningPriorityHigh: The priority is high, this is handy for when user input is required (but not absolutely necessary). Colour will be Lignite Red.
 - LMWarningPrioritySevere: The priority is severe and the app is having trouble handling its emotions without the user's input. This priority is twice as large as a normal warning and is always Lignite Red.
 */
typedef NS_ENUM(NSInteger, LMWarningPriority){
	LMWarningPriorityLow = 0,
	LMWarningPriorityHigh,
	LMWarningPrioritySevere
};

@interface LMWarning : NSObject

/**
 The text of the warning which will display inside of the warning bar.a
 */
@property NSString *text;

/**
 The priority of the warning.
 */
@property LMWarningPriority priority;

/**
 The colour that the warning bar should use, determined by the warning's priority.
 */
- (LMColour*)colour;

/**
 Creates a warning object with predefined text and a set priority.

 @param text The text of the warning to display to the user.
 @param priority The priority of the warning within the system.
 @return The warning object.
 */
+ (LMWarning*)warningWithText:(NSString*)text priority:(LMWarningPriority)priority;

@end
