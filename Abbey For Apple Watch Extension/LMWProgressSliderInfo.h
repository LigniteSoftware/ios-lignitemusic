//
//  LMWProgressSliderInfo.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMWProgressSliderInfo;

@protocol LMWProgressSliderDelegate<NSObject>

/**
 The progress slider slid to a new position.

 @param progressSliderInfo The progress slider info associated with the handling of the slide.
 @param percentage The percentage, in a decimal place between 0.0 and 1.0 of how far to the right the progress bar has been set to. ie. 0.69 is 69%.
 */
- (void)progressSliderWithInfo:(LMWProgressSliderInfo*)progressSliderInfo slidToNewPositionWithPercentage:(CGFloat)percentage;

@end

@interface LMWProgressSliderInfo : NSObject


/**
 The delegate for the slider info events.
 */
@property id<LMWProgressSliderDelegate> delegate;


/**
 Initialize the progress slider info with a certain size.

 @param progressBarGroup The progress bar group that will be the actual progress bar.
 @param containerGroup The container group which contains the progress bar.
 @param interfaceController The interface controller that contains the progress bar.
 @return The initialized progress slider info object.
 */
- (instancetype)initWithProgressBarGroup:(WKInterfaceGroup*)progressBarGroup inContainer:(WKInterfaceGroup*)containerGroup onInterfaceController:(WKInterfaceController*)interfaceController;

/**
 Handles the actual gesture, coming in from the interface controller that has the root group connected through an IBOutlet.

 @param panGestureRecognizer The pan gesture recognizer that the interface controller has recieved.
 */
- (void)handleProgressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer;

@end
