//
//  LMAlbumView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumView.h"

@interface LMAlbumView()

@property UILabel *titleLabel, *subtitleLabel;

@end

@implementation LMAlbumView

- (id)initWithContentItem:(MPContentItem*)item {
    self = [super init];
    if(self){
        
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
