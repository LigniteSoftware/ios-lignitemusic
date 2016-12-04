//
//  LMSearchBar.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/4/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchBar.h"
#import "LMColour.h"
#import "LMMusicPlayer.h"


@interface LMSearchBar()<UITextFieldDelegate>

/**
 The text field which search terms are inputted into.
 */
@property UITextField *searchTextField;

@property MPMusicPlayerController *musicPlayer;

@end

@implementation LMSearchBar

- (void)searchFieldDidChange {
	NSLog(@"%@", self.searchTextField.text);
	
	NSString *searchTerm = self.searchTextField.text;
	
	if(self.delegate){
		[self.delegate searchTermChangedTo:searchTerm];
	}
	
//	LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
	
//	MPMediaPropertyPredicate *artistNamePredicate = [MPMediaPropertyPredicate predicateWithValue:self.searchTextField.text
//																					 forProperty:MPMediaItemPropertyArtist
//																				  comparisonType:MPMediaPredicateComparisonContains];
// 
//	MPMediaQuery *myArtistQuery = [[MPMediaQuery alloc] init];
//	[myArtistQuery addFilterPredicate: artistNamePredicate];
 
	MPMediaQuery *myArtistQuery = [MPMediaQuery songsQuery];
	
	NSArray *itemsFromArtistQuery = [myArtistQuery items];
	
//	[musicPlayer queryCollectionsForMusicType:LMMusicTypeTitles];
	
	
	NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
	
	NSLog(@"%d results. Completed in %fs.", (int)itemsFromArtistQuery.count, endTime-startTime);
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
		
		self.backgroundColor = [LMColour darkGrayColour];
		
		self.didLayoutConstraints = YES;
		
		self.searchTextField = [UITextField newAutoLayoutView];
		self.searchTextField.textColor = [UIColor whiteColor];
		self.searchTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.frame.size.height/2.25];
		[self.searchTextField addTarget:self
								 action:@selector(searchFieldDidChange)
					   forControlEvents:UIControlEventEditingChanged];
		[self addSubview:self.searchTextField];
		
		[self.searchTextField autoPinEdgesToSuperviewMargins];
	}
	
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
