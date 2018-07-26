//
//  avcamtypes.h
//  AmikoDesitin
//
//  Created by Alex Bettarini on 26 Jul 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#ifndef avcamtypes_h
#define avcamtypes_h

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, AVCamLivePhotoMode ) {
    AVCamLivePhotoModeOn,
    AVCamLivePhotoModeOff
};

typedef NS_ENUM( NSInteger, AVCamDepthDataDeliveryMode ) {
    AVCamDepthDataDeliveryModeOn,
    AVCamDepthDataDeliveryModeOff
};

#endif /* avcamtypes_h */
