//
//  KSYMP4Frame.h
//  protos
//
//  Created by Blues on 10/12/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
  kFrameTypeAudio = 8,
  kFrameTypeVideo = 9
};

@interface KSYMP4Frame : NSObject

@property (atomic, assign) long offset;
@property (atomic, assign) long size;
// Timestamp in seconds
@property (atomic, assign) double timestamp;
@property (atomic, assign) Byte type;
@property (atomic, assign) BOOL keyFrame;
@property (atomic, assign) int timeOffset;

- (NSComparisonResult)compareMP4Frame:(KSYMP4Frame *)otherObject;

@end
