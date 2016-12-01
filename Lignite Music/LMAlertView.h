//
//  LMAlertView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMAlertView : UIView

/**
 The titles which go on the buttons of options. The first will be the bottom, the second will be above that, etc.
 */
@property NSArray<NSString*> *alertOptionTitles;

/**
 The colours which will go on the buttons. See alertOptionTitles documentation for more details on array structure.
 */
@property NSArray<UIColor*> *alertOptionColours;

/**
 The title of the alert.
 */
@property NSString *title;

/**
 The text body of the alert.
 */
@property NSString *body;

/**
 Launch the created alert view on top of another UIView with a completion handler that will be called when the user makes their decision.

 @param alertRootView The view to add the alert on top of.
 @param completionHandler The completion handler to be called when the user makes their decision.
 */
- (void)launchOnView:(UIView*)alertRootView withCompletionHandler:(void(^)(NSUInteger optionSelected))completionHandler;

@end
