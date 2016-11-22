//
//  LMSettingsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/21/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSettingsView.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"

@interface LMSettingsView()<LMSectionTableViewDelegate>

@property LMSectionTableView *sectionTableView;

@property BOOL hasPreparedSubviews;

@end

@implementation LMSettingsView

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [NSString stringWithFormat:@"A section called #%d", (int)section];
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	return section;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSUInteger rawRow = [sectionTableView rawIndexForIndexPath:indexPath];
	return [NSString stringWithFormat:@"Title %d.%d: %d %d", (int)indexPath.section, (int)indexPath.row, (int)rawRow, (int)rawRow % 12];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [NSString stringWithFormat:@"Subtitle %d.%d", (int)indexPath.section, (int)indexPath.row];
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt];
}

- (void)layoutSubviews {
	if(!self.hasPreparedSubviews){
		self.hasPreparedSubviews = YES;
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 100;
		[self addSubview:self.sectionTableView];
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
	}
}

@end
