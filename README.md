<p align="center" >
  <img src="kustomer_logo.png" title="Kustomer logo" float=left>
</p>

----------------

<p align="center" >
  The iOS SDK for the <a href="https://www.kustomer.com/">Kustomer.com</a> mobile client
</p>

## Requirements

- A [Kustomer.com](https://www.kustomer.com/) API Key
- Xcode 8.0+
- iOS 9.0+

#### API Key

The Kustomer iOS SDK requires a valid API Key with role `org.tracking`. See [Getting Started - Create an API Key](https://dev.kustomer.com/v1/getting-started)


## Installation

#### CocoaPods

The preferred installation method is with [CocoaPods](https://cocoapods.org). Add the following to your `Podfile`:

```ruby
pod 'kustomer-ios-sdk', '~> 0.0'
```

#### Carthage

For [Carthage](https://github.com/Carthage/Carthage), add the following to your `Cartfile`:

```ogdl
github "kustomer/kustomer-ios-sdk" ~> 0.0
```

## Setup

In your project's UIApplicationDelegate:
```objective-c
#import <Kustomer/Kustomer.h>

static NSString *kKustomerAPIKey = @"YOUR_API_KEY";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Kustomer initializeWithAPIKey:kKustomerAPIKey];
    return YES;
}
```

When you want to present the Kustomer chat interface to your users:

```objective-c
KustomerViewController *kustomerViewController = [[KustomerViewController alloc] init];
[self presentViewController:kustomerViewController animated:YES completion:nil];
```
