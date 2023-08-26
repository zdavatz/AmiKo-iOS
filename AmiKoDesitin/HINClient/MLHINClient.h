//
//  MLHINClient.h
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLHINTokens.h"
#import "MLHINProfile.h"
#import "MLHINADSwissSaml.h"
#import "Prescription.h"
#import "MLHINADSwissAuthHandle.h"
#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLHINClient : NSObject

+ (instancetype)shared;
- (NSString *)oauthCallbackScheme;

- (NSURL *)authURLForSDS;
- (NSURL *)authURLForADSwiss;

- (void)fetchAccessTokenWithAuthCode:(NSString *)authCode
                          completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)handleSDSOAuthCallback:(NSURL *)url callback:(void (^)(NSError *error))callback;
- (void)handleADSwissOAuthCallback:(NSURL *)url callback:(void (^)(NSError *error))callback;

- (void)renewTokenIfNeededWithToken:(MLHINTokens *)token
                         completion:(void (^_Nonnull)(NSError * _Nullable error, MLHINTokens * _Nullable tokens))callback;

- (void)fetchSDSSelfWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *error, MLHINProfile *profile))callback;

- (void)fetchADSwissSAMLWithToken:(MLHINTokens *)token completion:(void (^_Nonnull)(NSError *_Nullable error, MLHINADSwissSaml * _Nullable result))callback;

- (void)fetchADSwissAuthHandleWithToken:(MLHINTokens *)token
                               authCode:(NSString *)authCode
                             completion:(void (^_Nonnull)(NSError *_Nullable error, NSString *_Nullable authHandle))callback;

- (void)makeQRCodeWithAuthHandle:(MLHINADSwissAuthHandle *)authHandle
                   ePrescription:(Prescription *)prescription
                        callback:(void(^)(NSError *_Nullable error, UIImage *_Nullable qrCode))callback;

#pragma mark: - OAuth UI flow

- (void)performADSwissOAuthWithViewController:(UIViewController<ASWebAuthenticationPresentationContextProviding> *)controller
                                     callback:(void(^)(NSError * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
