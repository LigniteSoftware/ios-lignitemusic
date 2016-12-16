//
//  LMPaddedTextField.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMPaddedTextField.h"

@implementation LMPaddedTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
	return CGRectInset(bounds, 10, 10);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	return CGRectInset(bounds, 10, 10);
}

@end
