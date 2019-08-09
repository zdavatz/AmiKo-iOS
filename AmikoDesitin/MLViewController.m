/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
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

#import "MLViewController.h"

#import "MLConstants.h"
#import "MLUtility.h"

#import "MLSecondViewController.h"
#import "MLTitleViewController.h"
#import "MLMenuViewController.h"

#import "FullTextViewController.h"
#import "FullTextOverviewVC.h"

#import "PrescriptionViewController.h"
#import "AmkListViewController.h"

#import "DoctorViewController.h"
#import "PatientViewController.h"
#import "ContactsListViewController.h"

#import "MLUtility.h"
#import "MLAlertView.h"
#import "MLDBAdapter.h"
#import "MLSimpleTableCell.h"
#import "MLDataStore.h"

#import "SWRevealViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <mach/mach.h>
#import <sys/time.h>

#import "MLAppDelegate.h"

#import "FullTextDBAdapter.h"
#import "FullTextSearch.h"
#import "FullTextEntry.h"

// Requirement to show at least up to the first comma, no line wrapping
#define CUSTOM_FONT_SIZE_PICKER

// Fix issue #61
#define TWO_ITEMS_ON_LEFT_NAV_BAR

typedef NS_ENUM(NSInteger, DatabaseTypes) {
    DB_TYPE_AIPS=0,
    DB_TYPE_HOSPITAL=1,        // unused ?
    DB_TYPE_FAVORITES=2,
    DB_TYPE_INTERACTIONS=3,    // unused ?
    DB_TYPE_PRESCRIPTION,
    DB_TYPE_FULL_TEXT,
    DB_TYPE_NONE=100
};

// They are also used in objectAtIndex
// for iPad they get divided by 2 in setBarButtonItemsWith !
typedef NS_ENUM(NSInteger, SearchStates) {
    SEARCH_TITLE=0,
    SEARCH_AUTHOR=2,
    SEARCH_ATC_CODE=4,
    SEARCH_REG_NR=6,
    SEARCH_THERAPY=8,
    SEARCH_FULL_TEXT=10
};

static DatabaseTypes mUsedDatabase = DB_TYPE_NONE;
static SearchStates mCurrentSearchState = SEARCH_TITLE;

static CGFloat searchFieldWidth = 320.0f;

static BOOL mSearchInteractions = false;
static BOOL mShowReport = false;

#pragma mark -

////////////////////////////////////////////////////////////////////////////////
@interface DataObject : NSObject

@property NSString *title;
@property NSString *subTitle;
@property long medId;
@property NSString *hashId;

@end

#pragma mark -

////////////////////////////////////////////////////////////////////////////////
@implementation DataObject

@synthesize title;
@synthesize subTitle;
@synthesize medId;
@synthesize hashId;

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ id:%ld <%@>",
            NSStringFromClass([self class]), self.medId, self.title];
}

@end

#pragma mark -

////////////////////////////////////////////////////////////////////////////////
@implementation MLViewController
{
    // Instance variable declarations go here
    NSMutableArray *medi;
    
    NSMutableArray *titleData;
    NSMutableArray *subTitleData;
    NSMutableArray *favoriteKeyData;
    NSMutableArray *medIdArray;
    
    MLDBAdapter *mDb;
    MLMedication *mMed;
    FullTextDBAdapter *mFullTextDb;
    FullTextEntry *mFullTextEntry;
    FullTextSearch *mFullTextSearch;
    NSMutableString *mBarButtonItemName;
    NSMutableSet *favoriteMedsSet;
    NSMutableArray *items;
    MLDataStore *favoriteData;
   
    NSMutableDictionary *mMedBasket;
    
    __block NSArray *searchResults;
    
    NSArray *mListOfSectionIds;  // full paths
    NSArray *mListOfSectionTitles;
    
    SWRevealViewController *mainRevealController;
    
    MLSecondViewController *secondViewController;
    FullTextViewController *fullTextVC;

    MLTitleViewController *titleViewController;
    MLMenuViewController *menuViewController;
    AmkListViewController *amkListViewController;

    UINavigationController *otherViewNavigationController;
    UINavigationController *menuViewNavigationController;
    
    UIActivityIndicatorView *mActivityIndicator;
    
    NSIndexPath *mCurrentIndexPath;
    long mNumCurrSearchResults;
    int timeForSearch_ms;
    
    struct timeval beg_tv;
    struct timeval end_tv;
    
    BOOL runningActivityIndicator;

    NSDictionary *fullTextMessage;  // to pass around the anchor to be scrolled into view
    NSString *mFullTextContentStr;
    
    dispatch_queue_t mSearchQueue;
}

@synthesize searchField;
@synthesize myTextField;
@synthesize myTableView;
@synthesize myToolBar;
@synthesize myTabBar;
@synthesize pickerSheet, pickerView;

#pragma mark - Instance functions

- (IBAction) searchAction:(id)sender
{
    // Do something
}

- (IBAction) onToolBarButtonPressed:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s %d Button tag: %ld, title: %@", __FUNCTION__, __LINE__, (long)[sender tag], [sender title]);
#endif
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    mUsedDatabase = DB_TYPE_AIPS;  // default for all, except full text
    searchResults = [NSArray array];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ||
        (orientation == UIInterfaceOrientationLandscapeLeft) ||
        (orientation == UIInterfaceOrientationLandscapeRight) )
    {
        [searchField setText:@""];
        if ([btn.title isEqualToString:NSLocalizedString(@"Preparation", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"Preparation", "Full toolbar")];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Preparation", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Preparation", "Full toolbar")];
            mCurrentSearchState = SEARCH_TITLE;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Owner", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"Owner", "Full toolbar")];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Owner", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Owner", "Full toolbar")];
            mCurrentSearchState = SEARCH_AUTHOR;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"ATC Code", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"ATC Code", "Full toolbar")];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"ATC Code", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"ATC Code", "Full toolbar")];
            mCurrentSearchState = SEARCH_ATC_CODE;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Reg. No", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"Reg. No", "Full toolbar")];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Reg. No", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Reg. No", "Full toolbar")];
            mCurrentSearchState = SEARCH_REG_NR;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Therapy", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"Therapy", "Full toolbar")];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Therapy", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Therapy", "Full toolbar")];
            mCurrentSearchState = SEARCH_THERAPY;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Full Text", "Full toolbar")]) {
            [myTextField setText:NSLocalizedString(@"Full Text", "Full toolbar")];
            [searchField setPlaceholder:NSLocalizedString(@"Full Text Search", "Search placeholder")];
            [mBarButtonItemName setString:NSLocalizedString(@"Full Text", "Full toolbar")];
            mCurrentSearchState = SEARCH_FULL_TEXT;
            mUsedDatabase = DB_TYPE_FULL_TEXT;
            //searchResults = [NSArray array];
        }
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [searchField setText:@""];
        if ([btn.title isEqualToString:NSLocalizedString(@"Prep", "Short toolbar")]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Preparation", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Preparation", "Full toolbar")];
            mCurrentSearchState = SEARCH_TITLE;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Own", "Short toolbar")]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Owner", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Owner", "Full toolbar")];
            mCurrentSearchState = SEARCH_AUTHOR;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"ATC", "Short toolbar")]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"ATC Code", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"ATC Code", "Full toolbar")];
            mCurrentSearchState = SEARCH_ATC_CODE;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Reg", "Short toolbar")]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Reg. No", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Reg. No", "Full toolbar")];
            mCurrentSearchState = SEARCH_REG_NR;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"Ther", "Short toolbar")]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Therapy", "Full toolbar")]];
            [mBarButtonItemName setString:NSLocalizedString(@"Therapy", "Full toolbar")];
            mCurrentSearchState = SEARCH_THERAPY;
        }
        else if ([btn.title isEqualToString:NSLocalizedString(@"FTS", "Short toolbar")]) {
            [searchField setPlaceholder:NSLocalizedString(@"Full Text Search", "Search placeholder")];
            [mBarButtonItemName setString:NSLocalizedString(@"Full Text", "Full toolbar")];
            mCurrentSearchState = SEARCH_FULL_TEXT;
            mUsedDatabase = DB_TYPE_FULL_TEXT;
            
        }
    }
    
#ifdef DEBUG
    NSLog(@"%s %d, mUsedDatabase: %ld, mCurrentSearchState: %ld", __FUNCTION__, __LINE__,
          (long)mUsedDatabase, mCurrentSearchState);
#endif

    for (UIBarButtonItem *b in [myToolBar items]) {
        if (b==btn)
            [b setTintColor:MAIN_TINT_COLOR];
        else
            [b setTintColor:[UIColor lightGrayColor]];   // Default color
    }

    if (searchResults) {
        [self updateTableView];
        [myTableView reloadData];
        [searchField resignFirstResponder];
    }
}

- (void) dealloc
{
    NSLog(@"Goodbye MLViewController");
}

- (id) init
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    self = [super init];
    
    // Initialize constants
    [MLConstants start];
    
    // Retreive app related information
    [MLUtility checkVersion];
    
    medi = [NSMutableArray array];
    titleData = [NSMutableArray array];
    subTitleData = [NSMutableArray array];
    favoriteKeyData = [NSMutableArray array];   // equivalent to [[alloc] init] and [new]
    medIdArray = [NSMutableArray array];        // Used by tableview
    
    secondViewController = nil;
    otherViewNavigationController = nil;
    menuViewController = nil;
    menuViewNavigationController = nil;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    runningActivityIndicator = NO;
    
    mSearchQueue = dispatch_queue_create("com.ywesee.searchdb", nil);
    
    // Register observer to notify successful download of new database
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedDownloading:)
                                                 name:@"MLDidFinishLoading"
                                               object:nil];
    
    // Register observer to notify absence of file on pillbox server
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedDownloading:)
                                                 name:@"MLStatusCode404"
                                               object:nil];

    // Regisger observer to check if we are back from the background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dbSyncNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(patientDbListDidChangeSelection:)
                                                 name:@"PatientSelectedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ftOverviewDidChangeSelection:)
                                                 name:@"ftOverviewSelectedNotification"
                                               object:nil];
    // Set default database
    mUsedDatabase = DB_TYPE_AIPS;

    // Set current search state
    mCurrentSearchState = SEARCH_TITLE;
    
    return self;
}

- (instancetype) initWithLaunchState:(int)state
{
    id handle = [self init];
    
    if (handle != nil) {
        [self setLaunchState:state];
    }
    
    return handle;
}

- (void) setLaunchState:(int)state
{
#ifdef DEBUG
    NSLog(@"%s state:%d", __FUNCTION__, state);
#endif
    bool keyboard_visible = true;
    bool goBackToMainView = false;
    
    switch (state) {
        case eAips:
            goBackToMainView = true;
            mUsedDatabase = DB_TYPE_AIPS;
            mSearchInteractions = false;
            mCurrentIndexPath = nil;
            // Reset searchfield
            [self resetBarButtonItems];
            // Clear main table view
            [self clearDataInTableView];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
            break;
            
        case eFavorites:
            goBackToMainView = true;
            mUsedDatabase = DB_TYPE_FAVORITES;
            mCurrentSearchState = SEARCH_TITLE;
            mSearchInteractions = false;
            // The following programmatical call takes care of everything...
            [self switchTabBarItem:[myTabBar.items objectAtIndex:1]];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];
            break;
            
        case eInteractions:
            goBackToMainView = true;
            mUsedDatabase = DB_TYPE_AIPS;
            mCurrentSearchState = SEARCH_TITLE;
            mSearchInteractions = true;
            // Reset searchfield
            [self resetBarButtonItems];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:2]];
            break;
            
        case eDesitin:
            goBackToMainView = true;
            mUsedDatabase = DB_TYPE_AIPS;
            mCurrentSearchState = SEARCH_AUTHOR;
            mSearchInteractions = false;
            [self executeSearch:@"desitin"];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
            keyboard_visible = false;
            break;
            
        case ePrescription:
            goBackToMainView = true;
            mSearchInteractions = false;
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:3]];
            break;
            
        default:
            NSLog(@"Unknown: %s, line %i", __FUNCTION__, __LINE__);
            break;
    }

    if (goBackToMainView) {
        mainRevealController = self.revealViewController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];

        // Show keyboard
        if (keyboard_visible)
            [searchField becomeFirstResponder];
        else {
            [searchField resignFirstResponder];
            [searchField setText:@"desitin"];
        }
    }
}

- (void) doNotBackupDocumentsDir
{
    // See https://developer.apple.com/icloud/documentation/data-storage/index.html
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDir error:nil];
    if (files!=nil) {
        for (NSString *file in files) {
            [self addSkipBackupAttributeToItemAtURL:[documentsDir stringByAppendingPathComponent:file]];
        }
    }
}

- (BOOL) addSkipBackupAttributeToItemAtURL:(NSString *)filePathString
{
    NSURL *fileURL = [NSURL fileURLWithPath:filePathString];
#ifdef DEBUG
    assert([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]);
#endif
    
    NSError *error = nil;
    BOOL success = [fileURL setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success){
        NSLog(@"Error excluding %@ from backup %@", [fileURL lastPathComponent], error);
    }
    return success;
}

#pragma mark - Notifications

- (void)patientDbListDidChangeSelection:(NSNotification *)aNotification
{
#ifdef DEBUG
    NSLog(@"%s %@", __FUNCTION__, aNotification);
#endif
    // Set as default patient for prescriptions
    Patient *p = [aNotification object];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:p.uniqueId forKey:@"currentPatient"];
    [defaults synchronize];
    
#ifdef DEBUG_ISSUE_86
    NSLog(@"%s %d define currentPatient ID %@", __FUNCTION__, __LINE__, p.uniqueId);
#endif

    UIViewController *nc_front = self.revealViewController.frontViewController;
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];

    // Make sure we have the correct front controller
    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
#ifdef DEBUG
    //NSLog(@"appDel.editMode %ld", appDel.editMode);
    //NSLog(@"front: %@ %p", [vc_front class], vc_front);
#endif
    
    switch (appDel.editMode) {
        case EDIT_MODE_PRESCRIPTION:
            // There is only one case when we need to replace the front view
            if ([vc_front isKindOfClass:[PatientViewController class]])
                [self switchToPrescriptionView];
            break;

        case EDIT_MODE_PATIENTS:
            if ([vc_front isKindOfClass:[PatientViewController class]]) {
                PatientViewController *pvc = (PatientViewController *)vc_front;
                [pvc resetAllFields];
                [pvc setAllFields:p];
            }
            break;

        default:
        case EDIT_MODE_UNDEFINED:
            break;
    }
    
    [self.revealViewController rightRevealToggle:self];    
}

- (void) finishedDownloading:(NSNotification *)notification
{
    static int fileCnt = 0;
    
    if ([[notification name] isEqualToString:@"MLDidFinishLoading"]) {
        fileCnt++;
        NSLog(@"Finished downloading file %d", fileCnt);

        if (mDb != nil &&
            mFullTextDb != nil &&
            fileCnt==3)
        {
            // Reset file counter
            fileCnt=0;
            // Make sure downloaded files cannot be backed up
            [self doNotBackupDocumentsDir];

            // Sqlite database
            [mDb closeDatabase];
            [self openSQLiteDatabase];

            // Fulltext database
            [mFullTextDb closeDatabase];
            [self openFullTextDatabase];

            // Interaction database
            [mDb closeInteractionsCsvFile];
            [self openInteractionsCsvFile];

            // Reload table
            [self resetBarButtonItems];
            [self resetDataInTableView];
            
            // Display friendly message
            long numProducts = [mDb getNumProducts];
            long numSearchRes = [searchResults count]; // numFachinfos
            long numSearchTerms = [mFullTextDb getNumRecords];
            int numInteractions = (int)[mDb getNumInteractions];

            NSDictionary *d = [[NSBundle mainBundle] infoDictionary];
            NSString *bundleName = [d objectForKey:@"CFBundleName"];
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ Database Updated!",nil), bundleName];
            
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"The database contains:\n- %ld Products\n- %ld Specialist information\n- %ld Keywords\n- %d Interactions", nil), numProducts, numSearchRes, numSearchTerms, numInteractions];

            MLAlertView *alert = [[MLAlertView alloc] initWithTitle:title
                                                            message:message
                                                             button:@"OK"];
            [alert show];

            // Store update date, this variable is set very first time app is set up
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *key = [MLConstants databaseUpdateKey];
            [defaults setValue:[NSDate date] forKey:key];

            // Make sure it's saved to file immediately
            [defaults synchronize];
        }
    } else if ([[notification name] isEqualToString:@"MLStatusCode404"]) {
        NSLog(@"Status Code 404");
        MLAlertView *alert = [[MLAlertView alloc] initWithTitle:@"Datenbank kann nicht aktualisiert werden!"
                                                        message:@"Server unreachable..."
                                                         button:@"OK"];
        [alert show];
    }
}

- (void) dbSyncNotification:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:UIApplicationWillEnterForegroundNotification]) {
        [self checkLastDBSync];
    }
}

- (void)ftOverviewDidChangeSelection:(NSNotification *)aNotification
{
#if 0
    NSInteger row = [aNotification.object integerValue];
    //NSString *filter = [aNotification.object stringValue];
#else
    NSDictionary *d = [aNotification object];
    NSInteger row = [d[KEY_FT_ROW] integerValue];
    //NSString *filter = d[KEY_FT_TEXT];
#endif

    if (![mFullTextSearch.listOfSectionIds isEqual:[NSNull null]])
        mListOfSectionIds = mFullTextSearch.listOfSectionIds;

    if (![mFullTextSearch.listOfSectionTitles isEqual:[NSNull null]])
        mListOfSectionTitles = mFullTextSearch.listOfSectionTitles;

    // Re-sort results in webView
    NSString *contentStr = [mFullTextSearch tableWithArticles:nil
                                           andRegChaptersDict:nil
                                                    andFilter:mListOfSectionIds[row]];

    FullTextViewController *fullTextVC = [FullTextViewController sharedInstance];
    [fullTextVC updateFullTextSearchView:contentStr];
    
    [self.revealViewController rightRevealToggleAnimated:YES];
}

#pragma mark -

- (void) checkLastDBSync
{
    // Nag user all 30 days! = 60 x 60 x 24 x 30 seconds
    if ([MLUtility timeIntervalSinceLastDBSync] <= 60*60*24*30)
        return;

    // Show alert with OK button
    NSString *title = NSLocalizedString(@"Database Update", nil);
    NSString *message = NSLocalizedString(@"Your database is older than 30 days. We recommend an update. The update can also be done manually at any time by clicking on the pill in the upper left corner.", nil);

    MLAlertView *alert = [[MLAlertView alloc] initWithTitle:title
                                                    message:message
                                                     button:@"OK"];
    [alert show];

    // Store current date, and bother user again in a month
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSDate date] forKey:[MLConstants databaseUpdateKey]];

    // Make sure it's saved to file immediately
    [defaults synchronize];
}

- (void) openSQLiteDatabase
{
    mDb = [MLDBAdapter sharedInstance];

    if ([[MLConstants databaseLanguage] isEqualToString:@"de"]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_de"]) {
            NSLog(@"No German database!");
            mDb = nil;
        }
    } else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_fr"]) {
            NSLog(@"No French database!");
            mDb = nil;
        }
    }
}

- (void) openFullTextDatabase
{
    mFullTextDb = [FullTextDBAdapter new];
    if ([[MLConstants databaseLanguage] isEqualToString:@"de"]) {
        if (![mFullTextDb openDatabase:@"amiko_frequency_de"]) {
            NSLog(@"No German Fulltext database!");
            mFullTextDb = nil;
        }
    }
    else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"]) {
        if (![mFullTextDb openDatabase:@"amiko_frequency_fr"]) {
            NSLog(@"No French Fulltext database!");
            mFullTextDb = nil;
        }
    }
}

- (void) openInteractionsCsvFile
{
    if ([[MLConstants databaseLanguage] isEqualToString:@"de"]) {
        if (![mDb openInteractionsCsvFile:@"drug_interactions_csv_de"]) {
            NSLog(@"No German drug interactions file!");
        }
    } else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"]) {
        if (![mDb openInteractionsCsvFile:@"drug_interactions_csv_fr"]) {
            NSLog(@"No French drug interactions file!");
        }
    }
}

- (void) clearDataInTableView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    searchResults = [NSArray array];
    [medi removeAllObjects];
    [self.myTableView reloadData];
    mUsedDatabase = DB_TYPE_AIPS;
    mCurrentSearchState = SEARCH_TITLE;
    [self setBarButtonItemsWith:mCurrentSearchState];
}

- (void) resetDataInTableView
{
#ifdef DEBUG
    NSLog(@"%s %d, mUsedDatabase: %ld, mCurrentSearchState: %ld", __FUNCTION__, __LINE__,
          (long)mUsedDatabase, (long)mCurrentSearchState);
#endif
    searchResults = [self searchDatabaseWith:@""];
#ifdef DEBUG
    NSLog(@"%s %d, searchResults count: %ld", __FUNCTION__, __LINE__, [searchResults count]);
#endif
    if (searchResults) {
        [self updateTableView];
        [self.myTableView reloadData];
   }
}

- (void) resetBarButtonItems
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    // Reset search state
    mUsedDatabase = DB_TYPE_AIPS;
    mCurrentSearchState = SEARCH_TITLE;

    for (UIBarButtonItem *b in [myToolBar items])
       [b setTintColor:[UIColor lightGrayColor]];   // Default color

    // Highlight first button in toolbar at the top of the screen
    [[[myToolBar items] objectAtIndex:SEARCH_TITLE] setTintColor:MAIN_TINT_COLOR];

    [searchField setText:@""];
    [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                 NSLocalizedString(@"Search",nil),
                                 NSLocalizedString(@"Preparation", "Full toolbar")]];
    mCurrentSearchState = SEARCH_TITLE;
}

- (void) setBarButtonItemsWith:(SearchStates)searchState
{
    for (UIBarButtonItem *b in [myToolBar items])
        [b setTintColor:[UIColor lightGrayColor]];   // Default color

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        searchState /= 2;
    
    [[[myToolBar items] objectAtIndex:searchState] setTintColor:MAIN_TINT_COLOR];

    [searchField setText:@""];
    switch (searchState)
    {
        case SEARCH_TITLE:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Preparation", "Full toolbar")]];
            break;

        case SEARCH_AUTHOR:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Owner", "Full toolbar")]];
            break;

        case SEARCH_ATC_CODE:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"ATC Code", "Full toolbar")]];
            break;

        case SEARCH_REG_NR:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Reg. No", "Full toolbar")]];
            break;

        case SEARCH_THERAPY:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@",
                                         NSLocalizedString(@"Search",nil),
                                         NSLocalizedString(@"Therapy", "Full toolbar")]];
            break;

        case SEARCH_FULL_TEXT:
            [searchField setPlaceholder:NSLocalizedString(@"Full Text Search", "Search placeholder")];
            break;
    }

    mCurrentSearchState = searchState;
}

- (void) saveData
{
    NSString *path = @"~/Library/Preferences/data";
    path = [path stringByExpandingTildeInPath];
    
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
    [rootObject setValue:favoriteData forKey:@"kFavMedsSet"];
    
    // Save contents of rootObject by key, value must conform to NSCoding protocolw
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

- (void) loadData
{
    NSString *path = @"~/Library/Preferences/data";
    path = [path stringByExpandingTildeInPath];
    
    // Retrieves unarchived dictionary into rootObject
    NSMutableDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    if ([rootObject valueForKey:@"kFavMedsSet"]) {
        favoriteData = [rootObject valueForKey:@"kFavMedsSet"];
    }
}

- (void) showTabBarWithAnimation:(BOOL)withAnimation
{
    if (withAnimation == NO) {
        [myTabBar setHidden:NO];
    } else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:nil];
        [UIView setAnimationDuration:1.25];
        
        [myTabBar setAlpha:1.0];
        
        [UIView commitAnimations];
    }

    [self setTabbarItemFont];
}

- (void) hideTabBarWithAnimation:(BOOL)withAnimation
{
    if (withAnimation == NO) {
        [myTabBar setHidden:YES];
    } else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:nil];
        [UIView setAnimationDuration:0.25];
        
        [myTabBar setAlpha:0.0];
        
        [UIView commitAnimations];
    }
}

- (void) setTabbarItemFont
{
    NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2], NSFontAttributeName,
                                         // @1.0, NSKernAttributeName,
                                         // [NSValue valueWithUIOffset:UIOffsetMake(1,0)], UITextAttributeTextShadowOffset,
                                         nil];
    
    for (UIBarButtonItem *b in [myTabBar items])
        [b setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

- (void) setToolbarItemsFontSize
{
    NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [UIFont systemFontOfSize:14], NSFontAttributeName,
                                         nil];
    
    for (UIBarButtonItem *b in [myToolBar items])
        if (b.tag != 0)   // Skip UIBarButtonSystemItemFlexibleSpace
            [b setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

- (void) startActivityIndicator
{
    if (runningActivityIndicator==NO) {
        mActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        mActivityIndicator.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0f);
        mActivityIndicator.frame = CGRectIntegral(mActivityIndicator.frame);
        mActivityIndicator.color = [UIColor whiteColor];
        mActivityIndicator.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        [mActivityIndicator layer].cornerRadius = 8.0f;
        CGRect f = mActivityIndicator.bounds;
        f.size.width += 10;
        f.size.height += 10;
        mActivityIndicator.bounds = f;
    
        [self.view addSubview:mActivityIndicator];
        [mActivityIndicator startAnimating];
        runningActivityIndicator = YES;
    }
}

- (void) stopActivityIndicator
{
    [mActivityIndicator stopAnimating];
    [mActivityIndicator removeFromSuperview];
    runningActivityIndicator = NO;
}

/*
- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
}
*/

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef DEBUG
    NSLog(@"%s to orientation: %ld", __FUNCTION__, interfaceOrientation);
#endif
    return YES;
}

// TODO: use "viewWillTransitionToSize:withTransitionCoordinator:" instead
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                 duration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"%s to orientation: %ld", __FUNCTION__, toInterfaceOrientation);
#endif
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    } // iPad

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self setToolbarItemsFontSize];
        
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthLandscape];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawLandscape];
            
            // Items at index 1,3,5,7 are flexible space
            [[[myToolBar items] objectAtIndex:0] setTitle:NSLocalizedString(@"Preparation", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:2] setTitle:NSLocalizedString(@"Owner", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:4] setTitle:NSLocalizedString(@"ATC Code", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:6] setTitle:NSLocalizedString(@"Reg. No", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:8] setTitle:NSLocalizedString(@"Therapy", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:10] setTitle:NSLocalizedString(@"Full Text", "Full toolbar")];

            // Hide status bar and navigation bar (top)
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];

            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
            
            self.myTableViewHeightConstraint.constant = 5;
        }
        else {
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthPortrait];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawPortrait];
            
            [[[myToolBar items] objectAtIndex:0] setTitle:NSLocalizedString(@"Prep", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:2] setTitle:NSLocalizedString(@"Own", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:4] setTitle:NSLocalizedString(@"ATC", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:6] setTitle:NSLocalizedString(@"Reg", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:8] setTitle:NSLocalizedString(@"Ther", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:10] setTitle:NSLocalizedString(@"FTS", "Short toolbar")];

            // Display status and navigation bar (top)
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];

            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationSlide];

            self.myTableViewHeightConstraint.constant = 49;
        }

        [self showTabBarWithAnimation:YES]; // the tab bar is at the bottom of the view
        [myTableView layoutIfNeeded];
    } // iPhone
}

#pragma mark -
     
- (void) viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
        
        [[[myToolBar items] objectAtIndex:0] setTitle:NSLocalizedString(@"Preparation", "Full toolbar")];
        [[[myToolBar items] objectAtIndex:1] setTitle:NSLocalizedString(@"Owner", "Full toolbar")];
        [[[myToolBar items] objectAtIndex:2] setTitle:NSLocalizedString(@"ATC Code", "Full toolbar")];
        [[[myToolBar items] objectAtIndex:3] setTitle:NSLocalizedString(@"Reg. No", "Full toolbar")];
        [[[myToolBar items] objectAtIndex:4] setTitle:NSLocalizedString(@"Therapy", "Full toolbar")];
        [[[myToolBar items] objectAtIndex:5] setTitle:NSLocalizedString(@"Full Text", "Full toolbar")];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self setToolbarItemsFontSize];
        
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthLandscape];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawLandscape];
            
            [[[myToolBar items] objectAtIndex:0] setTitle:NSLocalizedString(@"Preparation", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:2] setTitle:NSLocalizedString(@"Owner", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:4] setTitle:NSLocalizedString(@"ATC Code", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:6] setTitle:NSLocalizedString(@"Reg. No", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:8] setTitle:NSLocalizedString(@"Therapy", "Full toolbar")];
            [[[myToolBar items] objectAtIndex:10] setTitle:NSLocalizedString(@"Full Text", "Full toolbar")];

            // [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
        }
        else {
            //
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthPortrait];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawPortrait];
            
            [[[myToolBar items] objectAtIndex:0] setTitle:NSLocalizedString(@"Prep", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:2] setTitle:NSLocalizedString(@"Own", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:4] setTitle:NSLocalizedString(@"ATC", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:6] setTitle:NSLocalizedString(@"Reg", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:8] setTitle:NSLocalizedString(@"Ther", "Short toolbar")];
            [[[myToolBar items] objectAtIndex:10] setTitle:NSLocalizedString(@"FTS", "Short toolbar")];

            // [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
        }
    }
    
    if (!mSearchInteractions) {
        if (mUsedDatabase == DB_TYPE_AIPS)
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
        else if (mUsedDatabase == DB_TYPE_FAVORITES)
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];
        else if (mUsedDatabase == DB_TYPE_PRESCRIPTION)
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:3]];
        else if (mUsedDatabase == DB_TYPE_NONE)
            [myTabBar setSelectedItem:nil]; // Clears all cells
    }
    else {
        [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:2]];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    for (id gr in self.view.gestureRecognizers)
//        NSLog(@"gestureRecognizer: %@", [gr class]);
#endif
    
    [super viewDidAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            // Hide status bar and navigation bar (top)
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];

            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
 
            self.myTableViewHeightConstraint.constant = 5;
        }
        else {
            // Display status and navigation bar (top)
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];

            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationSlide];
            
            self.myTableViewHeightConstraint.constant = 49;
        }
        
        [self showTabBarWithAnimation:YES];
        [myTableView layoutIfNeeded];

    } // iPhone
    
    [super viewDidLayoutSubviews];
    [self.myTabBar invalidateIntrinsicContentSize];
    [self setBarButtonItemsWith:mCurrentSearchState];
    
    // Initialize full text search
    mFullTextSearch = [FullTextSearch new];
}

//- (void) viewDidUnload
//{
//    [super viewDidUnload];
//}

- (void) viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = APP_NAME;
    
    // Sets color and font and whatever else of the navigation bar
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          VERY_LIGHT_GRAY_COLOR, NSForegroundColorAttributeName,
                                                          nil]];
    // Applies this color throughout the app
    // [[UISearchBar appearance] setBarTintColor:[UIColor lightGrayColor]];
    
    // Add icon (top center)
    // self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon_32x32.png"]];

    // Left button(s) - Add desitin icon
    UIButton *logoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoButton setImage:[UIImage imageNamed:@"desitin_icon_32x32.png"] forState:UIControlStateNormal];
    logoButton.frame = CGRectMake(0.0f, 0.0f, 32.0f, 32.0f);
    [logoButton addTarget:self
                   action:@selector(myShowMenuMethod:)
         forControlEvents:UIControlEventTouchUpInside];

    if (@available(iOS 9, *)) {
        [logoButton.widthAnchor constraintEqualToConstant:32.0f].active = YES;
        [logoButton.heightAnchor constraintEqualToConstant:32.0f].active = YES;
    }
    
    UIBarButtonItem *appIconItem = [[UIBarButtonItem alloc] initWithCustomView:logoButton];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        self.navigationItem.leftBarButtonItem = appIconItem;

    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
#ifndef TWO_ITEMS_ON_LEFT_NAV_BAR
        // A single button on the left
        self.navigationItem.leftBarButtonItem = appIconItem;
#endif
    }
    
    // Initialize menu view controllers
    if (menuViewController!=nil) {
        [menuViewController removeFromParentViewController];
        menuViewController = nil;
    }
    menuViewController =
    [[MLMenuViewController alloc] initWithNibName:@"MLMenuViewController" bundle:nil parent:self];
    
    if (menuViewNavigationController!=nil) {
        [menuViewNavigationController removeFromParentViewController];
        menuViewNavigationController = nil;
    }
    menuViewNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
    
    // Background color of navigation bar
    {
        self.navigationController.navigationBar.backgroundColor = VERY_LIGHT_GRAY_COLOR;// MAIN_TINT_COLOR;
        self.navigationController.navigationBar.barTintColor = VERY_LIGHT_GRAY_COLOR;
        self.navigationController.navigationBar.translucent = NO;
        
        // Customize tabbar
        [myTabBar setTintColor:MAIN_TINT_COLOR];
        [myTabBar setTranslucent:YES];
        
        // Sets tabbar selected images
        UITabBarItem *tabBarItem0 = [myTabBar.items objectAtIndex:0];
        UIImage* selectedImage = [[UIImage imageNamed:@"maindb-selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem0.selectedImage = selectedImage;
        
        UITabBarItem *tabBarItem1 = [myTabBar.items objectAtIndex:1];
        selectedImage = [[UIImage imageNamed:@"favorites-selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem1.selectedImage = selectedImage;
        
        UITabBarItem *tabBarItem2 = [myTabBar.items objectAtIndex:2];
        selectedImage = [[UIImage imageNamed:@"interactions-selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem2.selectedImage = selectedImage;
        
        UITabBarItem *tabBarItem3 = [myTabBar.items objectAtIndex:3];
        selectedImage = [[UIImage imageNamed:@"prescription-selected.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        tabBarItem3.selectedImage = selectedImage;
    }
    
    // Add search bar as title view to navigation bar
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        searchField.barTintColor = [UIColor lightGrayColor];
        searchField.backgroundColor = [UIColor clearColor];
        searchField.translucent = YES;
    } // iPad

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, searchFieldWidth, 44.0f)];
        searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchField.delegate = self;

        searchField.barStyle = UIBarStyleDefault;
        searchField.barTintColor = [UIColor clearColor];
        searchField.backgroundImage = [UIImage new];    // Necessary fo completely transparent search bar...
        searchField.backgroundColor = [UIColor clearColor];
        searchField.tintColor = [UIColor lightGrayColor];    // cursor color
        searchField.translucent = NO;
        
#ifdef TWO_ITEMS_ON_LEFT_NAV_BAR
        // Left
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:searchField];
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:appIconItem, searchItem, nil];
#else
        // Middle
        self.navigationItem.titleView = searchField;
#endif

        // Show keyboard
        [searchField becomeFirstResponder];
        
#if 1 // issue #57
        UIGestureRecognizer *tapper =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleSingleTap:)];
        tapper.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:tapper];
#endif
    
    } // iPhone
    
    mBarButtonItemName = [[NSMutableString alloc] initWithString:NSLocalizedString(@"Preparation", "Full toolbar")];
    
    // Add long press gesture recognizer to tableview
    UILongPressGestureRecognizer *mLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(myLongPressMethod:)];
    mLongPressRecognizer.minimumPressDuration = 1.0f;    // [sec]
    mLongPressRecognizer.delegate = self;
    [self.myTableView addGestureRecognizer:mLongPressRecognizer];
    
    // Open sqlite database
    [self openSQLiteDatabase];
#ifdef DEBUG
    NSLog(@"Number of Records = %ld", (long)[mDb getNumRecords]);
#endif

    // Open fulltext database
    [self openFullTextDatabase];
#ifdef DEBUG
    NSLog(@"Number of records in fulltext database = %ld", (long)[mFullTextDb getNumRecords]);
#endif

    // Open drug interactions csv file
    [self openInteractionsCsvFile];
#ifdef DEBUG
    NSLog(@"Number of records in interaction file = %lu", (unsigned long)[mDb getNumInteractions]);
#endif

    // Init medication basket
    mMedBasket = [NSMutableDictionary new];
    
    // Load favorites
    NSFileManager *fileManager = [NSFileManager new];
    NSArray *urls = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if ([urls count] > 0) {
        NSURL *libraryFolder = urls[0];
        // NSLog(@"%@ %@", libraryFolder, [libraryFolder absoluteString]);
        NSError *error = nil;
        NSArray *libraryFolderContent = [fileManager contentsOfDirectoryAtPath:[libraryFolder relativePath] error:&error];

        if (error)
            NSLog(@"%s: %@", __FUNCTION__, error.localizedDescription);
        else if ([libraryFolderContent count] == 0)
            NSLog(@"Library folder is empty!");
#ifdef DEBUG
        else
            NSLog(@"Contents of library folder = %@", libraryFolderContent);
#endif
    }
    else {
        NSLog(@"Could not find the Library folder.");
    }
    
    favoriteData = [MLDataStore new];
    [self loadData];
    
    favoriteMedsSet = [[NSMutableSet alloc] initWithSet:favoriteData.favMedsSet];
    
    [self checkLastDBSync];
}

// issue #57 - Removes keyboard on iPhones
- (void) handleSingleTap:(UITapGestureRecognizer *)sender
{
    [searchField resignFirstResponder];
}

- (void) myShowMenuMethod:(id)sender
{
    // Remove keyboard
    [searchField resignFirstResponder];
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        mainRevealController = self.revealViewController;
        [mainRevealController setFrontViewController:menuViewNavigationController];
        [mainRevealController setFrontViewPosition:FrontViewPositionRight animated:YES];
    } else {
        [menuViewController showMenu];
    }
}

- (void) invalidateObserver
{
    if (titleViewController!=nil && secondViewController!=nil) {
        @try {
            [titleViewController removeObserver:secondViewController forKeyPath:@"javaScript"];
        }
        @catch (NSException *exception) {
            // Do nothing, obviously the observer wasn't attached and an exception was thrown
            NSLog(@"Exception thrown...");
        }
    }
}

- (void) showReport:(id)sender
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];
    
    // Load style sheet from file
    NSString *amikoReportFile = nil;

    NSString *reportFilename = [NSString stringWithFormat:@"amiko_report_%@", [MLConstants databaseLanguage]];

    NSString *filePath = [[documentsDir stringByAppendingPathComponent:reportFilename] stringByAppendingPathExtension:@"html"];

    if ([fileManager fileExistsAtPath:filePath])
        amikoReportFile = filePath;
    else
        amikoReportFile = [[NSBundle mainBundle] pathForResource:reportFilename
                                                          ofType:@"html"];

    NSError *error = nil;
    NSString *amikoReport = [NSString stringWithContentsOfFile:amikoReportFile
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];

    if (amikoReport==nil)
        amikoReport = @"";

    // Rightviewcontroller is not needed, nil it!
    mainRevealController = self.revealViewController;
    mainRevealController.rightViewController = nil;

    if (!mShowReport) {
        [self invalidateObserver];
        mShowReport = true;
    }
    if (secondViewController!=nil) {
        // [secondViewController removeFromParentViewController];
        secondViewController = nil;
    }
    
    secondViewController = [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController"
                                                                    bundle:nil
                                                                     title:@"About"
                                                                  andParam:1];
    
    {
        UIFont *font = [UIFont fontWithName:@"Arial" size:14];
        secondViewController.htmlStr = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>", font.fontName, (int)font.pointSize, amikoReport];
    }

    if (otherViewNavigationController!=nil) {
        [otherViewNavigationController removeFromParentViewController];
        otherViewNavigationController = nil;
    }

    otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];

    [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
    
    report_memory();
}

//- (void) genSearchResultsWith:(NSString *)searchQuery
//{
//#ifdef DEBUG
//    NSLog(@"%s %d", __FUNCTION__, __LINE__);
//#endif
//    if (mCurrentSearchState == SEARCH_TITLE) {
//        searchResults = [mDb searchTitle:searchQuery];
//    }
//    else if (mCurrentSearchState == SEARCH_AUTHOR) {
//        searchResults = [mDb searchAuthor:searchQuery];
//    }
//    else if (mCurrentSearchState == SEARCH_ATC_CODE) {
//        searchResults = [mDb searchATCCode:searchQuery];
//    }
//    else if (mCurrentSearchState == SEARCH_REG_NR) {
//        searchResults = [mDb searchRegNr:searchQuery];
//    }
//    else if (mCurrentSearchState == SEARCH_THERAPY) {
//        searchResults = [mDb searchApplication:searchQuery];
//    }
//}

- (NSArray *) searchDatabaseWith:(NSString *)searchQuery
{
#ifdef DEBUG
    NSLog(@"%s %d, mCurrentSearchState: %ld", __FUNCTION__, __LINE__, (long)mCurrentSearchState);
#endif
    NSArray *searchRes = [NSArray array];
    
    NSDate *startTime = [NSDate date];

    if (mCurrentSearchState == SEARCH_TITLE) {
        searchRes = [mDb searchTitle:searchQuery];
    }
    else if (mCurrentSearchState == SEARCH_AUTHOR) {
        searchRes = [mDb searchAuthor:searchQuery];
    }
    else if (mCurrentSearchState == SEARCH_ATC_CODE) {
        searchRes = [mDb searchATCCode:searchQuery];
    }
    else if (mCurrentSearchState == SEARCH_REG_NR) {
        searchRes = [mDb searchRegNr:searchQuery];
    }
    else if (mCurrentSearchState == SEARCH_THERAPY) {
        searchRes = [mDb searchApplication:searchQuery];
    }
    else if (mCurrentSearchState == SEARCH_FULL_TEXT) {
        if ([searchQuery length] > 2) {
            searchRes = [mFullTextDb searchKeyword:searchQuery];    // NSArray of FullTextEntry
        }
    }
    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
    
    timeForSearch_ms = (int)(1000*execTime+0.5);
    mNumCurrSearchResults = (int)[searchRes count];
    NSLog(@"%ld hits in %dms", mNumCurrSearchResults, timeForSearch_ms);

    return searchRes;
}

- (NSArray *) retrieveAllFavorites
{
    NSMutableArray *medList = [NSMutableArray array];

    NSDate *startTime = [NSDate date];
    
    for (NSString *regnrs in favoriteMedsSet) {
        NSArray *med = [mDb searchRegNr:regnrs];
        if (med!=nil && [med count]>0)
            [medList addObject:med[0]];
    }
    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
    mNumCurrSearchResults = [medList count];
    
    NSLog(@"%ld favorites in %dms", mNumCurrSearchResults, (int)(1000*execTime+0.5));
    
    return medList;
}

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self startActivityIndicator];
    
    [self performSelector:@selector(switchTabBarItem:) withObject:item afterDelay:0.01];
}

// TabBar at the bottom of the screen
- (void) switchTabBarItem: (UITabBarItem *)item
{
    static bool inProgress = false;

#ifdef DEBUG
    NSLog(@"%s item.tag:%ld", __FUNCTION__, item.tag);
#endif
    
    switch (item.tag) {
        case 0:
        {
#ifdef DEBUG
            NSLog(@"TabBar - Aips Database");
#endif
            if (mUsedDatabase==DB_TYPE_FAVORITES || mSearchInteractions==true) {
                mUsedDatabase = DB_TYPE_AIPS;
                mSearchInteractions = false;
                mCurrentIndexPath = nil;
                [self stopActivityIndicator];
                [self clearDataInTableView];
                // Show keyboard
                [searchField becomeFirstResponder];
                // Reset search field
                [self resetBarButtonItems];
            }
            else {
                // Empty search field
                [searchField setText:@""];
                // 
                MLViewController* __weak weakSelf = self;
                //
                dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
                dispatch_async(search_queue, ^(void) {
                    MLViewController* scopeSelf = weakSelf;
                    if (!inProgress) {
                        inProgress = true;
                        mCurrentSearchState = SEARCH_TITLE;
                        // @synchronized(searchResults) {
                        searchResults = [scopeSelf searchDatabaseWith:@""];
                        // Update tableview
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [scopeSelf updateTableView];
                            [myTableView reloadData];
                            [searchField resignFirstResponder];
                            [myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms", (unsigned long)[searchResults count], NSLocalizedString(@"Hit",nil), timeForSearch_ms]];
                            inProgress = false;
                        });
                        //}
                    }
                });
            }
            break;
        }

        case 1:
        {
#ifdef DEBUG
            NSLog(@"TabBar - Favorite Database");
#endif
            mUsedDatabase = DB_TYPE_FAVORITES;
            mSearchInteractions = false;
            mCurrentIndexPath = nil;
            // Reset searchfield
            [self resetBarButtonItems];
            //
            MLViewController* __weak weakSelf = self;
            //
            // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
            dispatch_async(search_queue, ^(void) {
                MLViewController* scopeSelf = weakSelf;
                if (!inProgress) {
                    inProgress = true;
                    mCurrentSearchState = SEARCH_TITLE;
                    // @synchronized(searchResults) {
                    searchResults = [scopeSelf retrieveAllFavorites];
                    // Update tableview
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [scopeSelf updateTableView];
                        [myTableView reloadData];
                        // [searchField resignFirstResponder];
                        [myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms", (unsigned long)[searchResults count], NSLocalizedString(@"Hit",nil), timeForSearch_ms]];
                        inProgress = false;
                    });
                    //}
                }
            });
            break;
        }

        case 2:
#ifdef DEBUG
            NSLog(@"TabBar - Interactions");
#endif
            mUsedDatabase = DB_TYPE_AIPS;
            mSearchInteractions = true;
            [self stopActivityIndicator];
            [self setBarButtonItemsWith:SEARCH_TITLE];
            // Switch view
            [self switchToDrugInteractionView];
            break;

        case 3:
#ifdef DEBUG
            NSLog(@"TabBar - Prescription");
#endif
            mUsedDatabase = DB_TYPE_AIPS; // tabbar in rear view selects AIPS
            //mUsedDatabase = kPrescription;
            mSearchInteractions = false;
            {
                MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
                appDel.editMode = EDIT_MODE_PRESCRIPTION;
            }
            [self stopActivityIndicator];
            [self switchToPrescriptionView];
            break;

        case 4:
            NSLog(@"TabBar - Developer Info");
            // TODO
            break;

        default:
            break;
    }
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self executeSearch:searchText];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) searchDisplayControllerWillBeginSearch:(UISearchController *)controller
{
    controller.searchBar.showsCancelButton = YES;
    // self.searchDisplayController.searchBar.showsCancelButton = YES;
}

- (void) executeSearch:(NSString *)searchText
{
    static volatile bool inProgress = false;
    
    int minSearchChars = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        minSearchChars = 0;

    if (mCurrentSearchState == SEARCH_THERAPY)
        minSearchChars = 1;
    
    // Causes searchResults to be released if there are no strong references to it.
    searchResults = [NSArray array];
    
    MLViewController* __weak weakSelf = self;
    
    [self startActivityIndicator];
    
    // Introduces a delay before starting new thread
    /*
     double delayInSeconds = 0.1;
     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
     */
    // Creates a serial dispatch queue (tasks are completed in FIFO order)
    // dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
    // dispatch_after(popTime, mSearchQueue, ^(void){
    dispatch_async(mSearchQueue, ^(void) {
        MLViewController* scopeSelf = weakSelf;
        while (inProgress) {
            [NSThread sleepForTimeInterval:0.01];   // Wait 10ms
        }

        if (!inProgress) {
            @synchronized(self) {
                inProgress = true;
            }
            if ([searchText length] > minSearchChars) {
                self->searchResults = [scopeSelf searchDatabaseWith:searchText];
            }
            else {
                if (mUsedDatabase == DB_TYPE_FAVORITES) {
                    self->searchResults = [weakSelf retrieveAllFavorites];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (mUsedDatabase == DB_TYPE_FAVORITES &&
                    [searchText length] <= minSearchChars)
                {
                    [self->searchField resignFirstResponder];
                }

                [scopeSelf updateTableView];
                [self->myTableView reloadData];
                [self->myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms",
                                            (unsigned long)[self->searchResults count],
                                            NSLocalizedString(@"Hit", nil),
                                            self->timeForSearch_ms]];
                @synchronized(self) {
                    inProgress = false;
                }
            });
        }
    });
}

- (void) addTitle: (NSString *)title
      andPackInfo: (NSString *)packinfo
         andMedId: (long)medId
{
    DataObject *m = [DataObject new];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified];// @"k.A."

    if (![packinfo isEqual:[NSNull null]]) {
        if ([packinfo length]>0)
            m.subTitle = packinfo;
        else
            m.subTitle = [MLConstants notSpecified];// @"k.A."
    }
    else
        m.subTitle = [MLConstants notSpecified];// @"k.A."

    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title
        andAuthor:(NSString *)author
         andMedId:(long)medId
{
    DataObject *m = [DataObject new];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified];// @"k.A.";
    if (![author isEqual:[NSNull null]]) {
        if ([author length]>0)
            m.subTitle = author;
        else
            m.subTitle = [MLConstants notSpecified];// @"k.A.";
    } else
        m.subTitle = [MLConstants notSpecified];// @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title
       andAtcCode:(NSString *)atccode
      andAtcClass:(NSString *)atcclass
         andMedId:(long)medId
{
    DataObject *m = [DataObject new];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified];// @"k.A.";
    
    if ([atccode isEqual:[NSNull null]])
        atccode = [MLConstants notSpecified];
    if ([atcclass isEqual:[NSNull null]])
        atcclass = [MLConstants notSpecified];
    
    NSArray *m_atc = [atccode componentsSeparatedByString:@";"];
    NSArray *m_class = [atcclass componentsSeparatedByString:@";"];
    NSMutableString *m_atccode_str = nil;
    NSMutableString *m_atcclass_str = nil;
    if ([m_atc count] > 1) {
        if (![[m_atc objectAtIndex:0] isEqual:nil])
            m_atccode_str = [NSMutableString stringWithString:[m_atc objectAtIndex:0]];
        if (![[m_atc objectAtIndex:1] isEqual:nil])
            m_atcclass_str = [NSMutableString stringWithString:[m_atc objectAtIndex:1]];
    }
    if ([m_atccode_str isEqual:[NSNull null]])
        [m_atccode_str setString:[MLConstants notSpecified]];
    if ([m_atcclass_str isEqual:[NSNull null]])
        [m_atcclass_str setString:[MLConstants notSpecified]];
    
    NSMutableString *m_atcclass = nil;
    if ([m_class count] == 2) {  // *** Ver.<1.2
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:1]];
        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:[MLConstants notSpecified]];
        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@", m_atccode_str, m_atcclass_str, m_atcclass];
    } else if ([m_class count] == 3) {  // *** Ver.>=1.2
        NSArray *m_atc_class_l4_and_l5 = [m_class[2] componentsSeparatedByString:@"#"];
        int n = (int)[m_atc_class_l4_and_l5 count];
        if (n>1)
            m_atcclass = [NSMutableString stringWithString:[m_atc_class_l4_and_l5 objectAtIndex:n-2]];
        if ([m_atcclass isEqual:[NSNull null]])
            [m_atcclass setString:[MLConstants notSpecified]];
        m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@\n%@", m_atccode_str, m_atcclass_str, m_atcclass, m_class[1]];
    }
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title
        andRegnrs:(NSString *)regnrs
        andAuthor:(NSString *)author
         andMedId:(long)medId
{
    DataObject *m = [DataObject new];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified]; // @"k.A.";
    
    NSMutableString *m_regnrs = [NSMutableString stringWithString:regnrs];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_regnrs isEqual:[NSNull null]])
        [m_regnrs setString:[MLConstants notSpecified]];
    
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:[MLConstants notSpecified]];
    
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_regnrs, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addSubstances:(NSString *)substances andTitle:(NSString *)title andAuthor:(NSString *)author andMedId:(long)medId
{
    DataObject *m = [DataObject new];
    
    if (![substances isEqual:[NSNull null]]) {
        // Unicode for character 'alpha' = &#593;
        substances = [substances stringByReplacingOccurrencesOfString:@"&alpha;" withString:@"ɑ"];
        m.title = substances;
    }
    else
        m.title = [MLConstants notSpecified]; // @"k.A.";
    
    NSMutableString *m_title = [NSMutableString stringWithString:title];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_title isEqual:[NSNull null]])
        [m_title setString:[MLConstants notSpecified]];
    
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:[MLConstants notSpecified]];
    
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_title, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title
  andApplications:(NSString *)applications
         andMedId:(long)medId
{
    DataObject *m = [DataObject new];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified]; // @"k.A.";
    NSArray *m_applications = [applications componentsSeparatedByString:@";"];
    NSMutableString *m_swissmedic = nil;
    NSMutableString *m_bag = nil;
    if ([m_applications count]>0) {
        if (![[m_applications objectAtIndex:0] isEqual:nil])
            m_swissmedic = [NSMutableString stringWithString:[m_applications objectAtIndex:0]];
        if ([m_applications count]>1) {
            if (![[m_applications objectAtIndex:1] isEqual:nil])
                m_bag = [NSMutableString stringWithString:[m_applications objectAtIndex:1]];
        }
    }
    if ([m_swissmedic isEqual:[NSNull null]])
        [m_swissmedic setString:[MLConstants notSpecified]];
    if ([m_bag isEqual:[NSNull null]])
        [m_bag setString:[MLConstants notSpecified]];
    m.subTitle = [NSString stringWithFormat:@"%@\n%@", m_swissmedic, m_bag];
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addKeyword: (NSString *)keyword
         andNumHits: (unsigned long)numHits
            andHash: (NSString *)hash
{
    DataObject *m = [DataObject new];
    
    if (![keyword isEqual:[NSNull null]])
        m.title = keyword;
    else
        m.title = NSLocalizedString(@"Not specified", nil);
    
    m.subTitle = [NSString stringWithFormat:@"%ld Treffer", numHits];  // TODO: localize
    m.hashId = hash;
    
    [medi addObject:m];
}

- (void) updateTableView
{
#ifdef DEBUG
    NSLog(@"%s line %d, mCurrentSearchState: %ld", __FUNCTION__, __LINE__, (long)mCurrentSearchState);
#endif
    if (!searchResults) {
        [self stopActivityIndicator];
        return;
    }
    
    if (medi != nil)
        [medi removeAllObjects];
    
    if (favoriteKeyData != nil)
        [favoriteKeyData removeAllObjects];
    
    switch (mCurrentSearchState) {
        case SEARCH_TITLE:
            if (mUsedDatabase == DB_TYPE_AIPS) {
                for (MLMedication *m in searchResults) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title
                           andPackInfo:m.packInfo
                              andMedId:m.medId];
                    }
                }
            }
            else if (mUsedDatabase == DB_TYPE_FAVORITES) {
                for (MLMedication *m in searchResults) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title
                               andPackInfo:m.packInfo
                                  andMedId:m.medId];
                        }
                    }
                }
            }
            break;
            
        case SEARCH_AUTHOR:
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == DB_TYPE_AIPS) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title
                             andAuthor:m.auth
                              andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == DB_TYPE_FAVORITES) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title
                                 andAuthor:m.auth
                                  andMedId:m.medId];
                        }
                    }
                }
            }
            break;
            
        case SEARCH_ATC_CODE:
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == DB_TYPE_AIPS) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title
                            andAtcCode:m.atccode
                           andAtcClass:m.atcClass
                              andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == DB_TYPE_FAVORITES) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title
                                andAtcCode:m.atccode
                               andAtcClass:m.atcClass
                                  andMedId:m.medId];
                        }
                    }
                }
            }
            break;
            
        case SEARCH_REG_NR:
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == DB_TYPE_AIPS) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title
                             andRegnrs:m.regnrs
                             andAuthor:m.auth
                              andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == DB_TYPE_FAVORITES) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title
                                 andRegnrs:m.regnrs
                                 andAuthor:m.auth
                                  andMedId:m.medId];
                        }
                    }
                }
            }
            break;
            
        case SEARCH_THERAPY:
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == DB_TYPE_AIPS) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];
                        [self addTitle:m.title
                       andApplications:m.application
                              andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == DB_TYPE_FAVORITES) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addTitle:m.title
                           andApplications:m.application
                                  andMedId:m.medId];
                        }
                    }
                }
            }
            break;
            
        case SEARCH_FULL_TEXT:
#ifdef DEBUG
            NSLog(@"%s line %d, SEARCH_FULL_TEXT", __FUNCTION__, __LINE__);
#endif
            for (FullTextEntry *e in searchResults) {
                if (mUsedDatabase == DB_TYPE_FULL_TEXT)
                {
                    if (![e.hash isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:e.hash];
                        [self addKeyword:e.keyword
                              andNumHits:e.numHits
                                 andHash:e.hash];
                    }
                }
            }
            break;
    }

    // Sort array alphabetically
    if (mUsedDatabase == DB_TYPE_FAVORITES) {
        /*
        NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:
                                       ^(id obj1, id obj2) { return [obj1 compare:obj2 options:NSNumericSearch]; }];
        */

        NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [medi sortUsingDescriptors:[NSArray arrayWithObject:titleSort]];
    }
    
    [self stopActivityIndicator];
}

/** Dismisses the keyboard, resigns text field's active state
 */
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
#ifdef DEBUG
    NSLog(@"You entered %@", self.myTextField.text);
#endif
    [myTextField resignFirstResponder];
    
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
#ifdef DEBUG
    NSLog(@"Number of characters = %ld", (unsigned long)[myTextField.text length]);
#endif
    return YES;
}

#pragma mark -

- (void) switchToAipsView :(long int)mId
{
#ifdef DEBUG
    NSLog(@"%s, mId: %ld", __FUNCTION__, mId);
#endif
    if (secondViewController != nil) {
        // [secondViewController removeFromParentViewController];
        secondViewController = nil;
    }
    
    secondViewController =
    [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController"
                                             bundle:nil
                                              title:NSLocalizedString(@"Prescription Info", nil)//FACHINFO_STRING
                                           andParam:2];
    
    if (!mSearchInteractions) {
        {
            // Load style sheet from file
            NSString *amiko_Style;
            {
                NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
                NSString *amikoCss;
                if (amikoCssPath)
                    amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
                else
                    amikoCss = [NSString stringWithString:mMed.styleStr];
                
                amiko_Style = [NSString stringWithFormat:@"<style type=\"text/css\">%@</style>", amikoCss];
            }
            
            if (mCurrentSearchState == SEARCH_FULL_TEXT) {

                NSString *color_Style =
                    [NSString stringWithFormat:@"<style type=\"text/css\">%@</style>", [MLUtility getColorCss]];
                
                // Load JavaScript from file
                NSString *js_Script;
                {
                NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"main_callbacks" ofType:@"js"];
                NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:nil];
                js_Script = [NSString stringWithFormat:@"<script type=\"text/javascript\">%@</script>", jscriptStr];
                }

                NSString *headHtml = [NSString stringWithFormat:@"<head>%@\n%@\n%@\n</head>",
                                      js_Script,
                                      color_Style,
                                      amiko_Style];
#ifdef DEBUG
                NSLog(@"%s line %d, mMed.contentStr:\n\n%@", __FUNCTION__, __LINE__,
                      [mMed.contentStr substringToIndex:MIN(500,[mMed.contentStr length])]);
#endif

                secondViewController.htmlStr =
                [mMed.contentStr stringByReplacingOccurrencesOfString:@"<head></head>"
                                                           withString:headHtml];
//                secondViewController.htmlStr =
//                    [NSString stringWithFormat:@"<head>%@<style>%@</style></head>%@",
//                     jscriptHtml,
//                     amikoCss,
//                     mMed.contentStr];

                NSString *keyword = [mFullTextEntry keyword];
                if (keyword) {
#ifdef DEBUG
                    NSLog(@"%s line %d, keyword: %@", __FUNCTION__, __LINE__, keyword);
#endif
                    
//#ifdef DEBUG
//                    NSUInteger length = [secondViewController.htmlStr length];
//
//                    NSLog(@"%s line %d, htmlStr head :\n\n%@", __FUNCTION__, __LINE__,
//                          [secondViewController.htmlStr substringToIndex:MIN(500,length)]);
//
//                    NSLog(@"%s line %d, htmlStr tail :\n\n%@", __FUNCTION__, __LINE__,
//                          [secondViewController.htmlStr substringFromIndex:length - MIN(200,length)]);
//#endif
                    //secondViewController.anchor = fullTextMessage[@"Anchor"];
                    
                    //[secondViewController.searchField setText:keyword]; // NG: it will be reset when view appears
                    secondViewController.keyword = keyword;
                }
            }
            else {
                secondViewController.htmlStr =
                    [NSString stringWithFormat:@"<head>%@</head>%@",
                     amiko_Style,
                     mMed.contentStr];
                //secondViewController.anchor = @"";
            }
        }

        {
            NSArray *listofSectionIds = @[[MLConstants notSpecified]];
            NSArray *listofSectionTitles = @[[MLConstants notSpecified]];
            // Extract section ids
            if (![mMed.sectionIds isEqual:[NSNull null]]) {
                listofSectionIds = [mMed.sectionIds componentsSeparatedByString:@","];
            }
            // Extract section titles
            if (![mMed.sectionTitles isEqual:[NSNull null]]) {
                listofSectionTitles = [mMed.sectionTitles componentsSeparatedByString:@";"];
            }
            
            if (titleViewController!=nil) {
                [titleViewController removeFromParentViewController];
                titleViewController = nil;
            }
            titleViewController = [[MLTitleViewController alloc] initWithMenu:listofSectionTitles
                                                                   sectionIds:listofSectionIds
                                                                  andLanguage:[MLConstants databaseLanguage]];
        }
    }
    else {
        if (mId > -1) {
            [self pushToMedBasket];
            
            // Extract section ids
            NSArray *listofSectionIds = [NSArray array];
            // Extract section titles
            NSArray *listofSectionTitles = [NSArray array];
            
            if (titleViewController!=nil) {
                [titleViewController removeFromParentViewController];
                titleViewController = nil;
            }
            titleViewController = [[MLTitleViewController alloc] initWithMenu:listofSectionTitles
                                                                   sectionIds:listofSectionIds
                                                                  andLanguage:[MLConstants databaseLanguage]];
            
            // Update medication basket
            secondViewController.dbAdapter = mDb;
            secondViewController.titleViewController = titleViewController;
        }
        
        secondViewController.medBasket = mMedBasket;
        secondViewController.htmlStr = @"Interactions";
    }
    
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    mainRevealController = self.revealViewController;
    mainRevealController.rightViewController = titleViewController;
    
    // Class MLSecondViewController is now registered as an observer
    // so that when the string 'javaScript' is modified, the observer will execute the script
    [titleViewController addObserver:secondViewController
                          forKeyPath:@"javaScript"
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:@"javaScriptChanged"];
    
    // UINavigationController *otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondView];
    
    if (otherViewNavigationController!=nil) {
        [otherViewNavigationController removeFromParentViewController];
        otherViewNavigationController = nil;
    }
    otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
    
    // Show SecondViewController (UIWebView)
    [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
    
#ifdef DEBUG
    report_memory();
#endif
}

- (void) switchToDrugInteractionViewFromPrescription: (NSMutableDictionary *)medBasket
{
    mainRevealController = self.revealViewController;

    mShowReport = false;
    
    [mMedBasket removeAllObjects];
    mMedBasket = medBasket; // Save the basket so we can keep adding medicines to the interactions later on

    mSearchInteractions = true;
    
    // Right
#if 1
    // Extract section ids
    NSArray *listofSectionIds = [NSArray array];
    // Extract section titles
    NSArray *listofSectionTitles = [NSArray array];
    
    if (titleViewController!=nil) {
        [titleViewController removeFromParentViewController];
        titleViewController = nil;
    }
    titleViewController = [[MLTitleViewController alloc] initWithMenu:listofSectionTitles
                                                           sectionIds:listofSectionIds
                                                          andLanguage:[MLConstants databaseLanguage]];

    mainRevealController.rightViewController = titleViewController;
#endif
    
    // Front
#if 1
    if (secondViewController!=nil) {
        // [secondViewController removeFromParentViewController];
        secondViewController = nil;
    }
    
    secondViewController =
    [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController"
                                             bundle:nil
                                              title:NSLocalizedString(@"Prescription Info", nil)//FACHINFO_STRING
                                           andParam:2];
    
    // Update medication basket
    secondViewController.dbAdapter = mDb;
    secondViewController.titleViewController = titleViewController;
    
    secondViewController.medBasket = medBasket;
    secondViewController.htmlStr = @"Interactions";
    
    if (otherViewNavigationController!=nil) {
        [otherViewNavigationController removeFromParentViewController];
        otherViewNavigationController = nil;
    }
    otherViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:secondViewController];

    [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];
#endif
    
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
    
    // Class MLSecondViewController is now registered as an observer
    // so that when the string 'javaScript' is modified, the observer will execute the script
    [titleViewController addObserver:secondViewController
                          forKeyPath:@"javaScript"
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:@"javaScriptChanged"];
#ifdef DEBUG
    report_memory();
#endif
}

- (void) switchToDrugInteractionView
{
    // if (mCurrentIndexPath)
    [self tableView:myTableView didSelectRowAtIndexPath:mCurrentIndexPath];
}

- (void) switchToPrescriptionView
{
    mainRevealController = self.revealViewController;

    // Right
    if (amkListViewController!=nil) {
        [amkListViewController removeFromParentViewController];
        amkListViewController = nil;
    }
    
    amkListViewController = [[AmkListViewController alloc] initWithNibName:@"AmkListViewController"
                                                                      bundle:nil];
    [mainRevealController setRightViewController:amkListViewController];

    // Front
    PrescriptionViewController *prescriptionViewController = [PrescriptionViewController sharedInstance];
    
    if (otherViewNavigationController!=nil) {
        [otherViewNavigationController removeFromParentViewController];
        otherViewNavigationController = nil;
    }
    otherViewNavigationController =
        [[UINavigationController alloc] initWithRootViewController:prescriptionViewController];
    [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];

    //
    mainRevealController.rightViewRevealOverdraw = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        mainRevealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;

    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
}

- (void)switchFrontToPatientEditView
{
    mainRevealController = self.revealViewController;
    
    PatientViewController *patientListViewController = [PatientViewController sharedInstance];

    otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:patientListViewController];

    [mainRevealController setFrontViewController:otherViewNavigationController];
}

// Front: Patient Edit, Right: Contacts
- (void) switchToPatientEditView :(BOOL)animated
{
    mainRevealController = self.revealViewController;

    // Right
    ContactsListViewController *contactsListViewController =
    [[ContactsListViewController alloc] initWithNibName:@"ContactsListViewController"
                                                   bundle:nil];
    [mainRevealController setRightViewController:contactsListViewController];

    // Front
    PatientViewController *patientEditViewController = [PatientViewController sharedInstance];
    otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:patientEditViewController];
    [mainRevealController setFrontViewController:otherViewNavigationController
                                        animated:animated];

    //
    //mainRevealController.bounceBackOnOverdraw = NO;
    mainRevealController.rightViewRevealOverdraw = 0;
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft  // Center
                                      animated:animated];
}

// Front: Doctor Edit, Right: nil
- (void) switchToDoctorEditView
{
    mainRevealController = self.revealViewController;
    
    // Right
    mainRevealController.rightViewController = nil;

    // Front
    DoctorViewController *doctorEditViewController = [DoctorViewController sharedInstance];
    otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:doctorEditViewController];
    [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];
    
    //
    mainRevealController.rightViewRevealOverdraw = 0;
    //mainRevealController.bounceBackOnOverdraw = YES;
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
}

// Front: FullText, Right: FullTextResultsOverview
- (void) switchToFullTextView :(NSString *)hashId
{
    /* Search in full text search DB
     */
    
    if (![mFullTextSearch.listOfSectionIds isEqual:[NSNull null]])
        mListOfSectionIds = mFullTextSearch.listOfSectionIds;

    if (![mFullTextSearch.listOfSectionTitles isEqual:[NSNull null]])
        mListOfSectionTitles = mFullTextSearch.listOfSectionTitles;
    
    // Get entry
    mFullTextEntry = [mFullTextDb searchHash:hashId];
    
    NSArray *listOfRegnrs = [mFullTextEntry getRegnrsAsArray];
    NSArray *listOfArticles = [mDb searchRegnrsFromList:listOfRegnrs];
    NSDictionary *dict = [mFullTextEntry getRegChaptersDict];
    
    mFullTextContentStr = [mFullTextSearch tableWithArticles:listOfArticles
                                          andRegChaptersDict:dict
                                                   andFilter:@""];

    // Grab a handle to the reveal controller
    mainRevealController = self.revealViewController;

    // Front
    {
        FullTextViewController *fullTextVC = [FullTextViewController sharedInstance];
        [fullTextVC updateFullTextSearchView: mFullTextContentStr];

        if (otherViewNavigationController!=nil) {
            [otherViewNavigationController removeFromParentViewController];
            otherViewNavigationController = nil;
        }
        otherViewNavigationController = [[UINavigationController alloc] initWithRootViewController:fullTextVC];

        // Show FullTextViewController (WKWebView)
        [mainRevealController setFrontViewController:otherViewNavigationController animated:YES];
    }

    // Right
    {
        FullTextOverviewVC *fullTextOverviewVC = [FullTextOverviewVC sharedInstance];
        fullTextOverviewVC.ftResults = mFullTextSearch.listOfSectionTitles;
        mainRevealController.rightViewController = fullTextOverviewVC;
    }

    mainRevealController.rightViewRevealOverdraw = 0;
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
    
#ifdef DEBUG
    report_memory();
#endif
}

- (void) switchToAipsViewFromFulltext: (NSDictionary *)message
{
#ifdef DEBUG
    NSLog(@"%s, message: %@", __FUNCTION__, message);
//    NSString *ean = message[@"EanCode"];
//    NSString *anchor = message[@"Anchor"];
#endif

    mMed = [mDb getMediWithRegnr:message[@"EanCode"]];

    fullTextMessage = message;
    mSearchInteractions = false;
    [self switchToAipsView:-1];
}

/**
 Add med in the buffer to the interaction basket
 */
- (void) pushToMedBasket
{
    if (mMed) {
        NSString *title = [mMed title];
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([title length]>30) {
            title = [title substringToIndex:30];
            title = [title stringByAppendingString:@"..."];
        }
        
        // Add med to medication basket
        [mMedBasket setObject:mMed forKey:title];
    }
}

#pragma mark - UITableViewDataSource

/** UITableViewDataSource
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
#ifdef DEBUG
    NSLog(@"%s %d, mUsedDatabase: %ld, mCurrentSearchState: %ld", __FUNCTION__, __LINE__,
          (long)mUsedDatabase, mCurrentSearchState);
#endif

    if (mUsedDatabase == DB_TYPE_AIPS) {
        return [medi count];
        // return [titleData count];
    }
    
    if (mUsedDatabase == DB_TYPE_FAVORITES)
        return [favoriteKeyData count];
    
    if (mUsedDatabase == DB_TYPE_FULL_TEXT)
        return [searchResults count];

    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    // What to display in row n?
    // static NSString *simpleTableIdentifier = @"SimpleTableItem";
    // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    static NSString *simpleTableIdentifier = @"MLSimpleCell";
    MLSimpleTableCell *cell = (MLSimpleTableCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
   
    if (cell == nil) {
        cell = [[MLSimpleTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                        reuseIdentifier:simpleTableIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    // Check if cell.textLabel.text is in starred NSSet    
    NSString *regnrStr = favoriteKeyData[indexPath.row];//[favoriteKeyData objectAtIndex:indexPath.row];
    
    if ([favoriteMedsSet containsObject:regnrStr])
        cell.imageView.image = [UIImage imageNamed:@"28-star-ye.png"];
    else
        cell.imageView.image = [UIImage imageNamed:@"28-star-gy.png"];
    
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.row;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(myTapMethod:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];

    [cell.imageView addGestureRecognizer:tap];
  
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
    }
    
    // cell.textLabel.text = [titleData objectAtIndex:indexPath.row];
    cell.textLabel.text = [medi[indexPath.row] title];
    cell.textLabel.numberOfLines = 0; // there's no maximum
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    // cell.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // cell.detailTextLabel.text = [subTitleData objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [medi[indexPath.row] subTitle];
    cell.detailTextLabel.numberOfLines = 0; // 0: there's no maximum
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    // cell.detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // cell.detailTextLabel.textColor = [UIColor grayColor];
    // [cell.detailTextLabel sizeToFit];
    
    // Set colors
    if ([cell.detailTextLabel.text rangeOfString:@", O]"].location == NSNotFound) {
        if ([cell.detailTextLabel.text rangeOfString:@", G]"].location == NSNotFound) {
            cell.detailTextLabel.textColor = [UIColor grayColor];   // Default color
        } else {
            cell.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.2 alpha:1.0];   // Generika
        }
    } else {
        cell.detailTextLabel.textColor = [UIColor redColor];    // Original
    }
    
    return cell;
}

#pragma mark -

- (void) myTapMethod:(id)sender
{
    if (mNumCurrSearchResults>500)
        [self startActivityIndicator];
    
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    NSString *medRegnrs = [NSString stringWithString:[favoriteKeyData objectAtIndex:gesture.view.tag]];
    
    if ([favoriteMedsSet containsObject:medRegnrs])
        [favoriteMedsSet removeObject:medRegnrs];
    else
        [favoriteMedsSet addObject:medRegnrs];
    
    favoriteData = [MLDataStore initWithFavMedsSet:favoriteMedsSet];
    [self saveData];
    
    [self performSelector:@selector(starCellItemWithIndex:) withObject:gesture afterDelay:0.01];
}

- (void) starCellItemWithIndex:(UITapGestureRecognizer *)gesture
{
    // Update TableView --> slow implementation?
    /*
     NSIndexPath *indexPath = [NSIndexPath indexPathForItem:gesture.view.tag inSection:0];
     NSArray *indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
     [myTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationMiddle];// UITableViewRowAnimationNone];
     
     [myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
     */
    
    static bool inProgress = false;
    
    MLViewController* __weak weakSelf = self;
    
    dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.starCellItem", nil);
    dispatch_async(search_queue, ^(void) {
        MLViewController* scopeSelf = weakSelf;
        if (!inProgress) {
            inProgress = true;
            // Update tableview
            dispatch_async(dispatch_get_main_queue(), ^{
                [myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:gesture.view.tag inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationMiddle];
                inProgress = false;
                if (mNumCurrSearchResults>500)
                    [scopeSelf stopActivityIndicator];
            });
        }
    });
}

#pragma mark - UITableViewDelegate

// We selected one Medicine or one Favorite
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"%@ Selected medicine or favourite at row %ld", NSStringFromSelector(_cmd), [indexPath row]);
#endif
    mCurrentIndexPath = indexPath;
    
    if (mCurrentSearchState != SEARCH_FULL_TEXT) {
        /* Search in Aips DB or Interactions DB
         */
        long int mId = -1;

        if (mCurrentIndexPath) {
            mId = [medi[indexPath.row] medId];  // [[medIdArray objectAtIndex:row] longValue];
            mMed = [mDb searchId:mId];
        }
        
        if (!mShowReport) {
            [self invalidateObserver];
        }
        
        mShowReport = false;
        [self switchToAipsView:mId];
    }
    else {
        /* Search in full text search DB
         */
        NSString *hashId = [medi[indexPath.row] hashId];
        [self switchToFullTextView: hashId];
    }
}

#define PADDING_IPAD 50.0f
#define PADDING_IPHONE 40.0f
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = [medi[indexPath.row] title]; // [titleData objectAtIndex:indexPath.row];
    NSString *subText = [medi[indexPath.row] subTitle]; // [subTitleData objectAtIndex:indexPath.row];
    CGRect textRect, subTextRect;
    CGFloat retVal = 0;
    
    float frameWidth = self.myTableView.frame.size.width;
    
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            textRect = [text boundingRectWithSize:CGSizeMake(frameWidth - PADDING_IPAD, CGFLOAT_MAX)
                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                       attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0]}
                                          context:nil];
            subTextRect = [subText boundingRectWithSize:CGSizeMake(frameWidth - 1.6*PADDING_IPAD, CGFLOAT_MAX)
                                                options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                             attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:14.0]}
                                                context:nil];
            retVal = textRect.size.height + subTextRect.size.height + PADDING_IPAD * 0.25;
        }
        else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            textRect = [text boundingRectWithSize:CGSizeMake(frameWidth - 2.0*PADDING_IPHONE, CGFLOAT_MAX)
                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                       attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:13.0]}
                                          context:nil];
            subTextRect = [subText boundingRectWithSize:CGSizeMake(frameWidth - 1.8*PADDING_IPHONE, CGFLOAT_MAX)
                                                options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                             attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:12]}
                                                context:nil];
            retVal = textRect.size.height + subTextRect.size.height + PADDING_IPHONE * 0.3;
        }
    }

    return retVal;
}

- (CGSize) tableText:(NSString*)text sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size
{
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    
    CGRect frame = [text boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                   attributes:attributesDictionary
                                      context:nil];
    return frame.size;
}

#pragma mark -

- (void) addMedicineToPrescription:(MLMedication *)medication :(NSInteger)packageIndex
{
    //NSLog(@"Line %d, %@", __LINE__, mMed); // MLMedication
    Product *product = [[Product alloc] initWithMedication:mMed :packageIndex];
    //NSLog(@"%@", med);
    
    [[PrescriptionViewController sharedInstance] addMedication:product];
}

#pragma mark - UIGestureRecognizerDelegate

- (void) myLongPressMethod:(UILongPressGestureRecognizer *)gesture
{
#ifdef DEBUG
    //NSLog(@"%s mCurrentSearchState:%ld", __FUNCTION__, mCurrentSearchState);
#endif
    CGPoint p = [gesture locationInView:self.myTableView];
    NSIndexPath *indexPath = [self.myTableView indexPathForRowAtPoint:p];
    
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
        return;
    }
    
    if (gesture.state != UIGestureRecognizerStateBegan) {
#ifdef DEBUG
        //NSLog(@"gestureRecognizer.state = %ld", gesture.state);
#endif
        return;
    }
    
    NSLog(@"long press began on table view at row %ld", indexPath.row);

    switch (mCurrentSearchState) {
        case SEARCH_TITLE:    // Can only add medicine from Prep like in AmiKo OSX
        {
            NSString *subTitle = [medi[indexPath.row] subTitle];
            _pickerData = [subTitle componentsSeparatedByString:@"\n"];
#ifdef DEBUG
            DataObject *m = medi[indexPath.row];
            NSLog(@"%@", m);
            //NSLog(@"listOfPackages: <%@>", _pickerData);
            //NSLog(@"%ld packages", [_pickerData count]);
#endif

            //mCurrentIndexPath = indexPath;  // for drug interaction view
            long mId = [medi[indexPath.row] medId];
            mMed = [mDb searchId:mId];  // MLMedication
            NSLog(@"%@", mMed);

#if 1
            if ([_pickerData count] < 1) {
                NSLog(@"No packages to select from");
            }
            else if ([_pickerData count] == 1) {
                NSLog(@"Selected package <%@>", _pickerData[0]);
                [self addMedicineToPrescription:mMed :0];
            }
            else {
                self.pickerSheet = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select package", nil)
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
                self.pickerView = [[UIPickerView alloc]initWithFrame:CGRectZero];
                self.pickerView.dataSource = self;
                self.pickerView.delegate = self;
                self.pickerView.showsSelectionIndicator = YES;
                [self.pickerView selectRow:1 inComponent:0 animated:YES];
                [self.pickerSheet.view addSubview:self.pickerView];
                self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;
                UIView *view = self.pickerView;
                [self.pickerSheet.view addConstraints:[NSLayoutConstraint
                                                       constraintsWithVisualFormat:@"V:|[view]|"
                                                       options:0l
                                                       metrics:nil
                                                       views:NSDictionaryOfVariableBindings(view)]];
                
                [self.pickerSheet.view addConstraints:[NSLayoutConstraint
                                                       constraintsWithVisualFormat:@"H:|[view]|"
                                                       options:0l
                                                       metrics:nil
                                                       views:NSDictionaryOfVariableBindings(view)]];
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    UITableViewCell *cell = [myTableView cellForRowAtIndexPath:indexPath];
                    self.pickerSheet.popoverPresentationController.sourceView = cell.contentView;
                    self.pickerSheet.popoverPresentationController.sourceRect = cell.contentView.bounds;
                    self.pickerSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
                }
                
                [self presentViewController:self.pickerSheet animated:YES completion:^{
                }];
            }
#endif
        }
            break;
            
        case SEARCH_ATC_CODE:
        {
            NSString *subTitle = [medi[indexPath.row] subTitle];
            NSString *medSubTitle = [NSString stringWithString:subTitle];
            NSArray *mAtc = [medSubTitle componentsSeparatedByString:@" -"];
            if (mAtc[0]!=nil && ![[searchField text] isEqualToString:mAtc[0]]) {
                [searchField setText:mAtc[0]];
                [self executeSearch:mAtc[0]];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIPickerViewDelegate
#pragma mark - UIPickerViewDataSource

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _pickerData.count;
}

#ifdef CUSTOM_FONT_SIZE_PICKER
- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *)view;
    
    // Reuse the label if possible, otherwise create and configure a new one
    if ((pickerLabel == nil) || ([pickerLabel class] != [UILabel class])) { //newlabel
        CGRect frame = CGRectMake(0.0, 0.0, 270, 32.0);
        pickerLabel = [[UILabel alloc] initWithFrame:frame];
        pickerLabel.textAlignment = NSTextAlignmentLeft;
        pickerLabel.backgroundColor = [UIColor clearColor];
        pickerLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    //pickerLabel.textColor = [UIColor brownColor];
    pickerLabel.text = _pickerData[row];
    //[pickerLabel sizeToFit];
    return pickerLabel;
}
#else
- (NSString*)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component
{
    return _pickerData[row];
}
#endif

// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)pickerRow
       inComponent:(NSInteger)component
{
#ifdef DEBUG
    NSLog(@"%s, picker row:%ld", __FUNCTION__, pickerRow);
    NSLog(@"Selected package <%@>", _pickerData[pickerRow]);
    //NSLog(@"%ld medicines in table view", [medi count]);
#endif

    [self.pickerSheet dismissViewControllerAnimated:YES completion:^{
    }];
    
    [self addMedicineToPrescription:mMed :pickerRow];
}

#pragma mark - helper functions

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

void report_memory(void)
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}
@end
