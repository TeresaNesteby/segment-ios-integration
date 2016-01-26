//
//  SEGKahunaIntegration.h
//
//  Copyright (c) 2012-2016 Kahuna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>


@interface SEGKahunaIntegration : NSObject <SEGIntegration> {
    bool _applicationDidBecomeActiveAtleastOnce;
}

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) NSSet *kahunaCredentialsKeys;
@property Class kahunaClass;

- (id)initWithSettings:(NSDictionary *)settings;

@end
