#define CHECK_TARGET
#import <PSHeader/PS.h>
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
static CGFloat newSize;
static CGFloat newSizeSplit;

%hook UIKeyboardEmojiGraphicsTraits

- (CGFloat)emojiKeyWidth {
    CGFloat width = %orig;
    if (!enabled) return width;
    if ([UIKeyboardImplClass isSplit]) return newSizeSplit ?: width;
    return newSize ?: width;
}

- (CGFloat)minimumInteritemSpacing {
    return enabled && noHorizontalSpacing ? 0 : %orig;
}

- (CGFloat)minimumLineSpacing {
    return enabled && noVerticalSpacing ? 0 : %orig;
}

%end

%hook UIKeyboardEmojiCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self == nil || !enabled) return self;
    UILabel *label = [self valueForKey:@"_emojiLabel"];
    if ([label isKindOfClass:UILabel.class])
        label.lineBreakMode = 0;
    return self;
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
    if (isTarget(TargetTypeApps | TargetTypeGenericExtensions)) {
        UIKeyboardImplClass = %c(UIKeyboardImpl);
        notificationCallback(NULL, NULL, NULL, NULL, NULL);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, notificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
        %init;
    }
}
