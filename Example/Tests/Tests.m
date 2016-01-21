//
//  SEGKahunaIntegrationTests.m
//  Analytics
//
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGKahunaDefines.h"
#import "SEGKahunaIntegration.h"
#import <Kahuna/Kahuna.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGKahunaIntegrationTests : XCTestCase

@property SEGKahunaIntegration *integration;
@property Class kahunaClassMock;
@property Class nserrorClassMock;
@property NSError *nserrorMock;
@property Kahuna *kahunaMock;
@property KahunaUserCredentials *kahunaCredentialsMock;

@end


@implementation SEGKahunaIntegrationTests

- (void)setUp
{
    [super setUp];
    
    _kahunaMock = mock([Kahuna class]);
    _kahunaClassMock = mockClass([Kahuna class]);
    _nserrorMock = mock([NSError class]);
    _nserrorClassMock = mockClass([NSError class]);
    _kahunaCredentialsMock = mock([KahunaUserCredentials class]);
    
    [given([_kahunaClassMock sharedInstance]) willReturn:_kahunaMock];
    [given([_kahunaClassMock createUserCredentials]) willReturn:_kahunaCredentialsMock];
    [given([_nserrorClassMock errorWithDomain:anything() code:anything() userInfo:anything()]) willReturn:_nserrorMock];
    
    _integration = [[SEGKahunaIntegration alloc] init];
    [_integration setKahunaClass:_kahunaClassMock];
}

- (void)testStart
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    
    [verifyCount(_kahunaClassMock, times(1)) launchWithKey:@"foo"];
}

- (void)testReset
{
    [_integration reset];
    
    [verifyCount(_kahunaClassMock, times(1)) logout];
}

- (void)testIdentify
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc]
                                   initWithUserId:@"foo"
                                   anonymousId:nil
                                   traits:@{ @"bar" : @"baz" } context:nil integrations:nil];
    [_integration identify:payload];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{ @"bar" : @"baz" }];
}

- (void)testIdentifyWithNoTraits
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc]
                                   initWithUserId:@"foo"
                                   anonymousId:nil
                                   traits:@{} context:nil integrations:nil];
    
    [_integration identify:payload];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, never()) setUserAttributes:anything()];
}

- (void)testIdentifyWithNoCredentialsAndNoTraits
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc]
                                   initWithUserId:nil
                                   anonymousId:nil
                                   traits:@{} context:nil integrations:nil];
    
    [_integration identify:payload];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, never()) addCredential:anything() withValue:anything()];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, never()) setUserAttributes:anything()];
}

- (void)testIdentifyWithMultipleCredentialsAndTraits
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc]
                                   initWithUserId:@"foo"
                                   anonymousId:nil
                                   traits:@{ @"bar" : @"baz",
                                             KAHUNA_CREDENTIAL_EMAIL : @"segkah@gmail.com",
                                             @"moon" : @"drake" } context:nil integrations:nil];
    
    [_integration identify:payload];
    
    // Verify that Add Credential was called twice on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_EMAIL withValue:@"segkah@gmail.com"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{ @"bar" : @"baz", @"moon" : @"drake" }];
}

- (void)testTrack
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"foo"
                                                           properties:@{}
                                                              context:nil
                                                         integrations:nil];
    
    [_integration track:payload];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
}

- (void)testTrackWithRevenueButNoQuantity
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"foo"
                                                           properties:@{ @"revenue" : @10 }
                                                              context:nil
                                                         integrations:nil];
    
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
    [verifyCount(_kahunaClassMock, never()) trackEvent:@"foo" withCount:anything() andValue:anything()];
}

- (void)testTrackWithQuantityButNoRevenue
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"foo"
                                                           properties:@{ @"quantity" : @10 }
                                                              context:nil
                                                         integrations:nil];
    
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
    [verifyCount(_kahunaClassMock, never()) trackEvent:@"foo" withCount:anything() andValue:anything()];
}

- (void)testTrackWithQuantityAndRevenue
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"foo"
                                                           properties:@{ @"revenue" : @10, @"quantity" : @4 }
                                                              context:nil
                                                         integrations:nil];
    
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, never()) trackEvent:anything()];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo" withCount:4 andValue:1000];
}

- (void)testTrackWithQuantityRevenueAndProperties
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"foo"
                                                           properties:@{@"productId" : @"bar",
                                                                        @"quantity" : @10,
                                                                        @"receipt" : @"baz",
                                                                        @"revenue" : @5
                                                                        }
                                                              context:nil
                                                         integrations:nil];
    
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo" withCount:10 andValue:500];
}

- (void)testTrackWithPropertyViewedCategory
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:KAHUNA_VIEWED_PRODUCT_CATEGORY
                                                           properties:@{ KAHUNA_CATEGORY : @"shirts" }
                                                              context:nil
                                                         integrations:nil];
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_VIEWED_CATEGORY : @"shirts", KAHUNA_CATEGORIES_VIEWED : @"shirts" }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_VIEWED_PRODUCT_CATEGORY];
}

- (void)testTrackWithPropertyViewedProduct
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:KAHUNA_VIEWED_PRODUCT
                                                           properties:@{ KAHUNA_NAME : @"gopher shirts" }
                                                              context:nil
                                                         integrations:nil];
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PRODUCT_VIEWED_NAME : @"gopher shirts",
                                                                 KAHUNA_CATEGORIES_VIEWED : KAHUNA_NONE,
                                                                 KAHUNA_LAST_VIEWED_CATEGORY : KAHUNA_NONE }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_VIEWED_PRODUCT];
    
}

- (void)testTrackWithPropertyAddedProduct
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:KAHUNA_ADDED_PRODUCT
                                                           properties:@{ KAHUNA_NAME : @"gopher shirts" }
                                                              context:nil
                                                         integrations:nil];
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME : @"gopher shirts",
                                                                 KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY : KAHUNA_NONE }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_ADDED_PRODUCT];
}

- (void)testTrackWithPropertyCompletedOrder
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:KAHUNA_COMPLETED_ORDER
                                                           properties:@{ KAHUNA_DISCOUNT : @15.0 }
                                                              context:nil
                                                         integrations:nil];
    [_integration track:payload];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PURCHASE_DISCOUNT : @15.0 }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_COMPLETED_ORDER];
}

- (void)testScreen
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo", @"trackAllPages" : @1 }];
    
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"foo" properties:@{} context:nil integrations:nil];
    
    [_integration screen:payload];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"Viewed foo Screen"];
}

- (void)testScreenWithNoTrackAllPagesSettings
{
    [_integration initWithSettings:@{ @"apiKey" : @"foo" }];
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:@"foo" properties:@{} context:nil integrations:nil];
    
    [_integration screen:payload];
    
    [verifyCount(_kahunaClassMock, never()) trackEvent:anything()];
}

@end