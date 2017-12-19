//
//  LMSource.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSource.h"

@implementation LMSource

+ (LMSource*)sourceWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(LMIcon)icon {
	LMSource *newSource = [LMSource new];
	
	newSource.title = title;
	newSource.subtitle = subtitle;
	newSource.icon = [LMAppIcon imageForIcon:icon];
	
	newSource.lmIcon = icon;
	
	return newSource;
	
}

@end
