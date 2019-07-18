/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/06/2013.
 
 This file is part of AMiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLAppDelegate.h"

#import "MLConstants.h"
#import "SWRevealViewController.h"
#import "MLViewController.h"
#import "MLSecondViewController.h"
#import "PrescriptionViewController.h"
#import "MLTitleViewController.h"
#import "MLMenuViewController.h"
#import "MLUtility.h"
#import "MLAlertView.h"
#import "PatientDbListViewController.h"
#import "PatientDBAdapter.h"

#import <TesseractOCR/TesseractOCR.h>

@interface MLAppDelegate()<SWRevealViewControllerDelegate>
// Do stuff
@end

@implementation MLAppDelegate

@synthesize window = _window;
@synthesize navController = _navController;
@synthesize revealViewController = _revealViewController;

MLViewController *mainViewController;

int launchState = eAips;
bool launchedFromShortcut = NO;

void onUncaughtException(NSException *exception)
{
    NSLog(@"uncaught exception: %@", exception.description);
}

/** Utility functions
 */
CGSize PhysicalPixelSizeOfScreen(UIScreen *s)
{
    CGSize result = s.bounds.size;
    
    if ([s respondsToSelector: @selector(scale)]) {
        CGFloat scale = s.scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
    }
    
    return result;
}

/** Handles Quick Action shortcuts
 */
- (BOOL) handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    bool handled = NO;

    // Check which quick action to run
    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.aips"] ||
        [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.aips"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: aips");
#endif
        launchState = eAips;
        handled = YES;
    }

    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.favorites"] ||
        [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.favorites"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: favorites");
#endif
        launchState = eFavorites;
        handled = YES;
    }

    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.interactions"] ||
        [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.interactions"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: interactions");
#endif
        launchState = eInteractions;
        handled = YES;
    }

    if ([shortcutItem.type isEqualToString:@"com.ywesee.amiko.ios.desitin"] ||
        [shortcutItem.type isEqualToString:@"com.ywesee.comed.ios.desitin"]) {
#ifdef DEBUG
        NSLog(@"shortcut tapped: desitin");
#endif
        launchState = eDesitin;
        handled = YES;
    }
    
    if (mainViewController!=nil && handled==YES) {
        [mainViewController setLaunchState:launchState];
    }
    
    return handled;
}

/** Override delegate method: quick actions
 */
- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    bool handledShortcutItem = [self handleShortcutItem:shortcutItem];
    // completionHandler expects a bool indicating whether we are able to handle the item
    completionHandler(handledShortcutItem);
}


/** Override method: app entry point
 */
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    // Init main window
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBound];
    
    // Print out some useful info
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize sizeInPixels = PhysicalPixelSizeOfScreen([UIScreen mainScreen]);
#ifdef DEBUG
    // Screen size minus the size of the status bar (if visible)
    // This is the size of the app window
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] applicationFrame].size.width,
          [[UIScreen mainScreen] applicationFrame].size.height, screenScale);
    
    // Screen size regardless of status bar.
    // This is the size of the device
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] bounds].size.width,
          [[UIScreen mainScreen] bounds].size.height, screenScale);

    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] nativeBounds].size.width,
          [[UIScreen mainScreen] nativeBounds].size.height, screenScale);
    NSLog(@"physical w = %f, physical h = %f", sizeInPixels.width, sizeInPixels.height); // nativeBounds
    NSDictionary *d = [[NSBundle mainBundle] infoDictionary];
    NSLog(@"%@, %@, %@, %@",
          [d objectForKey:@"CFBundleName"],
          [d objectForKey:@"CFBundleExecutable"],
          [d objectForKey:@"CFBundleShortVersionString"],
          [d objectForKey:@"CFBundleVersion"]);
    NSString *bundleIdentifier = [d objectForKey:@"CFBundleIdentifier"];
//    NSLog(@"bundle identifier <%@>, display name <%@>",
//          bundleIdentifier,
//          [d objectForKey:@"CFBundleDisplayName"]);
//    NSLog(@"documents dir:\n\t%@", [MLUtility documentsDirectory]);
    NSLog(@"Defaults file:\n\t%@/Preferences/%@.plist",
          NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject,
          bundleIdentifier);
    NSLog(@"Tesseract version %@", [G8Tesseract version]);
#endif
    
    // Rear
    mainViewController = [[MLViewController alloc] init];
    UINavigationController *mainViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:mainViewController];

    // Front
    MLSecondViewController *secondViewController = [[MLSecondViewController alloc] init];
    UINavigationController *secondViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:secondViewController];

    // Check if app was launched by quick action
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (shortcutItem != nil) {
            [self handleShortcutItem:shortcutItem];
            // Method returns false if application was launched from shortcut
            // and prevents performActionForShortcutItem to be called...
            launchedFromShortcut = YES;
        }
    }
    
    // Init swipe (reveal) view controller
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:mainViewNavigationController
                                                frontViewController:secondViewNavigationController];
    
    MLTitleViewController *titleViewController = [[MLTitleViewController alloc] init];    
    mainRevealController.rightViewController = titleViewController;
    
    mainRevealController.delegate = self;

    // Make sure the orientation is correct
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }

        mainRevealController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPad;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController; 
    }
    mainRevealController.bounceBackOnOverdraw = YES;
    
    // Note: iOS7 - sets the global TINT color!!
    {
        [application setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];  // WHITE
        // [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        // [application setStatusBarStyle:UIStatusBarStyleDefault animated:YES];    // BLACK
        
        // Changes background color of navigation bar!
        // [[UINavigationBar appearance] setBarTintColor:MAIN_TINT_COLOR];
                
        self.window.clipsToBounds =YES;
        // self.window.frame = CGRectMake(0,0,self.window.frame.size.width,self.window.frame.size.height-20);
        
        // Text and tabbar button colors
        [self.window setTintColor:MAIN_TINT_COLOR];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIFont systemFontOfSize:14], NSFontAttributeName,
                                    [UIColor whiteColor], NSForegroundColorAttributeName, nil];
        [[UINavigationBar appearance] setTitleTextAttributes:attributes];
     
        // Remove shadow?
        /*
        [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setShadowImage:[UIImage new]];
        */
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    
    // Register the applications defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    NSString *keyDBLastUpdate = [MLConstants databaseUpdateKey];

    [appDefaults setValue:[NSDate date] forKey:keyDBLastUpdate];
    [defaults registerDefaults:appDefaults];

    // Initialize user defaults first time app is run
    NSDate* lastUpdated = [defaults objectForKey:keyDBLastUpdate];
    if (!lastUpdated) {
        [lastUpdated setValue:[NSDate date] forKey:keyDBLastUpdate];
        NSLog(@"Initializing defaults...");
    }

    [defaults removeObjectForKey:@"lastUsedPrescription"];
    [defaults synchronize];
    
    self.window.rootViewController = self.revealViewController;
    [self.window makeKeyAndVisible];
    
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    self.editMode = EDIT_MODE_UNDEFINED;
    
    // Issue #54
    [mainRevealController revealToggle:nil];
    [mainRevealController revealToggle:nil];
    
    return !launchedFromShortcut;
}

- (void) applicationWillResignActive: (UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground: (UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground: (UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive: (UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) applicationWillTerminate: (UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) showPrescriptionId:(NSString *)uniqueId :(NSString *)fileName
{
    // Update defaults to be used in other views
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:uniqueId forKey:@"currentPatient"];
    [defaults setObject:fileName forKey:@"lastUsedPrescription"];
    [defaults synchronize];
    
#ifdef DEBUG_ISSUE_86
    NSLog(@"%s %d define currentPatient ID %@", __FUNCTION__, __LINE__, uniqueId);
#endif
    
    PrescriptionViewController *vc = [PrescriptionViewController sharedInstance];
    vc.editedMedicines = false;
    
    // Switch to prescription view to show what we just imported
    UITabBarItem *item = [[UITabBarItem alloc] init];
    item.tag = 3;  // Simulate a tap on the tabbar 4th item
    [mainViewController switchTabBarItem:item];
    //[mainViewController setLaunchState:ePrescription];
}

// The file is in "Documents/Inbox/" and needs to be moved to "Documents/amk/"
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    NSError *error;

#ifdef DEBUG
    //NSLog(@"%s url:%@", __FUNCTION__, url);
#endif
    if (!url ||
        ![url isFileURL])
    {
        NSLog(@"Invalid URL");
        return NO;
    }

    // Validation of the filename
    NSString *fileName = [[url absoluteString] lastPathComponent];
    NSString *extName = [url pathExtension];
    if (![extName isEqualToString:@"amk"] ||
        ![fileName hasPrefix:@"RZ_"])
    {
        NSLog(@"Invalid filename:%@", fileName);
        return NO;
    }

    // Load the prescription from the file in Inbox
    Prescription *presInbox = [[Prescription alloc] init];
    [presInbox importFromURL:url];
    
    // Check if the patient subdirectory exists and possibly create it
    NSString *amk = [MLUtility amkBaseDirectory];
    NSString *amkDir = [amk stringByAppendingPathComponent:presInbox.patient.uniqueId];
    if (![[NSFileManager defaultManager] fileExistsAtPath:amkDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:amkDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error creating directory: %@", error.localizedDescription);
            amkDir = nil;
            // Cannot proceed if there is no target for the import
            return NO;
        }

#ifdef DEBUG
        NSLog(@"Created patient directory: %@", amkDir);
#endif
    }

    // Check if the patient is already in the DB and possibly add it.
    PatientDBAdapter *patientDb = [[PatientDBAdapter alloc] init];
    if (![patientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        return NO;
    }
    
    if ([patientDb getPatientWithUniqueID:presInbox.patient.uniqueId]==nil) {
        //NSLog(@"Add patient to DB");
        [patientDb addEntry:presInbox.patient];
    }

    [patientDb closeDatabase];
    
    // Check the hash of the existing amk files
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:amkDir error:&error];
    NSArray *amkFilesArray = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];

    BOOL prescriptionNeedsToBeImported = YES;
    Prescription *presAmkDir = [[Prescription alloc] init];
    NSString *foundFileName;
    NSString *foundUniqueId;
    for (NSString *f in amkFilesArray) {
        //NSLog(@"Checking existing amkFile:%@", f);
        NSString *fullFilePath = [amkDir stringByAppendingPathComponent:f];
        NSURL *url = [NSURL fileURLWithPath:fullFilePath];
        [presAmkDir importFromURL:url];
        if ([presInbox.hash isEqualToString:presAmkDir.hash]) {
            prescriptionNeedsToBeImported = NO;
            foundFileName = f;
            foundUniqueId = presAmkDir.patient.uniqueId;
            //NSLog(@"Line %d, hash %@ exists", __LINE__, presInbox.hash);
            break;
        }
    }
    
    if (!prescriptionNeedsToBeImported) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@ has already been imported",nil), fileName];
        error = [NSError errorWithDomain:@"receipt"
                                    code:99
                                userInfo:@{NSLocalizedDescriptionKey:message}];

        MLAlertView *alert1 = [[MLAlertView alloc] initWithTitle:@"Import Error"
                                                        message:error.localizedDescription
                                                         button:@"OK"];
        [alert1 show];
        
        // Clean up: discard amk file from Inbox
#ifdef DEBUG
        if (![[NSFileManager defaultManager] isDeletableFileAtPath:[url resourceSpecifier]])
            NSLog(@"Not deletable: %@", [url resourceSpecifier]);
#endif
        BOOL success = [[NSFileManager defaultManager] removeItemAtURL:url
                                                                 error:&error];
        if (!success)
            NSLog(@"Error removing file: %@", error.localizedDescription);

        [self showPrescriptionId:foundUniqueId :foundFileName];
        return NO;
    }

    // Finally move amk from Inbox to patient subdirectory
    //NSURL *destination = [[NSURL fileURLWithPath:amkDir] URLByAppendingPathComponent:fileName];
    NSString *source = [url path];
    NSString *destination = [amkDir stringByAppendingPathComponent:fileName];
    
    [[NSFileManager defaultManager] moveItemAtPath:source
                                            toPath:destination
                                             error:&error];
    if (!error) {
        NSString *alertMessage = [NSString stringWithFormat:@"Imported %@", fileName];
        MLAlertView *alert2;
        alert2 = [[MLAlertView alloc] initWithTitle:@"Success!"
                                           message:alertMessage
                                            button:@"OK"];
        [alert2 show];
    }
    
    [self showPrescriptionId:presInbox.patient.uniqueId :fileName];
    return YES;
}

- (void) switchRigthToPatientDbList
{
    id right = self.revealViewController.rightViewController;
    if (![right isKindOfClass:[PatientDbListViewController class]] ) {
        UIViewController *listViewController = [PatientDbListViewController sharedInstance];
        [self.revealViewController setRightViewController:listViewController];
#ifdef DEBUG
        //NSLog(@"Replacing right from %@ to %@", [right class], [listViewController class]);
#endif

        self.revealViewController.rightViewRevealOverdraw = 0;
#ifdef PATIENT_DB_LIST_FULL_WIDTH
        float frameWidth = self.view.frame.size.width;
        self.revealViewController.rightViewRevealWidth = frameWidth;
#endif
    }

    // Finally make it visible
    [self.revealViewController setFrontViewPosition:FrontViewPositionLeftSide animated:NO];
}

@end
