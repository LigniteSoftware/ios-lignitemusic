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

@interface LMTiledAlbumCoverView()

@property UIView *rootView;

@property NSMutableArray *tilesArray;
@property NSMutableArray *bigTileArray;

@property LMMusicTrackCollection *musicCollection;
@property NSMutableDictionary *uniqueAlbumCoversDictionary;

@property int amountOfAlbumsShowing;

@end

@implementation LMTiledAlbumCoverView

- (LMMusicTrack*)musicTrackForPersistentIdString:(NSString*)persistentId {
	for(int i = 0; i < self.musicCollection.count; i++){
		LMMusicTrack *track = [self.musicCollection.items objectAtIndex:i];
		
		if([persistentId isEqualToString:[NSString stringWithFormat:@"%llu", track.albumPersistentID]]){
			return track;
		}
	}
	return nil;
}

- (void)insertAlbumCovers {
	NSMutableArray *highestIds = [NSMutableArray new];
	NSMutableArray *regularIds = [NSMutableArray new];
	
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
	
	for(int i = 0; i < self.uniqueAlbumCoversDictionary.count; i++){
		NSString *key = [self.uniqueAlbumCoversDictionary.allKeys objectAtIndex:i];
		
		if(![highestIds containsObject:key]){
			[regularIds addObject:key];
		}
	}
	
	for(int i = 0; i < self.bigTileArray.count; i++){
		UIImageView *bigTile = [self.bigTileArray objectAtIndex:i];
		bigTile.image = [[self musicTrackForPersistentIdString:[highestIds objectAtIndex:i]] albumArt];
	}
	
	for(int i = 0; i < self.tilesArray.count; i++){
		NSLog(@"Spook %d", i);
		UIImageView *tile = [self.tilesArray objectAtIndex:i];
		if(![self.bigTileArray containsObject:tile]){
			tile.image = [[self musicTrackForPersistentIdString:[regularIds objectAtIndex:i]] albumArt];
		}
	}
	
	NSLog(@"Highest IDs %@\nRegular IDs %@", highestIds, regularIds);
}

- (NSMutableDictionary*)uniqueAlbumsInCollection {
	NSMutableDictionary *albumIdsCountDictionary = [NSMutableDictionary new];
	
	for(int i = 0; i < self.musicCollection.count; i++){
		LMMusicTrack *track = [self.musicCollection.items objectAtIndex:i];
		NSString *formattedPersistentString = [NSString stringWithFormat:@"%llu", track.albumPersistentID];
		NSNumber *count = [NSNumber numberWithInt:0];
		
		NSLog(@"Album %@ has id %@", track.albumTitle, formattedPersistentString);
		
		NSNumber *numberObject = [albumIdsCountDictionary objectForKey:formattedPersistentString];
		if(numberObject){
			count = numberObject;
		}
		int value = [count intValue];
		value++;
		count = [NSNumber numberWithInt:value];
		
		[albumIdsCountDictionary setObject:count forKey:formattedPersistentString];
	}
	
	NSLog(@"fuck you %lu", (unsigned long)[albumIdsCountDictionary allKeys].count);
	
	return albumIdsCountDictionary;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.tilesArray){
		LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		self.musicCollection = [[musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists] objectAtIndex:5];
		
		self.uniqueAlbumCoversDictionary = [self uniqueAlbumsInCollection];
		
		self.tilesArray = [NSMutableArray new];
		
		int amountOfItemsInCollection = 100;
		float amountOfTiles = self.uniqueAlbumCoversDictionary.count - (self.uniqueAlbumCoversDictionary.count % 4); //Round the number off to a multiple of four
		if(amountOfTiles < 4){
			amountOfTiles = 4;
		}
		
		self.amountOfAlbumsShowing = amountOfTiles;
		
		float areaTotal = self.frame.size.width * self.frame.size.height;
		float areaPerTile = areaTotal/amountOfTiles;
		float rawArea = sqrtf(areaPerTile);
		
		int amountOfTilesX = (int)floorf(self.frame.size.width/rawArea);
		int amountOfTilesY = (int)floorf(self.frame.size.height/rawArea);
		
		while((amountOfTilesX*(rawArea+1) < self.frame.size.width) && (amountOfTilesY*(rawArea+1) < self.frame.size.height)){
			rawArea++;
		}
		
		int actualAmountOfTiles = (amountOfTilesX * amountOfTilesY);
		
		CGSize tileSize = CGSizeMake(rawArea, rawArea);
		
		NSLog(@"\nLMTiledAlbumCover Generation\nAmount of items in collection: %d\nAmount of tiles generated: %f\nArea total: %f\nArea per tile: %f\nTile size: %@\nAmount of tiles X, Y: %d, %d", amountOfItemsInCollection, amountOfTiles, areaTotal, areaPerTile, NSStringFromCGSize(tileSize), amountOfTilesX, amountOfTilesY);
		
		self.rootView = [UIView newAutoLayoutView];
		self.rootView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.rootView];
		
		[self.rootView autoCenterInSuperview];
		[self.rootView autoSetDimension:ALDimensionWidth toSize:amountOfTilesX*rawArea];
		[self.rootView autoSetDimension:ALDimensionHeight toSize:amountOfTilesY*rawArea];
		
		for(int y = 0; y < amountOfTilesY; y++){
			BOOL firstRow = (y == 0);
			UIImageView *topElement = firstRow ? self.rootView : [self.tilesArray objectAtIndex:(y*amountOfTilesX)-1];
			for(int x = 0; x < amountOfTilesX; x++){
				BOOL firstColumn = (x == 0);
				UIImageView *sideElement = firstColumn ? self.rootView : [self.tilesArray objectAtIndex:x-1];
				
				int tileIndex = (y*amountOfTilesX)+x;
				
//				NSLog(@"Index of tile %d Column %d Row %d", tileIndex, x, y);
				
				UIImageView *testView = [UIImageView newAutoLayoutView];
				testView.backgroundColor = [UIColor colorWithRed:0.2*((float)(arc4random_uniform(5))+1.0) green:0.2*((float)(arc4random_uniform(5))+1.0) blue:0.2*((float)(arc4random_uniform(5))+1.0) alpha:1.0];
				[self.rootView addSubview:testView];
				
				[testView autoPinEdge:ALEdgeTop toEdge:firstRow ? ALEdgeTop : ALEdgeBottom ofView:topElement];
				[testView autoPinEdge:ALEdgeLeading toEdge:firstColumn ? ALEdgeLeading : ALEdgeTrailing ofView:sideElement];
				[testView autoSetDimension:ALDimensionHeight toSize:rawArea];
				[testView autoSetDimension:ALDimensionWidth toSize:rawArea];
				
				[self.tilesArray addObject:testView];
			}
		}
		
		self.bigTileArray = [NSMutableArray new];
		
		if(self.tilesArray.count > 4){
			int amountOfBigCovers = floor(sqrt(self.tilesArray.count)/2);
//			NSLog(@"Will generate %d big covers", amountOfBigCovers);
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
						if(actualAmountOfTiles == 16 && indexOfBigTile == 5){ //Prevents centering of big album art in 16 tile square view
							bigRedFlagPleaseWaveIfTrouble = YES;
//							NSLog(@"Index is cockblock, rejecting");
						}
						if(!bigRedFlagPleaseWaveIfTrouble){
							for(int otherBigTileIndex = 0; otherBigTileIndex < self.bigTileArray.count; otherBigTileIndex++){
								UIImageView *otherBigTile = [self.bigTileArray objectAtIndex:otherBigTileIndex];
								
								int indexesToCheck[4] = {
									indexOfBigTile, indexOfBigTile+1,
									indexOfBigTile+amountOfTilesX, indexOfBigTile+amountOfTilesX+1
								};
								for(int otherViewIndex = 0; otherViewIndex < 4; otherViewIndex++){
									UIImageView *otherView = [self.tilesArray objectAtIndex:indexesToCheck[otherViewIndex]];
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
						UIImageView *topLeftCornerView = [self.tilesArray objectAtIndex:finalIndex];
						
						UIImageView *bigTileView = [UIImageView newAutoLayoutView];
						bigTileView.backgroundColor = [UIColor colorWithRed:0.2*((float)(arc4random_uniform(5))+1.0) green:0.2*((float)(arc4random_uniform(5))+1.0) blue:0.2*((float)(arc4random_uniform(5))+1.0) alpha:1.0];
						[self.rootView addSubview:bigTileView];
						
						[bigTileView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:topLeftCornerView];
						[bigTileView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:topLeftCornerView];
						[bigTileView autoSetDimension:ALDimensionHeight toSize:tileSize.height*2];
						[bigTileView autoSetDimension:ALDimensionWidth toSize:tileSize.width*2];
						
						[self.bigTileArray addObject:bigTileView];
						
						int indexesToReplace[4] = {
							finalIndex, finalIndex+1,
							finalIndex+amountOfTilesX, finalIndex+amountOfTilesX+1
						};
						for(int viewToReplaceIndex = 0; viewToReplaceIndex < 4; viewToReplaceIndex++){
							[self.tilesArray replaceObjectAtIndex:indexesToReplace[viewToReplaceIndex] withObject:bigTileView];
						}
					}
				}
			}
		}
		
		[self insertAlbumCovers];
	}
	
	NSLog(@"New frame %@!", NSStringFromCGRect(self.frame));
}

- (void)setupWithCollection:(LMMusicTrackCollection*)collection {
	
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
