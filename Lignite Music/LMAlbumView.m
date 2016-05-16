//
//  LMAlbumView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumView.h"
#import "LMAlbumViewItem.h"

@interface LMAlbumView() <UIScrollViewDelegate>

@property UIScrollView *rootScrollView;
@property UILabel *titleLabel, *subtitleLabel;
@property NSMutableArray *albumsItemArray;

@end

@implementation LMAlbumView

- (void)reloadAlbumItems {
    CGRect visibleRect = CGRectMake(self.rootScrollView.contentOffset.x, self.rootScrollView.contentOffset.y, self.rootScrollView.contentOffset.x + self.rootScrollView.bounds.size.width, self.rootScrollView.contentOffset.y + self.rootScrollView.bounds.size.height);
    
    //NSLog(@"rect %@", NSStringFromCGRect(visibleRect));
    
    NSArray *albums = [[MPMediaQuery albumsQuery] collections];
    for(int i = 0; i < [albums count]; i++){
        LMAlbumViewItem *item = [self.albumsItemArray objectAtIndex:i];
        CGRect itemFrame = item.frame;
        int newRectStart = visibleRect.origin.y;
        int newFrameEnd = visibleRect.origin.y+self.frame.size.height;
        int itemFrameStart = itemFrame.origin.y+itemFrame.size.height;
        if(itemFrameStart >= newRectStart && itemFrameStart <= newFrameEnd+itemFrame.size.height){
            //NSLog(@"%d is under, with value %d (compared %d, %d)", i, itemFrameStart, newRectStart, newFrameEnd);
            [item loadImage];
            [self.rootScrollView addSubview:item];
        }
        else{
            //NSLog(@"%d is OVER, with value %d (compared %d, %d)", i, itemFrameStart, newRectStart, newFrameEnd);
            [item unloadImage];
            [item removeFromSuperview];
        }
    }

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self reloadAlbumItems];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.albumsItemArray = [[NSMutableArray alloc]init];
        
        CGRect currentFrame = self.frame;
        CGRect rootFrame = currentFrame; //CGRectMake(currentFrame.origin.x, currentFrame.origin.y, currentFrame.size.width, currentFrame.size.height);
        self.rootScrollView = [[UIScrollView alloc]initWithFrame:rootFrame];
        self.rootScrollView.backgroundColor = [UIColor lightGrayColor];
        [self.rootScrollView setContentSize:CGSizeMake(self.frame.size.width, self.frame.size.height*2)];
        [self addSubview:self.rootScrollView];
        
        NSTimeInterval startingTime = [[NSDate date] timeIntervalSince1970];
        
        MPMediaQuery *everything = [MPMediaQuery albumsQuery];
        [everything setGroupingType: MPMediaGroupingAlbum];
        
        NSLog(@"Logging items from a generic query...");
        
        NSArray *albums = [[MPMediaQuery albumsQuery] collections];
        int statusBarAdjust = [UIApplication sharedApplication].statusBarFrame.size.height*1.5;
        BOOL isOddNumber = [albums count] % 2 != 0;
        for(int i = 0; i < [[everything collections] count]; i++){
            MPMediaItemCollection *collection = [[everything collections] objectAtIndex:i];
            //NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
            //NSLog (@"%lu for %@", (unsigned long)[section count], [[section representativeItem] title]);
            uint8_t rowIsLeft = i % 2;
            int itemWidth = self.frame.size.width/2;
            CGRect itemFrame = CGRectMake(10+(itemWidth * rowIsLeft), (i/2)*(itemWidth) + statusBarAdjust, itemWidth - 20, itemWidth);
            LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:[collection representativeItem] onFrame:itemFrame withAlbumCount:[collection count]];
            [self.albumsItemArray addObject:newItem];
            [newItem loadImage];
        }
        /*
        NSLog(@"Logging items from a generic query...");
        for (MPMediaItemCollection *section in [everything collections]) {
            
            //NSString *songTitle = [song valueForProperty: MPMediaItemPropertyTitle];
            NSLog (@"%lu for %@", (unsigned long)[section count], [[section representativeItem] title]);
            
        }
         */

        /*
        NSArray *albums = [[MPMediaQuery albumsQuery] collections];
        int statusBarAdjust = [UIApplication sharedApplication].statusBarFrame.size.height*1.5;
        BOOL isOddNumber = [albums count] % 2 != 0;
        for(int i = 0; i < [albums count]; i++){
            MPMediaItemCollection *collection = [albums objectAtIndex:i];
            //NSLog(@"Album %d: %@", i, [[[collection items] objectAtIndex:0] albumTitle]);
            uint8_t rowIsLeft = i % 2;
            int halfWidth = self.frame.size.width/2;
            CGRect itemFrame = CGRectMake(10+(halfWidth * rowIsLeft), (i/2)*(halfWidth)*1.2 + statusBarAdjust, halfWidth - 20, (halfWidth)*1.2);
            LMAlbumViewItem *newItem = [[LMAlbumViewItem alloc]initWithMediaItem:[[collection items] objectAtIndex:0] onFrame:itemFrame];
            [self.albumsItemArray addObject:newItem];
            [newItem loadImage];
            //[self.rootScrollView addSubview:newItem];
        }
         */
        self.rootScrollView.delegate = self;
        [self.rootScrollView setContentSize:CGSizeMake(self.frame.size.width, ([albums count]/2)*(self.frame.size.width/2) + statusBarAdjust + (isOddNumber ? self.frame.size.width/2 : 0))];
        
        NSTimeInterval endingTime = [[NSDate date] timeIntervalSince1970];
        
        NSLog(@"Took %f seconds to complete.", endingTime-startingTime);
        
        [self reloadAlbumItems];
    }
    else{
        NSLog(@"Self (new instance of LMAlbumView) is nil!");
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
