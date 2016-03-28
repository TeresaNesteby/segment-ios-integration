//
//  SEGKahunaIntegration.m
//
//  Copyright (c) 2012-2016 Kahuna. All rights reserved.
//

#import "SEGKahunaIntegration.h"
#import <Kahuna/Kahuna.h>
#import <Analytics/SEGAnalyticsUtils.h>
#import "SEGKahunaDefines.h"
#import <Analytics/SEGAnalytics.h>

#define KAHUNA_NOT_STRING_NULL_EMPTY(obj) (obj != nil && [obj isKindOfClass:[NSString class]] && ![@"" isEqualToString:obj])


@implementation SEGKahunaIntegration

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey
{
    id revenueProperty = nil;

    for (NSString *key in dictionary.allKeys) {
        if ([key caseInsensitiveCompare:revenueKey] == NSOrderedSame) {
            revenueProperty = dictionary[key];
            break;
        }
    }

    if (revenueProperty) {
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            // Format the revenue.
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            return [formatter numberFromString:revenueProperty];
        } else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
            return revenueProperty;
        }
    }
    return nil;
}

- (id)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        if (!self.kahunaClass) {
            self.kahunaClass = [Kahuna class];
        }
        
        self.settings = settings;
        NSString *apiKey = [self.settings objectForKey:@"apiKey"];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
        [self.kahunaClass performSelector:@selector(setSDKWrapper:withVersion:) withObject:SEGMENT withObject:[SEGAnalytics version]];
#pragma GCC diagnostic pop
        [self.kahunaClass launchWithKey:apiKey];

        _kahunaCredentialsKeys = [NSSet setWithObjects:KAHUNA_CREDENTIAL_USERNAME,
                                                       KAHUNA_CREDENTIAL_EMAIL,
                                                       KAHUNA_CREDENTIAL_FACEBOOK,
                                                       KAHUNA_CREDENTIAL_TWITTER,
                                                       KAHUNA_CREDENTIAL_LINKEDIN,
                                                       KAHUNA_CREDENTIAL_USER_ID,
                                                       KAHUNA_CREDENTIAL_GOOGLE_PLUS,
                                                       KAHUNA_CREDENTIAL_INSTALL_TOKEN, nil];
    }
    return self;
}

- (void)identify:(SEGIdentifyPayload *)payload {
    [self identifyInternal:payload.userId traits:payload.traits];
}

- (void)identifyInternal:(NSString *)userId traits:(NSDictionary *)traits
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    KahunaUserCredentials *credentials = [self.kahunaClass createUserCredentials];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(userId)) {
        [credentials addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:userId];
    }

    // We will go through each of the above keys, and try to see if the traits has that key. If it does, then we will add the key:value as a credential.
    // All other traits is being tracked as an attribute.
    for (NSString *eachKey in traits) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(eachKey)) continue;

        NSString *eachValue = [traits objectForKey:eachKey];
        if (KAHUNA_NOT_STRING_NULL_EMPTY(eachValue)) {
            // Check if this is a Kahuna credential key.
            if ([_kahunaCredentialsKeys containsObject:eachKey]) {
                [credentials addCredential:eachKey withValue:eachValue];
            } else {
                [attributes setValue:eachValue forKey:eachKey];
            }
        } else if ([eachValue isKindOfClass:[NSNumber class]]) {
            // Check if this is a Kahuna credential key.
            if ([_kahunaCredentialsKeys containsObject:eachKey]) {
                [credentials addCredential:eachKey withValue:[NSString stringWithFormat:@"%@", eachValue]];
            } else {
                [attributes setValue:[NSString stringWithFormat:@"%@", eachValue] forKey:eachKey];
            }
        } else {
            @try {
                [attributes setValue:[eachValue description] forKey:eachKey];
            }
            @catch (NSException *exception) {
                // Do nothing.
            }
        }
    }

    NSError *error = nil;
    [self.kahunaClass loginWithCredentials:credentials error:&error];
    if (error) {
        NSLog(@"Kahuna-Segment Login Error : %@", error.description);
    }

    // Track the attributes if we have any items in it.
    if (attributes.count > 0) {
        [self.kahunaClass setUserAttributes:attributes];
    }
}

- (void)track:(SEGTrackPayload *)payload {
    [self trackInternal:payload.event properties:payload.properties];
}

- (void)trackInternal:(NSString *)event properties:(NSDictionary *)properties
{
    NSNumber *revenue = [SEGKahunaIntegration extractRevenue:properties withKey:@"revenue"];
    NSNumber *quantity = nil;
    for (NSString *key in properties) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(key)) continue;
        if ([key caseInsensitiveCompare:@"quantity"] == NSOrderedSame) {
            id value = properties[key];
            if ([value isKindOfClass:[NSString class]]) {
                quantity = @([value longLongValue]);
            } else if ([value isKindOfClass:[NSNumber class]]) {
                quantity = value;
            }
            
            break;
        }
    }
    
    KAHEventBuilder *kahunaEventBuilder = [KAHEventBuilder eventWithName:event];
    
    // If we get revenue and quantity in the properties, then no matter what we will try to extract the numbers they hold and trackEvent with Count and Value.
    if (revenue && quantity) {
        // Get the count and value from quantity and revenue.
        long value = (long)([revenue doubleValue] * 100);
        long count = [quantity longValue];
        
        [self.kahunaClass trackEvent:event withCount:count andValue:value];
        [kahunaEventBuilder setPurchaseCount:count andPurchaseValue:value];
    } else {
        [self.kahunaClass trackEvent:event];
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *intelligentEventProperties = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *lowerCaseKeyProperties = [[NSMutableDictionary alloc] init];
    
    // Lower case all the keys and copy over the properties into a new dictionary.
    for (NSString *eachKey in properties) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(eachKey)) continue;
        [lowerCaseKeyProperties setValue:properties[eachKey] forKey:[eachKey lowercaseString]];
        [intelligentEventProperties setValue:properties[eachKey] forKey:eachKey];
    }
    
    if ([event caseInsensitiveCompare:KAHUNA_VIEWED_PRODUCT_CATEGORY] == NSOrderedSame) {
        [self addViewedProductCategoryElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_VIEWED_PRODUCT] == NSOrderedSame) {
        [self addViewedProductElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_ADDED_PRODUCT] == NSOrderedSame) {
        [self addAddedProductElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_COMPLETED_ORDER] == NSOrderedSame) {
        [self addCompletedOrderElements:&attributes fromProperties:lowerCaseKeyProperties];
    }
    
    // If we have collected any attributes, then we will call the setUserAttributes API
    if (attributes.count > 0) {
        [self.kahunaClass setUserAttributes:attributes];
        
        for (NSString *key in attributes) {
            [intelligentEventProperties setValue:attributes[key] forKey:key];
        }
    }
    
    if (intelligentEventProperties.count > 0) {
        for (NSString *key in intelligentEventProperties) {
            [kahunaEventBuilder addProperty:key withValue:intelligentEventProperties[key]];
        }
        
        [self.kahunaClass track:[kahunaEventBuilder build]];
    }
}

- (void)screen:(SEGScreenPayload *)payload
{
    [self screenInternal:SEGEventNameForScreenTitle(payload.name) properties:payload.properties];
}

- (void)screenInternal:(NSString *)screenTitle properties:(NSDictionary *)properties
{
    BOOL trackAllPages = [(NSNumber *)[self.settings objectForKey:@"trackAllPages"] boolValue];
    if (trackAllPages && KAHUNA_NOT_STRING_NULL_EMPTY(screenTitle)) {
        // Track the screen view as an event.
        [self trackInternal:screenTitle properties:properties];
    }
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo
{
    [self handleActionWithIdentifier:nil forRemoteNotification:userInfo];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.kahunaClass handleNotificationRegistrationFailure:error];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self.kahunaClass setDeviceToken:deviceToken];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo
{
    // This method can be called in a background thread or the main thread. If the app is launched due to a push, then this method call
    // comes in the background thread. But if the app is in background and the user clicks on the push, then this method
    // is called on the main thread.
    
    if (_applicationDidBecomeActiveAtleastOnce) {
        [self.kahunaClass handleNotification:userInfo withActionIdentifier:identifier withApplicationState:[UIApplication sharedApplication].applicationState];
    } else {
        // If the application never became active and we get a remote notification, then we will handle the notification assuming application
        // is Inactive.
        [self.kahunaClass handleNotification:userInfo withActionIdentifier:identifier withApplicationState:UIApplicationStateInactive];
    }
}

- (void)reset
{
    [self.kahunaClass logout];
}

- (void) applicationDidBecomeActive {
    _applicationDidBecomeActiveAtleastOnce = true;
}

- (void)addViewedProductCategoryElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id value = properties[KAHUNA_CATEGORY];
    if (value && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        [(*attributes)setValue:value forKey:KAHUNA_LAST_VIEWED_CATEGORY];
        NSDictionary *existingAttributes = [self.kahunaClass getUserAttributes];
        id categoriesViewed = [existingAttributes valueForKey:KAHUNA_CATEGORIES_VIEWED];
        if (categoriesViewed && [categoriesViewed isKindOfClass:[NSString class]]) {
            NSMutableArray *aryOfCategoriesViewed = [[categoriesViewed componentsSeparatedByString:@","] mutableCopy];
            if (![aryOfCategoriesViewed containsObject:value]) {
                if (aryOfCategoriesViewed.count > 50) {
                    [aryOfCategoriesViewed removeObjectAtIndex:0]; // Remove the first object.
                }
                
                [aryOfCategoriesViewed addObject:value];
                [(*attributes)setValue:[aryOfCategoriesViewed componentsJoinedByString:@","] forKey:KAHUNA_CATEGORIES_VIEWED];
            }
        } else {
            [(*attributes)setValue:value forKey:KAHUNA_CATEGORIES_VIEWED];
        }
    } else {
        // Since we do not have a category, we will store "none" for last view category and categories viewed list.
        [(*attributes)setValue:KAHUNA_NONE forKey:KAHUNA_LAST_VIEWED_CATEGORY];
        [(*attributes)setValue:KAHUNA_NONE forKey:KAHUNA_CATEGORIES_VIEWED];
    }
}

- (void)addViewedProductElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id kname = properties[KAHUNA_NAME];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
        [(*attributes)setValue:kname forKey:KAHUNA_LAST_PRODUCT_VIEWED_NAME];
    }
    
    [self addViewedProductCategoryElements:attributes fromProperties:properties];
}

- (void)addAddedProductElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id kname = properties[KAHUNA_NAME];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
        [(*attributes)setValue:kname forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME];
    }
    
    id category = properties[KAHUNA_CATEGORY];
    if (!KAHUNA_NOT_STRING_NULL_EMPTY(category)) {
        category = KAHUNA_NONE;
    }
    
    [(*attributes)setValue:category forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY];
}

- (void)addCompletedOrderElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id discount = properties[KAHUNA_DISCOUNT];
    if ([discount isKindOfClass:[NSString class]] || [discount isKindOfClass:[NSNumber class]]) {
        [(*attributes)setValue:discount forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
    } else {
        [(*attributes)setValue:@0 forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
    }
}

@end
