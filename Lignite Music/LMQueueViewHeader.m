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
		
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.collectionIndex = 0;
		listEntry.isLabelBased = NO;
		listEntry.alignIconToLeft = NO;
		listEntry.stretchAcrossWidth = NO;
		
		[self addSubview:listEntry];
		listEntry.backgroundColor = [LMColour clearColour];
		
		[listEntry autoPinEdgesToSuperviewEdges];
	}
}

@end
