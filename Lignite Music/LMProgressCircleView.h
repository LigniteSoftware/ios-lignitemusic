//
//  LMProgressCircle.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMProgressCircleView : UIView

@property int thickness;
@property float maxValue;
@property float currentValue;

- (void)reload;

@end
