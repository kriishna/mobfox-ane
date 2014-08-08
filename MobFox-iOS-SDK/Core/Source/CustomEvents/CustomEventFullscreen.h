//
//  CustomEventFullscreen.h
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 10.03.2014.
//
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CustomEventFullscreenDelegate.h"

@interface CustomEventFullscreen : NSObject

- (void)loadFullscreenWithOptionalParameters:(NSString *)optionalParameters trackingPixel:(NSString *)trackingPixel;

- (void)showFullscreenFromRootViewController:(UIViewController *)rootViewController;

- (void)didDisplayAd;

@property (nonatomic, assign) id<CustomEventFullscreenDelegate> delegate;
@property (nonatomic, retain) NSString* trackingPixel;

@end
