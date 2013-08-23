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
#import "MLMenuViewController.h"
#import "MLDBAdapter.h"
#import "MLMedication.h"
#import "MLSimpleTableCell.h"
#import "MLDataStore.h"

#import "SWRevealViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <mach/mach.h>
#import <sys/time.h>

enum {
    kAips=0, kHospital=1, kFavorites=2
};

enum {
    kTitle=0, kAuthor=2, kAtcCode=4, kRegNr=6, kSubstances=8, kTherapy=10
};

static NSString *FULL_TOOLBAR_TITLE = @"Präparat";
static NSString *FULL_TOOLBAR_AUTHOR = @"Inhaber";
static NSString *FULL_TOOLBAR_ATCCODE = @"ATC Code";
static NSString *FULL_TOOLBAR_REGNR = @"Reg. Nr.";
static NSString *FULL_TOOLBAR_SUBSTANCES = @"Wirkstoff";
static NSString *FULL_TOOLBAR_THERAPY = @"Therapie";

static NSString *SHORT_TOOLBAR_TITLE = @"Prä";
static NSString *SHORT_TOOLBAR_AUTHOR = @"Inh";
static NSString *SHORT_TOOLBAR_ATCCODE = @"Atc";
static NSString *SHORT_TOOLBAR_REGNR = @"Reg";
static NSString *SHORT_TOOLBAR_SUBSTANCES = @"Wirk";
static NSString *SHORT_TOOLBAR_THERAPY = @"Ther";

static NSInteger mUsedDatabase = kAips;
static NSInteger mCurrentSearchState = kTitle;

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
    // Instance variable declarations go here
    NSMutableArray *medi;
    
    NSMutableArray *titleData;
    NSMutableArray *subTitleData;
    NSMutableArray *favoriteKeyData;
    NSMutableArray *medIdArray;
    
    MLDBAdapter *mDb;
    NSMutableString *mBarButtonItemName;
    NSMutableSet *favoriteMedsSet;
    NSMutableArray *items;
    MLDataStore *favoriteData;
   
    __block NSArray *searchResults;
    
    SWRevealViewController *revealController;
    UINavigationController *secondViewNavigationController;
    
    MLSecondViewController *secondView;
    MLMenuViewController *rightViewController;
    
    UIActivityIndicatorView *mActivityIndicator;
    
    float screenWidth;
    float screenHeight;
    int timeForSearch_ms;
    
    struct timeval beg_tv;
    struct timeval end_tv;
}

@synthesize searchField;
@synthesize myTextField;
@synthesize myTableView;
@synthesize myToolBar;
@synthesize myTabBar;

/** Instance functions
 */
#pragma mark Instance functions

- (IBAction) searchAction: (id)sender
{
    // Do something
}

- (IBAction) onToolBarButtonPressed: (id)sender
{  
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || (orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight) ) {
        [searchField setText:@""];
        if ([btn.title isEqualToString:FULL_TOOLBAR_TITLE]) {
            [myTextField setText:FULL_TOOLBAR_TITLE];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_TITLE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_TITLE];
            mCurrentSearchState = kTitle;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_AUTHOR]) {
            [myTextField setText:FULL_TOOLBAR_AUTHOR];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_AUTHOR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_AUTHOR];
            mCurrentSearchState = kAuthor;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_ATCCODE]) {
            [myTextField setText:FULL_TOOLBAR_ATCCODE];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_ATCCODE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_ATCCODE];
            mCurrentSearchState = kAtcCode;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_REGNR]) {
            [myTextField setText:FULL_TOOLBAR_REGNR];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_REGNR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_REGNR];
            mCurrentSearchState = kRegNr;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_SUBSTANCES]) {
            [myTextField setText:FULL_TOOLBAR_SUBSTANCES];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_SUBSTANCES]];
            [mBarButtonItemName setString:FULL_TOOLBAR_SUBSTANCES];
            mCurrentSearchState = kSubstances;
        } else if ([btn.title isEqualToString:FULL_TOOLBAR_THERAPY]) {
            [myTextField setText:FULL_TOOLBAR_THERAPY];
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_THERAPY]];
            [mBarButtonItemName setString:FULL_TOOLBAR_THERAPY];
            mCurrentSearchState = kTherapy;
        }
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [searchField setText:@""];
        if ([btn.title isEqualToString:SHORT_TOOLBAR_TITLE]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_TITLE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_TITLE];
            mCurrentSearchState = kTitle;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_AUTHOR]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_AUTHOR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_AUTHOR];
            mCurrentSearchState = kAuthor;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_ATCCODE]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_ATCCODE]];
            [mBarButtonItemName setString:FULL_TOOLBAR_ATCCODE];
            mCurrentSearchState = kAtcCode;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_REGNR]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_REGNR]];
            [mBarButtonItemName setString:FULL_TOOLBAR_REGNR];
            mCurrentSearchState = kRegNr;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_SUBSTANCES]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_SUBSTANCES]];
            [mBarButtonItemName setString:FULL_TOOLBAR_SUBSTANCES];
            mCurrentSearchState = kSubstances;
        } else if ([btn.title isEqualToString:SHORT_TOOLBAR_THERAPY]) {
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_THERAPY]];
            [mBarButtonItemName setString:FULL_TOOLBAR_THERAPY];
            mCurrentSearchState = kTherapy;
        }
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        for (UIBarButtonItem *b in [myToolBar items]) {
            [b setTintColor:nil];   // Default color
            if (b==btn)
                [b setTintColor:[UIColor lightGrayColor]];
        }
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        for (UIBarButtonItem *b in [myToolBar items]) {
            [b setTintColor:nil];   // Default color
            if (b==btn)
                [b setTintColor:[UIColor darkGrayColor]];
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
    
    secondView = nil;//[[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController" bundle:nil];
    secondViewNavigationController = nil;//[[UINavigationController alloc] initWithRootViewController:secondView];
    
    return self;
}

- (void) resetBarButtonItems
{
    for (UIBarButtonItem *b in [myToolBar items]) {
        [b setTintColor:nil];   // Default color
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [[[myToolBar items] objectAtIndex:kTitle] setTintColor:[UIColor lightGrayColor]];
    else
        [[[myToolBar items] objectAtIndex:kTitle] setTintColor:[UIColor darkGrayColor]];
    [searchField setText:@""];
    [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_TITLE]];
    mCurrentSearchState = kTitle;
}

- (void) setBarButtonItemsWith:(int)searchState
{
    // kTitle=0, kAuthor=2, kAtcCode=4, kRegNr=6, kSubstances=8, kTherapy=10    
    for (UIBarButtonItem *b in [myToolBar items]) {
        [b setTintColor:nil];   // Default color
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [[[myToolBar items] objectAtIndex:searchState] setTintColor:[UIColor lightGrayColor]];
    else
        [[[myToolBar items] objectAtIndex:searchState/2] setTintColor:[UIColor darkGrayColor]];
    [searchField setText:@""];
    switch(searchState)
    {
        case kTitle:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_TITLE]];
            break;
        case kAuthor:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_AUTHOR]];
            break;
        case kAtcCode:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_ATCCODE]];
            break;
        case kRegNr:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_REGNR]];
            break;
        case kSubstances:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_SUBSTANCES]];
            break;
        case kTherapy:
            [searchField setPlaceholder:[NSString stringWithFormat:@"Suche %@", FULL_TOOLBAR_THERAPY]];
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
        [UIView setAnimationDuration:0.75];
        
        [myTabBar setAlpha:1.0];
        
        [UIView commitAnimations];
    }
}

- (void) hideTabBarWithAnimation: (BOOL)withAnimation
{
    if (withAnimation == NO) {
        [myTabBar setHidden:YES];
    } else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelegate:nil];
        [UIView setAnimationDuration:0.75];
        
        [myTabBar setAlpha:0.0];
        
        [UIView commitAnimations];
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSLog(@"%s", __FUNCTION__);
    
    screenWidth = self.view.bounds.size.width;
    screenHeight = self.view.bounds.size.height;
    
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{    
    NSLog(@"%s", __FUNCTION__);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        } else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            /*
            NSLog(@"%s Landscape", __FUNCTION__);            
            // Add search bar as title view to navigation bar
            searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 32.0)];
            searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 32.0)];
            searchBarView.autoresizingMask = 0;
            searchField.delegate = self;
            [searchBarView addSubview:searchField];
            self.navigationItem.titleView = searchBarView;         
            */
            
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
            [[[myToolBar items] objectAtIndex:8] setTitle:FULL_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:FULL_TOOLBAR_THERAPY];
            
            // Hides navigation bar
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
            
            // Hides tab bar
            [self hideTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 0;
        } else {
         
            // Add search bar as title view to navigation bar
            /*
            NSLog(@"%s Portrait", __FUNCTION__);
            searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
            searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
            searchBarView.autoresizingMask = 0;
            searchField.delegate = self;
            [searchBarView addSubview:searchField];
            self.navigationItem.titleView = searchBarView;
            */
            
            // [self adjustHeightOfTableview];
            
            screenWidth = self.view.bounds.size.width;
            screenHeight = self.view.bounds.size.height;
            // self.myTableView.frame = CGRectMake(0, 44, screenWidth, screenHeight-44-49);

            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            
            [[[myToolBar items] objectAtIndex:0] setTitle:SHORT_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:SHORT_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:SHORT_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:SHORT_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:SHORT_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:SHORT_TOOLBAR_THERAPY];
            
            // Displays navigation bar
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
            
            // Displays tab bar
            [self showTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 49;
        }
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);    
    
    [super viewWillDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);    
    
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
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
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
            [[[myToolBar items] objectAtIndex:8] setTitle:FULL_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:FULL_TOOLBAR_THERAPY];
                        
            // [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
        } else {
            //
            /*
            myTabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, screenHeight-49, screenWidth, 49)];
            // myTabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:myTabBar];
            UITabBarItem *itemAips = [[UITabBarItem alloc] initWithTitle:@"AIPS" image:[UIImage imageNamed:@"10-medical.png"] tag:0];
            UITabBarItem *itemFavs = [[UITabBarItem alloc] initWithTitle:@"Favorites" image:[UIImage imageNamed:@"28-star.png"] tag:1];
            NSMutableArray *tabBarItems = [[NSMutableArray alloc] init];
            [tabBarItems addObject:itemAips];
            [tabBarItems addObject:itemFavs];
            myTabBar.items = tabBarItems;
            myTabBar.delegate = self; 
             */
            //
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            
            [[[myToolBar items] objectAtIndex:0] setTitle:SHORT_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:SHORT_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:SHORT_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:SHORT_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:SHORT_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:SHORT_TOOLBAR_THERAPY];
            
            // [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
        }
    }
    
    if (mUsedDatabase == kAips)
        [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
    else if (mUsedDatabase == kFavorites)
        [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];

    /*
    gettimeofday(&beg_tv, nil);
    
    gettimeofday(&end_tv, nil);
    double time_diff = end_tv.tv_sec + end_tv.tv_usec*0.000001 - beg_tv.tv_sec - beg_tv.tv_usec*0.000001;
    NSLog(@"%s %f", __FUNCTION__, time_diff);
    */
}

/*
- (void) viewDidAppear:(BOOL)animated
{   // - (void) viewDelayedAppear:
    [self performSelector:@selector(viewDelayedAppear) withObject:nil afterDelay:2.0f];
}
*/

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);    
    
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
            // Important!
            // self.myTableView.frame = CGRectMake(0, 44, screenWidth, screenHeight-44);
            /*
            if (screenHeight<500)
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone;
            else {
                self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPhone_Retina;
                self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Landscape_iPhone_Retina;
            }
            */
            
            // shifted to viewwillappear
            /*
            [[[myToolBar items] objectAtIndex:0] setTitle:FULL_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:FULL_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:FULL_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:FULL_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:FULL_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:FULL_TOOLBAR_THERAPY];
            */
            // must go in viewdidappear
            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
            
            // Hides tab bar
            [self hideTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 0;

        } else {
            // self.myTableView.frame = CGRectMake(0, 44, screenWidth, screenHeight-44-49);
            /*
            myTabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, screenHeight-49, screenWidth, 49)];          
            [self.view addSubview:myTabBar];
            UITabBarItem *itemAips = [[UITabBarItem alloc] initWithTitle:@"AIPS" image:[UIImage imageNamed:@"10-medical.png"] tag:0];
            UITabBarItem *itemFavs = [[UITabBarItem alloc] initWithTitle:@"Favorites" image:[UIImage imageNamed:@"28-star.png"] tag:1];
            NSMutableArray *tabBarItems = [[NSMutableArray alloc] init];
            [tabBarItems addObject:itemAips];
            [tabBarItems addObject:itemFavs];
            myTabBar.items = tabBarItems;
            myTabBar.delegate = self;
            if (mUsedDatabase == kAips)
                [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:0]];
            else if (mUsedDatabase == kFavorites)
                [myTabBar setSelectedItem:[myTabBar.items objectAtIndex:1]];
            */
            /*
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
            self.revealViewController.rearViewRevealOverdraw = RearViewRevealOverdraw_Portrait_iPhone;
            */
            
            // shifted to viewwillappear
            /*
            [[[myToolBar items] objectAtIndex:0] setTitle:SHORT_TOOLBAR_TITLE];
            [[[myToolBar items] objectAtIndex:2] setTitle:SHORT_TOOLBAR_AUTHOR];
            [[[myToolBar items] objectAtIndex:4] setTitle:SHORT_TOOLBAR_ATCCODE];
            [[[myToolBar items] objectAtIndex:6] setTitle:SHORT_TOOLBAR_REGNR];
            [[[myToolBar items] objectAtIndex:8] setTitle:SHORT_TOOLBAR_SUBSTANCES];
            [[[myToolBar items] objectAtIndex:10] setTitle:SHORT_TOOLBAR_THERAPY];
            */
            
            // Hides tab bar
            [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
            
            // Displays tab bar
            [self showTabBarWithAnimation:YES];
            [myTableView layoutIfNeeded];
            self.myTableViewHeightConstraint.constant = 49;
        }
    }
    
    [self setBarButtonItemsWith:mCurrentSearchState];
}

- (void)viewDidUnload
{
    NSLog(@"%s", __FUNCTION__);
    
    [super viewDidUnload];
}

- (void) viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = NSLocalizedString(@"AmiKo", nil);
    
    // Add icon
    // self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"28-star-ye.png"]];
    UIButton *logoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoButton setImage:[UIImage imageNamed:@"desitin_icon_32x32.png"] forState:UIControlStateNormal];
    logoButton.frame = CGRectMake(0, 0, 32, 32);
    [logoButton addTarget:self action:@selector(myIconPressMethod:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *app_icon = [[UIBarButtonItem alloc] initWithCustomView:logoButton];
    /*
    UIBarButtonItem *app_icon = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"desitin_icon_32x32.png"]]];
    */
    self.navigationItem.leftBarButtonItem = app_icon;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // Add search bar as title view to navigation bar
        searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(-5.0, 0.0, 320.0, 44.0)];
        searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 310.0, 44.0)];
        // searchBarView.autoresizingMask = 0;
        searchField.delegate = self;
        [searchBarView addSubview:searchField];
        self.navigationItem.titleView = searchBarView;
    }
    
    mBarButtonItemName = [[NSMutableString alloc] initWithString:FULL_TOOLBAR_TITLE];
    
    // Add long press gesture recognizer to tableview
    UILongPressGestureRecognizer *mLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(myLongPressMethod:)];
    mLongPressRecognizer.minimumPressDuration = 1.5;    // [sec]
    mLongPressRecognizer.delegate = self;
    [self.myTableView addGestureRecognizer:mLongPressRecognizer];
    
    mDb = [[MLDBAdapter alloc] init];
    [mDb openDatabase];
    NSLog(@"Number of Records = %ld", (long)[mDb getNumRecords]);
    // NSLog(@"%@", NSLocalizedString(@"Paste", @""));
        
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
    
    // Set default database
    mUsedDatabase = kAips;
   
    // Set current search state
    mCurrentSearchState = kTitle;
}

- (IBAction) myIconPressMethod:(id)sender
{  
    if (rightViewController != nil && secondView != nil) {
        [rightViewController removeObserver:secondView forKeyPath:@"javaScript"];
    }
    
    // Load style sheet from file
    NSString *amikoReportFile = [[NSBundle mainBundle] pathForResource:@"amiko_report_de" ofType:@"html"];
    NSError *error = nil;
    NSString *amikoReport = [NSString stringWithContentsOfFile:amikoReportFile encoding:NSASCIIStringEncoding error:&error];

    NSLog(@"Error: %@", error);    
    if (amikoReport==nil)
        amikoReport = @"";
    
    if (secondView!=nil) {
        [secondView removeFromParentViewController];
        secondView = nil;
    }
    
    secondView = [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController" bundle:nil title:@"About" andParam:1];
    UIFont *font = [UIFont fontWithName:@"Arial" size:15];
    secondView.htmlStr = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>", font.fontName, (int)font.pointSize, amikoReport];
    
    // Class MLSecondViewController is now registered as an observer of class MLMenuViewController
    [rightViewController addObserver:secondView
                          forKeyPath:@"javaScript"
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:@"javaScriptChanged"];
    
    if (secondViewNavigationController!=nil) {
        [secondViewNavigationController removeFromParentViewController];
        secondViewNavigationController = nil;
    }
    secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondView];
    
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    revealController = self.revealViewController;
    [revealController setFrontViewController:secondViewNavigationController animated:YES];
    [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    
    report_memory();
}

- (void) myLongPressMethod:(UILongPressGestureRecognizer *)gesture
{
    CGPoint p = [gesture locationInView:self.myTableView];
    
    NSIndexPath *indexPath = [self.myTableView indexPathForRowAtPoint:p];

    if( mCurrentSearchState == kAtcCode) {
        if (indexPath != nil) {
            NSString *medSubTitle = [NSString stringWithString:[medi[indexPath.row] subTitle]];
            NSArray *mAtc = [medSubTitle componentsSeparatedByString:@" -"];
            [searchField setText:mAtc[0]];
        }
    }
}

- (void) genSearchResultsWith:(NSString *)searchQuery
{
    if (mCurrentSearchState == kTitle) {
        searchResults = [mDb searchTitle:searchQuery];
    }
    else if (mCurrentSearchState == kAuthor) {
        searchResults = [mDb searchAuthor:searchQuery];
    }
    else if (mCurrentSearchState == kAtcCode) {
        searchResults = [mDb searchATCCode:searchQuery];
    }
    else if (mCurrentSearchState == kRegNr) {
        searchResults = [mDb searchRegNr:searchQuery];
    }
    else if (mCurrentSearchState == kSubstances) {
        searchResults = [mDb searchIngredients:searchQuery];
    }
    else if (mCurrentSearchState == kTherapy) {
        searchResults = [mDb searchApplication:searchQuery];
    }
}

- (NSArray *) searchAipsDatabaseWith:(NSString *)searchQuery
{
    NSArray *searchRes = [NSArray array];
    
    NSDate *startTime = [NSDate date];

    if (mCurrentSearchState == kTitle) {
        searchRes = [mDb searchTitle:searchQuery];
    }
    else if (mCurrentSearchState == kAuthor) {
        searchRes = [mDb searchAuthor:searchQuery];
    }
    else if (mCurrentSearchState == kAtcCode) {
        searchRes = [mDb searchATCCode:searchQuery];
    }
    else if (mCurrentSearchState == kRegNr) {
        searchRes = [mDb searchRegNr:searchQuery];
    }
    else if (mCurrentSearchState == kSubstances) {
        searchRes = [mDb searchIngredients:searchQuery];
    }
    else if (mCurrentSearchState == kTherapy) {
        searchRes = [mDb searchApplication:searchQuery];
    }
    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
    
    timeForSearch_ms = (int)(1000*execTime+0.5);
    NSLog(@"%d Treffer in %dms", [searchRes count], timeForSearch_ms);

    return searchRes;
}

- (NSArray *) retrieveAllFavorites
{
    NSMutableArray *medList = [NSMutableArray array];

    NSDate *startTime = [NSDate date];
    
    for (NSString *regnrs in favoriteMedsSet) {
        NSArray *med = [mDb searchRegNr:regnrs];
        [medList addObject:med[0]];
    }
    
    NSDate *endTime = [NSDate date];
    NSTimeInterval execTime = [endTime timeIntervalSinceDate:startTime];
    
    NSLog(@"%d Favoriten in %dms", [medList count], (int)(1000*execTime+0.5));
    
    return medList;
}

- (void) switchTabBarItem: (UITabBarItem *)item
{
    static bool inProgress = false;
    
    NSLog(@"%s", __FUNCTION__);       
    
    switch (item.tag) {
        case 0:
        {
            NSLog(@"TabBar - Aips Database");
            mUsedDatabase = kAips;
            // Reset searchfield
            [self resetBarButtonItems];
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
                        [myTextField setText:[NSString stringWithFormat:@"%d Treffer in %dms", [searchResults count], timeForSearch_ms]];
                        inProgress = false;
                    });
                    //}
                }
            });
            break;
        }
        case 1:
        {
            if (mUsedDatabase!=kFavorites) {
                NSLog(@"TabBar - Favorite Database");
                mUsedDatabase = kFavorites;
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
                            [searchField resignFirstResponder];
                            [myTextField setText:[NSString stringWithFormat:@"%d Treffer in %dms", [searchResults count], timeForSearch_ms]];
                            inProgress = false;
                        });
                        //}
                    }
                });
            }
            break;
        }
        case 2:
            NSLog(@"TabBar - Settings");
            // TODO
            break;
        case 3:
            NSLog(@"TabBar - Developer Info");
            // TODO
            break;
        default:
            break;
    }
}

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{    
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
    
    [self performSelector:@selector(switchTabBarItem:) withObject:item afterDelay:0.01];
}

- (void) searchBar: (UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    static bool inProgress = false;

    int minSearchChars = 0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        minSearchChars = 0;
    
    // Causes searchResults to be released if there are no strong references to it.
    searchResults = [NSArray array];

    MLViewController* __weak weakSelf = self;
    
    dispatch_queue_t search_queue = dispatch_queue_create("com.ywesee.searchdb", nil);    
    dispatch_async(search_queue, ^(void) {
        MLViewController* scopeSelf = weakSelf;
        if (!inProgress) {
            inProgress = true;
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
                [myTextField setText:[NSString stringWithFormat:@"%d Treffer in %dms", [searchResults count], timeForSearch_ms]];
                inProgress = false;
            });
        }
    });
}


- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) addTitle: (NSString *)title andPackInfo: (NSString *)packinfo andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = @"k.A.";
    if (![packinfo isEqual:[NSNull null]]) {
        if ([packinfo length]>0)
            m.subTitle = packinfo;
        else
            m.subTitle = @"k.A.";
    } else
        m.subTitle = @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addTitle: (NSString *)title andPackInfo: (NSString *)packinfo andMedId: (long)medId
{
    if (![title isEqual:[NSNull null]])
        [titleData addObject:title];
    else
        [titleData addObject:@"k.A."];
    if (![packinfo isEqual:[NSNull null]]) {
        if ([packinfo length]>0)
            [subTitleData addObject:packinfo];    // [m packinfo]
        else
            [subTitleData addObject:@"k.A."];
    } else
        [subTitleData addObject:@"k.A."];
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
*/

- (void) addTitle: (NSString *)title andAuthor: (NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = @"k.A.";
    if (![author isEqual:[NSNull null]]) {
        if ([author length]>0)
            m.subTitle = author;
        else
            m.subTitle = @"k.A.";
    } else
        m.subTitle = @"k.A.";
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addTitle: (NSString *)title andAuthor: (NSString *)author andMedId: (long)medId
{
    if (![title isEqual:[NSNull null]])
        [titleData addObject:title];
    else
        [titleData addObject:@"k.A."];       
    if (![author isEqual:[NSNull null]]) {
        if ([author length]>0)
            [subTitleData addObject:author];        // [m auth]
        else
            [subTitleData addObject:@"k.A."];
    } else
        [subTitleData addObject:@"k.A."];
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
*/

- (void) addTitle: (NSString *)title andAtcCode: (NSString *)atccode andAtcClass: (NSString *)atcclass andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = @"k.A.";
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
    NSMutableString *m_atcclass = nil;
    if ([m_class count] == 2)
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:0]];
    else if ([m_class count] == 3)
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:1]];
    if ([m_atccode_str isEqual:[NSNull null]])
        [m_atccode_str setString:@"k.A."];
    if ([m_atcclass_str isEqual:[NSNull null]])
        [m_atcclass_str setString:@"k.A."];
    if ([m_atcclass isEqual:[NSNull null]])
        [m_atcclass setString:@"k.A."];
    m.subTitle = [NSString stringWithFormat:@"%@ - %@\n%@", m_atccode_str, m_atcclass_str, m_atcclass];
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addTitle: (NSString *)title andAtcCode: (NSString *)atccode andAtcClass: (NSString *)atcclass andMedId: (long)medId
{
    if (![title isEqual:[NSNull null]])
        [titleData addObject:title];
    else
        [titleData addObject:@"k.A."];        
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
    NSMutableString *m_atcclass = nil;
    if ([m_class count] == 2)
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:0]];
    else if ([m_class count] == 3)
        m_atcclass = [NSMutableString stringWithString:[m_class objectAtIndex:1]];
    if ([m_atccode_str isEqual:[NSNull null]])
        [m_atccode_str setString:@"k.A."];
    if ([m_atcclass_str isEqual:[NSNull null]])
        [m_atcclass_str setString:@"k.A."];
    if ([m_atcclass isEqual:[NSNull null]])
        [m_atcclass setString:@"k.A."];
    [subTitleData addObject:[NSString stringWithFormat:@"%@ - %@\n%@", m_atccode_str, m_atcclass_str, m_atcclass]]; // [m atccode] [m atcclass]
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
*/

- (void) addTitle: (NSString *)title andRegnrs: (NSString *)regnrs andAuthor: (NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = @"k.A.";
    NSMutableString *m_regnrs = [NSMutableString stringWithString:regnrs];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_regnrs isEqual:[NSNull null]])
        [m_regnrs setString:@"k.A."];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:@"k.A."];
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_regnrs, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addTitle: (NSString *)title andRegnrs: (NSString *)regnrs andAuthor: (NSString *)author andMedId: (long)medId
{
    if (![title isEqual:[NSNull null]])
        [titleData addObject:title];
    else
        [titleData addObject:@"k.A."];
    NSMutableString *m_regnrs = [NSMutableString stringWithString:regnrs];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_regnrs isEqual:[NSNull null]])
        [m_regnrs setString:@"k.A."];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:@"k.A."];
    [subTitleData addObject:[NSString stringWithFormat:@"%@ - %@", m_regnrs, m_auth]];      // [m regnrs] - [m auth]
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
 */

- (void) addSubstances: (NSString *)substances andTitle: (NSString *)title andAuthor: (NSString *)author andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![substances isEqual:[NSNull null]])
        m.title = substances;     // [m substances]
    else
        m.title = @"k.A.";
    NSMutableString *m_title = [NSMutableString stringWithString:title];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_title isEqual:[NSNull null]])
        [m_title setString:@"k.A."];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:@"k.A."];
    m.subTitle = [NSString stringWithFormat:@"%@ - %@", m_title, m_auth];
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addSubstances: (NSString *)substances andTitle: (NSString *)title andAuthor: (NSString *)author andMedId: (long)medId
{
    if (![substances isEqual:[NSNull null]])
        [titleData addObject:substances];     // [m substances]
    else
        [titleData addObject:@"k.A."];
    NSMutableString *m_title = [NSMutableString stringWithString:title];
    NSMutableString *m_auth = [NSMutableString stringWithString:author];
    if ([m_title isEqual:[NSNull null]])
        [m_title setString:@"k.A."];
    if ([m_auth isEqual:[NSNull null]])
        [m_auth setString:@"k.A."];
    [subTitleData addObject:[NSString stringWithFormat:@"%@ - %@", m_title, m_auth]];       // [m title] - [m auth]
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
 */

- (void) addTitle: (NSString *)title andApplications: (NSString *)applications andMedId: (long)medId
{
    DataObject *m = [[DataObject alloc] init];
    
    if (![title isEqual:[NSNull null]])
        m.title = title;
    else
        m.title = @"k.A.";
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
        [m_swissmedic setString:@"k.A."];
    if ([m_bag isEqual:[NSNull null]])
        [m_bag setString:@"k.A."];
    m.subTitle = [NSString stringWithFormat:@"%@\n%@", m_swissmedic, m_bag];
    m.medId = medId;
    
    [medi addObject:m];
}

/*
- (void) addTitle: (NSString *)title andApplications: (NSString *)applications andMedId: (long)medId
{
    if (![title isEqual:[NSNull null]])
        [titleData addObject:title];
    else
        [titleData addObject:@"k.A."];
    if (![applications isEqual:[NSNull null]]) {
        if ([applications length]>0)
            [subTitleData addObject:applications]; // [m application]
        else
            [subTitleData addObject:@"k.A."];
    } else
        [subTitleData addObject:@"k.A."];
    [medIdArray addObject:[NSNumber numberWithLong:medId]];
}
 */

- (void) updateTableView
{
    if (searchResults) {
        
        /*
        if (titleData != nil)
            [titleData removeAllObjects];
        if (subTitleData != nil)
            [subTitleData removeAllObjects];
        if (medIdArray != nil)
            [medIdArray removeAllObjects];
        */
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
        else if (mCurrentSearchState == kSubstances) {
            for (MLMedication *m in searchResults) {
                if (mUsedDatabase == kAips) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        [favoriteKeyData addObject:m.regnrs];   
                        [self addSubstances:m.substances andTitle:m.title andAuthor:m.auth andMedId:m.medId];
                    }
                }
                else if (mUsedDatabase == kFavorites) {
                    if (![m.regnrs isEqual:[NSNull null]]) {
                        if ([favoriteMedsSet containsObject:m.regnrs]) {
                            [favoriteKeyData addObject:m.regnrs];
                            [self addSubstances:m.substances andTitle:m.title andAuthor:m.auth andMedId:m.medId];
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
    
    [mActivityIndicator stopAnimating];
    [mActivityIndicator removeFromSuperview];
}

/** Dismisses the keyboard, resigns text field's active state
 */
- (BOOL) textFieldShouldReturn: (UITextField *)textField
{
    NSLog(@"You entered %@", self.myTextField.text);
    [myTextField resignFirstResponder];
    
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    int count = [myTextField.text length];
    NSLog(@"Number of characters = %d", count);
    
    return YES;
}

- (void) buttonPressed
{
    // TODO
}

/** UITableViewDataSource
 */
- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
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

/** UITableViewDelegate
 */
- (UITableViewCell *) tableView: (UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    // What to display in row n?
    // static NSString *simpleTableIdentifier = @"SimpleTableItem";
    // UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    static NSString *simpleTableIdentifier = @"MLSimpleCell";
    MLSimpleTableCell *cell = (MLSimpleTableCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
   
    if (cell == nil) {
        cell = [[MLSimpleTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
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
    cell.detailTextLabel.textColor = [UIColor grayColor];
    // [cell.detailTextLabel sizeToFit];
    
    return cell;
}

- (void) myTapMethod: (id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    NSString *medRegnrs = [NSString stringWithString:[favoriteKeyData objectAtIndex:gesture.view.tag]];
    
    if ([favoriteMedsSet containsObject:medRegnrs])
        [favoriteMedsSet removeObject:medRegnrs];
    else
        [favoriteMedsSet addObject:medRegnrs];
    
    favoriteData = [MLDataStore initWithFavMedsSet:favoriteMedsSet];
    [self saveData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:gesture.view.tag inSection:0];
    NSArray *indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];

    // Update TableView
    [myTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    long mId = [medi[indexPath.row] medId];  // [[medIdArray objectAtIndex:row] longValue];
    
    if (rightViewController != nil && secondView != nil) {
        [rightViewController removeObserver:secondView forKeyPath:@"javaScript"];
    }
    MLMedication *med = [mDb searchId:mId];
    
    // Load style sheet from file
    NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
    NSString *amikoCss = nil;
    if (amikoCssPath)
        amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
    else
        amikoCss = [NSString stringWithString:med.styleStr];
    
    if (secondView!=nil) {
        [secondView removeFromParentViewController];
        secondView = nil;
    }
    secondView = [[MLSecondViewController alloc] initWithNibName:@"MLSecondViewController" bundle:nil title:@"Fachinformation" andParam:2];
    secondView.htmlStr = [NSString stringWithFormat:@"<head><style>%@</style></head>%@", amikoCss, med.contentStr];
    
    // Extract section ids
    NSArray *listofSectionIds = [med.sectionIds componentsSeparatedByString:@","];
    // Extract section titles
    NSArray *listofSectionTitles = [med.sectionTitles componentsSeparatedByString:@";"];
    
    if (rightViewController!=nil) {
        [rightViewController removeFromParentViewController];
        rightViewController = nil;
    }
    rightViewController = [[MLMenuViewController alloc] initWithMenu:listofSectionTitles andSectionIds:listofSectionIds];
    
    // Grab a handle to the reveal controller, as if you'd do with a navigation controller via self.navigationController.
    revealController = self.revealViewController;
    revealController.rightViewController = rightViewController;
    
    // Class MLSecondViewController is now registered as an observer of class MLMenuViewController
    [rightViewController addObserver:secondView
                          forKeyPath:@"javaScript"
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:@"javaScriptChanged"];
    
    if (secondViewNavigationController!=nil) {
        [secondViewNavigationController removeFromParentViewController];
        secondViewNavigationController = nil;
    }
    secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondView];
    
    // UINavigationController *secondViewNavigationController = [[UINavigationController alloc] initWithRootViewController:secondView];
    
    [revealController setFrontViewController:secondViewNavigationController animated:YES];
    
    // Show SecondViewController! (UIWebView)
    [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];

    report_memory();
    
    /*
    // TODO!!!
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // revealController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        // revealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPad;
     
        // At this point we simply set the front view controller of our revealController to the next revealController
        [revealController setFrontViewController:secondViewNavigationController animated:YES];

        // Show SecondViewController! (UIWebView)
        [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // revealController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPhone;
        // revealController.rightViewRevealWidth = RightViewRevealWidth_Portrait_iPhone;    // Check also MLMenuViewController.m
        
        [revealController setFrontViewController:secondViewNavigationController animated:YES];
        // Show SecondViewController! (UIWebView)
        [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    }
    */
}

#define PADDING_IPAD 50.0f
#define PADDING_IPHONE 40.0f
- (CGFloat) tableView: (UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
    NSString *text = [medi[indexPath.row] title]; // [titleData objectAtIndex:indexPath.row];
    NSString *subText = [medi[indexPath.row] subTitle]; // [subTitleData objectAtIndex:indexPath.row];
    CGSize textSize, subTextSize;
    CGFloat retVal = 0;
    
    float frameWidth = self.myTableView.frame.size.width;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:16.0f] constrainedToSize:CGSizeMake(frameWidth - PADDING_IPAD, CGFLOAT_MAX)];
        subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(frameWidth - 1.2*PADDING_IPAD, CGFLOAT_MAX)];
        retVal = textSize.height + subTextSize.height + PADDING_IPAD * 0.25f;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (frameWidth>500) {
            textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:13.0f] constrainedToSize:CGSizeMake(frameWidth - PADDING_IPHONE, CGFLOAT_MAX)];
            subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:12.0f] constrainedToSize:CGSizeMake(frameWidth - 1.5*PADDING_IPHONE, CGFLOAT_MAX)];
        } else {
            textSize = [text sizeWithFont:[UIFont boldSystemFontOfSize:13.0f] constrainedToSize:CGSizeMake(frameWidth - PADDING_IPHONE, CGFLOAT_MAX)];
            subTextSize = [subText sizeWithFont:[UIFont systemFontOfSize:12.0f] constrainedToSize:CGSizeMake(frameWidth - 1.4*PADDING_IPHONE, CGFLOAT_MAX)];
        }
        retVal = textSize.height + subTextSize.height + PADDING_IPHONE * 0.4f;
    }
    return retVal;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

void report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %u", info.resident_size);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}
@end
