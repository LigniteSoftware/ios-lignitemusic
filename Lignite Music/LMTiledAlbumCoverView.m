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
		float amountOfTiles = 4*(arc4random_uniform(4)+1);
		
		float areaTotal = self.frame.size.width * self.frame.size.height;
		float areaPerTile = areaTotal/amountOfTiles;
		float rawArea = sqrtf(areaPerTile);
		
		float amountOfTilesX = floorf(self.frame.size.width/rawArea);
		float amountOfTilesY = floorf(self.frame.size.height/rawArea);
		
		CGSize tileSize = CGSizeMake(rawArea, rawArea);
		
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
		
		NSLog(@"\nLMTiledAlbumCover Generation\nAmount of items in collection: %d\nAmount of tiles generated: %f\nArea total: %f\nArea per tile: %f\nTile size: %@\nAmount of tiles X, Y: %f, %f", amountOfItemsInCollection, amountOfTiles, areaTotal, areaPerTile, NSStringFromCGSize(tileSize), amountOfTilesX, amountOfTilesY);
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
