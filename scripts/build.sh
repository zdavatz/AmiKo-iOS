#!/bin/bash

# Alex Bettarini - 22 Aug 2019
# Copyright © 2019 Ywesee GmbH. All rights reserved.

STEP_REMOVE_SUPPORT_FILES=true
STEP_DOWNLOAD_SUPPORT_FILES=true
STEP_PODFILE=true
STEP_ARCHIVE=true
STEP_CREATE_IPA=true
STEP_UPLOAD_APP=true

#-------------------------------------------------------------------------------
TIMESTAMP1=$(date +%Y%m%d)
TIMESTAMP2=$(date +%Y%m%d_%H%M)
WD=$PWD
PILLBOX_ODDB_ORG="http://pillbox.oddb.org"

BUILD_PATH="$WD/../build"

ARCHIVE_PATH="$BUILD_PATH/Archives/$TIMESTAMP1"

PKG_PATH="$BUILD_PATH/ipa"

security unlock-keychain

#-------------------------------------------------------------------------------
if [ $STEP_REMOVE_SUPPORT_FILES ] ; then
pushd ../AmiKoDesitin
for EXT in db html csv ; do
    if ls *.$EXT 1> /dev/null 2>&1; then
        echo Removing *.$EXT
        rm *.$EXT
    fi
done
rm -r "$BUILD_PATH"
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_DOWNLOAD_SUPPORT_FILES ] ; then
pushd ../AmiKoDesitin
for LANG in de fr ; do
    wget $PILLBOX_ODDB_ORG/amiko_report_$LANG.html
    
    FILENAME=drug_interactions_csv_$LANG.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
    
    FILENAME=amiko_frequency_$LANG.db.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
    
    FILENAME=amiko_db_full_idx_$LANG.zip
    wget $PILLBOX_ODDB_ORG/$FILENAME
    unzip $FILENAME
    rm $FILENAME
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_PODFILE ] ; then
    pod --version
    pod install
fi

#-------------------------------------------------------------------------------
if [ $STEP_ARCHIVE ] ; then
pushd ../
mkdir -p $ARCHIVE_PATH
for SCHEME in AmiKoDesitin CoMedDesitin ; do
    echo "Archive $SCHEME"
    xcodebuild archive \
    -workspace AmiKoDesitin.xcworkspace \
    -scheme $SCHEME \
    -configuration Release \
    -derivedDataPath "build/DerivedData" \
    -archivePath "$ARCHIVE_PATH/$SCHEME $TIMESTAMP2.xcarchive"
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_CREATE_IPA ] ; then
#PRODUCT_BUNDLE_IDENTIFIER=org.oddb.generika
#PROVISIONING_PROFILE_SPECIFIER="Zeno Davatz"
pushd ../
for SCHEME in AmiKoDesitin CoMedDesitin ; do
  XC_ARCHIVE_PATH="$ARCHIVE_PATH/$SCHEME $TIMESTAMP2.xcarchive"
  echo "Export the .ipa from $XC_ARCHIVE_PATH"
  xcodebuild -exportArchive \
   -verbose \
   -archivePath "$XC_ARCHIVE_PATH" \
   -exportOptionsPlist $WD/store.plist \
   -exportPath "$PKG_PATH"
done
popd > /dev/null
fi

#-------------------------------------------------------------------------------
if [ $STEP_UPLOAD_APP ] ; then
#source $ITC_FILE
for f in $PKG_PATH/*.ipa ; do
    echo "Validating $f"
    xcrun altool --validate-app --type ios --file "$f" \
        --username "$ITC_USER" --password "$ITC_PASSWORD"

    echo "Uploading to iTC $f"
    xcrun altool --upload-app --type ios --file "$f" \
        --username "$ITC_USER" --password "$ITC_PASSWORD"
done
fi
