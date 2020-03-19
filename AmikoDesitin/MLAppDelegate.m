/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/06/2013.
 
 This file is part of AmiKoDesitin.
 
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
#import "PatientDbListViewController.h"
#import "PatientDBAdapter.h"
#import "MLPersistenceManager.h"

#pragma mark -

@interface MLAppDelegate()<SWRevealViewControllerDelegate>
// Do stuff
@end

#pragma mark -

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

#pragma mark -

// Show a UIAlertController without having a UIViewController
- (void) showPopupWithTitle:(NSString *) aTitle
                    message:(NSString *) aMessage
{
    // https://stackoverflow.com/questions/36155769/how-to-show-uialertcontroller-from-appdelegate
    __block UIWindow* topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    topWindow.rootViewController = [UIViewController new];
    topWindow.windowLevel = UIWindowLevelAlert + 1;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:aTitle
                                                                   message:aMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        // continue your work

        // important to hide the window after work completed.
        // this also keeps a reference to the window until the action is invoked.

#if 0
        // if you want to hide the top window then use this
        topWindow.hidden = YES;
#else
        // if you want to remove the top window then use this
        topWindow = nil;
#endif
    }]];

    [topWindow makeKeyAndVisible];
    [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

/** Handles Quick Action shortcuts
 */
- (BOOL) handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    bool handled = NO;

    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier;

    NSString *typeAips = [NSString stringWithFormat:@"%@.Aips", bundleId];
    NSString *typeFavorites = [NSString stringWithFormat:@"%@.Favorites", bundleId];
    NSString *typeInteractions = [NSString stringWithFormat:@"%@.Interactions", bundleId];
    NSString *typeDesitin = [NSString stringWithFormat:@"%@.Desitin", bundleId];

    // Check which quick action to run
    if ([shortcutItem.type isEqualToString:typeAips]) {
        launchState = eAips;
        handled = YES;
    }
    else if ([shortcutItem.type isEqualToString:typeFavorites]) {
        launchState = eFavorites;
        handled = YES;
    }
    else if ([shortcutItem.type isEqualToString:typeInteractions]) {
        launchState = eInteractions;
        handled = YES;
    }
    else if ([shortcutItem.type isEqualToString:typeDesitin]) {
        launchState = eDesitin;
        handled = YES;
    }
    
    if (mainViewController && handled)
        [mainViewController setLaunchState:launchState];
    
    return handled;
}

/** Override delegate method: quick actions
 */
- (void) application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    bool handledShortcutItem = [self handleShortcutItem:shortcutItem];
    // completionHandler expects a bool indicating whether we are able to handle the item
    completionHandler(handledShortcutItem);
}

/** Override method: app entry point
 */
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init main window
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:screenBound];
    
#ifdef DEBUG
    // Print out some useful info
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize sizeInPixels = PhysicalPixelSizeOfScreen([UIScreen mainScreen]);

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0  // Deprecated in iOS 9.0
    // Screen size minus the size of the status bar (if visible)
    // This is the size of the app window
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] applicationFrame].size.width,
          [[UIScreen mainScreen] applicationFrame].size.height, screenScale);
#endif
    
    // Screen size regardless of status bar.
    // This is the size of the device
    NSLog(@"points w = %f, points h = %f, scale = %f",
          [[UIScreen mainScreen] bounds].size.width,
          [[UIScreen mainScreen] bounds].size.height, screenScale);
#endif

    // Rear
    mainViewController = [MLViewController new];
    UINavigationController *mainViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:mainViewController];

    // Front
    MLSecondViewController *secondViewController = [MLSecondViewController new];
    UINavigationController *secondViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:secondViewController];
    
    // Setup Quick Action menu
    [self configDynamicShortcutItems];

    // Check if app was launched by quick action
    UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
    if (shortcutItem) {
        [self handleShortcutItem:shortcutItem];
        // Method returns false if application was launched from shortcut
        // and prevents performActionForShortcutItem to be called...
        launchedFromShortcut = YES;
    }
    
    // Init swipe (reveal) view controller
    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                initWithRearViewController:mainViewNavigationController
                                                frontViewController:secondViewNavigationController];
    
    MLTitleViewController *titleViewController = [MLTitleViewController new];
    mainRevealController.rightViewController = titleViewController;
    
    mainRevealController.delegate = self;

    // Make sure the orientation is correct

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
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
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        mainRevealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m

        self.revealViewController = mainRevealController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        self.window.rootViewController = self.revealViewController;
    }
    mainRevealController.bounceBackOnOverdraw = YES;
    
    // Note: iOS7 - sets the global TINT color!!
    {
        //[application setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        // Changes background color of navigation bar
        [[UINavigationBar appearance] setBarTintColor:[UIColor systemGray5Color]];
                
        self.window.clipsToBounds =YES;
        // self.window.frame = CGRectMake(0,0,self.window.frame.size.width,self.window.frame.size.height-20);
        
        // Text and TabBar button colors (also images on navigationBar ?)
        [self.window setTintColor:MAIN_TINT_COLOR];
        [self.window setTintColor:[UIColor labelColor]];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIFont systemFontOfSize:14], NSFontAttributeName,
                                    [UIColor labelColor], NSForegroundColorAttributeName,
                                    nil];
        [[UINavigationBar appearance] setTitleTextAttributes:attributes];
     
        // Remove shadow?
        /*
        [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setShadowImage:[UIImage new]];
        */
        
//        [[UIApplication sharedApplication] setStatusBarHidden:NO
//                                                withAnimation:UIStatusBarAnimationSlide];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Register the values that should be returned if an object is not found in the defaults
    // Note: it doesn't affect the "defaults"
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    NSString *keyDBLastUpdate = [MLConstants databaseUpdateKey];
    [appDefaults setValue:[NSDate date] forKey:keyDBLastUpdate];
    [defaults registerDefaults:appDefaults];

    BOOL appVersionChanged = [MLUtility checkAppVersion]; // read/write defaults
    if (appVersionChanged) {
        // Delete DB files in Documents folder so that the ones in the Bundle will be used
        [MLDBAdapter removeFileInDocDir:@"amiko_db_full_idx_" extension:@"db"];
        [MLDBAdapter removeFileInDocDir:@"drug_interactions_csv_" extension:@"csv"];
        [MLDBAdapter removeFileInDocDir:@"amiko_frequency_" extension:@"db"];
        [MLDBAdapter removeFileInDocDir:@"amiko_report_" extension:@"html"];

        [MLUtility updateDBCheckedTimestamp];
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
    
    [MLPersistenceManager shared];
    
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

#pragma mark -

/**
 *  @brief config dynamic shortcutItems
 *  @discussion after first launch, users can see dynamic shortcutItems
 */
- (void)configDynamicShortcutItems
{
    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier;

    NSString *typeAips = [NSString stringWithFormat:@"%@.Aips", bundleId];
    NSString *typeFavorites = [NSString stringWithFormat:@"%@.Favorites", bundleId];
    NSString *typeInteractions = [NSString stringWithFormat:@"%@.Interactions", bundleId];
    NSString *typeDesitin = [NSString stringWithFormat:@"%@.Desitin", bundleId];

    UIApplicationShortcutIcon *scAipsIcon = [UIApplicationShortcutIcon iconWithSystemImageName:@"doc.richtext"]; // SF Symbol
    UIApplicationShortcutIcon *scFavoritesIcon = [UIApplicationShortcutIcon iconWithSystemImageName:@"star"]; // SF Symbol
    UIApplicationShortcutIcon *scInteractionsIcon = [UIApplicationShortcutIcon iconWithSystemImageName:@"exclamationmark.triangle"]; // SF Symbol
    UIApplicationShortcutIcon *scDesitinIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"desitin_quick"]; // custom image in app bundles

    UIApplicationShortcutItem *shortcutAips =
        [[UIApplicationShortcutItem alloc] initWithType:typeAips
                                         localizedTitle:@"AIPS"
                                      localizedSubtitle:nil
                                                   icon:scAipsIcon
                                               userInfo:nil];

    UIApplicationShortcutItem *shortcutFavorites =
        [[UIApplicationShortcutItem alloc] initWithType:typeFavorites
                                         localizedTitle:NSLocalizedString(@"Favorites", nil)
                                      localizedSubtitle:nil
                                                   icon:scFavoritesIcon
                                               userInfo:nil];

    UIApplicationShortcutItem *shortcutInteractions =
        [[UIApplicationShortcutItem alloc] initWithType:typeInteractions
                                         localizedTitle:NSLocalizedString(@"Interactions", nil)
                                      localizedSubtitle:nil
                                                   icon:scInteractionsIcon
                                               userInfo:nil];

    UIApplicationShortcutItem *shortcutDesitin =
        [[UIApplicationShortcutItem alloc] initWithType:typeDesitin
                                         localizedTitle:NSLocalizedString(@"Desitin Products", nil)
                                      localizedSubtitle:nil
                                                   icon:scDesitinIcon
                                               userInfo:nil];
    // Add the array to our app
    [UIApplication sharedApplication].shortcutItems = @[shortcutDesitin,
                                                        shortcutInteractions,
                                                        shortcutFavorites,
                                                        shortcutAips];
}

- (void) showPrescriptionId:(NSString *)uniqueId :(NSString *)fileName
{
    // Update defaults to be used in other views
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:uniqueId forKey:@"currentPatient"];
    [defaults setObject:fileName forKey:@"lastUsedPrescription"];
    [defaults synchronize];
    
    PrescriptionViewController *vc = [PrescriptionViewController sharedInstance];
    vc.editedMedicines = false;
    
    // Switch to prescription view to show what we just imported
    UITabBarItem *item = [UITabBarItem new];
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
    Prescription *presInbox = [[Prescription alloc] initWithURL:url];

    // Check if the patient subdirectory exists and possibly create it
    NSURL *amkDir = [[MLPersistenceManager shared] amkDirectoryForPatient:presInbox.patient.uniqueId];

    // Check if the patient is already in the DB and possibly add it.
    if ([[MLPersistenceManager shared] getPatientWithUniqueID:presInbox.patient.uniqueId]==nil) {
        [[MLPersistenceManager shared] addPatient:presInbox.patient];
    }
    
    // Check the hash of the existing amk files
    NSArray<NSURL *> *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:amkDir
                                                      includingPropertiesForKeys:nil
                                                                         options:0
                                                                           error:&error];
    NSArray<NSURL *> *amkFilesArray = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];

    BOOL prescriptionNeedsToBeImported = YES;
    NSString *foundFileName;
    NSString *foundUniqueId;
    // TODO: handle case which the storage is iCloud, need time to download files
    for (NSURL *url in amkFilesArray) {
        NSString *f = url.lastPathComponent;
        Prescription *presAmkDir = [[Prescription alloc] initWithURL:url];
        if ([presInbox.hash isEqualToString:presAmkDir.hash]) {
            prescriptionNeedsToBeImported = NO;
            foundFileName = f;
            foundUniqueId = presAmkDir.patient.uniqueId;
            break;
        }
    }
    
    if (!prescriptionNeedsToBeImported) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"%@ has already been imported",nil), fileName];
        error = [NSError errorWithDomain:@"receipt"
                                    code:99
                                userInfo:@{NSLocalizedDescriptionKey:message}];

        [self showPopupWithTitle:@"Import Error"
                         message:error.localizedDescription];
        
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

    // Finally copy amk from Inbox to patient subdirectory
    [[NSFileManager defaultManager] copyItemAtURL:url
                                            toURL:[amkDir URLByAppendingPathComponent:fileName]
                                            error:&error];
    if (!error)
        [self showPopupWithTitle:@"Success!"
                         message:[NSString stringWithFormat:@"Imported %@", fileName]];
    
    [self showPrescriptionId:presInbox.patient.uniqueId :fileName];
    return YES;
}

- (void) switchRigthToPatientDbList
{
    id right = self.revealViewController.rightViewController;
    if (![right isKindOfClass:[PatientDbListViewController class]] ) {
        UIViewController *listViewController = [PatientDbListViewController sharedInstance];
        [self.revealViewController setRightViewController:listViewController];

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
