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

@property NSMutableArray *viewsArray;

@property LMMusicTrackCollection *musicCollection;

@end

@implementation LMTiledAlbumCoverView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.viewsArray){
		self.viewsArray = [NSMutableArray new];
		
		int amountOfItemsInCollection = 100;
		float amountOfTiles = 8*(arc4random_uniform(2)+1);
		
		float areaTotal = self.frame.size.width * self.frame.size.height;
		float areaPerTile = areaTotal/amountOfTiles;
		float rawArea = sqrtf(areaPerTile);
		
		int amountOfTilesX = (int)floorf(self.frame.size.width/rawArea);
		int amountOfTilesY = (int)floorf(self.frame.size.height/rawArea);
		
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
			UIView *topElement = firstRow ? self.rootView : [self.viewsArray objectAtIndex:(y*amountOfTilesY)-1];
			for(int x = 0; x < amountOfTilesX; x++){
				BOOL firstColumn = (x == 0);
				UIView *sideElement = firstColumn ? self.rootView : [self.viewsArray objectAtIndex:x-1];
				
				int tileIndex = (y*amountOfTilesX)+x;
				
				NSLog(@"Tile index %d", tileIndex);
				
				UIView *testView = [UIView newAutoLayoutView];
				testView.backgroundColor = [UIColor colorWithRed:0.2*((float)(arc4random_uniform(5))+1.0) green:0.2*((float)(arc4random_uniform(5))+1.0) blue:0.2*((float)(arc4random_uniform(5))+1.0) alpha:1.0];
				[self.rootView addSubview:testView];
				
				[testView autoPinEdge:ALEdgeTop toEdge:firstRow ? ALEdgeTop : ALEdgeBottom ofView:topElement];
				[testView autoPinEdge:ALEdgeLeading toEdge:firstColumn ? ALEdgeLeading : ALEdgeTrailing ofView:sideElement];
				[testView autoSetDimension:ALDimensionHeight toSize:rawArea];
				[testView autoSetDimension:ALDimensionWidth toSize:rawArea];
				
				[self.viewsArray addObject:testView];
			}
		}
		
		NSMutableArray *bigTileArray = [NSMutableArray new];
		
		if(self.viewsArray.count > 4){
			int amountOfBigCovers = floor(sqrt(self.viewsArray.count)/2);
			if(amountOfTilesX > 1 && amountOfTilesY > 1){
				for(int i = 0; i < amountOfBigCovers; i++){
					int finalIndex = -1;
					BOOL validIndex = NO;
					while(!validIndex){
						BOOL bigRedFlagPleaseWaveIfTrouble = NO;
						
						int indexOfBigTile = arc4random_uniform(actualAmountOfTiles);
						int columnOfBigTile = indexOfBigTile % amountOfTilesY;
						int rowOfBigTile = (indexOfBigTile-columnOfBigTile)/amountOfTilesY;
						NSLog(@"\nIndex of big tile %d\nColumn %d\nRow %d", indexOfBigTile, columnOfBigTile, rowOfBigTile);
						
						if((columnOfBigTile+1) > (amountOfTilesX-1) || (rowOfBigTile+1) > (amountOfTilesY-1)){
							bigRedFlagPleaseWaveIfTrouble = YES;
							NSLog(@"Index is on the edge, rejecting");
						}
						if(actualAmountOfTiles == 16 && indexOfBigTile == 5){ //Prevents centering of big album art in 16 tile square view
							bigRedFlagPleaseWaveIfTrouble = YES;
							NSLog(@"Index is cockblock, rejecting");
						}
						if(!bigRedFlagPleaseWaveIfTrouble){
							for(int otherBigTileIndex = 0; otherBigTileIndex < bigTileArray.count; otherBigTileIndex++){
								UIView *otherBigTile = [bigTileArray objectAtIndex:otherBigTileIndex];
								
								int indexesToCheck[4] = {
									indexOfBigTile, indexOfBigTile+1,
									indexOfBigTile+amountOfTilesY, indexOfBigTile+amountOfTilesY+1
								};
								for(int otherViewIndex = 0; otherViewIndex < 4; otherViewIndex++){
									UIView *otherView = [self.viewsArray objectAtIndex:indexesToCheck[otherViewIndex]];
									if([otherView isEqual:otherBigTile]){
										bigRedFlagPleaseWaveIfTrouble = YES;
									}
								}
							}
						}
						if(!bigRedFlagPleaseWaveIfTrouble){
							validIndex = YES;
							finalIndex = indexOfBigTile;
							NSLog(@"Valid index @ %d", indexOfBigTile);
						}
					}
					if(finalIndex > -1){
						UIView *topLeftCornerView = [self.viewsArray objectAtIndex:finalIndex];
						
						UIView *bigTileView = [UIView newAutoLayoutView];
						bigTileView.backgroundColor = [UIColor colorWithRed:0.2*((float)(arc4random_uniform(5))+1.0) green:0.2*((float)(arc4random_uniform(5))+1.0) blue:0.2*((float)(arc4random_uniform(5))+1.0) alpha:1.0];
						[self.rootView addSubview:bigTileView];
						
						[bigTileView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:topLeftCornerView];
						[bigTileView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:topLeftCornerView];
						[bigTileView autoSetDimension:ALDimensionHeight toSize:tileSize.height*2];
						[bigTileView autoSetDimension:ALDimensionWidth toSize:tileSize.width*2];
						
						[bigTileArray addObject:bigTileView];
						
						int indexesToReplace[4] = {
							finalIndex, finalIndex+1,
							finalIndex+amountOfTilesY, finalIndex+amountOfTilesY+1
						};
						for(int viewToReplaceIndex = 0; viewToReplaceIndex < 4; viewToReplaceIndex++){
							[self.viewsArray replaceObjectAtIndex:indexesToReplace[viewToReplaceIndex] withObject:bigTileView];
						}
					}
				}
			}
		}
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
