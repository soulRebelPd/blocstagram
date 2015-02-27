//
//  DataSource.h
//  Blocstagram
//
//  Created by Corey Norford on 2/27/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSource : NSObject

     +(instancetype) sharedInstance;
     @property (nonatomic, strong, readonly) NSMutableArray *mediaItems;

- (void) deleteMediaItemAtIndex:(NSInteger) index;

@end
