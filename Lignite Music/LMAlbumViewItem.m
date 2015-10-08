//
//  LMAlbumViewItem.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumViewItem.h"

@interface LMAlbumViewItem()

@property UIImageView *albumImageView;
@property UILabel *albumTitleView, *albumArtistView;

@end

@implementation LMAlbumViewItem

- (void)updateTextLayout{
    CGSize titleTextSize = [self.albumTitleView.text sizeWithAttributes:@{NSFontAttributeName: self.albumTitleView.font}];
    self.albumTitleView.frame = CGRectMake(self.albumTitleView.frame.origin.x, self.albumTitleView.frame.origin.y, self.frame.size.width-20, titleTextSize.height);
    
    CGSize subtitleTextSize = [self.albumArtistView.text sizeWithAttributes:@{NSFontAttributeName: self.albumArtistView.font}];
    self.albumArtistView.frame = CGRectMake(self.albumArtistView.frame.origin.x, self.albumTitleView.frame.origin.y+titleTextSize.height, self.frame.size.width-20, subtitleTextSize.height);
}

/*
 Initializes an LMAlbumViewItem with a media item (which contains information for the
 album, artist, etc.)
 */
- (id)initWithMediaItem:(MPMediaItem*)item onFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.albumImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width)];
        UIImage *image = [[item artwork] imageWithSize:self.frame.size];
        if(image == nil){
            NSLog(@"Image for %@ is nil", [item albumTitle]);
            image = [UIImage imageNamed:@"no_album.png"];
        }
        [self.albumImageView setImage:image];
        [self addSubview:self.albumImageView];
        
        int distanceToEnd = self.frame.size.height-self.albumImageView.frame.size.height;
        self.albumTitleView = [[UILabel alloc]initWithFrame:CGRectMake(10, self.frame.size.width+10, self.frame.size.width-20, distanceToEnd/2)];
        self.albumTitleView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
        self.albumTitleView.text = [item albumTitle];
        self.albumTitleView.textColor = [UIColor whiteColor];
        self.albumTitleView.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.albumTitleView];
        
        self.albumArtistView = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 0, 0)];
        self.albumArtistView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
        self.albumArtistView.text = [item artist];
        self.albumArtistView.textColor = [UIColor whiteColor];
        self.albumArtistView.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.albumArtistView];
        
        [self updateTextLayout];
    }
    else{
        NSLog(@"LMAlbumViewItem is nil!");
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
