//
//  iAdCustomEventBanner.m
//  MobFoxSDKSource
//
//  Created by Michał Kapuściński on 13.03.2014.
//
//

#import "iAdCustomEventBanner.h"

@interface iAdCustomEventBanner()
@property (nonatomic, retain) ADBannerView *adBannerView;
@end

@implementation iAdCustomEventBanner


- (void)loadBannerWithSize:(CGSize)size optionalParameters:(NSString *)optionalParameters trackingPixel:(NSString *)trackingPixel
{
    if (self)
    {
        self.trackingPixel = trackingPixel;
        
        if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
            self.adBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        } else {
            self.adBannerView = [[ADBannerView alloc] init];
        }
        self.adBannerView.delegate = self;
        [self.adBannerView setFrame:CGRectMake(0, 0, size.width, size.height)];
    }
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    self.adBannerView.delegate = nil;
    self.adBannerView = nil;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self didDisplayAd];
    [self.delegate customEventBannerDidLoadAd:self.adBannerView];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self.delegate customEventBannerDidFailToLoadAd];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [self.delegate customEventBannerWillExpand];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [self.delegate customEventBannerWillClose];
}




@end
