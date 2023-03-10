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
#import "MBProgressHUD.h"
#import "LMImageManager.h"
#import "LMColour.h"
#import "LMAlertViewController.h"
#import "LMReachability.h"
#import "LMMusicPlayer.h"
#import "LMSettings.h"
#import "NSTimer+Blocks.h"
#import "LMWarningManager.h"
#import "LMAnswers.h"
@import SDWebImage;

/**
 The estimated average size of an image from LastFM in bytes.

 @return The estimated average.
 */
#define AVERAGE_IMAGE_SIZE_IN_BYTES 110000

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

@interface LMImageManager() <LMWarningDelegate>

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

/**
 The last reported amount of available API calls which we can still use.
 */
@property NSInteger lastReportedAmountOfAvailableAPICalls;

/**
 The time when the amount of API calls available was reported.
 */
@property NSTimeInterval timeOfLastReportedAmountOfAvailableAPICalls;

/**
 Whether or not the image manager is currently downloading images.
 */
@property BOOL downloadingImages;

/**
 The warning manager for displaying progress of downloads.
 */
@property LMWarningManager *warningManager;

/**
 The warning for the download progress for the warning bar.
 */
@property LMWarning *downloadProgressWarning;

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
		sharedImageManager.warningManager = [LMWarningManager sharedWarningManager];
		sharedImageManager.downloadProgressWarning = [LMWarning warningWithText:@"Searching..." priority:LMWarningPriorityLow];
		sharedImageManager.downloadProgressWarning.delegate = sharedImageManager;
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
    return NO;
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

- (void)clearAllCaches {
	[self clearCacheForCategory:LMImageManagerCategoryArtistImages];
	[self clearCacheForCategory:LMImageManagerCategoryAlbumImages];
}

- (void)clearCacheForCategory:(LMImageManagerCategory)category {
	SDImageCache *imageCache = [self imageCacheForCategory:category];
	
	[imageCache deleteOldFilesWithCompletionBlock:nil];
	[imageCache clearDiskOnCompletion:nil];
	
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
	
	
	__block NSBlockOperation *albumArtOperation = [NSBlockOperation blockOperationWithBlock:^{
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
		
		BOOL imageExists = image ? YES : NO;
		
		if([[LMImageManager sharedImageManager] downloadPermissionStatus] == LMImageManagerPermissionStatusDenied){
			completionHandler(NO);
			albumArtOperation = nil;
			return;
		}
		
		completionHandler(!imageExists);
		
		albumArtOperation = nil;
	}];
	
	[self.operationQueue addOperation:albumArtOperation];
}

- (void)downloadImageForMusicTrack:(LMMusicTrack*)randomTrack forCategory:(LMImageManagerCategory)category {
//    LMMusicTrack *randomTrack = nil;
//    LMImageManagerCategory category = LMImageManagerCategoryArtistImages;
    
    BOOL isArtistCategory = (category == LMImageManagerCategoryArtistImages);
    
    NSString *typeString = isArtistCategory ? @"artist" : @"release";
	
	NSMutableString *albumMutableQueryString = [NSMutableString new];
	if(randomTrack.artist){
		[albumMutableQueryString appendString:[NSString stringWithFormat:@"%@ ", randomTrack.artist]];
	}
	if(randomTrack.albumTitle){
		[albumMutableQueryString appendString:randomTrack.albumTitle];
	}
	else{
		albumMutableQueryString = nil;
	}
	
	NSString *albumQueryString = albumMutableQueryString ? [NSString stringWithString:albumMutableQueryString] : nil;
	
    NSString *queryString = isArtistCategory ? randomTrack.artist : albumQueryString;
    //    typeString = @"artist";
    //    queryString = @"chiddy bang";
    if(!queryString){ //If the name doesn't exist, just reject it. Users gotta check their ID3 tags.
        [self setMusicTrack:randomTrack asBlacklisted:YES forCategory:category];
        return;
    }
    NSString *urlEncodedQueryString = [queryString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
	
	NSString *authHeader = [NSString stringWithFormat:@"Discogs key=%@, secret=%@", LMImageAPIKey, LMImageAPISecret];
    
    NSDictionary *headers = @{
                              @"Content-Type": @"application/json",
                              @"User-Agent":@"LigniteMusic/1.0 +https://www.lignitemusic.com",
                              @"Authorization":authHeader
                              };
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.discogs.com/database/search?q=%@&type=%@", urlEncodedQueryString, typeString];
	
	NSLog(@"Searching for %@", urlString);
    
    [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:urlString];
        [request setHeaders:headers];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // This is the asyncronous callback block
        NSInteger code = response.code;
        UNIJsonNode *body = response.body;
        NSDictionary *searchJSONResult = body.JSONObject;
        NSData *rawBody = response.rawBody;
        
        if(code != 200){
            NSLog(@"There was an error downloading images for some reason %@.", [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
            return;
        }
        
//        NSLog(@"First response shitpost %ld %@", code, [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
		
        NSArray *searchResultArray = [searchJSONResult objectForKey:@"results"];
        NSDictionary *searchResultObject = nil;
        
        if(searchResultArray.count > 0){
            searchResultObject = [searchResultArray objectAtIndex:0];
        }
        else{
            NSLog(@"For some reason, there were no results. Going to reject and blacklist this one, boss.");
                    
            [self setMusicTrack:randomTrack asBlacklisted:YES forCategory:category];

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
			
            if(code != 200){
                NSLog(@"There was an error trying to get the final result object, stopping");
                return;
            }
            
//            NSLog(@"Second response shitpost %ld %@", code, [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
			
            
            NSDictionary *finalResultJSONObject = body.JSONObject;
            NSInteger amountOfCallsLeft = [[responseHeaders objectForKey:@"X-Discogs-Ratelimit-Remaining"] integerValue];
            
            self.lastReportedAmountOfAvailableAPICalls = amountOfCallsLeft;
            self.timeOfLastReportedAmountOfAvailableAPICalls = [[NSDate date] timeIntervalSince1970];
            
            NSLog(@"Amount of calls left %ld", amountOfCallsLeft);
            
            NSArray *imagesObjectArray = [finalResultJSONObject objectForKey:@"images"];
            
            BOOL hasPrimaryImage = NO;
            for(NSDictionary *imageObject in imagesObjectArray){
                if([[imageObject objectForKey:@"type"] isEqualToString:@"primary"]){
                    hasPrimaryImage = YES;
                    break;
                }
            }
			
			if(imagesObjectArray){
				for(NSDictionary *imageObject in imagesObjectArray){
					NSString *imageType = [imageObject objectForKey:@"type"];
					NSString *imageURL = [imageObject objectForKey:@"uri"];
					//The image URL must exist and not be a blank string, and if the array has a primary image object, use that, otherwise use secondary
					if(imageURL && ![imageURL isEqualToString:@""] && ((hasPrimaryImage && [imageType isEqualToString:@"primary"]) || !hasPrimaryImage)){
						NSLog(@"Downloading %@", imageURL);
						
						SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
						[downloader downloadImageWithURL:[NSURL URLWithString:imageURL]
												 options:kNilOptions
												progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
		//                                                NSLog(@"%.02f%% complete", (CGFloat)receivedSize/(CGFloat)expectedSize * 100);
												}
											   completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
												   if(image && finished) {
													   LMImageManagerConditionLevel currentConditionLevel = [self conditionLevelForDownloading];
													   
													   if(currentConditionLevel == LMImageManagerConditionLevelOptimal){
														   //Calculate which is smaller, between width/height
														   BOOL widthIsSmaller = (image.size.width < image.size.height);
														   //Figure out the smaller and larger size based off of that
														   CGFloat smallerSize = widthIsSmaller ? image.size.width : image.size.height;
														   CGFloat largerSize = widthIsSmaller ? image.size.height : image.size.width;
														   //Figure out the CGPoint offset in that according axis to center it
														   CGFloat offsetOriginPoint = (largerSize/2) - (smallerSize/2);
														   //Create the point
														   CGRect newCropRect = CGRectMake(widthIsSmaller ? 0 : offsetOriginPoint, widthIsSmaller ? offsetOriginPoint : 0, smallerSize, smallerSize);
														   
														   //Create the image
														   CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], newCropRect);
														   UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
														   CGImageRelease(imageRef);
														   
														   
														   NSString *imageCacheKey = [self imageCacheKeyForMusicTrack:randomTrack forCategory:category];
														   NSLog(@"Done, now storing to %@.", imageCacheKey);
														   
														   [[self imageCacheForCategory:category] storeImage:croppedImage
																									  forKey:imageCacheKey
																								  completion:nil];
														   
														   [self notifyDelegatesOfCacheSizeChangeForCategory:category];
														   [self notifyDelegatesOfImageCacheChangeForCategory:category];
														   
														   
														   //                                                       NSLog(@"Done. Crop rect %@, new size %@.", NSStringFromCGRect(newCropRect), NSStringFromCGSize(croppedImage.size));
														   //
														   //                                                       dispatch_sync(dispatch_get_main_queue(), ^{
														   //                                                           callback(croppedImage);
														   //                                                       });
													   }
													   else{
														   NSLog(@"Not storing, conditions aren't right.");
													   }
												   }
											   }];
						break;
					}
				}
			}
			else{
				NSLog(@"Even though the data was there, images were not. I have to blacklist this track, sorry.");
				[self setMusicTrack:randomTrack asBlacklisted:YES forCategory:category];
			}
            
            //            NSLog(@"Shitpost %ld %@ %@", code, response.headers, [[NSString alloc] initWithData:rawBody encoding:NSUTF8StringEncoding]);
        }];
        
        return;
    }];
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
    
    NSTimeInterval timeNow = [[NSDate new] timeIntervalSince1970];
    CGFloat timeDifference = timeNow-self.timeOfLastReportedAmountOfAvailableAPICalls;
    //If it's been less than 70 seconds since an amount of API calls available went below 20, don't proceed and hold back
    //the next attempt for 30 seconds, and retry then.
    if(timeDifference < 70 && self.lastReportedAmountOfAvailableAPICalls < 20){
        NSLog(@"We're close to hitting the limit of API calls, let's back that tush up.");
        [NSTimer scheduledTimerWithTimeInterval:30 block:^{
			self.lastReportedAmountOfAvailableAPICalls = 30;
			self.timeOfLastReportedAmountOfAvailableAPICalls = 0;
			
            [self downloadNextImageInQueue];
        } repeats:NO];
        return;
	}
	
	self.downloadingImages = YES;
	
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
		
		if(differenceInTime < LMImageAPISecondsBetweenAPICalls){
			NSLog(@"Attempting to make calls to fast! Rejecting.");
			return;
		}
		
		if(imageManager.trackDownloadQueue.count < 1){ //Complete :)
			[imageManager.currentlyProcessingCategoryArray removeObject:@(LMImageManagerCategoryAlbumImages)];
			[imageManager.currentlyProcessingCategoryArray removeObject:@(LMImageManagerCategoryArtistImages)];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageManager.warningManager removeWarning:imageManager.downloadProgressWarning];
			});
			return;
		}
		
		LMMusicTrack *musicTrack = [imageManager.trackDownloadQueue firstObject];
		LMImageManagerCategory category = (LMImageManagerCategory)[[imageManager.categoryDownloadQueue firstObject] integerValue];
		
		LMImageManagerConditionLevel currentConditionLevel = [imageManager conditionLevelForDownloading];
		
		if(currentConditionLevel != LMImageManagerConditionLevelOptimal){
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageManager.warningManager removeWarning:imageManager.downloadProgressWarning];
			});
			
			imageManager.downloadingImages = NO;
			
//			[imageManager.trackDownloadQueue removeAllObjects];
//			[imageManager.categoryDownloadQueue removeAllObjects];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageManager downloadIfNeededForCategory:category];
			});
			
			NSLog(@"Something happened! Halting downloads.");
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			imageManager.downloadProgressWarning.text = [NSString stringWithFormat:NSLocalizedString(@"DownloadingImages", nil), imageManager.trackDownloadQueue.count];
			[imageManager.warningManager addWarning:imageManager.downloadProgressWarning];
		});

		if(imageManager.trackDownloadQueue.count > 0){
			[imageManager.trackDownloadQueue removeObjectAtIndex:0];
		}
		if(imageManager.categoryDownloadQueue.count > 0){
			[imageManager.categoryDownloadQueue removeObjectAtIndex:0];
		}
		
        NSLog(@"Next image download attempt: %@, with category %d.", musicTrack.artist, category);
		
		[imageManager downloadImageForMusicTrack:musicTrack forCategory:category];
	
		if(imageManager.trackDownloadQueue.count > 0){
			[imageManager downloadNextImageInQueue];
		}
		else{
			imageManager.downloadingImages = NO;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[imageManager.warningManager removeWarning:imageManager.downloadProgressWarning];
			});
		}
		
		imageManager.lastImageDownloadTime = currentDownloadTime;
	});
}

- (void)beginDownloadingImagesForCategory:(LMImageManagerCategory)category {
//	return;
//#warning image downloading is disabled
	
	NSLog(@"[LMImageManager]: Will begin the process for downloading images for category %d.", category);
	
	NSArray *collectionsAssociated = (category == LMImageManagerCategoryArtistImages) ? self.artistsCollection : self.albumsCollection;
	
	NSNumber *categoryNumber = @(category);
	
	[self.currentlyProcessingCategoryArray addObject:categoryNumber];
	
	NSLog(@"Processing category %d (%ld items).", category, collectionsAssociated.count);
	
	if(self.trackDownloadQueue.count > 0){ //Already processed queue, resume downloads
		dispatch_async(dispatch_get_main_queue(), ^{
			self.downloadProgressWarning.text = [NSString stringWithFormat:NSLocalizedString(@"DownloadingImages", nil), self.trackDownloadQueue.count];
			[self.warningManager addWarning:self.downloadProgressWarning];
		});
		
		if(!self.downloadingImages){ //Only restart once
			[self downloadNextImageInQueue];
		}
		return;
	}
	
//	int countUsing = (int)MIN(10, collectionsAssociated.count);
	int countUsing = (int)collectionsAssociated.count;
	
	for(int i = 0; i < countUsing; i++){
		[NSTimer scheduledTimerWithTimeInterval:0.05*i block:^{ //I have no clue why on iOS 11 there was a lockup, where when more than 60 asyncs were created requesting album art it would lock up. Fuck.
			LMMusicTrackCollection *collection = [collectionsAssociated objectAtIndex:i];
			LMMusicTrack *representativeTrack = collection.representativeItem;
			
			[self imageNeedsDownloadingForMusicTrack:representativeTrack
										 forCategory:category
										  completion:^(BOOL needsDownloading) {
											  if([self downloadPermissionStatus] == LMImageManagerPermissionStatusDenied){
												  [self.trackDownloadQueue removeAllObjects];
												  [self.categoryDownloadQueue removeAllObjects];
												  return;
											  }
											  //										  NSLog(@"%d %@ needs downloading: %d", i, representativeTrack.albumTitle, needsDownloading);
											  
											  //If it needs downloading, is not already in queue, and is not on the blacklist
											  if(needsDownloading
												 && ![self musicTrackIsOnBlacklist:representativeTrack forCategory:category])
											  {
												  if(representativeTrack != nil && categoryNumber != nil){
													  [self.trackDownloadQueue addObject:representativeTrack];
													  [self.categoryDownloadQueue addObject:categoryNumber];
												  }
											  }
											  
											  //Since this should mean we're at least part way through the list (since it's asynchronus), we can know with fairly high confidence that there will be some items in the queue, so we can start downloading them since we don't actually start downloading instantly.
											  if(i == countUsing-1 && !self.downloadingImages){
												  [self downloadNextImageInQueue];
											  }
										  }];
		} repeats:NO];
	}
}

- (void)notifyDelegatesOfConditionLevel:(LMImageManagerConditionLevel)conditionLevel {
	for(id<LMImageManagerDelegate> delegate in self.delegates){
		if([delegate respondsToSelector:@selector(imageDownloadConditionLevelChanged:)]){
			[delegate imageDownloadConditionLevelChanged:conditionLevel];
		}
	}
}

- (void)downloadIfNeededForAllCategories {
	[self downloadIfNeededForCategory:LMImageManagerCategoryArtistImages];
	[self downloadIfNeededForCategory:LMImageManagerCategoryAlbumImages];
}

- (void)downloadIfNeededForCategory:(LMImageManagerCategory)category {
	LMImageManagerConditionLevel currentConditionLevel = [self conditionLevelForDownloading];
	
	if([self.currentlyProcessingCategoryArray containsObject:@(category)]){
		NSLog(@"Already processing %d, rejecting.", category);
		return;
	}
	
//	currentConditionLevel = LMImageManagerConditionLevelSuboptimal;
	
	switch(currentConditionLevel){
		case LMImageManagerConditionLevelNever:
			break;
		case LMImageManagerConditionLevelSuboptimal: {
			//This level will put an alert on the system warning bar (core view controller handles it)
			break;
		}
		case LMImageManagerConditionLevelOptimal:
			[self beginDownloadingImagesForCategory:category];
			break;
	}
	
	[self notifyDelegatesOfConditionLevel:currentConditionLevel];
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

- (LMImageManagerConditionLevel)conditionLevelForDownloading {
	if(![self hasInternetConnection]){
		return LMImageManagerConditionLevelNever;
	}
	
	LMImageManagerPermissionStatus permissionStatusForCategory = [self downloadPermissionStatus];
		
	switch(permissionStatusForCategory){
		case LMImageManagerPermissionStatusDenied:
			return LMImageManagerConditionLevelNever;
		case LMImageManagerPermissionStatusNotDetermined:
		case LMImageManagerPermissionStatusAuthorized:
			break;
	}
	
	LMImageManagerPermissionStatus explicitPermissionStatus = [self explicitPermissionStatus];
	
	if([self storageSpaceLowForCategory:LMImageManagerCategoryAlbumImages]
	   || [self storageSpaceLowForCategory:LMImageManagerCategoryArtistImages]
	   || [self isOnCellularData]){
		switch(explicitPermissionStatus) {
			case LMImageManagerPermissionStatusNotDetermined:
				return LMImageManagerConditionLevelSuboptimal;
			case LMImageManagerPermissionStatusDenied:
				return LMImageManagerConditionLevelNever;
			case LMImageManagerPermissionStatusAuthorized:
				break;
		}
	}
	
	//Conditions are optimal and the user has not explicitly denied us from downloading the images, so set it to authorized
	[self setDownloadPermissionStatus:LMImageManagerPermissionStatusAuthorized];
	
	return LMImageManagerConditionLevelOptimal;
}

- (LMImageManagerPermissionStatus)downloadPermissionStatus {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	if([userDefaults objectForKey:LMImageManagerDownloadPermissionKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:LMImageManagerDownloadPermissionKey];
	}
	
	return permissionStatus;
}

- (void)setDownloadPermissionStatus:(LMImageManagerPermissionStatus)status {
	LMImageManagerPermissionStatus previousStatus = [self downloadPermissionStatus];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:(NSInteger)status forKey:LMImageManagerDownloadPermissionKey];
	[userDefaults synchronize];
	
	if(previousStatus != status){
		[self notifyDelegatesOfConditionLevel:[self conditionLevelForDownloading]];
	}
}

// http://stackoverflow.com/questions/5712527/how-to-detect-total-available-free-disk-space-on-the-iphone-ipad-device
+ (uint64_t)diskBytesFree {
	uint64_t totalFreeSpace = 0;
	NSError *error = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
	
	if (dictionary) {
		NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
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

- (CGFloat)freeSpacePercentageUsedIfDownloadedCategory:(LMImageManagerCategory)category {
	uint64_t freeSpace = [LMImageManager diskBytesFree];
	uint64_t spaceRequired = [self spaceRequiredForCategory:category];
	
	return ((CGFloat)spaceRequired)/((CGFloat)freeSpace);
}

- (BOOL)storageSpaceLowForCategory:(LMImageManagerCategory)category {
	return [self freeSpacePercentageUsedIfDownloadedCategory:category] >= 0.50;
}

- (BOOL)isOnCellularData {
//	return YES;
	
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
		[self downloadIfNeededForAllCategories];
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

- (LMImageManagerPermissionStatus)explicitPermissionStatus {
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMImageManagerExplicitPermissionKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:LMImageManagerExplicitPermissionKey];
	}
	
	return permissionStatus;
}

- (void)setExplicitPermissionStatus:(LMImageManagerPermissionStatus)permissionStatus {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:(NSInteger)permissionStatus forKey:LMImageManagerExplicitPermissionKey];
	[userDefaults synchronize];
}

- (NSString*)permissionRequestDescriptionString {
	BOOL storageSpaceLow = [self storageSpaceLowForCategory:LMImageManagerCategoryArtistImages] || [self storageSpaceLowForCategory:LMImageManagerCategoryAlbumImages];
	BOOL isOnCellularData = [self isOnCellularData] || true;
	
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
	
	NSString *descriptionString = [NSString stringWithFormat:NSLocalizedString(@"ImagesDownloadWarningDescription", nil),
								   
								   problemsString,
								   
								   (CGFloat)([self spaceRequiredForCategory:LMImageManagerCategoryAlbumImages]+[self spaceRequiredForCategory:LMImageManagerCategoryArtistImages])/1000000.0,
								   
								   storageSpaceLow
								    ? [NSString stringWithFormat:NSLocalizedString(@"AboutXOfYourStorage", nil), ([self freeSpacePercentageUsedIfDownloadedCategory:LMImageManagerCategoryAlbumImages] + [self freeSpacePercentageUsedIfDownloadedCategory:LMImageManagerCategoryArtistImages])*100.0]
									: @"",
								   
								   NSLocalizedString(@"DownloadAnyway", nil),
								   
								   NSLocalizedString(@"DontDownload", nil)];
	
	return descriptionString;
}

- (void)displayDownloadingAuthorizationAlertWithCompletionHandler:(void(^)(BOOL authorized))completionHandler; {
	LMImageManagerPermissionStatus currentStatus = [self downloadPermissionStatus];
	
	NSString *titleKey = @"ImagesDownloadWarningTitle";
	NSString *youCanKey = @"";
	NSString *enableButtonKey = @"";
	NSString *disableButtonKey = @"";
	NSString *currentStatusText = @"";
	switch(currentStatus){
		case LMImageManagerPermissionStatusNotDetermined:
		case LMImageManagerPermissionStatusDenied:
			youCanKey = @"YouCanTurnOnTo";
			enableButtonKey = @"Enable";
			disableButtonKey = @"KeepDisabled";
			currentStatusText = NSLocalizedString(@"YouCurrentlyHaveThisFeatureOff", nil);
			break;
		case LMImageManagerPermissionStatusAuthorized:
			youCanKey = @"YouCanTurnOffTo";
			enableButtonKey = @"KeepEnabled";
			disableButtonKey = @"ClearCacheAndDisable";
			currentStatusText = [NSString stringWithFormat:NSLocalizedString(@"UsingXOfYourStorage", nil), (CGFloat)[self sizeOfAllCaches]/1000000];
			break;
	}
	
	NSString *enableButtonAccessibilityLabelKey = [NSString stringWithFormat:@"VoiceOverLabel_%@", enableButtonKey];
	NSString *enableButtonAccessibilityHintKey = [NSString stringWithFormat:@"VoiceOverHint_%@", enableButtonKey];
	NSString *disableButtonAccessibilityLabelKey = [NSString stringWithFormat:@"VoiceOverLabel_%@", disableButtonKey];
	NSString *disableButtonAccessibilityHintKey = [NSString stringWithFormat:@"VoiceOverHint_%@", disableButtonKey];
	
	LMAlertViewController *alertViewController = [LMAlertViewController new];
	alertViewController.titleText = NSLocalizedString(titleKey, nil);
	alertViewController.bodyText = [NSString stringWithFormat:NSLocalizedString(@"SettingImagesAlertDescription", nil), currentStatusText, NSLocalizedString(youCanKey, nil)];
	alertViewController.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
	alertViewController.alertOptionTitles = @[NSLocalizedString(disableButtonKey, nil), NSLocalizedString(enableButtonKey, nil)];
	alertViewController.alertOptionAcceessibilityLabels = @[NSLocalizedString(disableButtonAccessibilityLabelKey, nil), NSLocalizedString(enableButtonAccessibilityLabelKey, nil)];
	alertViewController.alertOptionAcceessibilityHints = @[NSLocalizedString(disableButtonAccessibilityHintKey, nil), NSLocalizedString(enableButtonAccessibilityHintKey, nil)];
	alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
		//Reset the special permission statuses because the user's stance maybe different now and we'll have to recheck
		[self setExplicitPermissionStatus:LMImageManagerPermissionStatusNotDetermined];
		
		LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
		switch(optionSelected){
			case 0:
				permissionStatus = LMImageManagerPermissionStatusDenied;
				break;
			case 1:
				permissionStatus = LMImageManagerPermissionStatusAuthorized;
				break;
		}
		
		[self setDownloadPermissionStatus:permissionStatus];
		
		//In the rare case that for some reason something was left behind in the cache, we want to make sure the disable button always clears it even if it's already disabled, just to make sure the user is happy.
		if(optionSelected == 0){
			[self clearAllCaches];
			
			//Also, clear the queue in case anything was left there.
			[self.trackDownloadQueue removeAllObjects];
			[self.categoryDownloadQueue removeAllObjects];
		}
		
		[LMAnswers logCustomEventWithName:@"Image Download Alert Choice" customAttributes:@{
																							@"Disabled": @(optionSelected == 0)
																							}];
		
		if(completionHandler){
			completionHandler(optionSelected == 1);
		}
	};
	[self.navigationController presentViewController:alertViewController
											animated:YES
										  completion:nil];
}

- (void)displayDataAndStorageExplicitPermissionAlertWithCompletionHandler:(void(^)(BOOL authorized))completionHandler {
	LMAlertViewController *alertViewController = [LMAlertViewController new];
	alertViewController.titleText = NSLocalizedString(@"ExplicitImageDownloadingTitle", nil);
	alertViewController.bodyText = NSLocalizedString(@"ExplicitImageDownloadingBody", nil);
	alertViewController.alertOptionColours = @[[LMColour mainColourDark], [LMColour mainColour]];
	alertViewController.alertOptionTitles = @[NSLocalizedString(@"Deny", nil), NSLocalizedString(@"Allow", nil)];
	alertViewController.alertOptionAcceessibilityLabels = @[NSLocalizedString(@"VoiceOverLabel_Deny", nil), NSLocalizedString(@"VoiceOverLabel_Allow", nil)];
	alertViewController.alertOptionAcceessibilityHints = @[NSLocalizedString(@"VoiceOverHint_DenyExplicitImageDownloading", nil), NSLocalizedString(@"VoiceOverHint_AllowExplicitImageDownloading", nil)];
	alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
		//Reset the special permission statuses because the user's stance maybe different now and we'll have to recheck
		[self setExplicitPermissionStatus:LMImageManagerPermissionStatusNotDetermined];
		
		LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
		switch(optionSelected){
			case 0:
				permissionStatus = LMImageManagerPermissionStatusDenied;
				break;
			case 1:
				permissionStatus = LMImageManagerPermissionStatusAuthorized;
				break;
		}
		
		[self setExplicitPermissionStatus:permissionStatus];
		
		[self notifyDelegatesOfConditionLevel:self.conditionLevelForDownloading];
		
		[self downloadIfNeededForAllCategories];
		
		[LMAnswers logCustomEventWithName:@"Data and Low Storage Choice" customAttributes:@{
																							@"Disabled": @(optionSelected == 0)
																							}];
		
		if(completionHandler){
			completionHandler(optionSelected == 1);
		}
	};
	[self.navigationController presentViewController:alertViewController
															   animated:YES
															 completion:nil];
}

- (void)warningTapped:(LMWarning*)warning {
	if(warning == self.downloadProgressWarning){
		[self displayDownloadingAuthorizationAlertWithCompletionHandler:
		 ^(BOOL authorized) {
		    NSLog(@"Authorized download warning %d", authorized);
		    if(!authorized){
			    [self.warningManager removeWarning:self.downloadProgressWarning];
		    }
			
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
			
			hud.mode = MBProgressHUDModeCustomView;
			UIImage *image = [[UIImage imageNamed:@"icon_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			hud.customView = [[UIImageView alloc] initWithImage:image];
			hud.square = YES;
			hud.label.text = NSLocalizedString(authorized ? @"WillBeginDownloading" : @"ImagesDeleted", nil);
			hud.userInteractionEnabled = NO;
			
			[hud hideAnimated:YES afterDelay:3.f];
		}];
	}
}

/**
 *
 * END PERMISSION AND CONDITION LEVEL RELATED CODE
 *
 */

@end
