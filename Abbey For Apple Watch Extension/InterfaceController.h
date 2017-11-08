//
//  InterfaceController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController

@property IBOutlet WKInterfaceLabel *testLabel;

@property IBOutlet WKInterfaceGroup *progressBarGroup;

@property IBOutlet WKInterfaceGroup *progressBarContainer;

- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer;

@end
