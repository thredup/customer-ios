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
pod 'Kustomer', :git => 'https://github.com/kustomer/customer-ios.git'
```

#### Carthage

For [Carthage](https://github.com/Carthage/Carthage), add the following to your `Cartfile`:

```ogdl
github "kustomer/customer-ios" ~> 0.0.1
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
// or
[Kustomer presentSupport];
```

### Additional API Reference

```objective-c
// Initialize the Kustomer iOS SDK with an API key, and start a user session.
[Kustomer initializeWithAPIKey:@"API_KEY"];
```

```objective-c
// Convenience method that will present the chat interface on the topmost view controller.
[Kustomer presentSupport];
```

```objective-c
// Convenience methods that will present a browser interface pointing to your KnowledgeBase.
[Kustomer presentKnowledgeBase];
```

```objective-c
// Resets the user session, clearing the user's access to any existing chats from the device.
[Kustomer resetTracking];
```

```objective-c
// Securely identify a customer. Requires a valid JSON Web Token.
[Kustomer identify:@"SECURE_ID_HASH"];

/*
 Identifying users is the best way to ensure your users have a great chat experience because
 it gives them access to all of the previous conversations across devices.
 By default, users can see their conversation history only on a single device. By including a secure
 hash with the ID of your user, you can securely identify that user and grant them access.
*/

/*
 JSON Web Token:
 The JWT used for secure identification must use HMAC SHA256 and include the following header and claims:
 Header: @{ @"alg" : @"HS256", @"typ" : @"JWT" }
 Claims: @{ @"externalId" : @"your_user_id", @"iat" : @"current_time_utc" }
 NOTE: tokens with an @"iat" older than 15 minutes will be rejected
*/
```
