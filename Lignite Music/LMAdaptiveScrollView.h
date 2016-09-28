//
//  LMAdaptiveScrollView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/28/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMAdaptiveScrollView;

@protocol LMAdaptiveScrollViewDelegate <NSObject>
@required
- (void)prepareSubview:(id)subview forIndex:(NSUInteger)index;
@end

@interface LMAdaptiveScrollView : UIScrollView

@property NSArray *subviewArray;
@property id subviewDelegate;

@end
