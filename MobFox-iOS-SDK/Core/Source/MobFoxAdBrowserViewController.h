#import <UIKit/UIKit.h>

@class MobFoxAdBrowserViewController;

@protocol MobFoxAdBrowserViewController <NSObject>

- (void)mobfoxAdBrowserControllerDidDismiss:(MobFoxAdBrowserViewController *)mobfoxAdBrowserController;

@end

@interface MobFoxAdBrowserViewController : UIViewController <UIWebViewDelegate>
{
	UIWebView *_webView;
	NSURL *_url;
	NSString *userAgent;
	NSString *mimeType;
	NSString *textEncodingName;
	NSMutableData *receivedData;
    float buttonSize;

	__unsafe_unretained id <MobFoxAdBrowserViewController> delegate;
}

@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, readonly, strong) NSURL  *url;

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, assign) __unsafe_unretained id <MobFoxAdBrowserViewController> delegate;

- (id)initWithUrl:(NSURL *)url;

@end
