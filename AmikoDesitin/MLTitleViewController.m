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

#import "MLTitleViewController.h"

#import "SWRevealViewController.h"

// Class extension
@interface MLTitleViewController ()
    // Stuff goes here, e.g. method declarations
@end

static NSString *SectionTitle_DE[] = {@"Zusammensetzung", @"Galenische Form", @"Kontraindikationen", @"Indikationen", @"Dosierung/Anwendung", @"Vorsichtsmassnahmen", @"Interaktionen", @"Schwangerschaft", @"Fahrtüchtigkeit", @"Unerwünschte Wirk.", @"Überdosierung", @"Eig./Wirkung", @"Kinetik", @"Präklinik", @"Sonstige Hinweise", @"Zulassungsnummer", @"Packungen", @"Inhaberin", @"Stand der Information", nil};

static NSString *SectionTitle_FR[] = {@"Composition", @"Forme galénique", @"Contre-indications", @"Indications", @"Posologie", @"Précautions", @"Interactions", @"Grossesse/All.", @"Conduite", @"Effets indésir.", @"Surdosage", @"Propriétés/Effets", @"Cinétique", @"Préclinique", @"Remarques", @"Numéro d'autorisation", @"Présentation", @"Titulaire", @"Mise à jour", nil};


@implementation MLTitleViewController
{
    // iVars
    NSMutableArray *mSectionTitles;
    NSMutableArray *mSectionIds;
    NSString *mAppLanguage;     // For section titles
}

@synthesize myMenuView;
@synthesize javaScript;

- (instancetype) initWithNibName: (NSString *)nibNameOrNil
                          bundle: (NSBundle *)nibBundleOrNil
                        withMenu: (NSArray *)sectionTitles
{
    self = [super init];
    return self;
}

- (instancetype) initWithMenu: (NSArray *)sectionTitles
                   sectionIds: (NSArray *)sectionIds
                  andLanguage: (NSString *)appLanguage
{
    self = [super init];
    if (self) {
        mSectionTitles = [NSMutableArray new];
        for (NSString *title in sectionTitles) {
            [mSectionTitles addObject:title];
        }

        mSectionIds = [NSMutableArray new];
        for (NSString *identifier in sectionIds) {
            [mSectionIds addObject:identifier];
        }

        mAppLanguage = appLanguage;
    }
    
    // [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    // Restore default in case it was changed
    self.revealViewController.rightViewRevealOverdraw = 60.0;
}

- (void) setSectionTitles:(NSArray *)titles andIds:(NSArray *)ids
{
    mSectionTitles = [NSMutableArray new];
    for (NSString *title in titles) {
        [mSectionTitles addObject:title];
    }
    mSectionIds = [NSMutableArray new];
    for (NSString *identifier in ids) {
        [mSectionIds addObject:identifier];
    }
    [myMenuView reloadData];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Chapter", nil);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    myMenuView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // NSLog(@"# %s", __FUNCTION__);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Table view data source

/** UITableViewDataSource
 */
- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
    // Return the number of rows in the section.
    return ([mSectionTitles count]);
}

#pragma mark - Table view delegate

/** UITableViewDelegate
 */
- (UITableViewCell *) tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:cellIdentifier];
        // cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textAlignment = NSTextAlignmentRight;

        /** Use subview */
        UILabel *subLabel = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,230,36)];
            [subLabel setFont:[UIFont systemFontOfSize:14]];
        }
        else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,230,28)];
            [subLabel setFont:[UIFont systemFontOfSize:12]];
        }
        subLabel.textAlignment = NSTextAlignmentRight;
        
        // subLabel.text = [mSectionTitles objectAtIndex:indexPath.row];
        subLabel.tag = 123; // Constant which uniquely defines the label
        [cell.contentView addSubview:subLabel];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:123];
    
    // Use short form if possible, i.e. more than 5 letters match!
    if ([mAppLanguage isEqualToString:@"de"]) {
        for (int i=0; i<20; i++) {
            NSString *originalString = [mSectionTitles[indexPath.row] lowercaseString];
            NSString *compareString = [SectionTitle_DE[i] lowercaseString];
            if (originalString!=nil && compareString!=nil) {
                if ([originalString rangeOfString:compareString].location != NSNotFound) {
                    mSectionTitles[indexPath.row] = SectionTitle_DE[i];
                    break;
                }
            }
        }
    }
    else if ([mAppLanguage isEqualToString:@"fr"]) {
        for (int i=0; i<20; i++) {
            NSString *originalString = [mSectionTitles[indexPath.row] lowercaseString];
            NSString *compareString = [SectionTitle_FR[i] lowercaseString];
            if (originalString!=nil && compareString!=nil) {
                if ([originalString rangeOfString:compareString].location != NSNotFound) {
                    mSectionTitles[indexPath.row] = SectionTitle_FR[i];
                    break;
                }
            }
        }
    }

    label.text = mSectionTitles[indexPath.row];
    if ([label.text length]>23)
        label.text = [label.text substringToIndex:23];
    
    return cell;
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"%s line %d", __FUNCTION__, __LINE__);
#endif
    // self.javaScript = [NSString stringWithFormat:@"window.location.hash='#%@'", mSectionIds[indexPath.row]];
    self.javaScript = [NSString stringWithFormat:@"var hashElement=document.getElementById('%@');if(hashElement) {hashElement.scrollIntoView();}", mSectionIds[indexPath.row]];
    
    // NSLog(@"%s: Javascript = %@", __FUNCTION__, self.javaScript);
    
    // Grab a handle to the reveal controller
    SWRevealViewController *revealController = self.revealViewController;
    
    [revealController rightRevealToggleAnimated:YES];
}

@end
