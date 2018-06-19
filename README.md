AmiKo-iPhone
============

AmiKo for iPhone and iPad.

## Latest Release News
* https://medium.com/@zdavatz/rezeptfunktion-inkl-patienten-verwaltung-f%C3%BCr-amiko-comed-auf-iphone-ipad-c871723ec4b1

## Tesseract
For tesseract Support do
```
pod install
```
then open the _.xcworkspace_ directory.

## Build the App with
```
./build.sh Release
```

If you build via SSH you first need to do
```
security unlock-keychain
```

To clear the upload tokens (in case you get stuck uploading test-Builds) do
```
rm ~/.itmstransporter/UploadTokens/*.token
```

## Testflight the App with
```
./testflight
```

## .bash_profile 
for testflight script
```
export ITC_USER="your@email.com"
export ITC_PASSWORD="one-time-itc-pw"

alias ios="cd /Users/userid/Documents/xcode/amiko-ios"
```

## License
GPLv3.0, see https://github.com/zdavatz/AmiKo-iOS/blob/master/LICENSE

## French Translations
Dr. André Dubied
