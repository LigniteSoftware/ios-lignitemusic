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
@property MPMediaItem *item;
@property CAShapeLayer *circleLayer;

@end

@implementation LMAlbumViewItem

- (void)updateTextLayout{
    CGSize titleTextSize = [self.albumTitleView.text sizeWithAttributes:@{NSFontAttributeName: self.albumTitleView.font}];
    self.albumTitleView.frame = CGRectMake(self.albumTitleView.frame.origin.x, self.albumTitleView.frame.origin.y, self.frame.size.width-20, titleTextSize.height);
    
    CGSize subtitleTextSize = [self.albumArtistView.text sizeWithAttributes:@{NSFontAttributeName: self.albumArtistView.font}];
    self.albumArtistView.frame = CGRectMake(self.albumArtistView.frame.origin.x, self.albumTitleView.frame.origin.y+titleTextSize.height, self.frame.size.width-20, subtitleTextSize.height);
}

- (void)loadImage {
    int size = (self.frame.size.width/4) * 3;
    UIImage *image = [[self.item artwork] imageWithSize:CGSizeMake(size, size)];
    if(image == nil){
        image = [UIImage imageNamed:@"no_album.png"];
    }
    self.albumImageView.layer.cornerRadius = 10;
    [self.albumImageView setImage:image];
}

- (void)unloadImage {
    [self.albumImageView setImage:nil];
}

/*
 Initializes an LMAlbumViewItem with a media item (which contains information for the
 album, artist, etc.)
 */
- (id)initWithMediaItem:(MPMediaItem*)item onFrame:(CGRect)frame withAlbumCount:(NSInteger)count {
    self = [super initWithFrame:frame];
    //self.layer.backgroundColor = [UIColor blueColor].CGColor;
    if(self){
        self.item = item;
        
        int padding = 12;
        int fourthWidth = self.frame.size.width/4;
        int albumImageSize = (fourthWidth*3) - (padding*2);
        int albumImageOrigin = fourthWidth/2 + padding;
        self.albumImageView = [[UIImageView alloc]initWithFrame:CGRectMake(albumImageOrigin, albumImageOrigin, albumImageSize, albumImageSize)];
        self.albumImageView.clipsToBounds = YES;
        self.albumImageView.layer.backgroundColor = [UIColor redColor].CGColor;
        [self addSubview:self.albumImageView];
        
        int distanceToEnd = self.frame.size.height-self.albumImageView.frame.size.height;
        self.albumTitleView = [[UILabel alloc]initWithFrame:CGRectMake(10, albumImageOrigin+albumImageSize+10, self.frame.size.width-20, distanceToEnd/2)];
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
        
        int circleSize = 35;
        int halfCircleSize = circleSize/2;
        CGRect circleFrame = CGRectMake(albumImageOrigin+albumImageSize - halfCircleSize, albumImageOrigin-halfCircleSize, circleSize, circleSize);
        self.circleLayer = [CAShapeLayer layer];
        [self.circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:circleFrame] CGPath]];
        [self.layer addSublayer:self.circleLayer];
        
        UILabel *label = [[UILabel alloc]initWithFrame:circleFrame];
        [label setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
        //NSLog(@"Got value %lu for %@", (unsigned long)item.albumTrackCount, [self.albumTitleView text]);
        [label setText:[NSString stringWithFormat:@"%lu", (unsigned long)count]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:label];
        
        /*
        CATextLayer *label = [[CATextLayer alloc] init];
        [label setFont:@"Helvetica"];
        [label setFontSize:14];
        [label setFrame:circleFrame];
        [label setString:@"10"];
        [label setAlignmentMode:kCAAlignmentCenter];
        [label setForegroundColor:[[UIColor whiteColor] CGColor]];
        [self.layer addSublayer:label];
         */
         
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
