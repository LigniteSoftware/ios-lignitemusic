//
//  LMSearchView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchView.h"
#import "LMMusicPlayer.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"
#import "LMSearch.h"
#import "LMImageManager.h"

@interface LMSearchView()<LMSectionTableViewDelegate>

/**
 The section table view which powers the search view.
 */
@property LMSectionTableView *sectionTableView;

/**
 The current search term.
 */
@property NSString *currentSearchTerm;

/**
 The search results.
 */
@property NSArray<NSArray<MPMediaItemCollection*>*> *searchResultsArray;

/**
 The properties associated with each index in search.
 */
@property NSArray<NSString*>* associatedProperties;

/**
 The groupings associated.
 */
@property NSArray<NSNumber*>* associatedGroupings;

/**
 The image manager.
 */
@property LMImageManager *imageManager;

@end

@implementation LMSearchView

- (void)searchTermChangedTo:(NSString*)searchTerm {
	NSLog(@"Search view got new search term %@", searchTerm);
	
	self.currentSearchTerm = searchTerm;
	
	[self.sectionTableView reloadData];
	
	__weak id weakSelf = self;
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		LMSearchView *searchView = strongSelf;
		
		NSString *asyncSearchTerm = searchView.currentSearchTerm;
		
		NSLog(@"Term %@", asyncSearchTerm);
		
		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		NSArray *resultsArray = [LMSearch searchResultsForString:asyncSearchTerm];
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		
		if(![asyncSearchTerm isEqualToString:searchView.currentSearchTerm]){
			NSLog(@"Rejecting %@ (wasted %f seconds of thread time. Current \"%@\").", asyncSearchTerm, (endTime-startTime), searchView.currentSearchTerm);
			return;
		}
		
		NSLog(@"Done search for %@. Completed in %fs.", searchView.currentSearchTerm, endTime-startTime);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"%d items", (int)resultsArray.count);
			searchView.searchResultsArray = resultsArray;
			searchView.sectionTableView.totalNumberOfSections = searchView.searchResultsArray.count;
			[searchView.sectionTableView registerCellIdentifiers];
			[searchView.sectionTableView reloadData];
		});
	});
}

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.associatedGroupings objectAtIndex:section] unsignedIntegerValue];
	
	switch(mediaGrouping){
		case MPMediaGroupingArtist:
			return [LMAppIcon imageForIcon:LMIconArtists];
		case MPMediaGroupingAlbum:
			return [LMAppIcon imageForIcon:LMIconAlbums];
		case MPMediaGroupingComposer:
			return [LMAppIcon imageForIcon:LMIconComposers];
		case MPMediaGroupingGenre:
			return [LMAppIcon imageForIcon:LMIconGenres];
		case MPMediaGroupingTitle:
			return [LMAppIcon imageForIcon:LMIconTitles];
		default:
			return [LMAppIcon imageForIcon:LMIconBug];
	}
}

- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:section];

	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.associatedGroupings objectAtIndex:section] unsignedIntegerValue];
	
	switch(mediaGrouping){
		case MPMediaGroupingArtist:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Artist" : @"Artists", nil)];
		case MPMediaGroupingAlbum:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Album" : @"Albums", nil)];
		case MPMediaGroupingComposer:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Composer" : @"Composers", nil)];
		case MPMediaGroupingGenre:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Genre" : @"Genres", nil)];
		case MPMediaGroupingTitle:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Title" : @"Titles", nil)];
		default:
			return @"Unknown Section";
	}
	
	return [self.associatedProperties objectAtIndex:section];
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:section];
	

	return collections.count;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	
	return [collection.representativeItem valueForProperty:[self.associatedProperties objectAtIndex:indexPath.section]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	MPMediaItem *representativeItem = collection.representativeItem;
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.associatedGroupings objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	switch(mediaGrouping){
//		case MPMediaGroupingArtist:
//		case MPMediaGroupingComposer:
//			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Album" : @"Albums", nil)];
			
		case MPMediaGroupingAlbum:
			return [NSString stringWithFormat:
					@"%@ | %lu %@",
					representativeItem.artist ? representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil),
					collection.count,
					NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
			
		case MPMediaGroupingArtist:
		case MPMediaGroupingComposer:
		case MPMediaGroupingGenre:
			return [NSString stringWithFormat:@"%lu %@", collection.count, NSLocalizedString(collection.count == 1 ? @"Song" : @"Songs", nil)];
		case MPMediaGroupingTitle:
			return collection.representativeItem.artist;
		default:
			return @"Unknown Subtitle";
	}
	return nil;
}

- (UIImage*)iconForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	MPMediaItem *representativeItem = collection.representativeItem;

	UIImage *image = (indexPath.section == 0 || indexPath.section == 3) ? [self.imageManager imageForMediaItem:representativeItem withCategory:LMImageManagerCategoryArtistImages] : [[representativeItem artwork] imageWithSize:CGSizeMake(480, 480)];
	
	if(!image){
		image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	}
	
	return image;
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSLog(@"Tapped %d.%d", (int)indexPath.section, (int)indexPath.row);
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.didLayoutConstraints = YES;
		
		self.currentSearchTerm = @"Title";
		
		self.imageManager = [LMImageManager sharedImageManager];
		
		self.associatedProperties = @[
									   MPMediaItemPropertyArtist,
									   MPMediaItemPropertyAlbumTitle,
									   MPMediaItemPropertyTitle,
									   MPMediaItemPropertyComposer,
									   MPMediaItemPropertyGenre
									   ];
		
		self.associatedGroupings = @[
									 @(MPMediaGroupingArtist),
									 @(MPMediaGroupingAlbum),
									 @(MPMediaGroupingTitle),
									 @(MPMediaGroupingComposer),
									 @(MPMediaGroupingGenre)
									 ];
		
		self.backgroundColor = [UIColor cyanColor];
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 5;
		self.sectionTableView.title = @"Search";
		[self addSubview:self.sectionTableView];
		
		NSLog(@"section %@", self.sectionTableView);
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
	}
	
	[super layoutSubviews];
}

@end
