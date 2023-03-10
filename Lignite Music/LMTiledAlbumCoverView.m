//
//  LMTiledAlbumCoverView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMusicPlayer.h"
#import "LMTiledAlbumCoverView.h"
#import "LMOperationQueue.h"
#import "LMExtras.h"
#import "LMEditView.h"

@interface LMTiledAlbumCoverView()

@property UIView *rootView;

/**
 The tap to edit view, if it exists. This should be brought in front of any other views.
 */
@property UIView *tapToEditView;

@property NSMutableArray *tilesArray;
@property NSMutableArray *bigTileArray;

@property NSMutableDictionary *uniqueAlbumCoversDictionary;

@property int amountOfAlbumsShowing;

@property LMOperationQueue *queue;

/**
 The generation key for keeping track of asycnrohnus changes.
 */
@property NSString *generationKey;

@end

@implementation LMTiledAlbumCoverView

@synthesize musicCollection = _musicCollection;

- (LMMusicTrackCollection*)musicCollection {
	return _musicCollection;
}

- (void)setMusicCollection:(LMMusicTrackCollection *)musicCollection {
	_musicCollection = musicCollection;
	
	if(self.frame.size.width > 0){
		for(int i = 0; i < self.tilesArray.count; i++){
			UIView *tile = [self.tilesArray objectAtIndex:i];
			tile.frame = CGRectZero;
//			[tile.constraints autoRemoveConstraints];
			[tile removeFromSuperview];
			[tile setHidden:YES];
		}
		
		[self.rootView removeFromSuperview];
		[self.rootView setHidden:YES];
		
		self.tilesArray = nil;
		
		[self regenerate];
	}
}

- (LMMusicTrack*)musicTrackForPersistentIdString:(NSString*)persistentId {
	LMMusicTrackCollection *collectionToIterate = self.musicCollection;
	for(int i = 0; i < collectionToIterate.count; i++){
		if(self.musicCollection.items.count < collectionToIterate.items.count){
//			NSLog(@"Crash would have happened :)");
		}
		LMMusicTrack *track = [collectionToIterate.items objectAtIndex:i];
		
		if([persistentId isEqualToString:[NSString stringWithFormat:@"%llu", track.albumPersistentID]]){
			return track;
		}
	}
	return nil;
}

- (void)insertAlbumCovers {
//	if(!self.queue){
//		self.queue = [[LMOperationQueue alloc] init];
//	}
//
//	[self.queue cancelAllOperations];
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInitiated, 0), ^{
//	__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
//		@autoreleasepool {
	
			NSMutableArray *highestIds = [NSMutableArray new];
			NSMutableArray *regularIds = [NSMutableArray new];
			
			//	NSLog(@"Inserting album covers. Big tile count %ld regular count %ld", self.bigTileArray.count, self.tilesArray.count);
			
			//For each big tile, go through the songs and find which ones have the highest cover count in the collection
			for(int i = 0; i < self.bigTileArray.count; i++){
				NSString *highestIdKey = @"";
				int highestIdValue = -1;
				for(int keyIndex = 0; keyIndex < self.uniqueAlbumCoversDictionary.allKeys.count; keyIndex++){
					NSString *key = [self.uniqueAlbumCoversDictionary.allKeys objectAtIndex:keyIndex];
					NSNumber *value = [self.uniqueAlbumCoversDictionary objectForKey:key];
					
					if([value intValue] > highestIdValue && ![highestIds containsObject:key]){
						highestIdKey = key;
						highestIdValue = [value intValue];
					}
				}
				[highestIds addObject:highestIdKey];
			}
			
			//	NSLog(@"Showing %d", (int)self.uniqueAlbumCoversDictionary.count);
			//	if(self.uniqueAlbumCoversDictionary.count == 3){
			//		NSLog(@"UNIQUE SHIT %@", self.uniqueAlbumCoversDictionary);
			//	}
			
			//Remove all of the lowest covers from the dictionary of unique covers
			while(self.uniqueAlbumCoversDictionary.count > self.amountOfAlbumsShowing){
				NSString *lowestIdKey = @"";
				int lowestIdValue = INT_MAX;
				for(int i = 0; i < self.uniqueAlbumCoversDictionary.count; i++){
					NSString *key = [self.uniqueAlbumCoversDictionary.allKeys objectAtIndex:i];
					NSNumber *value = [self.uniqueAlbumCoversDictionary objectForKey:key];
					
					if([value intValue] < lowestIdValue){
						lowestIdKey = key;
						lowestIdValue = [value intValue];
					}
				}
				[self.uniqueAlbumCoversDictionary removeObjectForKey:lowestIdKey];
			}
			
			//Insert all of the rest of the IDs into the regular covers array where they will live happy normal lives
			for(int i = 0; i < self.uniqueAlbumCoversDictionary.count; i++){
				NSString *key = [self.uniqueAlbumCoversDictionary.allKeys objectAtIndex:i];
				
				if(![highestIds containsObject:key]){
					[regularIds addObject:key];
				}
			}
			
			NSMutableArray *bigTileImages = [NSMutableArray new];
			NSMutableArray *regularTileImages = [NSMutableArray new];
			
			//For each big tile load its associated big album art
			for(int i = 0; i < self.bigTileArray.count; i++){
				UIImage *image = nil;
				if(i < highestIds.count){
					image = [[self musicTrackForPersistentIdString:[highestIds objectAtIndex:i]] albumArt];
				}
				if(!image){
					image = [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
				}
				if(image != nil){
					[bigTileImages addObject:image];
				}
			}
			
			NSMutableArray *usedRegularIds = [NSMutableArray new];
			
			//For each regular tile load its regular image
			for(int i = 0; i < self.tilesArray.count; i++){
				UIImageView *tile = [self.tilesArray objectAtIndex:i];
				if(![self.bigTileArray containsObject:tile]){
					UIImage *image = nil;
					NSString *regularIdUsed = nil;
					if(regularIds.count > i){
						regularIdUsed = [regularIds objectAtIndex:i];
						image = [[self musicTrackForPersistentIdString:regularIdUsed] albumArt];
					}
					//Correct for odd amount of images to create a 4 tile cover
					else if(regularIds.count == 2 || regularIds.count == 3){
						regularIdUsed = [regularIds objectAtIndex:(i == 2) ? 1 : 0];
						image = [[self musicTrackForPersistentIdString:regularIdUsed] albumArt];
					}
					else if((i >= regularIds.count) && (regularIds.count > 0)){
						regularIdUsed = [regularIds objectAtIndex:(int)arc4random_uniform((int)regularIds.count)];
						
						int attempts = 0;
						while([usedRegularIds containsObject:regularIdUsed] && (attempts < 20)){
							regularIdUsed = [regularIds objectAtIndex:(int)arc4random_uniform((int)regularIds.count)];
						
							attempts++;
						}
						
						image = [[self musicTrackForPersistentIdString:regularIdUsed] albumArt];
					}
					
					if(image){
						[regularTileImages addObject:image];
						[usedRegularIds addObject:regularIdUsed];
					}
				}
			}
			
			if(self.musicCollection.count == 287 && regularTileImages.count < 8){
				NSLog(@"What");
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
//				if(operation.cancelled){
//					NSLog(@"Rejecting.");
//					return;
//				}
				
				NSArray *bigTileArrayToUse = [NSArray arrayWithArray:self.bigTileArray];
				
				//Set each big image to its associated view
				for(int i = 0; i < bigTileImages.count; i++){
					UIImage *image = [bigTileImages objectAtIndex:i];
					if(i < bigTileArrayToUse.count){
						UIImageView *bigTileView = [bigTileArrayToUse objectAtIndex:i];
						
						bigTileView.image = image;
					}
				}
				
				NSArray *tilesArrayToUse = [NSArray arrayWithArray:self.tilesArray];
				
				//Set each regular image to its associated view by taking the image at the top of the array and setting that as the image
				for(int i = 0; i < tilesArrayToUse.count; i++){
					if(regularTileImages.count > 0){
						UIImage *image = [regularTileImages firstObject];
						UIImageView *tile = [tilesArrayToUse objectAtIndex:i];
						
						if(![bigTileArrayToUse containsObject:tile]){
							tile.image = image;
							
							[regularTileImages removeObjectAtIndex:0]; //Remove first object
						}
					}
				}
				
//				operation = nil;
			});
	   });
//	}];
//
//	[self.queue addOperation:operation];

//	NSLog(@"Highest IDs %@\nRegular IDs %@", highestIds, regularIds);
}

- (NSMutableDictionary*)uniqueAlbumsInCollection {
	NSMutableDictionary *albumIdsCountDictionary = [NSMutableDictionary new];
	
//    NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
	
	LMMusicTrackCollection *collectionToIterate = self.musicCollection;
	
	for(int i = 0; i < collectionToIterate.count; i++){
		LMMusicTrack *track = [collectionToIterate.items objectAtIndex:i];
		NSString *formattedPersistentString = [NSString stringWithFormat:@"%llu", track.albumPersistentID];
		NSNumber *count = [NSNumber numberWithInt:0];
		
//		NSLog(@"Album %@ has id %@", track.albumTitle, formattedPersistentString);
		
		NSNumber *numberObject = [albumIdsCountDictionary objectForKey:formattedPersistentString];
		if(numberObject){
			count = numberObject;
		}
		int value = [count intValue];
		value++;
		count = [NSNumber numberWithInt:value];
		
        if([albumIdsCountDictionary objectForKey:formattedPersistentString]){
            [albumIdsCountDictionary setObject:count forKey:formattedPersistentString];
        }
        else{
            if(([[self musicTrackForPersistentIdString:formattedPersistentString] albumArt] != nil)){
                [albumIdsCountDictionary setObject:count forKey:formattedPersistentString];
            }
        }
	}
    
//    NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
    
//    NSLog(@"Converted covers (%ld) in %f seconds", collectionToIterate.count, endTime-startTime);
	
//	NSLog(@"fuck you %lu", (unsigned long)[albumIdsCountDictionary allKeys].count);
	
	if(self.musicCollection.count == 287){
		NSLog(@"%d entries in dictionary for soundtrack", (int)albumIdsCountDictionary.count);
	}
	
	return albumIdsCountDictionary;
}

- (NSString*)randomStringWithLength:(int)len {
	NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
	
	for (int i=0; i<len; i++) {
		[randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint32_t)[letters length])]];
	}
	
	return randomString;
}

- (void)regenerate {
	if(!self.tilesArray){
		self.tilesArray = [NSMutableArray new];
		
		__weak id weakSelf = self;

		dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
			id strongSelf = weakSelf;
			
			if (!strongSelf) {
				return;
			}
			
			LMTiledAlbumCoverView *tiledAlbumCoverView = strongSelf;
			
			NSString *generationKey = [self randomStringWithLength:10];
			tiledAlbumCoverView.generationKey = generationKey;
			
			tiledAlbumCoverView.uniqueAlbumCoversDictionary = [tiledAlbumCoverView uniqueAlbumsInCollection];
			
//            NSLog(@"Got %ld tiled covers", tiledAlbumCoverView.uniqueAlbumCoversDictionary.count);
			
			if(![generationKey isEqualToString:tiledAlbumCoverView.generationKey]){
				NSLog(@"Outdated, rejecting %@", generationKey);
				return;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				CGFloat amountOfTiles = tiledAlbumCoverView.uniqueAlbumCoversDictionary.count - (tiledAlbumCoverView.uniqueAlbumCoversDictionary.count % 4); //Round the number off to a multiple of four
				if(amountOfTiles < 4){
					amountOfTiles = 4;
				}
				
				if(tiledAlbumCoverView.musicCollection.count == 287){
					NSLog(@"%f tiles in soundtrack", amountOfTiles);
				}
				
				tiledAlbumCoverView.amountOfAlbumsShowing = amountOfTiles;
				
				CGFloat smallerDimension = MIN(tiledAlbumCoverView.frame.size.width, tiledAlbumCoverView.frame.size.height);
				CGFloat largerDimension = MAX(tiledAlbumCoverView.frame.size.width, tiledAlbumCoverView.frame.size.height);
				CGFloat differencePercentage = smallerDimension/largerDimension;
				BOOL maintainSquare = differencePercentage > 0.75;
				//		BOOL smallerDimensionIsWidth = (smallerDimension == tiledAlbumCoverView.frame.size.width);
				
				CGFloat widthToUse = maintainSquare ? smallerDimension : tiledAlbumCoverView.frame.size.width;
				CGFloat heightToUse = maintainSquare ? smallerDimension : tiledAlbumCoverView.frame.size.height;
				
//				if(maintainSquare){
//					largerDimension = smallerDimension;
//				}
				
				CGFloat areaTotal = widthToUse * heightToUse;
				CGFloat areaPerTile = areaTotal/amountOfTiles;
				CGFloat sideLength = sqrtf(areaPerTile);
				
				int amountOfTilesX = (int)floorf(widthToUse/sideLength);
				int amountOfTilesY = (int)floorf(heightToUse/sideLength);
				
				if(tiledAlbumCoverView.uniqueAlbumCoversDictionary.count == 1){ //Improve for one album art
					amountOfTilesX = 1;
					amountOfTilesY = 1;
				}
				
				if(tiledAlbumCoverView.musicCollection.count == 287){
					NSLog(@"%d/%d amountxy", amountOfTilesX, amountOfTilesY);
					NSLog(@"What");
				}
				
				while((amountOfTilesX*(sideLength+1) < widthToUse) && (amountOfTilesY*(sideLength+1) < heightToUse)){
					sideLength++;
				}
				
				int actualAmountOfTiles = (amountOfTilesX * amountOfTilesY);
				
				sideLength += 1; //To ensure that it fits the edges of the detail view properly
				
				CGSize tileSize = CGSizeMake(sideLength, sideLength);
				
				//		NSLog(@"Smaller %f larger %f difference %f maintainSquare %d", smallerDimension, largerDimension, differencePercentage, maintainSquare);
				
//				NSLog(@"\nLMTiledAlbumCover %@ Generation\nFrame: %@\nAmount of items in collection: %d\nAmount of tiles generated: %f\nArea total: %f\nArea per tile: %f\nTile size: %@\nAmount of tiles X, Y: %d, %d", tiledAlbumCoverView, NSStringFromCGRect(tiledAlbumCoverView.frame), (int)tiledAlbumCoverView.musicCollection.count, amountOfTiles, areaTotal, areaPerTile, NSStringFromCGSize(tileSize), amountOfTilesX, amountOfTilesY);
				
				tiledAlbumCoverView.rootView = [UIView new];
				tiledAlbumCoverView.rootView.backgroundColor = [UIColor blackColor];
				tiledAlbumCoverView.rootView.layer.shadowColor = [UIColor blackColor].CGColor;
				tiledAlbumCoverView.rootView.layer.shadowRadius = WINDOW_FRAME.size.width/45 / 3;
				tiledAlbumCoverView.rootView.layer.shadowOffset = CGSizeMake(0, tiledAlbumCoverView.rootView.layer.shadowRadius/2);
				tiledAlbumCoverView.rootView.layer.shadowOpacity = 0.25f;
				tiledAlbumCoverView.clipsToBounds = YES;
				tiledAlbumCoverView.layer.masksToBounds = YES;
				tiledAlbumCoverView.layer.cornerRadius = 8.0f;
				[tiledAlbumCoverView addSubview:tiledAlbumCoverView.rootView];
				
				for(UIView *subview in tiledAlbumCoverView.subviews){
//					NSLog(@"Subview %@", subview);
					if([subview class] == [LMEditView class]){
						NSLog(@"Is edit view");
						tiledAlbumCoverView.tapToEditView = subview;
						break;
					}
				}
				if(tiledAlbumCoverView.tapToEditView){
					BOOL wasHidden = tiledAlbumCoverView.tapToEditView.hidden;
					
					NSLog(@"Was hidden %d", wasHidden);
					
					[tiledAlbumCoverView bringSubviewToFront:tiledAlbumCoverView.tapToEditView];
					
					NSLog(@"Is hidden %d", tiledAlbumCoverView.tapToEditView.hidden);
//					tiledAlbumCoverView.tapToEditView.hidden = YES;
				}
				
				CGSize rootViewSize = CGSizeMake(amountOfTilesX*sideLength, amountOfTilesY*sideLength);
				CGPoint rootViewPosition = CGPointMake((tiledAlbumCoverView.frame.size.width-rootViewSize.width)/2, (tiledAlbumCoverView.frame.size.height-rootViewSize.height)/2);
				tiledAlbumCoverView.rootView.frame = CGRectMake(rootViewPosition.x, rootViewPosition.y, rootViewSize.width, rootViewSize.height);
				
				for(int y = 0; y < amountOfTilesY; y++){
					BOOL firstRow = (y == 0);
					UIImageView *topElement = firstRow ? tiledAlbumCoverView.rootView : [tiledAlbumCoverView.tilesArray objectAtIndex:(y*amountOfTilesX)-1];
					for(int x = 0; x < amountOfTilesX; x++){
						BOOL firstColumn = (x == 0);
						UIImageView *sideElement = firstColumn ? tiledAlbumCoverView.rootView : [tiledAlbumCoverView.tilesArray objectAtIndex:x-1];
						
						//				int tileIndex = (y*amountOfTilesX)+x;
						
						//				NSLog(@"Index of tile %d Column %d Row %d", tileIndex, x, y);
						
						UIImageView *testView = [UIImageView new];
						testView.backgroundColor = [UIColor whiteColor]; //[UIColor colorWithRed:0.2*((CGFloat)(arc4random_uniform(5))+1.0) green:0.2*((CGFloat)(arc4random_uniform(5))+1.0) blue:0.2*((CGFloat)(arc4random_uniform(5))+1.0) alpha:1.0];
						//				testView.image = [LMAppIcon imageForIcon:LMIconNoAlbumArt];
						testView.contentMode = UIViewContentModeScaleAspectFit;
						[tiledAlbumCoverView.rootView addSubview:testView];
						
						//				[testView autoPinEdge:ALEdgeTop toEdge:firstRow ? ALEdgeTop : ALEdgeBottom ofView:topElement];
						//				[testView autoPinEdge:ALEdgeLeading toEdge:firstColumn ? ALEdgeLeading : ALEdgeTrailing ofView:sideElement];
						//				[testView autoSetDimension:ALDimensionHeight toSize:sideLength];
						//				[testView autoSetDimension:ALDimensionWidth toSize:sideLength];
						
						CGSize testViewSize = CGSizeMake(sideLength, sideLength);
						CGPoint testViewPosition = CGPointMake(0, 0);
						
						testViewPosition.x = firstColumn ? 0 : (sideElement.frame.origin.x+sideElement.frame.size.width);
						testViewPosition.y = firstRow ? 0 : (topElement.frame.origin.y+topElement.frame.size.height);
						
						testView.frame = CGRectMake(testViewPosition.x, testViewPosition.y, testViewSize.width, testViewSize.height);
						
						[tiledAlbumCoverView.tilesArray addObject:testView];
					}
				}
				
				tiledAlbumCoverView.bigTileArray = [NSMutableArray new];
				
				if(tiledAlbumCoverView.tilesArray.count > 4 || tiledAlbumCoverView.uniqueAlbumCoversDictionary.count == 1){
					int amountOfBigCovers = tiledAlbumCoverView.uniqueAlbumCoversDictionary.count == 1 ? 1 : floor(sqrt(tiledAlbumCoverView.tilesArray.count)/2);
										
					if(amountOfTilesX > 1 && amountOfTilesY > 1){
						for(int i = 0; i < amountOfBigCovers; i++){
							int finalIndex = -1;
							BOOL validIndex = NO;
							int attempts = 0;
							while(!validIndex){
								BOOL bigRedFlagPleaseWaveIfTrouble = NO;
								
								attempts++;
								
								int indexOfBigTile = arc4random_uniform(actualAmountOfTiles);
								int columnOfBigTile = indexOfBigTile % amountOfTilesX;
								int rowOfBigTile = (indexOfBigTile-columnOfBigTile)/amountOfTilesY;
								//						NSLog(@"\nIndex of big tile %d\nColumn %d\nRow %d", indexOfBigTile, columnOfBigTile, rowOfBigTile);
								
								if((columnOfBigTile+1) > (amountOfTilesX-1) || (rowOfBigTile+1) > (amountOfTilesY-1)){
									bigRedFlagPleaseWaveIfTrouble = YES;
									//							NSLog(@"Index is on the edge, rejecting");
								}
								if(actualAmountOfTiles == 16  && indexOfBigTile == 5){ //Prevents centering of big album art in 16 tile square view
									bigRedFlagPleaseWaveIfTrouble = YES;
									//							NSLog(@"Index is cockblock, rejecting");
								}
								if(!bigRedFlagPleaseWaveIfTrouble){
									for(int otherBigTileIndex = 0; otherBigTileIndex < tiledAlbumCoverView.bigTileArray.count; otherBigTileIndex++){
										UIImageView *otherBigTile = [tiledAlbumCoverView.bigTileArray objectAtIndex:otherBigTileIndex];
										
										int indexesToCheck[4] = {
											indexOfBigTile, indexOfBigTile+1,
											indexOfBigTile+amountOfTilesX, indexOfBigTile+amountOfTilesX+1
										};
										for(int otherViewIndex = 0; otherViewIndex < 4; otherViewIndex++){
											UIImageView *otherView = [tiledAlbumCoverView.tilesArray objectAtIndex:indexesToCheck[otherViewIndex]];
											if([otherView isEqual:otherBigTile]){
												//										NSLog(@"Loop %d: Index is taken by another big tile at index %d, rejecting", otherViewIndex, indexesToCheck[otherViewIndex]);
												bigRedFlagPleaseWaveIfTrouble = YES;
											}
										}
									}
								}
								if(!bigRedFlagPleaseWaveIfTrouble){
									validIndex = YES;
									finalIndex = indexOfBigTile;
									//							NSLog(@"Valid index @ %d", indexOfBigTile);
								}
								if(attempts > 50){
									validIndex = YES;
									//							NSLog(@"Giving up hope.");
								}
							}
							if(finalIndex > -1){
								UIImageView *topLeftCornerView = [tiledAlbumCoverView.tilesArray objectAtIndex:finalIndex];
								
								UIImageView *bigTileView = [UIImageView new];
								bigTileView.backgroundColor = [UIColor whiteColor]; //[UIColor colorWithRed:0.2*((CGFloat)(arc4random_uniform(5))+1.0) green:0.2*((CGFloat)(arc4random_uniform(5))+1.0) blue:0.2*((CGFloat)(arc4random_uniform(5))+1.0) alpha:1.0];
								[tiledAlbumCoverView.rootView addSubview:bigTileView];
								
								CGSize bigTileViewSize = CGSizeMake(tileSize.height*2, tileSize.height*2);
								CGPoint bigTileViewPosition = CGPointMake(topLeftCornerView.frame.origin.x, topLeftCornerView.frame.origin.y);
								
								bigTileView.frame = CGRectMake(bigTileViewPosition.x, bigTileViewPosition.y, bigTileViewSize.width, bigTileViewSize.height);
								
								//						[bigTileView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:topLeftCornerView];
								//						[bigTileView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:topLeftCornerView];
								//						[bigTileView autoSetDimension:ALDimensionHeight toSize:tileSize.height*2];
								//						[bigTileView autoSetDimension:ALDimensionWidth toSize:tileSize.height*2];
								
								[tiledAlbumCoverView.bigTileArray addObject:bigTileView];
								
								int indexesToReplace[4] = {
									finalIndex, finalIndex+1,
									finalIndex+amountOfTilesX, finalIndex+amountOfTilesX+1
								};
								for(int viewToReplaceIndex = 0; viewToReplaceIndex < 4; viewToReplaceIndex++){
									[tiledAlbumCoverView.tilesArray replaceObjectAtIndex:indexesToReplace[viewToReplaceIndex] withObject:bigTileView];
								}
							}
						}
					}
				}
				
				[tiledAlbumCoverView insertAlbumCovers];
			});
		});
		
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(self.frame.size.width > 0){
		[self regenerate];
	}
}

@end
