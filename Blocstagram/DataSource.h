//
//  DataSource.h
//  Blocstagram
//
//  Created by Corey Norford on 2/27/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

typedef void (^NewItemCompletionBlock)(NSError *error);

@interface DataSource : NSObject
+ (instancetype) sharedInstance;
- (void) deleteMediaItem:(Media *)item;
@property (nonatomic, strong) NSArray *mediaItems;
 - (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;
 - (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;
@end
