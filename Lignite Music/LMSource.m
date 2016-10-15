//
//  LMSource.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSource.h"

@implementation LMSource

+ (LMSource*)sourceWithTitle:(NSString*)title andIconNamed:(NSString*)iconName {
	LMSource *newSource = [LMSource new];
	
	newSource.title = title;
	newSource.icon = [UIImage imageNamed:iconName];
	newSource.iconName = iconName;
	
	return newSource;
	
}

@end
