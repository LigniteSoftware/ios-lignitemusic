//
//  LMImageManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PureLayout/PureLayout.h>
#import <Unirest/UNIRest.h>
#import "LMImageManager.h"
#import "LMColour.h"
#import "LMAlertView.h"
#import "LMReachability.h"
#import "LMMusicPlayer.h"
#import "LMSettings.h"
#import "NSTimer+Blocks.h"
@import SDWebImage;

/**
 The estimated average size of an image from LastFM in bytes.

 @return The estimated average.
 */
#define AVERAGE_IMAGE_SIZE_IN_BYTES 215000

/**
 The image manager's disk cache namespaces for storing images.

 @return The name of a disk namespace.
 */
#define LMImageManagerCacheNamespaceArtist @"LMImageManagerCacheArtist"
#define LMImageManagerCacheNamespaceAlbum @"LMImageManagerCacheAlbum"

/**
 Our API key for the current image API. God forbid this ever get cutoff.

 @return The API key.
 */
#define LMImageAPIKey @"PysouAgyWfodlbXkRrAq"

/**
 The API secret for the current image API. Godspeed.

 @return The API secret.
 */
#define LMImageAPISecret @"uPoAOoqKhwgkrPebIrxTktOHEyjgslBK"

/**
 The amount of calls which can be made per second as per the rate limit of the last.fm API.

 @return The amount of calls.
 */
#define ImageAPICallsPerSecondLimit 4.0

/**
 The amount of calls we will actually make per second maximum.

 @return The amount of calls.
 */
#define LMImageAPICallsPerSecondLimit 0.25
//TODO: change this to 3.0 for release

/**
 The amount of seconds between API calls.

 @return The amount of seconds.
 */
#define LMImageAPISecondsBetweenAPICalls (1.0/LMImageAPICallsPerSecondLimit)

/**
 The amount of items per page that LastFM should return in its API results.

 @return The number of items per page.
 */
#define LMLastFMItemsPerPageLimit 10

@interface LMImageManager()

/**
 The system music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The collection of albums.
 */
@property NSArray<LMMusicTrackCollection*> *albumsCollection;

/**
 The collection of artists.
 */
@property NSArray<LMMusicTrackCollection*> *artistsCollection;

/**
 The artist image cache of the image manager.
 */
@property SDImageCache *artistImageCache;

/**
 The album art image cache of the image manager.
 */
@property SDImageCache *albumImageCache;

/**
 The operation queue.
 */
@property NSOperationQueue *operationQueue;

/**
 The queue of tracks which are lined up to have images downloaded for them.
 */
@property NSMutableArray<LMMusicTrack*>* trackDownloadQueue;

/**
 The category associated with the track in queue for downloading array.
 */
@property NSMutableArray<NSNumber*>* categoryDownloadQueue;

/**
 The delegates for the image manager.
 */
@property NSMutableArray<id<LMImageManagerDelegate>>* delegates;

/**
 The last time an image was downloaded.
 */
@property NSTimeInterval lastImageDownloadTime;

/**
 The timer which will count down from 2 seconds and will then begin the downloading process if on WiFi.
 */
@property NSTimer *reachabilityChangedTimer;

/**
 An array of categories which are currently being processed. When inside this array, the image download process should not begin again for them.
 */
@property NSMutableArray<NSNumber*> *currentlyProcessingCategoryArray;

@end

@implementation LMImageManager

/**
 *
 * GENERAL CODE
 *
 */

- (instancetype)init {
	self = [super init];
	if(self){
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.albumsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeAlbums];
		self.artistsCollection = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists];
		
		self.albumImageCache = [[SDImageCache alloc] initWithNamespace:LMImageManagerCacheNamespaceAlbum];
		self.artistImageCache = [[SDImageCache alloc] initWithNamespace:LMImageManagerCacheNamespaceArtist];
		
		self.operationQueue = [NSOperationQueue new];
		
		self.trackDownloadQueue = [NSMutableArray new];
		self.categoryDownloadQueue = [NSMutableArray new];
		
		self.delegates = [NSMutableArray new];
		
//		[self setPermissionStatus:LMImageManagerPermissionStatusNotDetermined
//	 forSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionLowStorage];
//		
//		[self setPermissionStatus:LMImageManagerPermissionStatusNotDetermined
//	 forSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionCellularData];
//		
//		[self wifiReactivated];
		
		[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
			LMReachability* reach = [LMReachability reachabilityWithHostname:@"www.google.com"];
			reach.reachableOnWWAN = NO;
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(reachabilityChanged:)
														 name:kReachabilityChangedNotification
													   object:nil];
			[reach startNotifier];
		} repeats:NO];
		
//
//		[self clearCacheForCategory:LMImageManagerCategoryArtistImages];
//		[self clearCacheForCategory:LMImageManagerCategoryAlbumImages];
		
//		NSLog(@"Current keys %@", [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]);
	}
	return self;
}

+ (LMImageManager*)sharedImageManager {	
	static LMImageManager *sharedImageManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedImageManager = [self new];
	});
	return sharedImageManager;
}

- (void)addDelegate:(id<LMImageManagerDelegate>)delegate {
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<LMImageManagerDelegate>)delegate {
	[self.delegates removeObject:delegate];
}

/**
 *
 * END GENERAL CODE AND BEGIN IMAGE DOWNLOADING CODE
 *
 */

- (void)notifyDelegatesOfCacheSizeChangeForCategory:(LMImageManagerCategory)category {
	for(int i = 0; i < self.delegates.count; i++){
		id<LMImageManagerDelegate> delegate = [self.delegates objectAtIndex:i];
		
		if([delegate respondsToSelector:@selector(cacheSizeChangedTo:forCategory:)]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[delegate cacheSizeChangedTo:[self sizeOfCacheForCategory:category] forCategory:category];
			});
		}
	}
}

- (void)notifyDelegatesOfImageCacheChangeForCategory:(LMImageManagerCategory)category {
	for(int i = 0; i < self.delegates.count; i++){
		id<LMImageManagerDelegate> delegate = [self.delegates objectAtIndex:i];
		
		if([delegate respondsToSelector:@selector(imageCacheChangedForCategory:)]){
			dispatch_async(dispatch_get_main_queue(), ^{
				[delegate imageCacheChangedForCategory:category];
			});
		}
	}
}

- (BOOL)highQualityImages {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	BOOL highQuality = NO;
	
	if([userDefaults objectForKey:LMSettingsKeyHighQualityImages]){
		highQuality = [userDefaults boolForKey:LMSettingsKeyHighQualityImages];
	}
	
	return highQuality;
}

- (void)highQualityImagesOptionDidChange {
	self.trackDownloadQueue = [NSMutableArray new];
	self.categoryDownloadQueue = [NSMutableArray new];
	
	[self clearCacheForCategory:LMImageManagerCategoryAlbumImages];
	[self clearCacheForCategory:LMImageManagerCategoryArtistImages];
	
	[self beginDownloadingImagesForCategory:LMImageManagerCategoryAlbumImages];
	[self beginDownloadingImagesForCategory:LMImageManagerCategoryArtistImages];
}

- (SDImageCache*)imageCacheForCategory:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return self.albumImageCache;
		case LMImageManagerCategoryArtistImages:
			return self.artistImageCache;
	}
}

- (NSUInteger)sizeOfCacheForCategory:(LMImageManagerCategory)category {
	SDImageCache *imageCache = [self imageCacheForCategory:category];
	
	return [imageCache getSize];
}

- (NSUInteger)sizeOfAllCaches {
	return [self sizeOfCacheForCategory:LMImageManagerCategoryAlbumImages] + [self sizeOfCacheForCategory:LMImageManagerCategoryArtistImages];
}

- (void)clearCacheForCategory:(LMImageManagerCategory)category {
	SDImageCache *imageCache = [self imageCacheForCategory:category];
	
	[imageCache clearDisk];
	[imageCache cleanDisk];
	
	[imageCache clearMemory];
	
	[self clearBlacklistForCategory:category];
	
	[self notifyDelegatesOfCacheSizeChangeForCategory:category];
	[self notifyDelegatesOfImageCacheChangeForCategory:category];
}

- (NSString*)imageCacheKeyForMusicTrack:(LMMusicTrack*)representativeItem forCategory:(LMImageManagerCategory)category {
	LMMusicTrackPersistentID persistentID;
	NSString *categoryName = @"";
	
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			persistentID = representativeItem.albumPersistentID;
			categoryName = @"albumArtImages";
			break;
		case LMImageManagerCategoryArtistImages:
			persistentID = representativeItem.artistPersistentID;
			categoryName = @"artistImages";
			break;
	}
	
	NSString *namespaceKey = [NSString stringWithFormat:@"%@_id%lld", categoryName, persistentID];
	
	return namespaceKey;
}


- (NSString*)imageCacheKeyForMediaItem:(MPMediaItem*)representativeItem forCategory:(LMImageManagerCategory)category {
	LMMusicTrackPersistentID persistentID;
	NSString *categoryName = @"";
	
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			persistentID = representativeItem.albumPersistentID;
			categoryName = @"albumArtImages";
			break;
		case LMImageManagerCategoryArtistImages:
			persistentID = representativeItem.artistPersistentID;
			categoryName = @"artistImages";
			break;
	}
	
	NSString *namespaceKey = [NSString stringWithFormat:@"%@_id%lld", categoryName, persistentID];
	
	return namespaceKey;
}

- (void)imageNeedsDownloadingForMusicTrack:(LMMusicTrack*)representativeItem forCategory:(LMImageManagerCategory)category completion:(void(^)(BOOL needsDownloading))completionHandler {
	
	NSBlockOperation *albumArtOperation = [NSBlockOperation blockOperationWithBlock:^{
		//TODO: Fix this not being cancelled because of weak reference
		if(albumArtOperation.isCancelled){
			return;
		}
		UIImage *image = nil;
		switch(category){
			case LMImageManagerCategoryAlbumImages:
				image = [representativeItem uncorrectedAlbumArt];
				break;
			case LMImageManagerCategoryArtistImages:
				image = [[LMImageManager sharedImageManager] imageForMusicTrack:representativeItem withCategory:LMImageManagerCategoryArtistImages];
				break;
		}
		completionHandler(image == nil);
	}];
	
	[self.operationQueue addOperation:albumArtOperation];
}

- (void)downloadImageForMusicTrack:(LMMusicTrack*)randomTrack forCategory:(LMImageManagerCategory)category {
    BOOL isArtistCategory = (category == LMImageManagerCategoryArtistImages);
    
    NSString *typeString = isArtistCategory ? @"artist" : @"release";
    NSString *queryString = isArtistCategory ? randomTrack.artist : randomTrack.albumTitle;
    typeString = @"artist";
    queryString = @"adam lambert";
    if(!queryString){ //If the name doesn't exist, just reject it. Users gotta check their ID3 tags.
        [self setMusicTrack:randomTrack asBlacklisted:YES forCategory:category];
        return;
    }
    NSString *urlEncodedQueryString = [queryString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    
    NSDictionary *headers = @{
                              @"Content-Type": @"application/json",
                              @"User-Agent":@"LigniteMusic/1.0 +https://www.lignitemusic.com",
                              @"Authorization":@"Discogs key=PysouAgyWfodlbXkRrAq, secret=uPoAOoqKhwgkrPebIrxTktOHEyjgslBK"
                              };
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.discogs.com/database/search?q=%@&type=%@", urlEncodedQueryString, typeString];
    
    [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:urlString];
        [request setHeaders:headers];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // This is the asyncronous callback block
        NSInteger code = response.code;
        NSDictionary *responseHeaders = response.headers;
        UNIJsonNode *body = response.body;
        NSDictionary *searchJSONResult = body.JSONObject;
        NSData *rawBody = response.rawBody;
        
        if(code != 200){
            NSLog(@"There was an error downloading images for some reason %@.", [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
            return;
        }
        
        NSLog(@"Response from Discogs made Lignite Music smile. Let's do this.");
        
        NSArray *searchResultArray = [searchJSONResult objectForKey:@"results"];
        NSDictionary *searchResultObject = nil;
        
        if(searchResultArray.count > 0){
            searchResultObject = [searchResultArray objectAtIndex:0];
        }
        else{
            NSLog(@"For some reason, there were no results. Going to reject this one, boss.");
            return;
        }
        
        NSLog(@"Got search result %@", [searchResultObject objectForKey:@"title"]);
        
        NSString *resourceURL = [searchResultObject objectForKey:@"resource_url"];
        
        NSLog(@"Artist url is %@", resourceURL);
        
        [[UNIRest get:^(UNISimpleRequest *request) {
            [request setUrl:resourceURL];
            [request setHeaders:headers];
        }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
            // This is the asyncronous callback block
            NSInteger code = response.code;
            NSDictionary *responseHeaders = response.headers;
            UNIJsonNode *body = response.body;
            NSData *rawBody = response.rawBody;
            NSDictionary *finalResultJSONObject = body.JSONObject;
            
            NSArray *imagesObjectArray = [finalResultJSONObject objectForKey:@"images"];
            
            for(NSDictionary *imageObject in imagesObjectArray){
                NSString *imageType = [imageObject objectForKey:@"type"];
                NSString *imageURL = [imageObject objectForKey:@"uri"];
                if([imageType isEqualToString:@"primary"] && imageURL){
                    NSLog(@"Downloading %@", imageURL);
                    
                    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
                    [downloader downloadImageWithURL:[NSURL URLWithString:imageURL]
                                             options:kNilOptions
                                            progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                NSLog(@"%.02f%% complete", (float)receivedSize/(float)expectedSize * 100);
                                            }
                                           completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                               if(image && finished) {
                                                   LMImageManagerConditionLevel currentConditionLevel = [self conditionLevelForDownloadingForCategory:category];
                                                   
                                                   if(currentConditionLevel == LMImageManagerConditionLevelOptimal){
//                                                       NSLog(@"Done, now storing to %@.", imageCacheKey);
                                                       
//                                                       [[self imageCacheForCategory:category] storeImage:image forKey:imageCacheKey];
                                                       
//                                                       [self notifyDelegatesOfCacheSizeChangeForCategory:category];
//                                                       [self notifyDelegatesOfImageCacheChangeForCategory:category];
                                                       NSLog(@"Done :)");
                                                   }
                                                   else{
                                                       NSLog(@"Not storing, conditions aren't right.");
                                                   }
                                               }
                                           }];
                }
            }
            
            NSLog(@"Shitpost %ld %@ %@", code, response.headers, [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
        }];
        
        return;
    }];
    
//	NSError *error;
//	
//	//Prepare the contents of the search
//	NSString *typeOfSearch = @"";
//	NSString *imageNameSearchString = @"";
//	switch(category){
//		case LMImageManagerCategoryAlbumImages:
//			typeOfSearch = @"album";
//			imageNameSearchString = randomTrack.albumTitle;
//			
//			if(randomTrack.artist){
//				imageNameSearchString = [NSString stringWithFormat:@"%@ %@", randomTrack.albumTitle, randomTrack.artist];
//			}
//			break;
//		case LMImageManagerCategoryArtistImages:
//			typeOfSearch = @"artist";
//			imageNameSearchString = randomTrack.artist;
//			break;
//	}
//	
//	NSLog(@"Download search beginning an %@ image, with contents %@", typeOfSearch, imageNameSearchString);
//	
//	NSString *matchesString = [NSString stringWithFormat:@"%@matches", typeOfSearch];
//	
//	imageNameSearchString = [imageNameSearchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//	
//	//Prepare the API url
//	NSString *urlString = [NSString stringWithFormat:@"https://api.discogs.com/artists/%ld?method=%@.search&%@=%@&limit=%d&api_key=%@&format=json",
//                           1000000
//						   typeOfSearch, //For the method
//						   typeOfSearch, //For the variable name
//						   imageNameSearchString, //The actual search query
//						   LMLastFMItemsPerPageLimit, //The limit of items per page
//						   LMImageAPIKey]; //Our API key
//	
//	NSLog(@"%@", urlString);
//	
//	//Get the data from the API URL
//	NSURL *jsonURL = [NSURL URLWithString:urlString];
//	NSData *data = [NSData dataWithContentsOfURL:jsonURL];
//	if(!data){
//		return;
//	}
//	NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//
//	//Get the items of search results that were returned
//	NSArray *items = [[[jsonResponse objectForKey:@"results"] objectForKey:matchesString] objectForKey:typeOfSearch];
//	
//	//Loop through each one
//	for(int i = 0; i < items.count; i++){
//		NSDictionary *item = [items objectAtIndex:i];
//		
//		NSLog(@"%d Image name %@", i, [item objectForKey:@"name"]);
//		//Get the item's images (each have a different size)
//		NSArray *itemImages = [item objectForKey:@"image"];
//		
//		//Loop through each of those
//		for(int itemImageIndex = 0; itemImageIndex < [itemImages count]; itemImageIndex++){
//			//Get that image object
//			NSDictionary *itemImage = [itemImages objectAtIndex:itemImageIndex];
//			
//			NSString *itemImageURL = [itemImage objectForKey:@"#text"];
//			NSString *itemImageSize = [itemImage objectForKey:@"size"];
//			NSString *sizeRequired = @"extralarge";
//			
//			//Check if it's the size we need
//			if([itemImageSize isEqualToString:sizeRequired] && ![itemImageURL isEqualToString:@""]){
//				NSString *imageCacheKey = [self imageCacheKeyForMusicTrack:randomTrack forCategory:category];
//				
//				NSLog(@"Cache key %@", imageCacheKey);
//				
//				if([self highQualityImages]){
//					itemImageURL = [itemImageURL stringByReplacingOccurrencesOfString:@"/300x300" withString:@"/500x500"];
//					NSLog(@"High quality image being downloaded from %@.", itemImageURL);
//				}
//				else{
//					NSLog(@"Extra large image @ %@", itemImageURL);
//				}
//
//				//Good to download!
//				
//SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
//[downloader downloadImageWithURL:[NSURL URLWithString:itemImageURL]
//						 options:0
//						progress:^(NSInteger receivedSize, NSInteger expectedSize) {
////											NSLog(@"%.02f%% complete", (float)receivedSize/(float)expectedSize * 100);
//						}
//					   completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//						   if(image && finished) {
//							   LMImageManagerConditionLevel currentConditionLevel = [self conditionLevelForDownloadingForCategory:category];
//							   
//							   if(currentConditionLevel == LMImageManagerConditionLevelOptimal){
//								   NSLog(@"Done, now storing to %@.", imageCacheKey);
//								   
//								   [[self imageCacheForCategory:category] storeImage:image forKey:imageCacheKey];
//								   
//								   [self notifyDelegatesOfCacheSizeChangeForCategory:category];
//								   [self notifyDelegatesOfImageCacheChangeForCategory:category];
//							   }
//							   else{
//								   NSLog(@"Not storing, conditions aren't right.");
//							   }
//						   }
//					   }];
//				return;
//			}
//		}
//	}
//	
//	NSLog(@"Couldn't find anything, blacklisting.");
//	
//	[self setMusicTrack:randomTrack asBlacklisted:YES forCategory:category];
}

- (UIImage*)imageForMusicTrack:(LMMusicTrack*)musicTrack withCategory:(LMImageManagerCategory)category {
	return [[self imageCacheForCategory:category] imageFromDiskCacheForKey:[self imageCacheKeyForMusicTrack:musicTrack forCategory:category]];
}

- (UIImage*)imageForMediaItem:(MPMediaItem*)mediaItem withCategory:(LMImageManagerCategory)category {
	return [[self imageCacheForCategory:category] imageFromDiskCacheForKey:[self imageCacheKeyForMediaItem:mediaItem forCategory:category]];
}

- (void)downloadNextImageInQueue {
	__weak id weakSelf = self;
	
	double delayInSeconds = 1.0 / LMImageAPICallsPerSecondLimit;
	
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_global_queue(NSQualityOfServiceUtility, 0), ^(void){
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		LMImageManager *imageManager = strongSelf;
		
		NSTimeInterval currentDownloadTime = [[NSDate new] timeIntervalSince1970];
		NSTimeInterval lastDownloadTime = imageManager.lastImageDownloadTime;
		
		NSTimeInterval differenceInTime = currentDownloadTime-lastDownloadTime;
		
//		NSLog(@"Difference %f seconds between %f", differenceInTime, LMImageAPISecondsBetweenAPICalls);
		
		if(differenceInTime < LMImageAPISecondsBetweenAPICalls){
			NSLog(@"Attempting to make calls to fast! Rejecting.");
			return;
		}
		
		if(imageManager.trackDownloadQueue.count < 1){
			[imageManager.currentlyProcessingCategoryArray removeObject:@(LMImageManagerCategoryAlbumImages)];
			[imageManager.currentlyProcessingCategoryArray removeObject:@(LMImageManagerCategoryArtistImages)];
			return;
		}
		
		LMMusicTrack *musicTrack = [imageManager.trackDownloadQueue firstObject];
		LMImageManagerCategory category = (LMImageManagerCategory)[[imageManager.categoryDownloadQueue firstObject] integerValue];
		
		LMImageManagerConditionLevel currentConditionLevel = [imageManager conditionLevelForDownloadingForCategory:category];
		
		if(currentConditionLevel != LMImageManagerConditionLevelOptimal){
			[imageManager.trackDownloadQueue removeAllObjects];
			[imageManager.categoryDownloadQueue removeAllObjects];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageManager downloadIfNeededForCategory:category];
			});
			
			NSLog(@"Something happened! Halting downloads.");
			return;
		}
		
		if(imageManager.trackDownloadQueue.count > 0){
			[imageManager.trackDownloadQueue removeObjectAtIndex:0];
		}
		if(imageManager.categoryDownloadQueue.count > 0){
			[imageManager.categoryDownloadQueue removeObjectAtIndex:0];
		}
		
		
		[imageManager downloadImageForMusicTrack:musicTrack forCategory:category];
		
		NSLog(@"Next image download attempt: %@, with category %d.", musicTrack.albumTitle, category);
	
		if(imageManager.trackDownloadQueue.count > 0){
			[imageManager downloadNextImageInQueue];
		}
		
		imageManager.lastImageDownloadTime = currentDownloadTime;
	});
}

- (void)beginDownloadingImagesForCategory:(LMImageManagerCategory)category {
	NSLog(@"[LMImageManager]: Will begin the process for downloading images for category %d.", category);
	
	NSArray *collectionsAssociated = (category == LMImageManagerCategoryArtistImages) ? self.artistsCollection : self.albumsCollection;
	
	NSNumber *categoryNumber = @(category);
	
	[self.currentlyProcessingCategoryArray addObject:categoryNumber];
	
	NSLog(@"Processing %d.", category);
	
	for(int i = 0; i < collectionsAssociated.count; i++){
		LMMusicTrackCollection *collection = [collectionsAssociated objectAtIndex:i];
		LMMusicTrack *representativeTrack = collection.representativeItem;
		
		[self imageNeedsDownloadingForMusicTrack:representativeTrack
									 forCategory:category
									  completion:^(BOOL needsDownloading) {
//										  NSLog(@"%d %@ needs downloading: %d", i, representativeTrack.albumTitle, needsDownloading);
										  
										  //If it needs downloading, is not already in queue, and is not on the blacklist
										  if(needsDownloading
//											 && ![self.trackDownloadQueue containsObject:representativeTrack]
											 && ![self musicTrackIsOnBlacklist:representativeTrack forCategory:category])
										  {
											  if(representativeTrack && categoryNumber){
												  [self.trackDownloadQueue addObject:representativeTrack];
												  [self.categoryDownloadQueue addObject:categoryNumber];
											  }
										  }
										  
										  //Since this should mean we're at least part way through the list (since its asynchronus), we can know with fairly high confidence that there will be some items in the queue, so we can start downloading them since we don't actually start downloading instantly.
										  if(i == collectionsAssociated.count-1){
											  [self downloadNextImageInQueue];
										  }
									  }];
	}
}

- (void)downloadIfNeededForCategory:(LMImageManagerCategory)category {
	LMImageManagerConditionLevel currentConditionLevel = [self conditionLevelForDownloadingForCategory:category];
	
	if([self.currentlyProcessingCategoryArray containsObject:@(category)]){
		NSLog(@"Already processing %d, rejecting.", category);
		return;
	}
	
	switch(currentConditionLevel){
		case LMImageManagerConditionLevelNever:
			break;
		case LMImageManagerConditionLevelSuboptimal: {
			[self launchPermissionRequestOnView:self.viewToDisplayAlertsOn
											forCategory:category
								  withCompletionHandler:^(LMImageManagerPermissionStatus permissionStatus) {
									  if(permissionStatus == LMImageManagerPermissionStatusAuthorized) {
										  [self beginDownloadingImagesForCategory:category];
									  }
								  }];
			break;
		}
		case LMImageManagerConditionLevelOptimal:
			[self beginDownloadingImagesForCategory:category];
			break;
	}
}

- (BOOL)musicTrackIsOnBlacklist:(LMMusicTrack*)musicTrack forCategory:(LMImageManagerCategory)category {
	NSString *cacheKey = [self imageCacheKeyForMusicTrack:musicTrack forCategory:category];
	NSString *blacklistKey = [NSString stringWithFormat:@"blacklist_%@", cacheKey];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	return [userDefaults objectForKey:blacklistKey] ? YES : NO;
}

- (void)setMusicTrack:(LMMusicTrack*)musicTrack asBlacklisted:(BOOL)blacklisted forCategory:(LMImageManagerCategory)category {
	NSString *cacheKey = [self imageCacheKeyForMusicTrack:musicTrack forCategory:category];
	NSString *blacklistKey = [NSString stringWithFormat:@"blacklist_%@", cacheKey];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if(blacklisted){
		[userDefaults setBool:YES forKey:blacklistKey];
	}
	else{
		[userDefaults setNilValueForKey:blacklistKey];
	}
	
	[userDefaults synchronize];
}

- (void)clearBlacklistForCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSArray<NSString*> *allKeys = [[userDefaults dictionaryRepresentation] allKeys];
	
	NSString *categoryName = @"";
	
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			categoryName = @"albumArtImages";
			break;
		case LMImageManagerCategoryArtistImages:
			categoryName = @"artistImages";
			break;
	}
	
	for(int i = 0; i < allKeys.count; i++){
		NSString *key = [allKeys objectAtIndex:i];
		if([key containsString:categoryName]){
			[userDefaults removeObjectForKey:key];
		}
	}
	
	[userDefaults synchronize];
}


/**
 *
 * END IMAGE DOWNLOADING CODE AND BEGIN PERMISSION AND CONDITION LEVEL RELATED CODE
 *
 */

- (LMImageManagerConditionLevel)conditionLevelForDownloadingForCategory:(LMImageManagerCategory)category {
	if(![self hasInternetConnection]){
		return LMImageManagerConditionLevelNever;
	}
	
	LMImageManagerPermissionStatus permissionStatusForCategory = [self permissionStatusForCategory:category];
		
	switch(permissionStatusForCategory){
		case LMImageManagerPermissionStatusDenied:
			return LMImageManagerConditionLevelNever;
			
		case LMImageManagerPermissionStatusNotDetermined:
		case LMImageManagerPermissionStatusAuthorized:
			break;
	}
	
	LMImageManagerPermissionStatus permissionStatusForLowStorage = [self permissionStatusForSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionLowStorage];
	
	if([self storageSpaceLowForCategory:category]){
		switch(permissionStatusForLowStorage) {
			case LMImageManagerPermissionStatusNotDetermined:
				return LMImageManagerConditionLevelSuboptimal;
			case LMImageManagerPermissionStatusDenied:
				return LMImageManagerConditionLevelNever;
			case LMImageManagerPermissionStatusAuthorized:
				break;
		}
	}
	
	LMImageManagerPermissionStatus permissionStatusForCellularData = [self permissionStatusForSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionCellularData];
	
	if([self isOnCellularData]){
		switch(permissionStatusForCellularData) {
			case LMImageManagerPermissionStatusNotDetermined:
				return LMImageManagerConditionLevelSuboptimal;
			case LMImageManagerPermissionStatusDenied:
				return LMImageManagerConditionLevelNever;
			case LMImageManagerPermissionStatusAuthorized:
				break;
		}
	}
	
	//Conditions are optimal and the user has not explicitly denied us from downloading the images, so set it to authorized
	[self setPermissionStatus:LMImageManagerPermissionStatusAuthorized forCategory:category];
	
	return LMImageManagerConditionLevelOptimal;
}

/**
 Gets the key associated for an image permission. Should be used for NSUserDefaults and SDWebImage disk cache namespace.

 @param category The permission to get the key for.
 @return The category's key.
 */
+ (NSString*)keyForPermission:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return @"LMImageManagerPermissionAlbumImages";
		case LMImageManagerCategoryArtistImages:
			return @"LMImageManagerPermissionArtistImages";
	}
}

- (LMImageManagerPermissionStatus)permissionStatusForCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *categoryKey = [LMImageManager keyForPermission:category];
	
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	if([userDefaults objectForKey:categoryKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:categoryKey];
	}
	
	return permissionStatus;
}

- (void)setPermissionStatus:(LMImageManagerPermissionStatus)status forCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *permissionStatusKey = [LMImageManager keyForPermission:category];
	
	[userDefaults setInteger:(NSInteger)status forKey:permissionStatusKey];
	[userDefaults synchronize];
}

// http://stackoverflow.com/questions/5712527/how-to-detect-total-available-free-disk-space-on-the-iphone-ipad-device
+ (uint64_t)diskBytesFree {
	uint64_t totalSpace = 0;
	uint64_t totalFreeSpace = 0;
	NSError *error = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
	if (dictionary) {
		NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
		NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
		totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
		totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
	}
	else {
		NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
	}
	
	return totalFreeSpace;
}

- (NSUInteger)itemCountForCategory:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return self.albumsCollection.count;
		case LMImageManagerCategoryArtistImages:
			return self.artistsCollection.count;
	}
}

- (uint64_t)spaceRequiredForCategory:(LMImageManagerCategory)category {
	//High quality images are about 10x the space of normal images
	return [self itemCountForCategory:category]*AVERAGE_IMAGE_SIZE_IN_BYTES*([self highQualityImages] ? 10 : 1);
}

- (float)freeSpacePercentageUsedIfDownloadedCategory:(LMImageManagerCategory)category {
	uint64_t freeSpace = [LMImageManager diskBytesFree];
	uint64_t spaceRequired = [self spaceRequiredForCategory:category];
	
	return ((float)spaceRequired)/((float)freeSpace);
}

- (BOOL)storageSpaceLowForCategory:(LMImageManagerCategory)category {
	return [self freeSpacePercentageUsedIfDownloadedCategory:category] >= 0.50;
}

- (BOOL)isOnCellularData {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status == ReachableViaWWAN;
}

- (BOOL)hasInternetConnection {
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status != NotReachable;
}

- (void)wifiReactivated {
	BOOL hasInternetConnection = [self hasInternetConnection];
	
	if(hasInternetConnection){
		[self downloadIfNeededForCategory:LMImageManagerCategoryArtistImages]; //Crash 3
		[self downloadIfNeededForCategory:LMImageManagerCategoryAlbumImages];
	}
}

- (void)reachabilityChanged:(NSNotification*)notification {
	BOOL hasInternetConnection = [self hasInternetConnection];
	BOOL timerExists = self.reachabilityChangedTimer || self.reachabilityChangedTimer.valid;
	
	if(timerExists){
		[self.reachabilityChangedTimer invalidate];
		self.reachabilityChangedTimer = nil;
	}
	
	if(hasInternetConnection){ //Shoutout to Ms. Mac's famous "Wifive" ;)
		self.reachabilityChangedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																		 target:self
																	   selector:@selector(wifiReactivated)
																	   userInfo:nil
																		repeats:NO];
	}
}

- (NSString*)storageKeyForSpecialDownloadPermission:(LMImageManagerSpecialDownloadPermission)specialDownloadPermission {
	switch(specialDownloadPermission){
		case LMImageManagerSpecialDownloadPermissionLowStorage:
			return @"LMImageManagerSpecialDownloadPermissionLowStorage";
		case LMImageManagerSpecialDownloadPermissionCellularData:
			return @"LMImageManagerSpecialDownloadPermissionCellularData";
	}
}

- (LMImageManagerPermissionStatus)permissionStatusForSpecialDownloadPermission:(LMImageManagerSpecialDownloadPermission)specialDownloadPermission {
	NSString *downloadPermissionKey = [self storageKeyForSpecialDownloadPermission:specialDownloadPermission];
	
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:downloadPermissionKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:downloadPermissionKey];
	}
	
	return permissionStatus;
}

- (void)setPermissionStatus:(LMImageManagerPermissionStatus)permissionStatus forSpecialDownloadPermission:(LMImageManagerSpecialDownloadPermission)specialDownloadPermission {
	
	NSString *downloadPermissionKey = [self storageKeyForSpecialDownloadPermission:specialDownloadPermission];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:(NSInteger)permissionStatus forKey:downloadPermissionKey];
	[userDefaults synchronize];
}

- (NSString*)permissionRequestDescriptionStringForCategory:(LMImageManagerCategory)category {
	BOOL storageSpaceLow = [self storageSpaceLowForCategory:category];
	BOOL isOnCellularData = [self isOnCellularData];
	
	//Tells the user why the images won't automatically download
	NSMutableString *problemsString = [NSMutableString stringWithString:@""];
	
	if(storageSpaceLow){
		problemsString = [NSMutableString stringWithString:NSLocalizedString(@"YouAreLowOnStorage", nil)];
	}
	if(isOnCellularData){
		if(storageSpaceLow){
			[problemsString appendString:NSLocalizedString(@"SpaceAndSpace", nil)];
		}
		[problemsString appendString:NSLocalizedString(@"YouAreOnData", nil)];
	}
	
	//The string which describes which types of images are being downloaded
	NSString *ofYourTypeString = @"";
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			ofYourTypeString = @"OfYourAlbums";
			break;
		case LMImageManagerCategoryArtistImages:
			ofYourTypeString = @"OfYourArtists";
			break;
	}
	
	NSString *descriptionString = [NSString stringWithFormat:NSLocalizedString(@"ImagesDownloadWarningDescription", nil),
								   NSLocalizedString(ofYourTypeString, nil),
								   problemsString,
								   (float)[self spaceRequiredForCategory:category]/1000000.0,
								   storageSpaceLow ? [NSString stringWithFormat:NSLocalizedString(@"AboutXOfYourStorage", nil), ([self freeSpacePercentageUsedIfDownloadedCategory:category])*100.0] : @"",
								   NSLocalizedString(@"DownloadAnyway", nil),
								   NSLocalizedString(@"DontDownload", nil)];
	
	return descriptionString;
}

- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler {
	
	NSString *titleString = @"";
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			titleString = @"AlbumImagesTitle";
			break;
		case LMImageManagerCategoryArtistImages:
			titleString = @"ArtistImagesTitle";
			break;
	}
	
	BOOL storageSpaceLow = [self storageSpaceLowForCategory:category];
	BOOL isOnCellularData = [self isOnCellularData];
	
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	
	alertView.title = NSLocalizedString(titleString, nil);
	alertView.body = [self permissionRequestDescriptionStringForCategory:category];
	alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
	alertView.alertOptionTitles = @[NSLocalizedString(@"DontDownload", nil), NSLocalizedString(@"DownloadAnyway", nil)];
	
	[alertView launchOnView:view withCompletionHandler:^(NSUInteger optionSelected) {
		LMImageManagerPermissionStatus permissionStatus = (optionSelected == 1) ? LMImageManagerPermissionStatusAuthorized : LMImageManagerPermissionStatusDenied;
		
		completionHandler(permissionStatus);
		
		if(storageSpaceLow){
			[self setPermissionStatus:permissionStatus forSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionLowStorage];
		}
		if(isOnCellularData){
			[self setPermissionStatus:permissionStatus forSpecialDownloadPermission:LMImageManagerSpecialDownloadPermissionCellularData];
		}
	}];
}

/**
 *
 * END PERMISSION AND CONDITION LEVEL RELATED CODE
 *
 */

@end
