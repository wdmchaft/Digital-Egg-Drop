//
//  WindDisaster.h
//  EggDrop
//
//  Created by Alec Thomson on 4/30/11.
//  Copyright 2011 Massachusetts Institute of Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EggDisaster.h"
#import "SimpleAudioEngine.h"

@interface WindDisaster : EggDisaster {
@private
    float windStrength;
    float windDuration;
    ALuint mySoundID;
}

-(id)initWithDelay:(float)delay andStrength:(float)strength andDuration:(float)duration;

@end
