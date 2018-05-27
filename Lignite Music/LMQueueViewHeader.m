//
//  LMQueueViewHeader.m
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMQueueViewHeader.h"
#import "LMListEntry.h"
#import "LMAppIcon.h"
#import "LMColour.h"

@interface LMQueueViewHeader()<LMListEntryDelegate>

/**
 Whether or not the subviews have been lain out.
 */
@property BOOL didLayoutSubviews;

/**
 The list entry for this header view.
 */
@property LMListEntry *listEntry;

@end

@implementation LMQueueViewHeader

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %@", entry);
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour redColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	if(self.delegate){
		return [self.delegate titleForHeader:self];
	}
	
	return @"Unknown Header";
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	if(self.delegate){
		return [self.delegate subtitleForHeader:self];
	}
	
	return @"Unknown subtitle for header";
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	if(self.delegate){
		return [self.delegate iconForHeader:self];
	}
	
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (void)reload {
	[self.listEntry reloadContents];
}

- (void)layoutSubviews {
	if(!self.didLayoutSubviews){
		self.didLayoutSubviews = YES;
		
		self.listEntry = [LMListEntry newAutoLayoutView];
		self.listEntry.delegate = self;
		self.listEntry.collectionIndex = 0;
		self.listEntry.isLabelBased = NO;
		self.listEntry.alignIconToLeft = NO;
		self.listEntry.stretchAcrossWidth = NO;
		
		[self addSubview:self.listEntry];
		self.listEntry.backgroundColor = [LMColour clearColour];
		
		[self.listEntry autoPinEdgesToSuperviewEdges];
	}
}

@end
