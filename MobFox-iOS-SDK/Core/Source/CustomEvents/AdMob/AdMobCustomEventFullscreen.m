//
//  AdMobCustomEventFullscreen.m
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 10.03.2014.
//
//

#import "AdMobCustomEventFullscreen.h"

@implementation AdMobCustomEventFullscreen

- (void)loadFullscreenWithOptionalParameters:(NSString *)optionalParameters trackingPixel:(NSString *)trackingPixel
{
    self.trackingPixel = trackingPixel;
    if(interstitial_) {
        interstitial_.delegate = nil;
        interstitial_ = nil;
    }
    
    Class interstitialClass = NSClassFromString(@"GADInterstitial");
    Class requestClass = NSClassFromString(@"GADRequest");
    if(!interstitialClass || !requestClass) {
        [self.delegate customEventFullscreenDidFailToLoadAd];
        return;
    }
    
    interstitial_ = [[interstitialClass alloc] init];
    interstitial_.adUnitID = optionalParameters;
    interstitial_.delegate = self;
    
    GADRequest *request = [requestClass request];
    request.testDevices = [NSArray arrayWithObjects: GAD_SIMULATOR_ID, nil];
    
    [interstitial_ loadRequest:request];
}

- (void)showFullscreenFromRootViewController:(UIViewController *)rootViewController
{
    [interstitial_ presentFromRootViewController:rootViewController];
}

- (void)dealloc
{
    interstitial_.delegate = nil;
    interstitial_ = nil;
}

#pragma mark GADInterstitialDelegate methods
- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial
{
    [self.delegate customEventFullscreenDidLoadAd:self];
}

- (void)interstitial:(GADInterstitial *)interstitial didFailToReceiveAdWithError:(GADRequestError *)error
{
    [self.delegate customEventFullscreenDidFailToLoadAd];
}


- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial
{
    [self didDisplayAd];
    [self.delegate customEventFullscreenWillAppear];
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)interstitial
{
    [self.delegate customEventFullscreenWillClose];
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)interstitial
{
    [self.delegate customEventFullscreenWillLeaveApplication];
}



@end
