//
//  LMLagDetectionThread.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/20/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LMLagDetectionThread : NSThread

/**
 The view to display lag alerts on.
 */
@property UIView *viewToDisplayAlertsOn;

@end
