# Changelog for Kustomer iOS SDK


## 0.1.14

* Added no history feature

## 0.1.13

* Removed autoreply logic
* Fixed back to chat issue

## 0.1.12

* Added single chat functionality

## 0.1.11

* Added end chat functionality
* Added custom form selection mechanism

## 0.1.10

* Fixed Localization files issue

## 0.1.9

* Added Localization features to support devices of different languages.
* Added support for chat volume control features. 


## 0.1.8

* Added async method `isChatAvailable` for getting the current online/offline state of your chat settings
* fixed bug where the chat assistant would prompt customer for email even though already being passed via customer `[Kustomer describeCustomer]`

## 0.1.7
* Fixed bug where conversational forms would crash if a question asked for a response but did not set a property

## 0.1.6

* Created a new method to present specific web page interface using the
* following format: [Kustomer presentCustomWebPage:@"url"];

## 0.1.5

* Fix in-app notification window layout issue on iPhone X.

## 0.1.4

* Exposed the current count of unread messages via `+[Kustomer unreadMessageCount]`.
* Changed initial screen behavior to open directly to the most recent chat when there are multiple chats for the user.

## 0.1.3

* Fixed a bug that would prevent time-based conversational campaigns from properly triggering.
* Mitigated a race condition that would cause campaign messages to be received with a large delay.

## 0.1.2

* Added support for tracking current page names; support conversational campaigns.
* Fixed retain cycle due to `NSTimer`.
* Improved tolerance settings on `NSTimer` to improve system performance.
* Fixed crash due to conversational forms with a no response values.
* Fixed conversational forms only working on first conversation per app launch.

## 0.1.1

* Added support for transparent gravatar images to match web SDK behavior.
* Improved socket connection behavior for new users.
* Made Kustomer `User-Agent` header reflect that of the container app.

## 0.1.0

* Significantly improved retry logic for failed message sends.
* Improved debug logging for network requests.
* Added support for displaying multiple avatars in chat headers.
* Reduced the main thread usage of paginated datasources to improve performance.
* Added unread count badge to the back button when in a chat.
