# Changelog for Kustomer iOS SDK

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
