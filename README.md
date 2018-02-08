AmiKo-iPhone
============

AmiKo for iPhone and iPad.

## Build the App with
```
./build.sh Release
```

If you build via SSH you first need to do
```
security unlock-keychain
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
