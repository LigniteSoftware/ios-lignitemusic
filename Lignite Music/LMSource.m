//
//  LMSource.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSource.h"

@implementation LMSource

+ (LMSource*)sourceWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIconNamed:(NSString*)iconName {
	LMSource *newSource = [LMSource new];
	
	newSource.title = title;
	newSource.subtitle = subtitle;
	newSource.icon = [UIImage imageNamed:iconName];
	newSource.iconName = iconName;
	
	return newSource;
	
}

@end
