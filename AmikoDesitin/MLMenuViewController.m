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

#import "MLMenuViewController.h"

#import "SWRevealViewController.h"

// Class extension
@interface MLMenuViewController ()
    // Stuff goes here, e.g. method declarations
@end

static NSString *SectionTitle_DE[] = {@"Zusammensetzung", @"Galenische Form", @"Indikationen", @"Dosierung/Anwendung", @"Kontraindikationen", @"Vorsichtsmassnahmen", @"Interaktionen", @"Schwangerschaft", @"Fahrtüchtigkeit", @"Unerwünschte Wirk.", @"Überdosierung", @"Eig./Wirkung", @"Kinetik", @"Präklinik", @"Sonstige Hinweise", @"Zulassungsnummer", @"Packungen", @"Inhaberin", @"Stand der Information", nil};

static NSString *SectionTitle_FR[] = {@"Composition", @"Forme galènique", @"Indications", @"Posologie", @"Contre-indic.", @"Prècautions", @"Interactions", @"Grossesse/All.", @"Conduite", @"Effets indèsir.",	@"Surdosage", @"Propriètes/Effets", @"Cinètique", @"Prèclinique", @"Remarques", @"Prèsentation", @"Titulaire", @"Mise à jour"};


@implementation MLMenuViewController
{
    // iVars
    NSMutableArray *mSectionTitles;
    NSMutableArray *mSectionIds;
}

@synthesize myMenuView;
@synthesize javaScript;

- (id) initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil withMenu: (NSArray *)sectionTitles
{
    self = [super init];
    
    return self;
}

- (id) initWithMenu: (NSArray *)sectionTitles andSectionIds: (NSArray *)sectionIds
{
    self = [super init];
    
    if (self) {
        mSectionTitles = [[NSMutableArray alloc] init];
        // Load abbreviations for section titles
        for (NSString *title in sectionTitles) {
            [mSectionTitles addObject:title];
        }
        mSectionIds = [[NSMutableArray alloc] init];
        for (NSString *identifier in sectionIds) {
            [mSectionIds addObject:identifier];
        }
    }
    
    
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Kapitel", nil);
    
    // Note: iOS7
    if (IOS_NEWER_OR_EQUAL_TO_7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
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

#pragma mark - Table view data source

/** UITableViewDataSource
 */
- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section
{
    // Return the number of rows in the section.
    return ([mSectionTitles count] - 1);
}

#pragma mark - Table view delegate

/** UITableViewDelegate
 */
- (UITableViewCell *) tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    }

    /** Use subview */
    UILabel *subLabel = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,230,44)];
        [subLabel setFont:[UIFont systemFontOfSize:14]];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,230,28)];
        [subLabel setFont:[UIFont systemFontOfSize:12]];
    }
    subLabel.textAlignment = NSTextAlignmentRight;
    
    // Use short form if possible, i.e. more than 5 letters match!
    for (int i=0; i<20; i++) {
        NSString *originalString = mSectionTitles[indexPath.row];
        NSString *compareString = SectionTitle_DE[i];
        if (originalString!=nil && compareString!=nil) {
            if ([originalString rangeOfString:compareString].location != NSNotFound) {
                mSectionTitles[indexPath.row] = SectionTitle_DE[i];
            }
        }
    }
    
    subLabel.text = [mSectionTitles objectAtIndex:indexPath.row];
    [cell.contentView addSubview:subLabel];
    
    return cell;
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{    
    self.javaScript = [NSString stringWithFormat:@"window.location.hash='#%@'", mSectionIds[indexPath.row]];
    // NSLog(@"%s: Javascript = %@", __FUNCTION__, self.javaScript);
    
    // Grab a handle to the reveal controller
    SWRevealViewController *revealController = self.revealViewController;
    
    [revealController rightRevealToggleAnimated:YES];
}

@end
