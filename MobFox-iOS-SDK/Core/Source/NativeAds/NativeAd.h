//
//  NativeAd.h
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 21.05.2014.
//
//

#import <Foundation/Foundation.h>
@class ImageAsset;
@class Tracker;
@class UIImage;

@interface NativeAd : NSObject
@property (nonatomic, strong) NSString* clickUrl;
@property (nonatomic, strong) NSMutableDictionary* imageAssets;
@property (nonatomic, strong) NSMutableDictionary* textAssets;
@property (nonatomic, strong) NSMutableArray* trackers;

@end

@interface ImageAsset : NSObject
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSString* width;
@property (nonatomic, strong) NSString* height;
@end

@interface Tracker : NSObject
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* url;
@end