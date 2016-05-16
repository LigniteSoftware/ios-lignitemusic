//
//  NPVTextInfoView.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NPTextInfoView : UIView

- (id)initWithFrame:(CGRect)frame withMiniPlayerStatus:(BOOL)isMiniPlayer;
- (void)updateContentWithMediaItem:(MPMediaItem*)newItem;
- (void)updateContentWithFrame:(CGRect)newFrame isPortrait:(BOOL)isPortrait;

@end
