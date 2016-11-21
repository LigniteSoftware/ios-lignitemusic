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
	return @"Section title";
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	switch(section){
		case 0:
			return 1;
		case 1:
			return 3;
		case 2:
			return 5;
		case 3:
			return 1;
	}
	return 0;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return @"Title";
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return @"Subtitle";
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt];
}

- (void)layoutSubviews {
	if(!self.hasPreparedSubviews){
		self.hasPreparedSubviews = YES;
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.delegate = self;
		self.sectionTableView.numberOfSections = 4;
		[self addSubview:self.sectionTableView];
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
	}
}

@end
