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
#import "LMAppIcon.h"

@interface LMSearchBar()<UITextFieldDelegate>

/**
 The text field which search terms are inputted into.
 */
@property UITextField *searchTextField;

/**
 The background view for the clear text button.
 */
@property UIView *clearTextButtonBackgroundView;

/**
 The image view for the clear text button.
 */
@property UIImageView *clearTextButtonImageView;

/**
 The current search term. Should be put against any other search term in queue to make sure there are no overlapping instances.
 */
@property NSString *currentSearchTerm;


@property MPMusicPlayerController *musicPlayer;


@end

@implementation LMSearchBar

- (void)searchFieldDidChange {
	NSLog(@"%@", self.searchTextField.text);
	
	NSString *searchTerm = self.searchTextField.text;
	
	self.currentSearchTerm = searchTerm;
	
	if(self.delegate){
		[self.delegate searchTermChangedTo:searchTerm];
	}
	
	__weak id weakSelf = self;
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceUserInteractive, 0), ^{
		id strongSelf = weakSelf;
		
		if (!strongSelf) {
			return;
		}
		
		LMSearchBar *searchBar = strongSelf;
		
		NSString *asyncSearchTerm = searchBar.currentSearchTerm;
		
		LMMusicPlayer *musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		NSLog(@"Term %@", asyncSearchTerm);
		
		NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
		MPMediaPropertyPredicate *artistNamePredicate = [MPMediaPropertyPredicate predicateWithValue:asyncSearchTerm
																						 forProperty:MPMediaItemPropertyArtist
																					  comparisonType:MPMediaPredicateComparisonContains];
	
		MPMediaQuery *myArtistQuery = [[MPMediaQuery alloc] init];
		[myArtistQuery addFilterPredicate: artistNamePredicate];
		
//		MPMediaQuery *myArtistQuery = [MPMediaQuery songsQuery];
		
		NSArray *itemsFromArtistQuery = [myArtistQuery items];
		
		[musicPlayer queryCollectionsForMusicType:LMMusicTypeArtists];
		
		
		NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
		
		if(![asyncSearchTerm isEqualToString:searchBar.currentSearchTerm]){
			NSLog(@"Rejecting %@ (current %@).", asyncSearchTerm, searchBar.currentSearchTerm);
			return;
		}
		
		NSLog(@"%d results for %@ (current %@). Completed in %fs.", (int)itemsFromArtistQuery.count, asyncSearchTerm, searchBar.currentSearchTerm, endTime-startTime);
	});
}

- (void)tappedClearSearch {
	self.searchTextField.text = @"";
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints) {
		self.musicPlayer = [MPMusicPlayerController systemMusicPlayer];
		
		self.backgroundColor = [LMColour darkGrayColour];
		
		self.didLayoutConstraints = YES;
	
		
		self.clearTextButtonBackgroundView = [UIView newAutoLayoutView];
		self.clearTextButtonBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self addSubview:self.clearTextButtonBackgroundView];
		
		[self.clearTextButtonBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.clearTextButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[self.clearTextButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self];
		[self.clearTextButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedClearSearch)];
		[self.clearTextButtonBackgroundView addGestureRecognizer:tapGesture];
		
		
		self.clearTextButtonImageView = [UIImageView newAutoLayoutView];
		self.clearTextButtonImageView.image = [LMAppIcon imageForIcon:LMIconXCross];
		self.clearTextButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.clearTextButtonBackgroundView addSubview:self.clearTextButtonImageView];
		
		[self.clearTextButtonImageView autoCenterInSuperview];
		[self.clearTextButtonImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.clearTextButtonBackgroundView withMultiplier:(1.0/2.0)];
		[self.clearTextButtonImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.clearTextButtonBackgroundView withMultiplier:(1.0/2.0)];
		
		
		self.searchTextField = [UITextField newAutoLayoutView];
		self.searchTextField.textColor = [UIColor whiteColor];
		self.searchTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:self.frame.size.height/2.25];
		[self.searchTextField addTarget:self
								 action:@selector(searchFieldDidChange)
					   forControlEvents:UIControlEventEditingChanged];
		[self addSubview:self.searchTextField];
		
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeTop];
		[self.searchTextField autoPinEdgeToSuperviewMargin:ALEdgeBottom];
		[self.searchTextField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.clearTextButtonBackgroundView withOffset:-10.0];
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
