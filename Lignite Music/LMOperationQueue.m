//
//  LMOperationQueue.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMOperationQueue.h"

@implementation LMOperationQueue

- (id)init {
	self = [super init];
	if(self){
		self.maxConcurrentOperationCount = 1;
	}
	else{
		NSLog(@"Failed to create LMOperationQueue!");
	}
	return self;
}

@end
