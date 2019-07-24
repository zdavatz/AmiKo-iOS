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

@import UIKit;
#import "MLMedication.h"

//#define FIX_ISSUE_38

enum {
    eAips=0,
    eFavorites=1,
    eInteractions=2,
    eDesitin=3,
    ePrescription=4
};

/**
 UITableViewDelegate -> deals with the appearance of UITableView, manages height of table row, configure section headings and footers, ...
 UITableViewDataSource -> link between data and table view, two required methods: cellForRowAtIndexPath: and numberOfRowsInSection:
*/

@interface MLViewController : UIViewController <UISearchBarDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSArray *_pickerData;

    IBOutlet UISearchBar *searchField;
    IBOutlet UITextField *myTextField;
    IBOutlet UILabel *myLabel;
    IBOutlet UIButton *myButton;
    IBOutlet UITableView *myTableView;
    IBOutlet UITabBar *myTabBar;    // bottom of the screen
    IBOutlet UIToolbar *myToolBar;  // top of the screen
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchField;
@property (nonatomic, retain) IBOutlet UITextField *myTextField;
@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) IBOutlet UITabBar *myTabBar;
@property (nonatomic, retain) IBOutlet UIToolbar *myToolBar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *myTableViewHeightConstraint;  // Unused ?

@property (nonatomic, retain) UIAlertController *pickerSheet;
@property (nonatomic, retain) UIPickerView *pickerView;


- (instancetype) initWithLaunchState:(int)state;
- (void) setLaunchState:(int)state;

- (IBAction) searchAction: (id)sender;
- (IBAction) onToolBarButtonPressed: (id)sender;
- (void) myLongPressMethod:(UILongPressGestureRecognizer *)gesture;

- (void) switchToAipsView :(long int)mId;
- (void) switchFrontToPatientEditView;
- (void) switchToPatientEditView :(BOOL)animated;
- (void) switchToDoctorEditView;
- (void) switchToFullTextView :(NSString *)hashId;
- (void) showReport:(id)sender;
- (void) switchToDrugInteractionViewFromPrescription: (NSMutableDictionary *)medBasket;
- (void) switchToDrugInteractionView;
- (void) switchToPrescriptionView;

- (void) switchTabBarItem: (UITabBarItem *)item;

- (void) patientDbListDidChangeSelection:(NSNotification *)aNotification;
- (void) executeSearch:(NSString *)searchText;
- (void) addMedicineToPrescription:(MLMedication *)medication :(NSInteger)packageIndex;

@end
