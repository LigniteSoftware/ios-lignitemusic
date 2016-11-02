//
//  TestingTableViewCell.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import "LMOperationQueue.h"

@class LMTableViewCell;

@protocol LMTableViewCellSubviewDelegate <NSObject>

@end

@interface LMTableViewCell : UITableViewCell

@property LMOperationQueue* queue;
@property id subview;
@property BOOL didSetupConstraints;

/**
 If NO, the cell will not pin the subview to the bottom (in case of resizing cells)
 */
@property BOOL shouldNotPinContentsToBottom;

@end
