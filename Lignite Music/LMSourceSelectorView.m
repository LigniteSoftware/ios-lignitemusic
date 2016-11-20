//
//  LMSourceSelector.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSourceSelectorView.h"
#import "LMButton.h"
#import "LMCircleView.h"
#import "LMLabel.h"
#import "LMNewTableView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMSettings.h"

@interface LMSourceSelectorView() <LMTableViewSubviewDataSource, LMListEntryDelegate>

@property LMNewTableView *viewsTableView;
@property NSMutableArray *itemArray;

@property NSInteger currentlyHighlighted;

@end

@implementation LMSourceSelectorView

- (void)setSourceTitle:(NSString*)title {
	if(self.delegate){
		[self.delegate sourceTitleChangedTo:title];
	}
}

- (void)setSourceSubtitle:(NSString*)subtitle {
	if(self.delegate){
		[self.delegate sourceSubtitleChangedTo:subtitle];
	}
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMNewTableView *)tableView {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.sources objectAtIndex:index];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	return entry;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMNewTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
		for(int i = 0; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iconInsetMultiplier = (1.0/3.0);
			listEntry.iconPaddingMultiplier = (3.0/4.0);
			listEntry.invertIconOnHighlight = YES;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
		}
		
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		NSInteger lastSourceOpened = 0;
		if([settings objectForKey:LMSettingsKeyLastOpenedSource]){
			lastSourceOpened = [settings integerForKey:LMSettingsKeyLastOpenedSource];
		}
				
		[self tappedListEntry:[self.itemArray objectAtIndex:lastSourceOpened]];
	}
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMNewTableView *)tableView {
	return WINDOW_FRAME.size.height*(1.0f/8.0f);
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *indexEntry = [self.itemArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.itemArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMNewTableView *)tableView {
	return 10;
}

- (void)setCurrentSourceWithIndex:(NSInteger)index {
	LMListEntry *entry = [self listEntryForIndex:index];
	
	LMSource *source = [self.sources objectAtIndex:index];
	
	[source.delegate sourceSelected:source];
	
	if(source.shouldNotSelect){
		return;
	}
	
//	NSLog(@"Source image %@", source.icon);
	
//	[self.sourceSelectorButton setImage:[LMAppIcon invertImage:source.icon]];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = index;
		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:index forKey:LMSettingsKeyLastOpenedSource];
	[defaults synchronize];
}

- (void)tappedListEntry:(LMListEntry*)entry{
	[self setCurrentSourceWithIndex:entry.collectionIndex];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.icon;
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	self.currentlyHighlighted = -1;
	
	self.viewsTableView = [LMNewTableView newAutoLayoutView];
	self.viewsTableView.totalAmountOfObjects = self.sources.count;
	self.viewsTableView.subviewDataSource = self;
	self.viewsTableView.shouldUseDividers = YES;
	self.viewsTableView.title = @"SourceSelector";
	self.viewsTableView.dividerColour = [UIColor blackColor];
	self.viewsTableView.bottomSpacing = WINDOW_FRAME.size.height/8 + 10;
	[self addSubview:self.viewsTableView];
	
	[self.viewsTableView autoPinEdgesToSuperviewEdges];
	
	[self.viewsTableView reloadSubviewData];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
