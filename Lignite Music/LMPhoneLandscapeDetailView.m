//
//  LMPhoneLandscapeDetailView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMPhoneLandscapeDetailView.h"
#import "LMColour.h"

@interface LMPhoneLandscapeDetailView()



@end

@implementation LMPhoneLandscapeDetailView

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor whiteColor];
	}
}

@end
