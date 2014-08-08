//
//  NativeAd.m
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 21.05.2014.
//
//

#import "NativeAd.h"

@implementation NativeAd

- (id)init {
    self = [super init];
    self.imageAssets = [[NSMutableDictionary alloc]init];
    self.textAssets = [[NSMutableDictionary alloc]init];
    self.trackers = [[NSMutableArray alloc] init];
    
    return self;
}

@end

@implementation ImageAsset
@end

@implementation Tracker
@end