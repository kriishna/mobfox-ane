#import "MobFoxBannerView.h"
#import "NSString+MobFox.h"
#import "DTXMLDocument.h"
#import "DTXMLElement.h"
#import "UIView+FindViewController.h"
#import "NSURL+MobFox.h"
#import "MobFoxAdBrowserViewController.h"
#import "RedirectChecker.h"
#import "UIDevice+IdentifierAddition.h"
#import "AdMobCustomEventBanner.h"
#import "iAdCustomEventBanner.h"

#import <AdSupport/AdSupport.h>
#import "MobFoxMRAIDBannerAdapter.h"
#import "MPBaseBannerAdapter.h"
#import "MPAdView.h"
#import "MPAdConfiguration.h"
#import "CustomEvent.h"



NSString * const MobFoxErrorDomain = @"MobFox";

@interface MobFoxBannerView () <UIWebViewDelegate, MPBannerAdapterDelegate, CustomEventBannerDelegate, UIGestureRecognizerDelegate> {
    int ddLogLevel;
    NSString *skipOverlay;
    NSMutableArray *customEvents;
    BOOL wasUserAction;
}

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, strong) NSString *skipOverlay;
@property (nonatomic, strong) NSString *adType;
@property (nonatomic, strong) MobFoxMRAIDBannerAdapter *adapter;
@property (nonatomic, assign) CGFloat currentLatitude;
@property (nonatomic, assign) CGFloat currentLongitude;

@property (nonatomic, retain) UIView *bannerView;
@property (nonatomic, retain) CustomEventBanner *customEventBanner;

@property (nonatomic, strong) NSMutableDictionary *browserUserAgentDict;

@end



@implementation MobFoxBannerView
{
	RedirectChecker *redirectChecker;
}


- (void)setup
{

    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    self.userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];

    [self setUpBrowserUserAgentStrings];
    self.autoresizingMask = UIViewAutoresizingNone;
	self.backgroundColor = [UIColor clearColor];
	refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
    self.allowDelegateAssigmentToRequestAd = YES;

    customEvents = [[NSMutableArray alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
	{
		[self setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    delegate = nil;
	[_refreshTimer invalidate], _refreshTimer = nil;
}

#pragma mark Utilities

- (UIImage*)darkeningImageOfSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetGrayFillColor(ctx, 0, 1);
	CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return cropped;
}

- (NSURL *)serverURL
{
	return [NSURL URLWithString:self.requestURL];
}

#pragma mark Properties

- (void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setTransform:(CGAffineTransform)transform
{
	[super setTransform:transform];
	for (UIView *oneView in self.subviews)
	{
		oneView.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
	}
}

- (void)setDelegate:(id <MobFoxBannerViewDelegate>)newDelegate
{
	if (newDelegate != delegate)
	{
		delegate = newDelegate;

		if (delegate)
		{
			if(self.allowDelegateAssigmentToRequestAd) {
                [self requestAd];
            }
		}
	} else {
    }
}

- (void)setRefreshTimerActive:(BOOL)active
{
    if (refreshTimerOff) {
        return;
    }
    
    BOOL currentlyActive = (_refreshTimer!=nil);
	if (active == currentlyActive)
	{
		return;
	}
    
	if (active && !bannerViewActionInProgress && _refreshInterval)
	{
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(requestAd) userInfo:nil repeats:YES];
	}
	else
	{
		[_refreshTimer invalidate], _refreshTimer = nil;
	}
}

#pragma - mark Utilities

- (void)hideStatusBar
{
	UIApplication *app = [UIApplication sharedApplication];
	if (!app.statusBarHidden)
	{
		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		}
		else
		{
			[app setStatusBarHidden:YES];
		}

		_statusBarWasVisible = YES;
	}
}

- (void)showStatusBarIfNecessary
{
	if (_statusBarWasVisible)
	{
		UIApplication *app = [UIApplication sharedApplication];

		if ([app respondsToSelector:@selector(setStatusBarHidden:withAnimation:)])
		{
			[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		}
		else
		{
			[app setStatusBarHidden:NO];
		}
	}
}

- (void)setUpBrowserUserAgentStrings {

    NSArray *array;
    self.browserUserAgentDict = [NSMutableDictionary dictionaryWithCapacity:0];
	array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.2.2"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.2.1"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.2"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.9"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.8"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.7"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.6"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.5"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.4"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.3"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.2"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1.1"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.1"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.0.2"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.0.1"];
    array = @[@" Version/6.0", @" Safari/8536.25"];
    [self.browserUserAgentDict setObject:array forKey:@"6.0"];
    array = @[@" Version/5.1", @" Safari/7534.48.3"];
    [self.browserUserAgentDict setObject:array forKey:@"5.1.1"];
    array = @[@" Version/5.1", @" Safari/7534.48.3"];
    [self.browserUserAgentDict setObject:array forKey:@"5.1"];
    array = @[@" Version/5.1", @" Safari/7534.48.3"];
    [self.browserUserAgentDict setObject:array forKey:@"5.0.1"];
    array = @[@" Version/5.1", @" Safari/7534.48.3"];
    [self.browserUserAgentDict setObject:array forKey:@"5.0"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3.5"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3.4"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3.3"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3.2"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3.1"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.3"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.10"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.9"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.8"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.7"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.6"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.5"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2.1"];
    array = @[@" Version/5.0.2", @" Safari/6533.18.5"];
    [self.browserUserAgentDict setObject:array forKey:@"4.2"];
    array = @[@" Version/4.0.5", @" Safari/6531.22.7"];
    [self.browserUserAgentDict setObject:array forKey:@"4.1"];

}

- (NSString*)browserAgentString
{

    NSString *osVersion = [UIDevice currentDevice].systemVersion;
    NSArray *agentStringArray = self.browserUserAgentDict[osVersion];
    NSMutableString *agentString = [NSMutableString stringWithString:self.userAgent];

    NSRange range = [agentString rangeOfString:@"like Gecko)"];

    if (range.location != NSNotFound && range.length) {

        NSInteger theIndex = range.location + range.length;

		if ([agentStringArray objectAtIndex:0]) {
			[agentString insertString:[agentStringArray objectAtIndex:0] atIndex:theIndex];
			[agentString appendString:[agentStringArray objectAtIndex:1]];
		}
        else {
			[agentString insertString:@" Version/unknown" atIndex:theIndex];
			[agentString appendString:@" Safari/unknown"];
		}

    }

    return agentString;
}


#pragma mark MRAID (MOPUB required)

- (UIViewController *)viewControllerForPresentingModalView
{
	return [self firstAvailableUIViewController];
}

#pragma mark Ad Handling
- (void)reportSuccess
{
	bannerLoaded = YES;
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewDidLoadMobFoxAd:)])
	{
		[delegate mobfoxBannerViewDidLoadMobFoxAd:self];
	}
}

- (void)reportRefresh
{
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewDidLoadRefreshedAd:)])
	{
		[delegate mobfoxBannerViewDidLoadRefreshedAd:self];
	}
}

- (void)reportError:(NSError *)error
{
	bannerLoaded = NO;
	if ([delegate respondsToSelector:@selector(mobfoxBannerView:didFailToReceiveAdWithError:)])
	{
		[delegate mobfoxBannerView:self didFailToReceiveAdWithError:error];
	}
}

- (void)setupAdFromXml:(DTXMLDocument *)xml
{
	if ([xml.documentRoot.name isEqualToString:@"error"])
	{
		NSString *errorMsg = xml.documentRoot.text;

		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];

		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
    NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];

    DTXMLElement *htmlElement = [xml.documentRoot getNamedChild:@"htmlString"];
    self.skipOverlay = [htmlElement.attributes objectForKey:@"skipoverlaybutton"];

	NSString *clickType = [xml.documentRoot getNamedChild:@"clicktype"].text;
	if ([clickType isEqualToString:@"inapp"])
	{
		_tapThroughLeavesApp = NO;
	}
	else
	{
		_tapThroughLeavesApp = YES;
	}
	NSString *clickUrlString = [xml.documentRoot getNamedChild:@"clickurl"].text;
	if ([clickUrlString length])
	{
		_tapThroughURL = [NSURL URLWithString:clickUrlString];
	}
	_shouldScaleWebView = [[xml.documentRoot getNamedChild:@"scale"].text isEqualToString:@"yes"];
	_shouldSkipLinkPreflight = [[xml.documentRoot getNamedChild:@"skippreflight"].text isEqualToString:@"yes"];
	_bannerView = nil;
	adType = [xml.documentRoot.attributes objectForKey:@"type"];
    refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
	_refreshInterval = [[xml.documentRoot getNamedChild:@"refresh"].text intValue];
	[self setRefreshTimerActive:YES];
	if ([adType isEqualToString:@"imageAd"])
	{
		if (!__bannerImage)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error loading banner image" forKey:NSLocalizedDescriptionKey];
			NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
			[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
			return;
		}

		CGFloat bannerWidth = [[xml.documentRoot getNamedChild:@"bannerwidth"].text floatValue];
		CGFloat bannerHeight = [[xml.documentRoot getNamedChild:@"bannerheight"].text floatValue];

		UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(0, 0, bannerWidth, bannerHeight)];
		[button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];

		[button setImage:__bannerImage forState:UIControlStateNormal];
		button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
		_bannerView = button;
	}
	else if ([adType isEqualToString:@"textAd"])
	{
		NSString *html = [xml.documentRoot getNamedChild:@"htmlString"].text;

        CGSize bannerSize;
        if(adspaceHeight && adspaceWidth)
        {
            bannerSize = CGSizeMake(adspaceWidth, adspaceHeight);
        }
		else if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
		{
			bannerSize = CGSizeMake(728, 90);
		}
        else
        {
            bannerSize = CGSizeMake(320, 50);
        }

		UIWebView *webView=[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, bannerSize.width, bannerSize.height)];

		[webView loadHTMLString:html baseURL:nil];

		if([skipOverlay isEqualToString:@"1"]) {

            wasUserAction = NO;
            
            webView.delegate = (id)self;
            webView.userInteractionEnabled = YES;
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
            
            [webView addGestureRecognizer:tap];
            
            tap.delegate = self;
            
            
        } else {

            webView.delegate = nil;
            webView.userInteractionEnabled = NO;
            
//          add overlay later, only if no custom event is shown
        }
		webView.backgroundColor = [UIColor clearColor];
		webView.opaque = NO;

		_bannerView = webView;
	}
    else if ([adType isEqualToString:@"mraidAd"])
	{
        refreshAnimation = UIViewAnimationTransitionNone;
        _refreshInterval = 0;
        [self setRefreshTimerActive:NO];

        NSString *html = [xml.documentRoot getNamedChild:@"htmlString"].text;
        NSData  *_data = [html dataUsingEncoding:NSUTF8StringEncoding];

        if(!self.adapter) {
            self.adapter = [[MobFoxMRAIDBannerAdapter alloc] initWithDelegate:self];
        }
        
        CGSize size;
        if(adspaceHeight && adspaceWidth)
        {
            size = CGSizeMake(adspaceWidth, adspaceHeight);
        }
        else if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
		{
			size = CGSizeMake(728, 90);
		}
        else
        {
            size = CGSizeMake(320, 50);
        }
        
        
        MPAdConfiguration *mPAdConfiguration = [[MPAdConfiguration alloc] init];

        mPAdConfiguration.adResponseData = _data;
        mPAdConfiguration.preferredSize = size;
        mPAdConfiguration.adType = MPAdTypeBanner;

        [self.adapter getAdWithConfiguration:mPAdConfiguration containerSize:size];

        _bannerView = self.adapter.adView;
        [self.adapter unregisterDelegate];
        self.adapter = nil;

    }   else if ([adType isEqualToString:@"noAd"])
	{
        //do nothing, there still can be custom events.
	}
	else if ([adType isEqualToString:@"error"])
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:NSLocalizedDescriptionKey];

		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	else
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown ad type '%@'", adType] forKey:NSLocalizedDescriptionKey];

		NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
		[self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}

    [customEvents removeAllObjects];
    DTXMLElement *customEventsElement = [xml.documentRoot getNamedChild:@"customevents"];
    _customEventBanner = nil;

    if(customEventsElement)
    {
        
        NSArray *customEventElements = [customEventsElement getNamedChildren:@"customevent"];
        for(int i=0; i<[customEventElements count];i++)
        {
            @try {
                DTXMLElement *customEventElement = [customEventElements objectAtIndex:i];
                CustomEvent *customEvent = [[CustomEvent alloc] init];
                customEvent.className = [customEventElement getNamedChild:@"class"].text;
                customEvent.optionalParameter = [customEventElement getNamedChild:@"parameter"].text;
                customEvent.pixelUrl = [customEventElement getNamedChild:@"pixel"].text;
                [customEvents addObject:customEvent];
            }
            @catch (NSException *exception) {
                NSLog(@"Error creating custom event");
            }
        }
        
    }
    
    
	if (_bannerView && [customEvents count] == 0)
	{
        [self showBannerView:_bannerView withPreviousSubviews:previousSubviews];
	} else
    {
        [self loadCustomEventBanner];
        if (!_customEventBanner)
        {
            [customEvents removeAllObjects];
            if(_bannerView)
            {
                [self showBannerView:_bannerView withPreviousSubviews:previousSubviews];
            }
            else {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No inventory for ad request" forKey:NSLocalizedDescriptionKey];
                
                _refreshInterval = 20;
                [self setRefreshTimerActive:YES];
                
                NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorInventoryUnavailable userInfo:userInfo];
                [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];

            }
        } else {
            _refreshInterval = 30; //enable banner refresh for  custom events.
            [self setRefreshTimerActive:YES];
        }
    }
}

- (void)showBannerView:(UIView*)nextBannerView withPreviousSubviews:(NSArray*)previousSubviews
{
    if([adType isEqualToString:@"textAd"] && !skipOverlay && !_customEventBanner) { //create overlay only if necessary, to not interfere with custom events
        UIImage *grayingImage = [self darkeningImageOfSize:_bannerView.frame.size];
        
        UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:_bannerView.bounds];
        [button addTarget:self action:@selector(tapThrough:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:grayingImage forState:UIControlStateHighlighted];
        button.alpha = 0.47;
        
        button.center = CGPointMake(roundf(self.bounds.size.width / 2.0), roundf(self.bounds.size.height / 2.0));
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        [self addSubview:button];
        
    }
    
    nextBannerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    if (CGRectEqualToRect(self.bounds, CGRectZero))
    {
        self.bounds = nextBannerView.bounds;
    }
    
    if ([previousSubviews count])
    {
        [UIView beginAnimations:@"flip" context:nil];
        [UIView setAnimationDuration:1.5];
        [UIView setAnimationTransition:refreshAnimation forView:self cache:NO];
    }
    
    [self insertSubview:nextBannerView atIndex:0];
    [previousSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if ([previousSubviews count]) {
        [UIView commitAnimations];
        
        [self performSelectorOnMainThread:@selector(reportRefresh) withObject:nil waitUntilDone:YES];
    } else {
        [self performSelectorOnMainThread:@selector(reportSuccess) withObject:nil waitUntilDone:YES];
    }
}

- (void)loadCustomEventBanner
{
    CGSize size;
    if(adspaceHeight && adspaceWidth)
    {
        size = CGSizeMake(adspaceWidth, adspaceHeight);
    }
    else if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
    {
        size = CGSizeMake(728, 90);
    }
    else
    {
        size = CGSizeMake(320, 50);
    }
    _customEventBanner = nil;
    while ([customEvents count] > 0)
    {
        @try
        {
            CustomEvent *event = [customEvents objectAtIndex:0];
            [customEvents removeObjectAtIndex:0];
            
            NSString* className = [NSString stringWithFormat:@"%@CustomEventBanner",event.className];
            Class customClass = NSClassFromString(className);
            if(customClass) {
                _customEventBanner = [[customClass alloc] init];
                _customEventBanner.delegate = self;
                [_customEventBanner loadBannerWithSize:size optionalParameters:event.optionalParameter trackingPixel:event.pixelUrl];
                break;
            } else {
                NSLog(@"custom event for %@ not implemented!",event.className);
            }
        }
        @catch (NSException *exception) {
            _customEventBanner = nil;
            NSLog( @"Exception while creating custom event!" );
            NSLog( @"Name: %@", exception.name);
            NSLog( @"Reason: %@", exception.reason );
        }
        
    }
}

- (void)asyncRequestAdWithPublisherId:(NSString *)publisherId
{
	@autoreleasepool
	{
        NSString *mRaidCapable = @"1";
        
        NSString *adWidth = [NSString stringWithFormat:@"%d",(int)adspaceWidth];
        NSString *adHeight = [NSString stringWithFormat:@"%d",(int)adspaceHeight];
        
        int r = arc4random_uniform(50000);
        NSString *random = [NSString stringWithFormat:@"%d", r];
        
        NSString *adStrict;
        if (adspaceStrict)
        {
            adStrict = @"1";
        }
        else
        {
            adStrict = @"0";
        }
        
        NSString *requestType;
        if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
        {
            requestType = @"iphone_app";
        }
        else
        {
            requestType = @"ipad_app";
        }

        NSString *osVersion = [UIDevice currentDevice].systemVersion;

        NSString *requestString;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        NSString *iosadvid;
        if ([ASIdentifierManager instancesRespondToSelector:@selector(advertisingIdentifier )]) {
            iosadvid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            NSString *o_iosadvidlimit = @"0";
            if (NSClassFromString(@"ASIdentifierManager")) {

                if (![ASIdentifierManager sharedManager].advertisingTrackingEnabled) {
                    o_iosadvidlimit = @"1";
                }
            }
            
            requestString=[NSString stringWithFormat:@"c.mraid=%@&c_customevents=1&r_type=banner&o_iosadvidlimit=%@&rt=%@&u=%@&u_wv=%@&u_br=%@&o_iosadvid=%@&v=%@&s=%@&iphone_osversion=%@&spot_id=%@&r_random=%@",
						   [mRaidCapable stringByUrlEncoding],
						   [o_iosadvidlimit stringByUrlEncoding],
						   [requestType stringByUrlEncoding],
						   [self.userAgent stringByUrlEncoding],
						   [self.userAgent stringByUrlEncoding],
						   [[self browserAgentString] stringByUrlEncoding],
						   [iosadvid stringByUrlEncoding],
						   [SDK_VERSION stringByUrlEncoding],
						   [publisherId stringByUrlEncoding],
						   [osVersion stringByUrlEncoding],
						   [advertisingSection?advertisingSection:@"" stringByUrlEncoding],
                           [random stringByUrlEncoding]];
            
        } else {
			requestString=[NSString stringWithFormat:@"c.mraid=%@&c_customevents=1&r_type=banner&rt=%@&u=%@&u_wv=%@&u_br=%@&v=%@&s=%@&iphone_osversion=%@&spot_id=%@&r_random=%@",
                           [mRaidCapable stringByUrlEncoding],
                           [requestType stringByUrlEncoding],
                           [self.userAgent stringByUrlEncoding],
                           [self.userAgent stringByUrlEncoding],
                           [[self browserAgentString] stringByUrlEncoding],
                           [SDK_VERSION stringByUrlEncoding],
                           [publisherId stringByUrlEncoding],
                           [osVersion stringByUrlEncoding],
                           [advertisingSection?advertisingSection:@"" stringByUrlEncoding],
                           [random stringByUrlEncoding]];

        }
#else

        requestString=[NSString stringWithFormat:@"c.mraid=%@&c_customevents=1&r_type=banner&rt=%@&u=%@&u_wv=%@&u_br=%@&v=%@&s=%@&iphone_osversion=%@&spot_id=%@&r_random=%@",
                       [mRaidCapable stringByUrlEncoding],
                       [requestType stringByUrlEncoding],
                       [self.userAgent stringByUrlEncoding],
                       [self.userAgent stringByUrlEncoding],
                       [[self browserAgentString] stringByUrlEncoding],
                       [SDK_VERSION stringByUrlEncoding],
                       [publisherId stringByUrlEncoding],
                       [osVersion stringByUrlEncoding],
                       [advertisingSection?advertisingSection:@"" stringByUrlEncoding],
                       [random stringByUrlEncoding]];

#endif
        NSString *requestStringWithLocation;
        if(locationAwareAdverts && self.currentLatitude && self.currentLongitude)
        {
            NSString *latitudeString = [NSString stringWithFormat:@"%+.6f", self.currentLatitude];
            NSString *longitudeString = [NSString stringWithFormat:@"%+.6f", self.currentLongitude];
            
            requestStringWithLocation = [NSString stringWithFormat:@"%@&latitude=%@&longitude=%@",
                                 requestString,
                                 [latitudeString stringByUrlEncoding],
                                 [longitudeString stringByUrlEncoding]
                                 ];
        }
        else
        {
            requestStringWithLocation = requestString;
        }
        
        
        NSString *fullRequestString;
        if(adspaceHeight && adspaceWidth)
        {
            fullRequestString = [NSString stringWithFormat:@"%@&adspace.width=%@&adspace.height=%@&adspace.strict=%@",
                                requestStringWithLocation,
                                [adWidth stringByUrlEncoding],
                                [adHeight stringByUrlEncoding],
                                [adStrict stringByUrlEncoding]
                                ];
        }
        else
        {
            fullRequestString = requestStringWithLocation;
        }
        
        if([userGender isEqualToString:@"female"]) {
            fullRequestString = [NSString stringWithFormat:@"%@&demo.gender=f",
                                 fullRequestString];
        } else if([userGender isEqualToString:@"male"]) {
            fullRequestString = [NSString stringWithFormat:@"%@&demo.gender=m",
                                 fullRequestString];
        }
        if(userAge) {
            NSString *age = [NSString stringWithFormat:@"%d",(int)userAge];
            fullRequestString = [NSString stringWithFormat:@"%@&demo.age=%@",
                                 fullRequestString,
                                 [age stringByUrlEncoding]];
        }
        if(keywords) {
            NSString *words = [keywords componentsJoinedByString:@","];
            fullRequestString = [NSString stringWithFormat:@"%@&demo.keywords=%@",
                                 fullRequestString,
                                 words];
            
        }
        
        NSURL *serverURL = [self serverURL];

        if (!serverURL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error - no or invalid requestURL. Please set requestURL" forKey:NSLocalizedDescriptionKey];

            NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
            [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
            return;
        }

        NSURL *url;
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", serverURL, fullRequestString]];
        

        NSMutableURLRequest *request;
        NSError *error;
        NSURLResponse *response;
        NSData *dataReply;

        request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod: @"GET"];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
        [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];

        dataReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        DTXMLDocument *xml = [DTXMLDocument documentWithData:dataReply];

        if (!xml)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Error parsing xml response from server" forKey:NSLocalizedDescriptionKey];

            NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
            [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
            return;
        }
        NSString *bannerUrlString = [xml.documentRoot getNamedChild:@"imageurl"].text;
        __bannerImage = nil;
        if ([bannerUrlString length])
        {
            NSURL *bannerUrl = [NSURL URLWithString:bannerUrlString];
            __bannerImage = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:bannerUrl]];
        }
        
        [self performSelectorOnMainThread:@selector(setupAdFromXml:) withObject:xml waitUntilDone:YES];

	}

}

- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude {
    self.currentLatitude = latitude;
    self.currentLongitude = longitude;
}

- (void)showErrorLabelWithText:(NSString *)text
{
	UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor whiteColor];
	label.font = [UIFont boldSystemFontOfSize:12];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor redColor];
	label.text = text;
	[self addSubview:label];
}

- (void)requestAd
{

    if (!delegate)
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate not set"];

		return;
	}
	if (![delegate respondsToSelector:@selector(publisherIdForMobFoxBannerView:)])
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate does not implement publisherIdForMobFoxBannerView:"];

		return;
	}
	NSString *publisherId = [delegate publisherIdForMobFoxBannerView:self];
	if (![publisherId length])
	{
		[self showErrorLabelWithText:@"MobFoxBannerViewDelegate returned invalid publisher ID."];

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Invalid publisher ID or Publisher ID not set" forKey:NSLocalizedDescriptionKey];

        NSError *error = [NSError errorWithDomain:MobFoxErrorDomain code:MobFoxErrorUnknown userInfo:userInfo];
        [self performSelectorOnMainThread:@selector(reportError:) withObject:error waitUntilDone:YES];
		return;
	}
	[self performSelectorInBackground:@selector(asyncRequestAdWithPublisherId:) withObject:publisherId];
}


#pragma mark Interaction

- (void)checker:(RedirectChecker *)checker detectedRedirectionTo:(NSURL *)redirectURL
{
	if ([redirectURL isDeviceSupported])
	{
		[[UIApplication sharedApplication] openURL:redirectURL];
		return;
	}
	UIViewController *viewController = [self firstAvailableUIViewController];
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:redirectURL];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	[self hideStatusBar];
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillPresent:)])
    {
        [delegate mobfoxBannerViewActionWillPresent:self];
    }
    [viewController presentModalViewController:browser animated:YES];
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFinishWithData:(NSData *)data
{
	UIViewController *viewController = [self firstAvailableUIViewController];
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:nil];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	NSString *scheme = [_tapThroughURL scheme];
	NSString *host = [_tapThroughURL host];
	NSString *path = [[_tapThroughURL path] stringByDeletingLastPathComponent];
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@/", scheme, host, path]];
	[browser.webView loadData:data MIMEType:checker.mimeType textEncodingName:checker.textEncodingName baseURL:baseURL];
	[self hideStatusBar];
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillPresent:)])
    {
        [delegate mobfoxBannerViewActionWillPresent:self];
    }
    [viewController presentModalViewController:browser animated:YES];
	bannerViewActionInProgress = YES;
}

- (void)checker:(RedirectChecker *)checker didFailWithError:(NSError *)error
{
	bannerViewActionInProgress = NO;
}

- (void)tapThrough:(id)sender
{
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionShouldBegin:willLeaveApplication:)])
	{
		BOOL allowAd = [delegate mobfoxBannerViewActionShouldBegin:self willLeaveApplication:_tapThroughLeavesApp];

		if (!allowAd)
		{
			return;
		}
	}
	if (_tapThroughLeavesApp || [_tapThroughURL isDeviceSupported])
	{

        if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillLeaveApplication:)])
        {
            [delegate mobfoxBannerViewActionWillLeaveApplication:self];
        }

        [[UIApplication sharedApplication]openURL:_tapThroughURL];
		return;
	}
	UIViewController *viewController = [self firstAvailableUIViewController];
	if (!viewController)
	{
		return;
	}
	[self setRefreshTimerActive:NO];
	if (!_shouldSkipLinkPreflight)
	{
		redirectChecker = [[RedirectChecker alloc] initWithURL:_tapThroughURL userAgent:self.userAgent delegate:(id)self];
		return;
	}
	MobFoxAdBrowserViewController *browser = [[MobFoxAdBrowserViewController alloc] initWithUrl:_tapThroughURL];
	browser.delegate = (id)self;
	browser.userAgent = self.userAgent;
	browser.webView.scalesPageToFit = _shouldScaleWebView;
	[self hideStatusBar];
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillPresent:)])
    {
        [delegate mobfoxBannerViewActionWillPresent:self];
    }
    [viewController presentModalViewController:browser animated:YES];
	bannerViewActionInProgress = YES;
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    // this is called after gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer: so we can safely remove the delegate here
    if (gestureRecognizer.delegate) {
        gestureRecognizer.delegate = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    wasUserAction = YES; //countermeasure for malicious, "auto-clicking" banners
    return YES;
}

- (void)mobfoxAdBrowserControllerDidDismiss:(MobFoxAdBrowserViewController *)mobfoxAdBrowserController
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillFinish:)])
	{
		[delegate mobfoxBannerViewActionWillFinish:self];
	}
    [self showStatusBarIfNecessary];
	[mobfoxAdBrowserController dismissModalViewControllerAnimated:YES];
	bannerViewActionInProgress = NO;
	[self setRefreshTimerActive:YES];
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionDidFinish:)])
	{
		[delegate mobfoxBannerViewActionDidFinish:self];
	}
}

#pragma mark WebView Delegate (Text Ads)

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{

    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
        if (![urlString isEqualToString:@"about:blank"] && ![urlString isEqualToString:@""] && wasUserAction) {
            if(_tapThroughURL) {
                NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:_tapThroughURL];
                [request2 setHTTPMethod: @"GET"];
                [NSURLConnection sendAsynchronousRequest:request2 queue:[[NSOperationQueue alloc] init] completionHandler:nil];
            }
            _tapThroughURL = url;
            [self tapThrough:nil];
            return NO;
        } else {
            return YES;
        }

	}
    else if(navigationType == UIWebViewNavigationTypeOther)
    {
        NSString* documentURL = [[request mainDocumentURL] absoluteString];
        
        if( [urlString isEqualToString:documentURL]) {             //if they are the same this is a javascript href click
            if (![urlString isEqualToString:@"about:blank"] && ![urlString isEqualToString:@""] && wasUserAction) {
                if(_tapThroughURL) {
                    NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:_tapThroughURL];
                    [request2 setHTTPMethod: @"GET"];
                    [NSURLConnection sendAsynchronousRequest:request2 queue:[[NSOperationQueue alloc] init] completionHandler:nil];
                }
                _tapThroughURL = url;
                [self tapThrough:nil];
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark MPBannerAdapterDelegate
- (MPAdView *)banner{
    return (MPAdView *)self;
}

- (id<MPAdViewDelegate>)bannerDelegate{
    return nil;
}

- (CLLocation *)location{
    return nil;
}

- (void)adapter:(MPBaseBannerAdapter *)adapter didFinishLoadingAd:(UIView *)ad
{
    bannerLoaded = YES;
	if ([delegate respondsToSelector:@selector(mobfoxBannerViewDidLoadMobFoxAd:)])
	{
		[delegate mobfoxBannerViewDidLoadMobFoxAd:self];
	}
}

- (void)adapter:(MPBaseBannerAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
    bannerLoaded = NO;
	if ([delegate respondsToSelector:@selector(mobfoxBannerView:didFailToReceiveAdWithError:)])
	{
		[delegate mobfoxBannerView:self didFailToReceiveAdWithError:error];
	}
}

- (void)userActionWillBeginForAdapter:(MPBaseBannerAdapter *)adapter
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillPresent:)])
    {
        [delegate mobfoxBannerViewActionWillPresent:self];
    }
}

- (void)userActionDidFinishForAdapter:(MPBaseBannerAdapter *)adapter
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionDidFinish:)])
	{
		[delegate mobfoxBannerViewActionWillFinish:self];
	}
}

- (void)userWillLeaveApplicationFromAdapter:(MPBaseBannerAdapter *)adapter
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillLeaveApplication:)])
    {
        [delegate mobfoxBannerViewActionWillLeaveApplication:self];
    }
}

- (CGSize)maximumAdSize
{
    if(adspaceWidth && adspaceHeight)
    {
        return CGSizeMake(adspaceWidth, adspaceHeight);
    }
	return CGSizeMake(320.0, 50.0);
}

- (MPNativeAdOrientation)allowedNativeAdsOrientation
{
	return NO;
}

- (void)pauseAutorefresh
{
}

- (void)resumeAutorefreshIfEnabled
{
}

#pragma mark CustomEventBannerDelegate

- (void)customEventBannerDidLoadAd:(UIView *)ad {
    bannerLoaded = YES;
    NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];
    [self showBannerView:ad withPreviousSubviews:previousSubviews];
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewDidLoadMobFoxAd:)])
	{
		[delegate mobfoxBannerViewDidLoadMobFoxAd:self];
	}
}

- (void)customEventBannerDidFailToLoadAd
{
    [self loadCustomEventBanner];
    NSArray *previousSubviews = [NSArray arrayWithArray:self.subviews];
    if (_customEventBanner)
    {
        return;
    }
    else if (_bannerView)
    {
        [self showBannerView:_bannerView withPreviousSubviews:previousSubviews];
    }
    else
    {
        bannerLoaded = NO;
        if ([delegate respondsToSelector:@selector(mobfoxBannerView:didFailToReceiveAdWithError:)])
        {
            [delegate mobfoxBannerView:self didFailToReceiveAdWithError:nil];
        }
    }
}

- (void)customEventBannerWillExpand
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillPresent:)])
	{
		[delegate mobfoxBannerViewActionWillPresent:self];
	}
}

- (void)customEventBannerWillClose
{
    if ([delegate respondsToSelector:@selector(mobfoxBannerViewActionWillFinish:)])
	{
		[delegate mobfoxBannerViewActionWillFinish:self];
	}
}


#pragma mark Notifications
- (void) appDidBecomeActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:YES];
}

- (void) appWillResignActive:(NSNotification *)notification
{
	[self setRefreshTimerActive:NO];
}

@synthesize delegate;
@synthesize advertisingSection;
@synthesize bannerLoaded;
@synthesize bannerViewActionInProgress;
@synthesize refreshAnimation;
@synthesize refreshTimerOff;
@synthesize requestURL;
@synthesize allowDelegateAssigmentToRequestAd;
@synthesize userAgent;
@synthesize skipOverlay;
@synthesize adType;
@synthesize adapter;
@synthesize adspaceHeight;
@synthesize adspaceWidth;
@synthesize adspaceStrict;
@synthesize locationAwareAdverts;
@synthesize userGender,userAge,keywords;




@end

