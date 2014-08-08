//
//  iAdCustomEventFullscreen.m
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 14.03.2014.
//
//

#import "iAdCustomEventFullscreen.h"
#import "CustomEventFullscreen.h"

@implementation iAdCustomEventFullscreen


- (void)loadFullscreenWithOptionalParameters:(NSString *)optionalParameters trackingPixel:(NSString *)trackingPixel
{
    self.trackingPixel = trackingPixel;
    interstitial_ = [[ADInterstitialAd alloc] init];
    interstitial_.delegate = self;
}

- (void)showFullscreenFromRootViewController:(UIViewController *)rootViewController
{
    [interstitial_ presentFromViewController:rootViewController];
}

#pragma mark delegate methods

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    [self.delegate customEventFullscreenDidFailToLoadAd];
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd {
    [self.delegate customEventFullscreenDidLoadAd:self];
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd {
    [self.delegate customEventFullscreenWillClose];
    
}

- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave {
    [self didDisplayAd];
    [self.delegate customEventFullscreenWillAppear];
    if(willLeave) {
        [self.delegate customEventFullscreenWillLeaveApplication];
    }
    return YES;
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
   
}




@end
