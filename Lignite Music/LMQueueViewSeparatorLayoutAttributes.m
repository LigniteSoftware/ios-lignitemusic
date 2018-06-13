//
//  LMQueueViewSeparatorLayoutAttributes.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import "LMQueueViewSeparatorLayoutAttributes.h"

@implementation LMQueueViewSeparatorLayoutAttributes

- (instancetype)copyWithZone:(NSZone *)zone {
	LMQueueViewSeparatorLayoutAttributes *newAttributes = [super copyWithZone:zone];
	if(newAttributes){
		newAttributes.additionalOffset = 0.0;
	}
	return newAttributes;
}

@end
