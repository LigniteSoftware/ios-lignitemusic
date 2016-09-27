//
//  LMAlbumCountLabel.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMAlbumCountLabel.h"

@interface LMAlbumCountLabel ()

@end

@implementation LMAlbumCountLabel

-(void)layoutSubviews {
	[super layoutSubviews];
	
	self.layer.cornerRadius = self.bounds.size.width/2;
	self.backgroundColor = [UIColor blackColor];
	self.layer.masksToBounds = YES;
	self.layer.opaque = NO;
	self.clipsToBounds = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
