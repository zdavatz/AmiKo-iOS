//
//  MLHINClient.m
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLHINClient.h"
#import "MLHINClientCredential.h"
#import "MLPersistenceManager.h"
#import "MLConstants.h"
#import "Operator.h"

@implementation MLHINClient

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MLHINClient *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[MLHINClient alloc] init];
    });
    return shared;
}

- (NSString *)oauthCallbackScheme {
    if ([[MLConstants databaseLanguage] isEqualToString:@"de"]) {
        return @"amiko";
    }
    return @"comed";
}

- (NSString *)oauthCallback {
    return [NSString stringWithFormat:@"%@://oauth", [self oauthCallbackScheme]];
}

- (NSURL*)authURLWithApplication:(NSString *)applicationName {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://apps.hin.ch/REST/v1/OAuth/GetAuthCode/%@?response_type=code&client_id=%@&redirect_uri=%@&state=teststate", applicationName, HIN_CLIENT_ID, [[self oauthCallback] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
}

- (NSURL*)authURLForSDS {
    return [self authURLWithApplication:@"hin_sds"];
}

- (NSURL *)authURLForADSwiss {
    return [self authURLWithApplication:
#ifdef DEBUG
            @"ADSwiss_CI-Test"
#else
            @"ADSwiss_CI"
#endif
    ];
}

- (NSString*)HINDomainForADSwiss {
#ifdef DEBUG
    return @"oauth2.ci-prep.adswiss.hin.ch";
#else
    return @"oauth2.ci.adswiss.hin.ch";
#endif
}

- (NSString*)certifactionDomain {
#ifdef DEBUG
    return CERTIFACTION_TEST_SERVER;
#else
    return CERTIFACTION_SERVER;
#endif
}

- (void)fetchAccessTokenWithAuthCode:(NSString *)authCode
                          completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken"]];
    [request setAllHTTPHeaderFields:@{
        @"Accept": @"application/json",
        @"Content-Type": @"application/x-www-form-urlencoded",
    }];
    [request setHTTPMethod:@"POST"];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"authorization_code"],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:[self oauthCallback]],
        [NSURLQueryItem queryItemWithName:@"code" value:authCode],
        [NSURLQueryItem queryItemWithName:@"client_id" value:HIN_CLIENT_ID],
        [NSURLQueryItem queryItemWithName:@"client_secret" value:HIN_CLIENT_SECRET],
    ];
    [request setHTTPBody:[components.query dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            callback(jsonError, nil);
            return;
        }
        MLHINTokens *tokens = [[MLHINTokens alloc] initWithResponseJSON:jsonObj];
        if (!tokens) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        callback(nil, tokens);
    }] resume];
    //curl -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:application/json' --data 'grant_type=authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fcallback&code=xxxxxx&client_id=xxxxx&client_secret=xxxxx' https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken
}

- (void)handleSDSOAuthCallback:(NSURL *)url callback:(void (^)(NSError *error))callback {
    NSLog(@"url: %@", url);
    //    http://localhost:8080/callback?state=teststate&code=xxxxxx
    NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                             resolvingAgainstBaseURL:NO];
    typeof(self) __weak _self = self;
    for (NSURLQueryItem *query in [components queryItems]) {
        if ([query.name isEqual:@"code"]) {
            [self fetchAccessTokenWithAuthCode:query.value
                                    completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
                if (error) {
                    callback(error);
                    return;
                }
                if (!tokens) {
                    callback([NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                 code:0
                                             userInfo:@{
                        NSLocalizedDescriptionKey: @"Invalid token response"
                    }]);
                    return;
                }
                [[MLPersistenceManager shared] setHINSDSTokens:tokens];
                [_self fetchSDSSelfWithToken:tokens
                                  completion:^(NSError * _Nonnull error, MLHINProfile * _Nonnull profile) {
                    if (error) {
                        callback(error);
                        return;
                    }
                    if (!profile) {
                        callback([NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                     code:0
                                                 userInfo:@{
                            NSLocalizedDescriptionKey: @"Invalid profile response"
                        }]);
                        return;
                    }
                    Operator *doctor = [Operator new];
                    NSDictionary *doctorDictionary = [[MLPersistenceManager shared] doctorDictionary];
                    [doctor importFromDict:doctorDictionary];
                    [_self mergeHINProfile:profile withDoctor:doctor];
                    [[MLPersistenceManager shared] setDoctorDictionary:[doctor toDictionary]];
                    callback(nil);
                }];
            }];
            break;
        }
    }
}

- (void)mergeHINProfile:(MLHINProfile *)profile withDoctor:(Operator *)doctor {
    if (!doctor.emailAddress.length) {
        doctor.emailAddress = profile.email;
    }
    if (!doctor.familyName.length) {
        doctor.familyName = profile.lastName;
    }
    if (!doctor.givenName.length) {
        doctor.givenName = profile.firstName;
    }
    if (!doctor.postalAddress.length) {
        doctor.postalAddress = profile.address;
    }
    if (!doctor.zipCode.length) {
        doctor.zipCode = profile.postalCode;
    }
    if (!doctor.city.length) {
        doctor.city = profile.city;
    }
    if (!doctor.phoneNumber.length) {
        doctor.phoneNumber = profile.phoneNr;
    }
    if (!doctor.gln.length) {
        doctor.gln = profile.gln;
    }
}

- (void)handleADSwissOAuthCallback:(NSURL *)url callback:(void (^)(NSError *error))callback {
    NSLog(@"url: %@", url);
    //    http://localhost:8080/callback?state=teststate&code=xxxxxx
    NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                             resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *query in [components queryItems]) {
        if ([query.name isEqual:@"code"]) {
            [self fetchAccessTokenWithAuthCode:query.value
                                    completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
                if (error) {
                    callback(error);
                    return;
                }
                if (!tokens) {
                    callback([NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                 code:0
                                             userInfo:@{
                        NSLocalizedDescriptionKey: @"Invalid token response"
                    }]);
                    return;
                }
                [[MLPersistenceManager shared] setHINADSwissTokens:tokens];
                callback(nil);
            }];
            break;
        }
    }
}

- (void)renewTokenIfNeededWithToken:(MLHINTokens *)token
                         completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback {
    if (!token.expired) {
        callback(nil, token);
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken"]];
    [request setAllHTTPHeaderFields:@{
        @"Accept": @"application/json",
        @"Content-Type": @"application/x-www-form-urlencoded",
    }];
    [request setHTTPMethod:@"POST"];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"refresh_token"],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:[self oauthCallback]],
        [NSURLQueryItem queryItemWithName:@"refresh_token" value:token.refreshToken],
        [NSURLQueryItem queryItemWithName:@"client_id" value:HIN_CLIENT_ID],
        [NSURLQueryItem queryItemWithName:@"client_secret" value:HIN_CLIENT_SECRET],
    ];
    [request setHTTPBody:[components.query dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSError *jsonError = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            callback(jsonError, nil);
            return;
        }
        MLHINTokens *newTokens = [[MLHINTokens alloc] initWithResponseJSON:jsonObj];
        if (!newTokens) {
            NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        if (token.application == MLHINTokensApplicationSDS) {
            [[MLPersistenceManager shared] setHINSDSTokens:newTokens];
        } else if (token.application == MLHINTokensApplicationADSwiss) {
            [[MLPersistenceManager shared] setHINADSwissTokens:newTokens];
        }
        callback(nil, newTokens);
    }] resume];
//    curl -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept:application/json' --data 'grant_type=refresh_token&refresh_token=xxxxxx&client_id=xxxxx&client_secret=xxxxx' https://oauth2.hin.ch/REST/v1/OAuth/GetAccessToken
}

# pragma mark: - SDS

- (void)fetchSDSSelfWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *error, MLHINProfile *profile))callback {
    [self renewTokenIfNeededWithToken:token
                           completion:^(NSError * _Nullable error, MLHINTokens * _Nullable tokens) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth2.sds.hin.ch/api/public/v1/self/"]];
        [request setAllHTTPHeaderFields:@{
            @"Accept": @"application/json",
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", token.accessToken],
        }];
        [request setHTTPMethod:@"GET"];
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                callback(error, nil);
                return;
            }
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                callback(jsonError, nil);
                return;
            }
            MLHINProfile *profile = [[MLHINProfile alloc] initWithResponseJSON:jsonObj];
            if (!profile) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            callback(nil, profile);
        }] resume];
        //curl -H 'Authorization: Bearer xxxxx' https://oauth2.sds.hin.ch/api/public/v1/self/
    }];
}

# pragma mark: ADSwiss

- (void)fetchADSwissSAMLWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *_Nullable error, MLHINADSwissSaml *result))callback {
    [self renewTokenIfNeededWithToken:token
                           completion:^(NSError * _Nullable error, MLHINTokens * _Nullable newTokens) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/authService/EPDAuth?targetUrl=%@&style=redirect", [self HINDomainForADSwiss], [self oauthCallback]]]];
        [request setAllHTTPHeaderFields:@{
            @"Accept": @"application/json",
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", token.accessToken],
        }];
        [request setHTTPMethod:@"POST"];
        NSLog(@"Fetching SAML from: %@", request.URL);
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                callback(error, nil);
                return;
            }
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                callback(jsonError, nil);
                return;
            }
            MLHINADSwissSaml *saml = [[MLHINADSwissSaml alloc] initWithResponseJSON:jsonObj token:token];
            if (!saml) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            callback(nil, saml);
        }] resume];
        // curl --request POST --url 'https://oauth2.ci-prep.adswiss.hin.ch/authService/EPDAuth?targetUrl=http%3A%2F%2Flocalhost:8080%2Fcallback&style=redirect' --header 'accept: application/json' --header 'Authorization: Bearer b#G7XRWMzXd...aMALnxAj#GpN7V'
    }];
}

- (void)fetchADSwissAuthHandleWithToken:(MLHINTokens *)token
                               authCode:(NSString *)authCode
                             completion:(void (^_Nonnull)(NSError *_Nullable error, NSString * _Nullable authHandle))callback {
    [self renewTokenIfNeededWithToken:token
                           completion:^(NSError * _Nullable error, MLHINTokens * _Nullable newTokens) {
        if (error != nil) {
            callback(error, nil);
            return;
        }
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/authService/EPDAuth/auth_handle", [self HINDomainForADSwiss]]]];
        [request setAllHTTPHeaderFields:@{
            @"Accept": @"application/json",
            @"Content-Type": @"application/json",
            @"Authorization": [NSString stringWithFormat:@"Bearer %@", token.accessToken],
        }];
        NSError *jsonError = nil;
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"authCode": authCode}
                                                             options:0
                                                               error:&jsonError]];
        if (jsonError != nil) {
            callback(jsonError, nil);
            return;
        }
        [request setHTTPMethod:@"POST"];
        NSLog(@"Fetching Auth Handle from: %@", request.URL);
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                callback(error, nil);
                return;
            }
            NSError *jsonError = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError != nil) {
                NSLog(@"response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                callback(jsonError, nil);
                return;
            }
            NSString *authHandle = [jsonObj objectForKey:@"authHandle"];
            if (!authHandle) {
                NSLog(@"auth handle response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
            callback(nil, authHandle);
        }] resume];
        // curl --request POST --url "https://oauth2.ci-prep.adswiss.hin.ch/authService/EPDAuth/auth_handle" -d "{\"authCode\":\"vzut..Q2E6\"}" --header "accept: application/json" --header "Content-Type: application/json" --header "Authorization: Bearer b#G7XRWMzX...nxAj#GpN7V"
    }];
}

- (void)makeQRCodeWithAuthHandle:(MLHINADSwissAuthHandle *)authHandle
                   ePrescription:(Prescription *)prescription
                        callback:(void(^)(NSError *_Nullable error, UIImage *_Nullable qrCode))callback {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ePrescription/create?output-format=qrcode", [self certifactionDomain]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setAllHTTPHeaderFields:@{
        @"Content-Type": @"text/plain",
        @"Authorization": [NSString stringWithFormat:@"Bearer %@", authHandle.token],
    }];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[prescription ePrescription]];
    [authHandle updateLastUsedAt];
    [[MLPersistenceManager shared] setHINADSwissAuthHandle:authHandle];

    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            callback(error, nil);
            return;
        }
        NSHTTPURLResponse *res = (NSHTTPURLResponse*)response;
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[location path]];
        if ([res statusCode] >= 400 || !image) {
            NSString *responseStr =[[NSString alloc] initWithContentsOfURL:location
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:nil];
            callback([[NSError alloc] initWithDomain:@"com.ywesee.amiko" code: 0 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Error response: %@", responseStr],
            }], nil);
            return;
        }
        callback(nil, image);
    }];
    [task resume];
}

@end
