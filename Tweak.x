#define CHECK_TARGET
#import <PSHeader/PS.h>
#import <CoreGraphics/CoreGraphics.h>
@class UIKBTree;
#import <UIKit/UIKit.h>
#import <UIKit/UIKeyboardImpl.h>

@interface UIKeyboardEmojiCollectionViewCell : UICollectionViewCell
@end

Class UIKeyboardImplClass;

static CFStringRef domain = CFSTR("com.apple.UIKit");
static CFStringRef notificationString = CFSTR("com.apple.UIKit/preferences.changed");

static BOOL enabled;
static BOOL noHorizontalSpacing;
static BOOL noVerticalSpacing;
static CGFloat newSize = 0;
static CGFloat newSizeSplit = 0;

%hook UIKeyboardEmojiGraphicsTraits

- (CGFloat)emojiKeyWidth {
    CGFloat width = %orig;
    if (!enabled) return width;
    if ([UIKeyboardImplClass isSplit]) return newSizeSplit ?: width;
    return newSize ?: width;
}

- (CGSize)fakeEmojiKeySize {
    CGSize size = %orig;
    if (!enabled || newSize == 0) return size;
    if ([UIKeyboardImplClass isSplit]) {
        if (newSizeSplit == 0) return size;
        return CGSizeMake(newSizeSplit + 8, newSizeSplit + 16);
    }
    return CGSizeMake(newSize + 8, newSize + 16);
}

- (CGFloat)minimumInteritemSpacing {
    return enabled && noHorizontalSpacing ? 0 : %orig;
}

- (CGFloat)minimumLineSpacing {
    return enabled && noVerticalSpacing ? 0 : %orig;
}

%end

%hook UIKeyboardEmojiCollectionViewCell

- (void)setEmoji:(id)emoji {
    %orig;
    if (!enabled || newSize >= 32) return;
    UILabel *label = [self valueForKey:@"_emojiLabel"];
    label.lineBreakMode = 0;
}

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    enabled = CFPreferencesGetAppBooleanValue(CFSTR("EmoZoomEnabled"), domain, NULL);
    newSize = CFPreferencesGetAppIntegerValue(CFSTR("EmoZoomNewSize"), domain, NULL);
    newSizeSplit = CFPreferencesGetAppIntegerValue(CFSTR("EmoZoomNewSizeSplit"), domain, NULL);
    noHorizontalSpacing = CFPreferencesGetAppBooleanValue(CFSTR("EmoZoomNoHorizontalSpacing"), domain, NULL);
    noVerticalSpacing = CFPreferencesGetAppBooleanValue(CFSTR("EmoZoomNoVerticalSpacing"), domain, NULL);
}

%ctor {
    if (isTarget(TargetTypeApps)) {
        UIKeyboardImplClass = %c(UIKeyboardImpl);
        notificationCallback(NULL, NULL, NULL, NULL, NULL);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, notificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
        %init;
    }
}
