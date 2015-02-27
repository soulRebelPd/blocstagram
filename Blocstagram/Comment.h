//
//  Comment.h
//  Blocstagram
//
//  Created by Corey Norford on 2/27/15.
//  Copyright (c) 2015 Bloc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface Comment : NSObject

    @property (nonatomic, strong) NSString *idNumber;
    @property (nonatomic, strong) User *from;
    @property (nonatomic, strong) NSString *text;

@end
