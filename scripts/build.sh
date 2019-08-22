#!/bin/bash

#STEP_REMOVE_SUPPORT_FILES=true
#STEP_DOWNLOAD_SUPPORT_FILES=true
#STEP_PODFILE=true
STEP_ARCHIVE=true

#-------------------------------------------------------------------------------
TIMESTAMP1=$(date +%Y%m%d)
TIMESTAMP2=$(date +%Y%m%d_%H%M)
WD=$PWD
PILLBOX_ODDB_ORG="http://pillbox.oddb.org"

BUILD_PATH="$WD/../build"

ARCHIVE_PATH="$BUILD_PATH/Archives/$TIMESTAMP1"

PKG_PATH="$BUILD_PATH/pkg"

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

exit 0

#-------------------------------------------------------------------------------

usage() {
  echo """Target Usage:\n$0 [Debug|Staging|Release]
  """ 1>&2;
  exit 1;
}

if [ $# -eq 0 ]
  then
    usage
    exit 1
fi

mkdir -p build/

TARGET=$1

echo "Target is $TARGET"

xcodebuild archive \
  -verbose \
  -jobs 2 \
  -workspace AmiKoDesitin.xcworkspace \
    CONFIGURATION_BUILD_DIR=$(PWD)/build \
    -scheme AmiKoDesitin \
    -configuration $TARGET \
    -derivedDataPath "$PWD/DerivedData" \
    -archivePath $PWD/build/AmiKoDesitin.xcarchive \
    || exit 1


#named config variables - pass values in directly for override
# xcodebuild archive \
#   -verbose \
#   -jobs 2 \
#   -project AmiKoDesitin.xcodeproj \
#     -scheme AmiKoDesitin \
#     -configuration $TARGET \
#     -derivedDataPath "$PWD/DerivedData" \
#     -archivePath ./build/AmiKoDesitin.xcarchive \
#     || exit 1
     PRODUCT_BUNDLE_IDENTIFIER=org.oddb.generika \
     PROVISIONING_PROFILE_SPECIFIER="Zeno Davatz" \
#     || exit 1

echo "Building IPA..."

#clean the build directory for .ipa
rm -rf ./build/*.app


#choose export options
if [ $TARGET = "Release" ]; then
  options="store.plist"
else
  options="adhoc.plist"
fi

#now create the .IPA using export options specified in property list files
xcodebuild -exportArchive \
 -verbose \
 -archivePath ./build/AmiKoDesitin.xcarchive \
 -exportPath ./build \
 -exportOptionsPlist ./exportOptions/"$options" \
