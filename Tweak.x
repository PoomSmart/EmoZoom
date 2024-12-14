#define CHECK_TARGET
#import <PSHeader/PS.h>
#import <CoreGraphics/CoreGraphics.h>
@class UIKBTree;
#import <UIKit/UIKeyboardImpl.h>

Class UIKeyboardImplClass;

static CFStringRef domain = CFSTR("com.apple.UIKit");
static CFStringRef notificationString = CFSTR("com.apple.UIKit/preferences.changed");

static BOOL enabled;
static CGFloat newSize = 0;
static CGFloat newSizeSplit = 0;

%hook UIKeyboardEmojiGraphicsTraits

- (CGFloat)emojiKeyWidth {
    CGFloat width = %orig;
    if ([UIKeyboardImplClass isSplit]) return newSizeSplit ?: width;
    return newSize ?: width;
}

- (CGSize)fakeEmojiKeySize {
    CGSize size = %orig;
    if (newSize == 0) return size;
    if ([UIKeyboardImplClass isSplit]) {
        if (newSizeSplit == 0) return size;
        return CGSizeMake(newSizeSplit + 8, newSizeSplit + 16);
    }
    return CGSizeMake(newSize + 8, newSize + 16);
}

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    enabled = CFPreferencesGetAppBooleanValue(CFSTR("EmoZoomEnabled"), domain, NULL);
    newSize = CFPreferencesGetAppIntegerValue(CFSTR("EmoZoomNewSize"), domain, NULL);
    newSizeSplit = CFPreferencesGetAppIntegerValue(CFSTR("EmoZoomNewSizeSplit"), domain, NULL);
}

%ctor {
    if (isTarget(TargetTypeApps)) {
        UIKeyboardImplClass = %c(UIKeyboardImpl);
        notificationCallback(NULL, NULL, NULL, NULL, NULL);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, notificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
        %init;
    }
}
