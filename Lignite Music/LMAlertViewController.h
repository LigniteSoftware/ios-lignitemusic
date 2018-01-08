//
//  LMAlertViewController.h
//  Lignite Music
//
//  Created by Edwin Finch on 1/6/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMAlertViewController : UIViewController

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
@property NSString *titleText;

/**
 The text body of the alert.
 */
@property NSString *bodyText;

/**
 The text of the checkbox, if confirmation from the user is required (for things such as confirming they understand lag in iOS 11.2 is not our fault). If nil, no checkbox will be displayed.
 */
@property NSString *checkboxText;

/**
 If checkboxText is non-nil, this must also be non-nil. It provides a small link at the bottom of the dialogue for more information about why the user is checking the box.
 */
@property NSString *checkboxMoreInformationText;

/**
 If checkboxText is non-nil, this must also be non-nil. It is the link that checkboxMoreInformationText will redirect to once tapped on.
 */
@property NSString *checkboxMoreInformationLink;


/**
 The completion handler for when the option is selected. Stored from the initial load.
 
 @param optionSelected What option was selected, 0 being the first button associated with the first values in alertOptionTitles & alertOptionColours.
 @param checkboxChecked If checkboxText is defined, this will be a YES or NO on whether or not the user has checked the verification checkbox.
 */
@property void (^completionHandler)(NSUInteger optionSelected, BOOL checkboxChecked);

@end
