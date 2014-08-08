//
//  AdMobCustomEventBanner.m
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 25.02.2014.
//
//

#import "AdMobCustomEventBanner.h"

@interface AdMobCustomEventBanner()
@property (nonatomic, retain) GADBannerView *adBannerView;
@end

@implementation AdMobCustomEventBanner

- (void)loadBannerWithSize:(CGSize)size optionalParameters:(NSString *)optionalParameters trackingPixel:(NSString *)trackingPixel
{
    self.trackingPixel = trackingPixel;
    [_adBannerView setFrame:CGRectMake(0, 0, size.width, size.height)];
    self.adBannerView.adUnitID = optionalParameters;
    self.adBannerView.rootViewController = [self.delegate viewControllerForPresentingModalView];
    
    Class requestClass = NSClassFromString(@"GADRequest");
    if(!requestClass) {
        [self.delegate customEventBannerDidFailToLoadAd];
        return;
    }

    GADRequest *request = [requestClass request];
    request.testDevices = [NSArray arrayWithObjects: GAD_SIMULATOR_ID, nil];
    [_adBannerView loadRequest:request];
}

- (id)init
{
    Class bannerClass = NSClassFromString(@"GADBannerView");
    if(!bannerClass) {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        self.adBannerView = [[bannerClass alloc] init];
        self.adBannerView.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    self.adBannerView.delegate = nil;
    self.adBannerView = nil;
}

#pragma mark GADBannerViewDelegate methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    [self didDisplayAd];
    [self.delegate customEventBannerDidLoadAd:self.adBannerView];
}

- (void)adView:(GADBannerView *)bannerView
didFailToReceiveAdWithError:(GADRequestError *)error
{
    [self.delegate customEventBannerDidFailToLoadAd];
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
    [self.delegate customEventBannerWillExpand];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView
{
    [self didDisplayAd];
    [self.delegate customEventBannerWillExpand];
}

- (void)adViewDidDismissScreen:(GADBannerView *)bannerView
{
    [self.delegate customEventBannerWillClose];
}



@end



