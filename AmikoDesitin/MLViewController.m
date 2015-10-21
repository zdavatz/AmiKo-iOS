/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
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

#import "MLViewController.h"

#import "MLConstants.h"

#import "MLSecondViewController.h"
#import "MLTitleViewController.h"
#import "MLMenuViewController.h"

#import "MLAlertView.h"
#import "MLDBAdapter.h"
#import "MLMedication.h"
#import "MLSimpleTableCell.h"
#import "MLDataStore.h"

#import "SWRevealViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <mach/mach.h>
#import <sys/time.h>

enum {
    kAips=0, kHospital=1, kFavorites=2, kInteractions=3, kNone=100
};

enum {
    kTitle=0, kAuthor=2, kAtcCode=4, kRegNr=6, kTherapy=8
};

static NSString *SEARCH_STRING = @"Suche";
static NSString *FACHINFO_STRING = @"Fachinformation";
static NSString *TREFFER_STRING = @"Treffer";

static NSString *FULL_TOOLBAR_TITLE = @"Präparat";
static NSString *FULL_TOOLBAR_AUTHOR = @"Inhaber";
static NSString *FULL_TOOLBAR_ATCCODE = @"Wirkstoff/ATC";
static NSString *FULL_TOOLBAR_REGNR = @"Reg. Nr.";
static NSString *FULL_TOOLBAR_SUBSTANCES = @"Wirkstoff";
static NSString *FULL_TOOLBAR_THERAPY = @"Therapie";

static NSString *SHORT_TOOLBAR_TITLE = @"Prä";
static NSString *SHORT_TOOLBAR_AUTHOR = @"Inh";
static NSString *SHORT_TOOLBAR_ATCCODE = @"Wirk/Atc";
static NSString *SHORT_TOOLBAR_REGNR = @"Reg";
static NSString *SHORT_TOOLBAR_SUBSTANCES = @"Wirk";
static NSString *SHORT_TOOLBAR_THERAPY = @"Ther";

static NSInteger mUsedDatabase = kNone;
static NSInteger mCurrentSearchState = kTitle;

static CGFloat searchFieldWidth = 320.0f;

static BOOL mSearchInteractions = false;
static BOOL mShowReport = false;

@interface DataObject : NSObject

@property NSString *title;
@property NSString *subTitle;
@property long medId;

@end

@implementation DataObject

@synthesize title;
@synthesize subTitle;
@synthesize medId;

@end

@implementation MLViewController
{
    // Enumerations
    enum {
        eAips=0, eFavorites=1, eInteractions=2
    };

    // Instance variable declarations go here
    NSMutableArray *medi;
    
    NSMutableArray *titleData;
    NSMutableArray *subTitleData;
    NSMutableArray *favoriteKeyData;
    NSMutableArray *medIdArray;
    
    MLDBAdapter *mDb;
    MLMedication *mMed;
    NSMutableString *mBarButtonItemName;
    NSMutableSet *favoriteMedsSet;
    NSMutableArray *items;
    MLDataStore *favoriteData;
   
    NSMutableDictionary *mMedBasket;
    
    __block NSArray *searchResults;
    
    SWRevealViewController *mainRevealController;
    
    MLSecondViewController *secondViewController;
    MLTitleViewController *titleViewController;
    MLMenuViewController *menuViewController;

    UINavigationController *secondViewNavigationController;
    UINavigationController *menuViewNavigationController;
    
    UIActivityIndicatorView *mActivityIndicator;
    
    float screenWidth;
    float screenHeight;
    
    NSIndexPath *mCurrentIndexPath;
    long mNumCurrSearchResults;
    int timeForSearch_ms;
    
    struct timeval beg_tv;
    struct timeval end_tv;
    
    BOOL runningActivityIndicator;
    
    dispatch_queue_t mSearchQueue;
}

@synthesize searchField;
@synthesize myTextField;
@synthesize myTableView;
@synthesize myToolBar;
@synthesize myTabBar;

/** Instance functions
 */
#pragma mark Instance functions

- (IBAction) searchAction:(id)sender
{
    // Do something
}

- (IBAction) onToolBarButtonPressed:(id)sender
{  
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || (orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight) ) {
        [searchField setText:@""];
        if ([btn.title isEqualToString:FULL_TOOLBAR_TITLE]) {
            [myTextField setText:FULL_TOOLBAR_TITLE];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_TITLE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_TITLE];
            mCurrentSearchState = kTitle;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_AUTHOR]) {
            [myTextField setText:FULL_TOOLBAR_AUTHOR];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_AUTHOR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_AUTHOR];
            mCurrentSearchState = kAuthor;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_ATCCODE]) {
            [myTextField setText:FULL_TOOLBAR_ATCCODE];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_ATCCODE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_ATCCODE];
            mCurrentSearchState = kAtcCode;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_REGNR]) {
            [myTextField setText:FULL_TOOLBAR_REGNR];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_REGNR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_REGNR];
            mCurrentSearchState = kRegNr;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_THERAPY]) {
            [myTextField setText:FULL_TOOLBAR_THERAPY];
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_THERAPY]];
            [mBarButtonItemName setString:FULL_TOOLBAR_THERAPY];
            mCurrentSearchState = kTherapy;
        }
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [searchField setText:@""];
        if ([btn.title isEqualToString:SHORT_TOOLBAR_TITLE]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_TITLE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_TITLE];
            mCurrentSearchState = kTitle;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_AUTHOR]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_AUTHOR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_AUTHOR];
            mCurrentSearchState = kAuthor;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_ATCCODE]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_ATCCODE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_ATCCODE];
            mCurrentSearchState = kAtcCode;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_REGNR]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_REGNR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_REGNR];
            mCurrentSearchState = kRegNr;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_THERAPY]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_THERAPY]];
            [mBarButtonItemName setString:FULL_TOOLBAR_THERAPY];
            mCurrentSearchState = kTherapy;
        }
    }

    if ([MLConstants iosVersion]>=7.0f) {
        for (UIBarButtonItem *b in [myToolBar items]) {
            [b setTintColor:[UIColor lightGrayColor]];   // Default color
            if (b==btn)
                [b setTintColor:MAIN_TINT_COLOR];
        }
    } else {
        for (UIBarButtonItem *b in [myToolBar items]) {
            [b setTintColor:nil];   // Default color
            if (b==btn)
                [b setTintColor:[UIColor lightGrayColor]];
        }
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
    self = [super init];
    
    medi = [NSMutableArray array];
    
    titleData = [NSMutableArray array];
    subTitleData = [NSMutableArray array];
    // Saved to persistent store
    favoriteKeyData = [NSMutableArray array];   // equivalent to [[alloc] init]
    // Used by tableview
    medIdArray = [NSMutableArray array];
    
    secondViewController = nil;//[[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController" bundle:nil];
    secondViewNavigationController = nil;//[[UINavigationController alloc] initWithRootViewController:secondView];
    
    menuViewController = nil;
    menuViewNavigationController = nil;
    
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        SEARCH_STRING = @"Suche";
        FACHINFO_STRING = @"Fachinformation";
        TREFFER_STRING = @"Treffer";
        //
        FULL_TOOLBAR_TITLE = @"Präparat";
        FULL_TOOLBAR_AUTHOR = @"Inhaber";
        FULL_TOOLBAR_ATCCODE = @"Wirkstoff/ATC";
        FULL_TOOLBAR_REGNR = @"Reg. Nr.";
        FULL_TOOLBAR_SUBSTANCES = @"Wirkstoff";
        FULL_TOOLBAR_THERAPY = @"Therapie";
        //
        SHORT_TOOLBAR_TITLE = @"Prä";
        SHORT_TOOLBAR_AUTHOR = @"Inh";
        SHORT_TOOLBAR_ATCCODE = @"Wirk/Atc";
        SHORT_TOOLBAR_REGNR = @"Reg";
        SHORT_TOOLBAR_SUBSTANCES = @"Wirk";
        SHORT_TOOLBAR_THERAPY = @"Ther";
    } else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        SEARCH_STRING = @"Recherche";
        FACHINFO_STRING = @"Notice Infopro";
        TREFFER_STRING = @"Réponse(s)";
        //
        FULL_TOOLBAR_TITLE = @"Préparation";
        FULL_TOOLBAR_AUTHOR = @"Titulaire";
        FULL_TOOLBAR_ATCCODE = @"Principe/ATC";
        FULL_TOOLBAR_REGNR = @"No d'Autor";
        FULL_TOOLBAR_SUBSTANCES = @"Principe";
        FULL_TOOLBAR_THERAPY = @"Thérapie";
        //
        SHORT_TOOLBAR_TITLE = @"Pré";
        SHORT_TOOLBAR_AUTHOR = @"Tit";
        SHORT_TOOLBAR_ATCCODE = @"Prin/Atc";
        SHORT_TOOLBAR_REGNR = @"Aut";
        SHORT_TOOLBAR_SUBSTANCES = @"Prin";
        SHORT_TOOLBAR_THERAPY = @"Thér";
    }
    
    // Note: iOS7 or above
    if ([MLConstants iosVersion]>=7.0f) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
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

    // Set default database
    mUsedDatabase = kAips;
    // Set current search state
    mCurrentSearchState = kTitle;
    
    return self;
}

- (id) initWithLaunchState:(int)state
{
    id handle = [self init];
    
    if (handle != nil) {
        [self setLaunchState:state];
    }
    
    return handle;
}

- (void) setLaunchState:(int)state
{
    if (state==eAips || state==eFavorites || state==eInteractions) {
        if (state==eAips) {
            mUsedDatabase = kAips;
            mSearchInteractions = false;
            mCurrentIndexPath = nil;
            // Reset searchfield
            [self resetBarButtonItems];
            // Clear main table view
            [self clearDataInTableView];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
        } else if (state==eFavorites) {
            mUsedDatabase = kFavorites;
            mCurrentSearchState = kTitle;
            mSearchInteractions = false;
            // The following programmatical call takes care of everything...
            [self switchTabBarItem:[myTabBar.items objectAtIndex:1]];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];
        } else if (state==eInteractions) {
            mUsedDatabase = kAips;
            mCurrentSearchState = kTitle;
            mSearchInteractions = true;
            // Reset searchfield
            [self resetBarButtonItems];
            //
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:2]];
        }
        // Go back to main view
        mainRevealController = self.revealViewController;
        [mainRevealController setFrontViewPosition:FrontViewPositionRightMost animated:YES];
        // Show keyboard
        [searchField becomeFirstResponder];
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

- (void) finishedDownloading:(NSNotification *)notification
{
    static int fileCnt = 0;
    
    if ([[notification name] isEqualToString:@"MLDidFinishLoading"]) {
        fileCnt++;
        if (fileCnt==1)
            NSLog(@"Finished downloading first file");
        else if (fileCnt==2)
            NSLog(@"Finished downloading second file");
        if (mDb!=nil && fileCnt==2) {
            // Reset file counter
            fileCnt=0;
            // Make sure downloaded files cannot be backuped
            [self doNotBackupDocumentsDir];
            // Close sqlite database
            [mDb closeDatabase];
            // Re-open sqlite database
            [self openSQLiteDatabase];
            // Close interaction database
            [mDb closeInteractionsCsvFile];
            // Re-open interaction database
            [self openInteractionsCsvFile];
            // Reload table
            [self resetDataInTableView];
            
            // Display friendly message
            long numSearchRes = [searchResults count];
            int numInteractions = (int)[mDb getNumInteractions];
            
            if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
                MLAlertView *alert = [[MLAlertView alloc] initWithTitle:@"AIPS Datenbank aktualisiert!"
                                                                message:[NSString stringWithFormat:@"Die Datenbank enthält %ld Fachinfos \nund %d Interaktionen.", numSearchRes, numInteractions]
                                                                 button:@"OK"];
                [alert show];
            } else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
                MLAlertView *alert = [[MLAlertView alloc] initWithTitle:@"Banque des donnees AIPS mises à jour!"
                                                                message:[NSString stringWithFormat:@"La banque des données contien %ld notices infopro \net %d interactions.", numSearchRes, numInteractions]
                                                                 button:@"OK"];
                [alert show];
            }
        }
    } else if ([[notification name] isEqualToString:@"MLStatusCode404"]) {
        NSLog(@"Status Code 404");
        MLAlertView *alert = [[MLAlertView alloc] initWithTitle:@"Datenbank kann nicht aktualisiert werden!"
                                                        message:@"Server unreachable..."
                                                         button:@"OK"];
        [alert show];
    }
}

- (void) openInteractionsCsvFile
{
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        if (![mDb openInteractionsCsvFile:@"drug_interactions_csv_de"]) {
            NSLog(@"No German drug interactions file!");
        }
    } else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        if (![mDb openInteractionsCsvFile:@"drug_interactions_csv_fr"]) {
            NSLog(@"No French drug interactions file!");
        }
    }
}

- (void) openSQLiteDatabase
{
    mDb = [[MLDBAdapter alloc] init];
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_de"]) {
            NSLog(@"No German database!");
            mDb = nil;
        }
    } else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        if (![mDb openDatabase:@"amiko_db_full_idx_fr"]) {
            NSLog(@"No French database!");
            mDb = nil;
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
    mCurrentSearchState = kTitle;
    [self setBarButtonItemsWith:mCurrentSearchState];
}

- (void) resetDataInTableView
{
    // Reset search state
    mCurrentSearchState = kTitle;
    
    searchResults = [self searchAipsDatabaseWith:@""];
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
    
    for (UIBarButtonItem *b in [myToolBar items]) {
       [b setTintColor:[UIColor lightGrayColor]];   // Default color
    }
    if ([MLConstants iosVersion]>=7.0f)
        [[[myToolBar items] objectAtIndex:kTitle] setTintColor:MAIN_TINT_COLOR];
    else
        [[[myToolBar items] objectAtIndex:kTitle] setTintColor:[UIColor lightGrayColor]];

    [searchField setText:@""];
    [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_TITLE]];
    mCurrentSearchState = kTitle;
}

- (void) setBarButtonItemsWith:(NSInteger)searchState
{
    // kTitle=0, kAuthor=2, kAtcCode=4, kRegNr=6, kTherapy=8
    for (UIBarButtonItem *b in [myToolBar items]) {
        [b setTintColor:[UIColor lightGrayColor]];   // Default color
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        searchState /= 2;
    
    if ([MLConstants iosVersion]>=7.0f)
        [[[myToolBar items] objectAtIndex:searchState] setTintColor:MAIN_TINT_COLOR];
    else
        [[[myToolBar items] objectAtIndex:searchState] setTintColor:[UIColor lightGrayColor]];

    [searchField setText:@""];
    switch(searchState)
    {
        case kTitle:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_TITLE]];
            break;
        case kAuthor:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_AUTHOR]];
            break;
        case kAtcCode:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_ATCCODE]];
            break;
        case kRegNr:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_REGNR]];
            break;
        case kTherapy:
            [searchField setPlaceholder:[NSString stringWithFormat:@"%@ %@", SEARCH_STRING, FULL_TOOLBAR_THERAPY]];
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
    
    if ([MLConstants iosVersion]>=7.0f)
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
                                         [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2], UITextAttributeFont,
                                         // @1.0, NSKernAttributeName,
                                         // [NSValue valueWithUIOffset:UIOffsetMake(1,0)], UITextAttributeTextShadowOffset,
                                         nil];
    
    for (int i=0; i<3; i++)
        [[myTabBar items][i] setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

- (void) setToolbarItemsFontSize
{
    NSDictionary *titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [UIFont systemFontOfSize:14], UITextAttributeFont,
                                         nil];
    
    for (int i=0; i<9; i+=2)    // 17.06.2014 -> used to be '11'
        [[myToolBar items][i] setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
}

- (void) startActivityIndicator
{
    if (runningActivityIndicator==NO) {
#ifdef DEBUG
        // NSLog(@"Start activity indicator");
#endif
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
#ifdef DEBUG
    // NSLog(@"Stop activity indicator");
#endif
    [mActivityIndicator stopAnimating];
    [mActivityIndicator removeFromSuperview];
    runningActivityIndicator = NO;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    screenWidth = self.view.bounds.size.width;
    screenHeight = self.view.bounds.size.height;
    
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        if ([MLConstants iosVersion]>=7.0f) {
            [self setToolbarItemsFontSize];
        }
        
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            screenWidth = self.view.bounds.size.width;
            screenHeight = self.view.bounds.size.height;
            // self.myTableView.frame = CGRectMake(0, 44, screenWidth, screenHeight-44);

            if (screenHeight<500)
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone;
            else {
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone_Retina;
                self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Landscape_iPhone_Retina;
            }
            
            [[[myToolBar items] objectAtIndex:0] setTitle:FULL_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:FULL_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:FULL_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:FULL_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:FULL_TOOLBAR_THERAPY];
            
            // Hide status bar and navigation bar
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
            if ([MLConstants iosVersion]>=7.0f)
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            
            // Hides tab bar (bottom)
            [self hideTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 5;
        } else {
            screenWidth = self.view.bounds.size.width;
            screenHeight = self.view.bounds.size.height;
            // self.myTableView.frame = CGRectMake(0, 44, screenWidth, screenHeight-44-49);

            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            
            [[[myToolBar items] objectAtIndex:0] setTitle:SHORT_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:SHORT_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:SHORT_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:SHORT_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:SHORT_TOOLBAR_THERAPY];
            
            // Display status and navigation bar (top)
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
            if ([MLConstants iosVersion]>=7.0f) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
            }
            // Shows tab bar (bottom)
            [self showTabBarWithAnimation:YES];
            
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 49;
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);    
#endif
    
    [super viewWillDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);    
#endif
    
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    screenWidth = self.view.bounds.size.width;
    screenHeight = self.view.bounds.size.height;
        
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
        
        [[[myToolBar items] objectAtIndex:0] setTitle:FULL_TOOLBAR_TITLE];
        [[[myToolBar items] objectAtIndex:1] setTitle:FULL_TOOLBAR_AUTHOR];
        [[[myToolBar items] objectAtIndex:2] setTitle:FULL_TOOLBAR_ATCCODE];
        [[[myToolBar items] objectAtIndex:3] setTitle:FULL_TOOLBAR_REGNR];
        [[[myToolBar items] objectAtIndex:4] setTitle:FULL_TOOLBAR_THERAPY];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        if ([MLConstants iosVersion]>=7.0f) {
            [self setToolbarItemsFontSize];
        }
                
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
 
            screenHeight = self.view.bounds.size.width;
            if (screenHeight<500)
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone;
            else {
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone_Retina;
                self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Landscape_iPhone_Retina;
            }
            
            [[[myToolBar items] objectAtIndex:0] setTitle:FULL_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:FULL_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:FULL_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:FULL_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:FULL_TOOLBAR_THERAPY];
                        
            // [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
        } else {
            //
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            
            [[[myToolBar items] objectAtIndex:0] setTitle:SHORT_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:SHORT_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:SHORT_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:SHORT_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:SHORT_TOOLBAR_THERAPY];
            
            // [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
        }
    }
    if (mSearchInteractions==false) {
        if (mUsedDatabase == kAips)
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
        else if (mUsedDatabase == kFavorites)
            [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];
        else if (mUsedDatabase == kNone)
            [myTabBar setSelectedItem:nil]; // Clears all cells
    } else {
        [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:2]];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [super viewDidAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    screenWidth = self.view.bounds.size.width;
    screenHeight = self.view.bounds.size.height;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            // must go in viewdidappear
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
            
            // Hides tab bar
            [self hideTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 5;
            
            // Hides status bar
            if ([MLConstants iosVersion]>=7.0f)
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

        } else {
            // Shows navigation bar
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
            
            // Displays tab bar
            [self showTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 49;
        }
    }
    
    [self setBarButtonItemsWith:mCurrentSearchState];
}

- (void) viewDidUnload
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super viewDidUnload];
}

- (void) viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = NSLocalizedString(APP_NAME, nil);
    
    // Sets color and font and whatever else of the navigation bar
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          VERY_LIGHT_GRAY_COLOR, UITextAttributeTextColor,
                                                          nil]];
    // Applies this color throughout the app
    // [[UISearchBar appearance] setBarTintColor:[UIColor lightGrayColor]];
    
    // Add icon (top center)
    // self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_icon_32x32.png"]];

    // Add desitin icon
    UIButton *logoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoButton setImage:[UIImage imageNamed:@"desitin_icon_32x32.png"] forState:UIControlStateNormal];
    logoButton.frame = CGRectMake(0.0f, 0.0f, 32.0f, 32.0f);
    [logoButton addTarget:self action:@selector(myShowMenuMethod:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *appIconItem = [[UIBarButtonItem alloc] initWithCustomView:logoButton];

    self.navigationItem.leftBarButtonItem = appIconItem;
    
    // Initialize menu view controllers
    if (menuViewController!=nil) {
        [menuViewController removeFromParentViewController];
        menuViewController = nil;
    }
    menuViewController = [[MLMenuViewController alloc] initWithNibName:@"MLMenuViewController" bundle:nil parent:self];
    
    if (menuViewNavigationController!=nil) {
        [menuViewNavigationController removeFromParentViewController];
        menuViewNavigationController = nil;
    }
    menuViewNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
    
    // Background color of navigation bar
    if ([MLConstants iosVersion]>=7.0f) {
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
    }
    
    // Add search bar as title view to navigation bar
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([MLConstants iosVersion]>=7.0f) {
            searchField.barTintColor = [UIColor lightGrayColor];
            searchField.backgroundColor = [UIColor clearColor];
            searchField.translucent = YES;
        }
    }    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // Note: iOS7
        if ([MLConstants iosVersion]>=7.0f) {
            searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(10.0f, 0.0f, searchFieldWidth-20.0f, 44.0f)];
            searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            searchField.barStyle = UIBarStyleDefault;
            searchField.barTintColor = [UIColor clearColor];
            searchField.backgroundImage = [UIImage new];    // Necessary fo completely transparent search bar...
            searchField.backgroundColor = [UIColor clearColor];
            searchField.tintColor = [UIColor lightGrayColor];    // cursor color
            searchField.translucent = YES;
        } else {
            searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(10.0f, 0.0f, searchFieldWidth-20.0f, 44.0f)];
            searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        }
        searchField.delegate = self;
        
        UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, searchFieldWidth, 44.0f)];
        // searchBarView.autoresizingMask = 0;
        [searchBarView addSubview:searchField];
        
        self.navigationItem.titleView = searchBarView;
    }
    
    mBarButtonItemName = [[NSMutableString alloc] initWithString:FULL_TOOLBAR_TITLE];
    
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

    // Open drug interactions csv file
    [self openInteractionsCsvFile];
#ifdef DEBUG
    NSLog(@"Number of records in interaction file = %lu", (unsigned long)[mDb getNumInteractions]);
#endif

    // Init medication basket
    mMedBasket = [[NSMutableDictionary alloc] init];
    
    // Load favorites
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *urls = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if ([urls count] > 0) {
        NSURL *libraryFolder = urls[0];
        // NSLog(@"%@ %@", libraryFolder, [libraryFolder absoluteString]);
        NSError *error = nil;
        NSArray *libraryFolderContent = [fileManager contentsOfDirectoryAtPath:[libraryFolder relativePath] error:&error];
        if ([libraryFolderContent count] > 0 && error == nil) {
            // NSLog(@"Contents of library folder = %@", libraryFolderContent);
        } else if ([libraryFolderContent count] == 0 && error == nil)
            NSLog(@"Library folder is empty!");
        else
            NSLog(@"%s: %@", __FUNCTION__, error);
    } else {
        NSLog(@"Could not find the Library folder.");
    }
    
    favoriteData = [[MLDataStore alloc] init];
    [self loadData];
    
    favoriteMedsSet = [[NSMutableSet alloc] initWithSet:favoriteData.favMedsSet];
}

- (void) myShowMenuMethod:(id)sender
{
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        mainRevealController = self.revealViewController;
        [mainRevealController setFrontViewController:menuViewNavigationController];
        [mainRevealController setFrontViewPosition:FrontViewPositionRight animated:YES];
    } else {
        [menuViewController showMenu];
    }
}

- (void) myLongPressMethod:(UILongPressGestureRecognizer *)gesture
{
    CGPoint p = [gesture locationInView:self.myTableView];
    
    NSIndexPath *indexPath = [self.myTableView indexPathForRowAtPoint:p];
    
    if (mCurrentSearchState == kAtcCode) {
        if (indexPath != nil) {
            NSString *subTitle = [medi[indexPath.row] subTitle];
            if (subTitle!=nil) {
                NSString *medSubTitle = [NSString stringWithString:subTitle];
                NSArray *mAtc = [medSubTitle componentsSeparatedByString:@" -"];
                if (mAtc[0]!=nil && ![[searchField text] isEqualToString:mAtc[0]]) {
                    [searchField setText:mAtc[0]];
                    [self executeSearch:mAtc[0]];
                }
            }
        }
    }
}

- (void) invalidateObserver
{
    if (titleViewController!=nil && secondViewController!=nil) {
        @try {
            [titleViewController removeObserver:secondViewController forKeyPath:@"javaScript"];
        } @catch (NSException *exception) {
            // Do nothing, obviously the observer wasn't attached and an exception was thrown
            NSLog(@"Expection thrown...");
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
    
    if ([[MLConstants appLanguage] isEqualToString:@"de"]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_de"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath])
            amikoReportFile = filePath;
        else
            amikoReportFile = [[NSBundle mainBundle] pathForResource:@"amiko_report_de" ofType:@"html"];
    } else if ([[MLConstants appLanguage] isEqualToString:@"fr"]) {
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:@"amiko_report_fr"] stringByAppendingPathExtension:@"html"];
        if ([fileManager fileExistsAtPath:filePath])
            amikoReportFile = filePath;
        else
            amikoReportFile = [[NSBundle mainBundle] pathForResource:@"amiko_report_fr" ofType:@"html"];
    }

    NSError *error = nil;
    NSString *amikoReport = [NSString stringWithContentsOfFile:amikoReportFile encoding:NSUTF8StringEncoding error:&error];

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
    
    if ([MLConstants iosVersion]>=7.0f) {
        UIFont *font = [UIFont fontWithName:@"Arial" size:14];
        secondViewController.htmlStr = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>", font.fontName, (int)font.pointSize, amikoReport];
    } else {
        UIFont *font = [UIFont fontWithName:@"Arial" size:15];
        secondViewController.htmlStr = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>", font.fontName, (int)font.pointSize, amikoReport];
    }

    if (secondViewNavigationController!=nil) {
        [secondViewNavigationController removeFromParentViewController];
        secondViewNavigationController = nil;
    }
    secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];
    
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    mainRevealController = self.revealViewController;
    [mainRevealController setFrontViewController:secondViewNavigationController animated:YES];
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    
    report_memory();
}

- (void) genSearchResultsWith:(NSString *)searchQuery
{
    if (mCurrentSearchState == kTitle) {
        searchResults = [mDb searchTitle:searchQuery];
    } else if (mCurrentSearchState == kAuthor) {
        searchResults = [mDb searchAuthor:searchQuery];
    } else if (mCurrentSearchState == kAtcCode) {
        searchResults = [mDb searchATCCode:searchQuery];
    } else if (mCurrentSearchState == kRegNr) {
        searchResults = [mDb searchRegNr:searchQuery];
    } else if (mCurrentSearchState == kTherapy) {
        searchResults = [mDb searchApplication:searchQuery];
    }
}

- (NSArray *) searchAipsDatabaseWith:(NSString *)searchQuery
{
    NSArray *searchRes = [NSArray array];
    
    NSDate *startTime = [NSDate date];

    if (mCurrentSearchState == kTitle) {
        searchRes = [mDb searchTitle:searchQuery];
    } else if (mCurrentSearchState == kAuthor) {
        searchRes = [mDb searchAuthor:searchQuery];
    } else if (mCurrentSearchState == kAtcCode) {
        searchRes = [mDb searchATCCode:searchQuery];
    } else if (mCurrentSearchState == kRegNr) {
        searchRes = [mDb searchRegNr:searchQuery];
    } else if (mCurrentSearchState == kTherapy) {
        searchRes = [mDb searchApplication:searchQuery];
    }
    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
    
    timeForSearch_ms = (int)(1000*execTime+0.5);
    mNumCurrSearchResults = (int)[searchRes count];
    NSLog(@"%ld Treffer in %dms", mNumCurrSearchResults, timeForSearch_ms);

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
    
    NSLog(@"%ld Favoriten in %dms", mNumCurrSearchResults, (int)(1000*execTime+0.5));
    
    return medList;
}

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self startActivityIndicator];
    
    [self performSelector:@selector(switchTabBarItem:) withObject:item afterDelay:0.01];
}

- (void) switchTabBarItem: (UITabBarItem *)item
{
    static bool inProgress = false;
    
    switch (item.tag) {
        case 0:
        {
#ifdef DEBUG
            NSLog(@"TabBar - Aips Database");
#endif
            if (mUsedDatabase==kFavorites || mSearchInteractions==true) {
                mUsedDatabase = kAips;
                mSearchInteractions = false;
                mCurrentIndexPath = nil;
                [self stopActivityIndicator];
                [self clearDataInTableView];
                // Show keyboard
                [searchField becomeFirstResponder];
                // Reset searchfield
                [self resetBarButtonItems];
            } else {
                // Empty searchfield
                [searchField setText:@""];
                // 
                MLViewController* __weak weakSelf = self;
                //
                dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);
                dispatch_async(search_queue, ^(void) {
                    MLViewController* scopeSelf = weakSelf;
                    if (!inProgress) {
                        inProgress = true;
                        mCurrentSearchState = kTitle;
                        // @synchronized(searchResults) {
                        searchResults = [scopeSelf searchAipsDatabaseWith:@""];
                        // Update tableview
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [scopeSelf updateTableView];
                            [myTableView reloadData];
                            [searchField resignFirstResponder];
                            [myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms", (unsigned long)[searchResults count], TREFFER_STRING, timeForSearch_ms]];
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
            mUsedDatabase = kFavorites;
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
                    mCurrentSearchState = kTitle;
                    // @synchronized(searchResults) {
                    searchResults = [scopeSelf retrieveAllFavorites];
                    // Update tableview
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [scopeSelf updateTableView];
                        [myTableView reloadData];
                        // [searchField resignFirstResponder];
                        [myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms", (unsigned long)[searchResults count], TREFFER_STRING, timeForSearch_ms]];
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
            mUsedDatabase = kAips;
            mSearchInteractions = true;
            [self stopActivityIndicator];
            [self setBarButtonItemsWith:kTitle];
            // Switch view
            [self switchToDrugInteractionView];
            break;
        case 3:
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

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.searchDisplayController.searchBar.showsCancelButton = YES;
}

- (void) executeSearch:(NSString *)searchText
{
    static volatile bool inProgress = false;
    
    int minSearchChars = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        minSearchChars = 0;
    if (mCurrentSearchState == kTherapy)
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
                searchResults = [scopeSelf searchAipsDatabaseWith:searchText];
            } else {
                if (mUsedDatabase == kFavorites) {
                    searchResults = [weakSelf retrieveAllFavorites];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (mUsedDatabase == kFavorites && [searchText length] <= minSearchChars)
                    [searchField resignFirstResponder];
                [scopeSelf updateTableView];
                [myTableView reloadData];
                [myTextField setText:[NSString stringWithFormat:@"%ld %@ in %dms", (unsigned long)[searchResults count], TREFFER_STRING, timeForSearch_ms]];
                @synchronized(self) {
                    inProgress = false;
                }
            });
        }
    });
}

- (void) addTitle: (NSString *)title andPackInfo: (NSString *)packinfo andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified];// @"k.A.";
    if (![packinfo isEqual:[NSNull null]]) {
        if ([packinfo length]>0)
            m.subTitle = packinfo;
        else
            m.subTitle = [MLConstants notSpecified];// @"k.A.";
    } else
        m.subTitle = [MLConstants notSpecified];// @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

- (void) addTitle:(NSString *)title andAuthor:(NSString *)author andMedId:(long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
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

- (void) addTitle:(NSString *)title andAtcCode:(NSString *)atccode andAtcClass:(NSString *)atcclass andMedId:(long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
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

- (void) addTitle:(NSString *)title andRegnrs:(NSString *)regnrs andAuthor:(NSString *)author andMedId:(long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = [MLConstants notSpecified]; // @"k.A.";;
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
    DataObject *m = [[DataObject alloc] init];
    
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

- (void) addTitle:(NSString *)title andApplications:(NSString *)applications andMedId:(long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
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

- (void) updateTableView
{
    if (searchResults) {

        if (medi != nil)
            [medi removeAllObjects];
        
        if (favoriteKeyData != nil)
            [favoriteKeyData removeAllObjects];
        
        if (mCurrentSearchState == kTitle) {
            if (mUsedDatabase == kAips) {
                for (MLMedication *m in searchResults) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];   
                        [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                    }
                }
            }
            else if (mUsedDatabase == kFavorites) {
                for (MLMedication *m in searchResults) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];       
                            [self addTitle:m.title andPackInfo:m.packInfo andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kAuthor) {
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];   
                        [self addTitle:m.title andAuthor:m.auth andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];       
                            [self addTitle:m.title andAuthor:m.auth andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kAtcCode) {
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];   
                        [self addTitle:m.title andAtcCode:m.atccode andAtcClass:m.atcClass andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];      
                            [self addTitle:m.title andAtcCode:m.atccode andAtcClass:m.atcClass andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kRegNr) {
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];   
                        [self addTitle:m.title andRegnrs:m.regnrs andAuthor:m.auth andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];      
                            [self addTitle:m.title andRegnrs:m.regnrs andAuthor:m.auth andMedId:m.medId];
                        }
                    }
                }
            }
        }
        else if (mCurrentSearchState == kTherapy) {
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];  
                        [self addTitle:m.title andApplications:m.application andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];      
                            [self addTitle:m.title andApplications:m.application andMedId:m.medId];
                        }
                    }
                }
            }
        }
        // Sort array alphabetically
        if (mUsedDatabase == kFavorites) {
            /*
            NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:
                                           ^(id obj1, id obj2) { return [obj1 compare:obj2 options:NSNumericSearch]; }];
            */

            NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
            [medi sortUsingDescriptors:[NSArray arrayWithObject:titleSort]];
        }
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

- (void) buttonPressed
{
    // TODO
}

- (void) switchToDrugInteractionView
{
    // if (mCurrentIndexPath!=nil)
    [self tableView:myTableView didSelectRowAtIndexPath:mCurrentIndexPath];
}

/**
 Add med in the buffer to the interaction basket
 */
- (void) pushToMedBasket
{
    if (mMed!=nil) {
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

/** UITableViewDataSource
 */
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // How many rows in the table?
    if (mUsedDatabase == kAips)
        return [medi count];
        // return [titleData count];
    else if (mUsedDatabase == kFavorites) {
        return [favoriteKeyData count];
    }
    else
        return 0;
}

#pragma mark UITableView delegate methods

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
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    mCurrentIndexPath = indexPath;

    long mId = -1;
    
    if (mCurrentIndexPath!=nil) {
        mId = [medi[indexPath.row] medId];  // [[medIdArray objectAtIndex:row] longValue];
        mMed = [mDb searchId:mId];
    }
  
    if (!mShowReport) {
        [self invalidateObserver];
    }
    mShowReport = false;
    if (secondViewController!=nil) {
        // [secondViewController removeFromParentViewController];
        secondViewController = nil;
    }
    secondViewController = [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController"
                                                                    bundle:nil
                                                                     title:FACHINFO_STRING
                                                                  andParam:2];
    
    if (mSearchInteractions==false) {
        // Load style sheet from file
        NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
        NSString *amikoCss = nil;
        if (amikoCssPath)
            amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
        else
            amikoCss = [NSString stringWithString:mMed.styleStr];
 
        secondViewController.htmlStr = [NSString stringWithFormat:@"<head><style>%@</style></head>%@", amikoCss, mMed.contentStr];
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
                                                         andLanguage:[MLConstants appLanguage]];
    } else {
        if (mId>-1) {
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
                                                              andLanguage:[MLConstants appLanguage]];
        
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
    
    // Class MLSecondViewController is now registered as an observer of class MLMenuViewController
    [titleViewController addObserver:secondViewController
                          forKeyPath:@"javaScript"
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:@"javaScriptChanged"];
    
    // UINavigationController *secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondView];
    
    if (secondViewNavigationController!=nil) {
        [secondViewNavigationController removeFromParentViewController];
        secondViewNavigationController = nil;
    }
    secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];

    // Show SecondViewController! (UIWebView)
    [mainRevealController setFrontViewController:secondViewNavigationController animated:YES];
    [mainRevealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

#ifdef DEBUG
    report_memory();
#endif
}

#define PADDING_IPAD 50.0f
#define PADDING_IPHONE 40.0f
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = [medi[indexPath.row] title]; // [titleData objectAtIndex:indexPath.row];
    NSString *subText = [medi[indexPath.row] subTitle]; // [subTitleData objectAtIndex:indexPath.row];
    CGSize textSize, subTextSize;
    CGFloat retVal = 0;
    
    float frameWidth = self.myTableView.frame.size.width;
    
    if ([MLConstants iosVersion]>=7.0f) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            textSize = [self tableText:text sizeWithFont:[UIFont boldSystemFontOfSize:16.0]
                     constrainedToSize:CGSizeMake(frameWidth - PADDING_IPAD, CGFLOAT_MAX)];
            subTextSize = [self tableText:subText sizeWithFont:[UIFont boldSystemFontOfSize:14.0]
                        constrainedToSize:CGSizeMake(frameWidth - 1.6*PADDING_IPAD, CGFLOAT_MAX)];
            retVal = textSize.height + subTextSize.height + PADDING_IPAD * 0.25;
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            textSize = [self tableText:text sizeWithFont:[UIFont boldSystemFontOfSize:13.0]
                     constrainedToSize:CGSizeMake(frameWidth - 2.0*PADDING_IPHONE, CGFLOAT_MAX)];
            subTextSize = [self tableText:subText sizeWithFont:[UIFont boldSystemFontOfSize:12]
                        constrainedToSize:CGSizeMake(frameWidth - 1.8*PADDING_IPHONE, CGFLOAT_MAX)];
            retVal = textSize.height + subTextSize.height + PADDING_IPHONE * 0.3;
        }
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:16.0]
                        constrainedToSize:CGSizeMake(frameWidth - PADDING_IPAD, CGFLOAT_MAX)];
            subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:14.0]
                              constrainedToSize:CGSizeMake(frameWidth - 1.2*PADDING_IPAD, CGFLOAT_MAX)];
            retVal = textSize.height + subTextSize.height + PADDING_IPAD * 0.25;
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (frameWidth > 500) {
                textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:13.0]
                            constrainedToSize:CGSizeMake(frameWidth - PADDING_IPHONE, CGFLOAT_MAX)];
                subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:12.0]
                                  constrainedToSize:CGSizeMake(frameWidth - 1.4*PADDING_IPHONE, CGFLOAT_MAX)];
            } else {
                textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:13.0]
                            constrainedToSize:CGSizeMake(frameWidth - PADDING_IPHONE, CGFLOAT_MAX)];
                subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:12.0]
                                  constrainedToSize:CGSizeMake(frameWidth - 1.4*PADDING_IPHONE, CGFLOAT_MAX)];
            }
            retVal = textSize.height + subTextSize.height + PADDING_IPHONE * 0.4;
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
    
    /* SLOWER implementation
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];

    CGRect frame = [attributedText boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                      context:nil];
    */
    /*
    textSize = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:13]}];
    subTextSize = [subText sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:12]}];
    */
    
    return frame.size;
}

#pragma mark helper functions

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
        NSLog(@"Memory in use (in bytes): %u", info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}
@end
