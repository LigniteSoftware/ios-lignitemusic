//
//  LMSearchView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchView.h"
#import "LMSectionTableView.h"
#import "LMAppIcon.h"
#import "LMSearch.h"
#import "LMImageManager.h"
#import "LMLayoutManager.h"

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
 The grouping types of the search results.
 */
@property NSArray<NSNumber*> *searchResultsGroupingArray;

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

/**
 Whether or not the user has done any search query.
 */
@property BOOL hasSearched;


/**
 The background view for the stupid welcome to search screen.
 */
@property UIView *welcomeToSearchBackgroundView;

/**
 The background view for the content of the ri-dic-u-lous welcome to search screen.
 */
@property UIView *welcomeToSearchContentBackgroundView;

/**
 The label for the insane welcome to search screen.
 */
@property UILabel *welcomeToSearchLabel;

/**
 Ugh, I hate this stupid welcome to search screen.
 */
@property UIView *welcomeToSearchImageBackgroundView;

/**
 The image view for the search icon for the annoying welcome to search screen.
 */
@property UIImageView *welcomeToSearchImageView;

@end

@implementation LMSearchView

- (BOOL)noResults {
	if(!self.searchResultsArray || !self.searchResultsGroupingArray){
		return YES;
	}
	if(self.searchResultsArray.count == 0){
		return YES;
	}
	return NO;
}

- (void)tappedCloseButtonForSectionTableView:(LMSectionTableView *)sectionTableView {
	[(UINavigationController*)self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchTermChangedTo:(NSString*)searchTerm {
	NSLog(@"Search view got new search term %@", searchTerm);
	
	self.currentSearchTerm = searchTerm;
	
	BOOL isBlankSearch = [[self.currentSearchTerm stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""];
	
	if(isBlankSearch){
		self.searchResultsArray = nil;
		self.searchResultsGroupingArray = nil;
		self.sectionTableView.totalNumberOfSections = 1;
		
		self.welcomeToSearchLabel.text = NSLocalizedString(@"WelcomeToSearch", nil);
		self.welcomeToSearchImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconSearch]];
	}
	
	self.welcomeToSearchBackgroundView.hidden = !isBlankSearch;
	
	[self.sectionTableView reloadData];
	
	if(isBlankSearch){
		return;
	}
	
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
			NSLog(@"%d items for %@", (int)resultsArray.count, searchView.currentSearchTerm);
			searchView.searchResultsGroupingArray = [resultsArray objectAtIndex:0];
			NSMutableArray *actualResultsArray = [NSMutableArray arrayWithArray:resultsArray];
			[actualResultsArray removeObjectAtIndex:0];
			
			NSLog(@"Search results grouping %@", searchView.searchResultsGroupingArray);
			
			searchView.searchResultsArray = actualResultsArray;
			searchView.sectionTableView.totalNumberOfSections = searchView.searchResultsArray.count;
			
			if(searchView.searchResultsArray.count == 0){
				searchView.searchResultsArray = nil;
				searchView.searchResultsGroupingArray = nil;
				searchView.sectionTableView.totalNumberOfSections = 1;
				
				searchView.welcomeToSearchLabel.text = NSLocalizedString(@"NoSearchResults", nil);
				searchView.welcomeToSearchImageView.image = [LMAppIcon imageForIcon:LMIconNoSearchResults];
			}
			else{
				[searchView.sectionTableView registerCellIdentifiers];
			}
			
			searchView.welcomeToSearchBackgroundView.hidden = !(searchView.searchResultsArray.count == 0);
			
			searchView.hasSearched = YES;
			[searchView.sectionTableView reloadData];
		});
	});
}

- (UIImage*)iconAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return nil;
	}
	
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:section] unsignedIntegerValue];
	
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
		case MPMediaGroupingPlaylist:
			return [LMAppIcon imageForIcon:LMIconPlaylists];
		default:
			return [LMAppIcon imageForIcon:LMIconBug];
	}
}

- (NSString*)titleAtSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return @"";
	}
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:section];

	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:section] unsignedIntegerValue];
	
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
		case MPMediaGroupingPlaylist:
			return [NSString stringWithFormat:@"%lu %@", collections.count, NSLocalizedString(collections.count == 1 ? @"Playlist" : @"Playlists", nil)];
		default:
			return @"Unknown Section";
	}
	
	return [self.associatedProperties objectAtIndex:section];
}

- (NSUInteger)numberOfRowsForSection:(NSUInteger)section forSectionTableView:(LMSectionTableView*)sectionTableView {
	if([self noResults]){
		return 0;
	}
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:section];
	

	return collections.count;
}

- (NSString*)titleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	return (mediaGrouping == MPMediaGroupingPlaylist) ? [collection valueForProperty:MPMediaPlaylistPropertyName] : [collection.representativeItem valueForProperty:[self.associatedProperties objectAtIndex:[self.associatedGroupings indexOfObject:@(mediaGrouping)]]];
}

- (NSString*)subtitleForIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	MPMediaItem *representativeItem = collection.representativeItem;
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:indexPath.section] unsignedIntegerValue];
	
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
		case MPMediaGroupingPlaylist:
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
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:indexPath.section] unsignedIntegerValue];

	UIImage *image = (mediaGrouping == MPMediaGroupingArtist || mediaGrouping == MPMediaGroupingComposer) ? [self.imageManager imageForMediaItem:representativeItem withCategory:LMImageManagerCategoryArtistImages] : [[representativeItem artwork] imageWithSize:CGSizeMake(480, 480)];
	
	if(!image){
		image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
	}
	
	return image;
}

- (void)tappedIndexPath:(NSIndexPath*)indexPath forSectionTableView:(LMSectionTableView*)sectionTableView {
	NSLog(@"Tapped %d.%d", (int)indexPath.section, (int)indexPath.row);
	
	NSArray<MPMediaItemCollection*>* collections = [self.searchResultsArray objectAtIndex:indexPath.section];
	MPMediaItemCollection *collection = [collections objectAtIndex:indexPath.row];
	MPMediaItem *representativeItem = [collection representativeItem];
	MPMediaGrouping mediaGrouping = (MPMediaGrouping)[[self.searchResultsGroupingArray objectAtIndex:indexPath.section] unsignedIntegerValue];
	
	switch(mediaGrouping){
		case MPMediaGroupingAlbum:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:representativeItem.albumPersistentID withMusicType:LMMusicTypeAlbums];
			break;
		case MPMediaGroupingArtist:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:representativeItem.artistPersistentID withMusicType:LMMusicTypeArtists];
			break;
		case MPMediaGroupingComposer:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:representativeItem.composerPersistentID withMusicType:LMMusicTypeComposers];
			break;
		case MPMediaGroupingGenre:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:representativeItem.genrePersistentID withMusicType:LMMusicTypeGenres];
			break;
		case MPMediaGroupingPlaylist:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:collection.persistentID withMusicType:LMMusicTypePlaylists];
			break;
		case MPMediaGroupingTitle:
			[self.searchSelectedDelegate searchEntryTappedWithPersistentID:representativeItem.persistentID withMusicType:LMMusicTypeTitles];
			break;
		default:
			NSLog(@"Windows fucking error! Tapped an index not recognized.");
			break;
	}
	
	NSLog(@"%d items", (int)collection.count);
}

- (void)reloadData {
	[self.sectionTableView reloadData];
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
									   MPMediaItemPropertyGenre,
									   MPMediaPlaylistPropertyName
									   ];
		
		self.associatedGroupings = @[
									 @(MPMediaGroupingArtist),
									 @(MPMediaGroupingAlbum),
									 @(MPMediaGroupingTitle),
									 @(MPMediaGroupingComposer),
									 @(MPMediaGroupingGenre),
									 @(MPMediaGroupingPlaylist)
									 ];
		
		self.backgroundColor = [UIColor clearColor];
		
		self.sectionTableView = [LMSectionTableView newAutoLayoutView];
		self.sectionTableView.contentsDelegate = self;
		self.sectionTableView.totalNumberOfSections = 1;
		self.sectionTableView.title = @"Search";
		self.sectionTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
		[self addSubview:self.sectionTableView];
		
		NSLog(@"section %@", self.sectionTableView);
		
		[self.sectionTableView autoPinEdgesToSuperviewEdges];
		
		[self.sectionTableView setup];
		
		
		
		self.welcomeToSearchBackgroundView = [UIView newAutoLayoutView];
//		self.welcomeToSearchBackgroundView.backgroundColor = [UIColor blueColor];
		[self addSubview:self.welcomeToSearchBackgroundView];
		
		[self.welcomeToSearchBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.welcomeToSearchBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.welcomeToSearchBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		NSArray *welcomeToSearchBackgroundViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.welcomeToSearchBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:WINDOW_FRAME.size.height/11.0]; //Headers are /10.0
		}];
		[LMLayoutManager addNewPortraitConstraints:welcomeToSearchBackgroundViewPortraitConstraints];
		
		NSArray *welcomeToSearchBackgroundViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.welcomeToSearchBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:WINDOW_FRAME.size.height/20.0];
		}];
		[LMLayoutManager addNewLandscapeConstraints:welcomeToSearchBackgroundViewLandscapeConstraints];
		
		
		self.welcomeToSearchContentBackgroundView = [UIView newAutoLayoutView];
//		self.welcomeToSearchContentBackgroundView.backgroundColor = [UIColor magentaColor];
		[self.welcomeToSearchBackgroundView addSubview:self.welcomeToSearchContentBackgroundView];
		
		[self.welcomeToSearchContentBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(6.0/10.0)];
		[self.welcomeToSearchContentBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.welcomeToSearchContentBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.welcomeToSearchContentBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
		
		self.welcomeToSearchLabel = [UILabel newAutoLayoutView];
		self.welcomeToSearchLabel.numberOfLines = 0;
		self.welcomeToSearchLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f];
		self.welcomeToSearchLabel.text = NSLocalizedString(@"WelcomeToSearch", nil);
		self.welcomeToSearchLabel.textAlignment = NSTextAlignmentCenter;
		[self.welcomeToSearchContentBackgroundView addSubview:self.welcomeToSearchLabel];
		
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.welcomeToSearchLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		
		
		self.welcomeToSearchImageBackgroundView = [UIView newAutoLayoutView];
//		self.welcomeToSearchImageBackgroundView.backgroundColor = [UIColor yellowColor];
		[self.welcomeToSearchContentBackgroundView addSubview:self.welcomeToSearchImageBackgroundView];
		
		[self.welcomeToSearchImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.welcomeToSearchImageBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.welcomeToSearchImageBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.welcomeToSearchLabel withOffset:-20];
		[self.welcomeToSearchImageBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.welcomeToSearchContentBackgroundView withMultiplier:(3.0/10.0)];
		
		
		self.welcomeToSearchImageView = [UIImageView newAutoLayoutView];
//		self.welcomeToSearchImageView.backgroundColor = [UIColor orangeColor];
		self.welcomeToSearchImageView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconSearch]];
		self.welcomeToSearchImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.welcomeToSearchImageBackgroundView addSubview:self.welcomeToSearchImageView];

		[self.welcomeToSearchImageView autoPinEdgesToSuperviewEdges];
	}
	
	[super layoutSubviews];
}

@end
