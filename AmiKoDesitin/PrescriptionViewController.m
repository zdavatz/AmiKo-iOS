//
//  PrescriptionViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "PrescriptionViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"

#import "MLViewController.h"
#import "MLAppDelegate.h"
#import "AmkListViewController.h"
#import "PatientDBAdapter.h"
#import "PatientViewController.h"

#ifdef DEBUG
//#define DEBUG_COLOR_BG
#endif

static const float kInfoCellHeight = 20.0;  // fixed

static const float kSectionHeaderHeight = 27.0;

// Medicine cell layout
static const float kLabelVerMargin = 2.4;
static const float kMedCellHorMargin = 12.0;
static const float kMedCellVerMargin = 8.0;
static const float kMedCellHeight = 44.0;  // minimum height

enum {
    kSectionMeta=0,
    kSectionOperator,
    kSectionPatient,
    kSectionMedicines,

    kNumSections
};

CGSize getSizeOfLabel(UILabel *label, CGFloat width)
{
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundSize = [label.text boundingRectWithSize:constraint
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:label.font}
                                                context:context].size;
    return CGSizeMake(ceil(boundSize.width), ceil(boundSize.height));
}

//#pragma mark -
//@interface ItemProvider : UIActivityItemProvider
//
//@property (nonatomic, strong) NSURL *filepath;
//@property (nonatomic, strong) NSString *emailBody;
//@property (nonatomic, strong) NSString *emailSubject;
//
//@end
//
//@implementation ItemProvider
//
//- (id)initWithPlaceholderItem:(id)placeholderItem
//{
//    //Initializes and returns a provider object with the specified placeholder data
//    return [super initWithPlaceholderItem:placeholderItem];
//}
//
//- (id)item
//{
//    //Generates and returns the actual data object
//    return [NSDictionary dictionary];
//}
//@end

#pragma mark -

@interface PrescriptionViewController ()
{
    UITextView *activeTextView;
    CGPoint savedOffset;
    CGFloat savedKeyboardY;
    bool commentEditingActive;
    NSURL *lastUsedURL;
}

- (IBAction)btnClickedDone:(id)sender;

- (void)layoutCellSeparator:(UITableViewCell *)cell;
- (void)layoutFrames;
- (void)loadDefaultDoctor;
- (BOOL)loadDefaultPrescription;
- (BOOL)loadDefaultPatient;

- (void) updateButtons;
- (void) saveButtonOn;
- (void) saveButtonOff;
- (void) recalculateSavedOffset;
- (void) updateMainframeRect;
- (void) showCameraForHealthCardOCR;
- (void) showCameraForBarcodeAcquisition;
@end

#pragma mark -

@implementation PrescriptionViewController
{
    CGRect mainFrame;
    bool possibleToOverwrite;
    NSInteger editingCommentIdx;
}

@synthesize prescription;
@synthesize infoView;
@synthesize editedMedicines;

+ (PrescriptionViewController *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
    });
    
    return sharedObject;
}

- (void)layoutFrames
{
    [self updateMainframeRect];

#if 0
    CGRect infoFrame = self.infoView.frame;
    infoFrame.origin.y = 0.6;
    infoFrame.size.width = self.view.bounds.size.width;

    infoFrame.size.height = ((kSectionHeaderHeight * 2) +
                             (kInfoCellHeight * [prescription.doctor entriesCount]) +
                             (kInfoCellHeight * [prescription.patient entriesCount]) +
                             20.8); // margin
    
    NSLog(@"%s %d, infoFrame:%@", __FUNCTION__, __LINE__, NSStringFromCGRect(infoFrame));
    

    CGFloat height = 0.0;
    for (int i = 0; i < [prescription.medications count]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i
                                                    inSection:kSectionMedicines];
        CGFloat rowHeight = [self tableView:infoView heightForRowAtIndexPath:indexPath];
        height += rowHeight;
    }

    CGFloat defaultHeight = kMedCellHeight * [prescription.medications count];
    if (defaultHeight > height) {
        height = defaultHeight;
    }

    CGRect itemFrame = CGRectMake(0,
                                  CGRectGetMaxY(infoFrame) + 8.0,
                                  self.view.bounds.size.width,
                                  (kSectionHeaderHeight + height));

    infoFrame.size.height += itemFrame.size.height;

    [self.infoView setFrame:infoFrame];
    [self.view layoutIfNeeded];
#endif
}

- (void)layoutCellSeparator:(UITableViewCell *)cell
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        cell.separatorInset = UIEdgeInsetsZero;
    }

    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        cell.preservesSuperviewLayoutMargins = NO;
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateMainframeRect
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    int navBarHeight = self.navigationController.navigationBar.frame.size.height;
    int barHeight = statusBarHeight + navBarHeight;
    mainFrame = CGRectMake(0, barHeight,
                           screenBounds.size.width,
                           CGRectGetHeight(screenBounds) - barHeight);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    SWRevealViewController *revealController = [self revealViewController];

    // Left button(s)
    UIBarButtonItem *revealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
#if 1
    // A single button on the left
    self.navigationItem.leftBarButtonItem = revealButtonItem;
#else
    // Two buttons on the left (with spacer between them)
    UIBarButtonItem *patientsItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Search Patients", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(showPatientDbList:)];

    UIBarButtonItem *spacer =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    spacer.width = 90.0f;

    self.navigationItem.leftBarButtonItems =
        [NSArray arrayWithObjects:revealButtonItem, spacer, patientsItem, nil];
#endif
    
#if 1
    // Middle button
    CGRect frame = CGRectMake(0, 0, 200, 44);
    UIButton* myButton = [[UIButton alloc] initWithFrame:frame];
    [myButton setTitle:NSLocalizedString(@"Search Patients", nil) forState:UIControlStateNormal];
    
    CGSize stringSize = [myButton.titleLabel.text sizeWithFont:myButton.titleLabel.font];
    CGRect frame2 = myButton.frame;
    frame2.size = stringSize;
    [myButton setFrame:frame2];
    
    [myButton setTitleColor:MAIN_TINT_COLOR forState:UIControlStateNormal];
    [myButton addTarget:self action:@selector(showPatientDbList:) forControlEvents:UIControlEventTouchDown];
    //myButton.backgroundColor = [UIColor grayColor];
    self.navigationItem.titleView = myButton;
#endif

    // Right button
#if 1
    // First ensure the "right" is a ContactsListViewController
    id aTarget = self;
    SEL aSelector = @selector(myRightRevealToggle:);
#else
    id aTarget = revealController;
    SEL aSelector = @selector(rightRevealToggle:);
#endif

    UIBarButtonItem *rightRevealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                     style:UIBarButtonItemStylePlain
                                    target:aTarget
                                    action:aSelector];
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;

    [self updateMainframeRect];
    
    if (!prescription)
        prescription = [[Prescription alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(amkListDidChangeSelection:)
                                                 name:@"AmkFilenameSelectedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(amkDeleted:)
                                                 name:@"AmkFilenameDeletedNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(patientDbListDidChangeSelection:)
                                                 name:@"PatientSelectedNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    self.editedMedicines = false;
    possibleToOverwrite = false;
    editingCommentIdx = -1;
    lastUsedURL = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Make sure we have a reveal gesture recognizer (only for "front" controllers)

    bool found = false;
    for (id gr in self.view.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]] ) { // SWRevealViewController
            found = true;
            break;
        }
    }
    
    if (!found)
        [self.view addGestureRecognizer:[self revealViewController].panGestureRecognizer];
}

- (void) viewDidAppear:(BOOL)animated
{
    if (editedMedicines) {
#ifdef DEBUG
        //NSLog(@"%s %d", __FUNCTION__, __LINE__);
#endif
        [self loadDefaultDoctor];
    }
    else {
#ifdef DEBUG
        //NSLog(@"%s %d", __FUNCTION__, __LINE__);
#endif
        // do the following only if we haven't added any medicines yet
        if (![self loadDefaultPrescription]) {
            [self loadDefaultDoctor];
            [self loadDefaultPatient];
        }
    }
    
    [self updateButtons];
    [infoView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)didRotate:(NSNotification *)notification
{
    [self layoutFrames];
    
    [self.infoView performSelectorOnMainThread:@selector(reloadData)
                                    withObject:nil
                                 waitUntilDone:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(
                                              id<UIViewControllerTransitionCoordinatorContext> context) {
        // willRotateToInterfaceOrientation
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // didRotateFromInterfaceOrientation would go here.
        [self didRotate:nil];
    }];
}

#pragma mark -

- (NSString *) makeNewUniqueHash
{
    // Creates and returns a new UUID with RFC 4122 version 4 random bytes
    return [[NSUUID UUID] UUIDString];
}

#pragma mark -

- (BOOL) checkDefaultDoctor
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *doctorDictionary = [defaults dictionaryForKey:@"currentDoctor"];
    if (doctorDictionary)
        return TRUE;
    
#ifdef DEBUG
    NSLog(@"Default doctor is not defined");
#endif
    return FALSE;
}

- (void) loadDefaultDoctor
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
#if 0
    if ([self checkDefaultDoctor])
        return;
#else
    // Init from defaults
    // See also Operator importFromDict
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *doctorDictionary = [defaults dictionaryForKey:@"currentDoctor"];
    if (!doctorDictionary) {
  #ifdef DEBUG
        NSLog(@"Default doctor is not yet defined");
  #endif

        // Maybe there was a doctor imported from an AMK,
        // but it's not the default doctor, so clear it.
        if (prescription.doctor)
            self.prescription.doctor = nil;

        return;
    }
#endif
    
#ifdef DEBUG
    //NSLog(@"Default doctor %@", doctorDictionary);
#endif
    if (!prescription.doctor)
        self.prescription.doctor = [[Operator alloc] init];
    
    [prescription.doctor importFromDict:doctorDictionary];
    [prescription.doctor importSignatureFromFile];
}

// Try to reopen the last used file
- (BOOL)loadDefaultPrescription
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    // Try to reopen the last used file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fileName = [defaults stringForKey:@"lastUsedPrescription"];
    if (!fileName) {
        NSLog(@"%s %d Default prescription not yet defined", __FUNCTION__, __LINE__);
        return FALSE;
    }
    
    NSString *fullFilePath = [[MLUtility amkDirectory] stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
        [defaults removeObjectForKey:@"lastUsedPrescription"];
        [defaults synchronize];
        NSLog(@"%s %d", __FUNCTION__, __LINE__);
        return FALSE;
    }

    NSURL *url = [NSURL fileURLWithPath:fullFilePath];
    [prescription importFromURL:url];
    possibleToOverwrite = true;
    NSLog(@"Reopened:%@", fileName);
    return TRUE;
}

- (BOOL)loadDefaultPatient
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *patientId = [defaults stringForKey:@"currentPatient"];
    if (!patientId) {
#ifdef DEBUG
        NSLog(@"Default patient is not yet defined");
#endif
        return FALSE;
    }
    
    PatientDBAdapter *patientDb = [[PatientDBAdapter alloc] init];
    if (![patientDb openDatabase:@"patient_db"]) {
        NSLog(@"Could not open patient DB!");
        return FALSE;
    }

    Patient *pat = [patientDb getPatientWithUniqueID:patientId];
    [prescription setPatient:pat];
    [patientDb closeDatabase];
    return TRUE;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumSections;
}

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    if (section == kSectionMeta)
        return 1;

    if (section == kSectionOperator)
    {
        if (prescription.doctor)
            return [prescription.doctor entriesCount];
        else
            return 1; // just a warning message
    }
    
    if ((section == kSectionPatient) && (prescription.patient != nil))
        return [prescription.patient entriesCount];
    
    if (section == kSectionMedicines)
        return [prescription.medications count];
    
    return 0;
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // set height by section
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 0);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    
    CGFloat leftMargin = 0.0;
    if (@available(iOS 11, *))
        leftMargin = self.view.safeAreaInsets.left;

    CGRect labelFrame = CGRectMake(leftMargin+kMedCellHorMargin, 2, 200, kSectionHeaderHeight-2);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightLight];
    label.textColor = [UIColor darkGrayColor];
    frame.size.height = kSectionHeaderHeight-2;
    
    if (section == kSectionMeta) {
        frame.size.height = 0;
        label.text = @"";
    }
    else if (section == kSectionOperator)
        label.text = NSLocalizedString(@"Doctor", nil);
    else if (section == kSectionPatient)
        label.text = NSLocalizedString(@"Patient", nil);
    else if (section == kSectionMedicines) {
        NSString *format;
        NSInteger count = [prescription.medications count];
        if (count == 1)
            format = NSLocalizedString(@"Medicine", nil);
        else
            format = NSLocalizedString(@"Medicines", nil);

        label.text = [NSString stringWithFormat:@"%@ (%lu)", format, count];
        [view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    }

    [view addSubview:label];

    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // default value: UITableViewAutomaticDimension;
    if (section == kSectionMeta)
        return kSectionHeaderHeight / 2.5;
    
    // operator|patient
    return kSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ((indexPath.section == kSectionOperator) && (indexPath.row == 0))
//        return DOCTOR_TN_H;

    if (indexPath.section != kSectionMedicines)
        return kInfoCellHeight;

    if (prescription.medications==nil)
        return kInfoCellHeight;

    Product *med = prescription.medications[indexPath.row];
    if (med==nil)
        return kMedCellHeight;

    CGFloat height = 0.0;
    CGFloat width = tableView.frame.size.width - 24.0; // TODO

    // package name label
    UILabel *packLabel = [self makeLabel:med.packageInfo
                               textColor:[UIColor clearColor]];
    height += getSizeOfLabel(packLabel, width).height;
    height += kLabelVerMargin;

    // ean label
    UILabel *eanLabel = [self makeLabel:med.eanCode
                              textColor:[UIColor clearColor]];
    height += getSizeOfLabel(eanLabel, width).height;
    height += kLabelVerMargin;
    height += kMedCellVerMargin;

    // comment label
    UILabel *commentLabel = [self makeLabel:med.comment
                                  textColor:[UIColor clearColor]];
    height += getSizeOfLabel(commentLabel, width).height;
    height += kLabelVerMargin;
    height += kMedCellVerMargin;
    
    return MAX(kMedCellHeight,height);
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
{
    [self layoutCellSeparator:cell];
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
//    NSLog(@"%s section:%ld, row:%ld", __FUNCTION__, indexPath.section, indexPath.row);
//    NSLog(@"Line %d, tableView size: %@", __LINE__, NSStringFromCGSize(tableView.frame.size));
//    NSLog(@"Line %d, contentInset: %@", __LINE__, NSStringFromUIEdgeInsets(tableView.contentInset));
//    //NSLog(@"Line %d, safeAreaInsets TLBR: %@", __LINE__, NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
//    NSLog(@"Line %d, contentSize: %@", __LINE__, NSStringFromCGSize(tableView.contentSize));
#endif
#ifdef DEBUG_COLOR_BG
    self.view.backgroundColor = [UIColor blueColor];
#endif

    static NSString *tableIdentifier = @"PrescriptionTableItem";
    UITableViewCell *cell;
#if 0
    cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (cell == nil)
#endif
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    }
    
    if (indexPath.section != kSectionMedicines)
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    CGRect frame = CGRectMake(12.0, 0, tableView.frame.size.width, 25.0);  // TODO: remove magic numbers
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    if (indexPath.section == kSectionMeta) {
        label.font = [UIFont systemFontOfSize:13.8];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = prescription.placeDate;
    }
    else if (indexPath.section == kSectionOperator) {
        if (!prescription.doctor) {
            label.font = [UIFont systemFontOfSize:13.0];
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = MAIN_TINT_COLOR;
            label.backgroundColor = [UIColor clearColor];
            label.text = NSLocalizedString(@"Please add doctor's address", nil);
            
            label.preferredMaxLayoutWidth = frame.size.width;
            [label sizeToFit];
            [cell.contentView addSubview:label];
            return cell;
        }

        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"";  // Initialize for appending
#ifdef DEBUG_COLOR_BG
        cell.backgroundColor = [UIColor greenColor];
#else
        cell.backgroundColor = [UIColor clearColor];  // Allow the signature to show over multiple cells
#endif
        switch (indexPath.row) {
            case 0:
                if ([prescription.doctor.title isEqualToString:@""]) {
                    label.text = [NSString stringWithFormat:@"%@ %@",
                                  prescription.doctor.familyName,
                                  prescription.doctor.givenName];
                }
                else {
                    label.text = [NSString stringWithFormat:@"%@ %@ %@",
                                  prescription.doctor.title,
                                  prescription.doctor.familyName,
                                  prescription.doctor.givenName];
                }

                if (([prescription.doctor signature] != nil) &&
                    ![prescription.doctor.signature isEqualToString:@""])
                {
                    UIImage *img = [prescription.doctor thumbnailFromSignature:CGSizeMake(DOCTOR_TN_W, DOCTOR_TN_H)];
                    UIImageView *signatureView = [[UIImageView alloc] initWithImage:img];

                    CGFloat xPos = frame.size.width;
                    if (@available(iOS 11, *))
                        xPos -= self.view.safeAreaInsets.right;
                    
                    CGRect imageFrame = CGRectMake(xPos - (DOCTOR_TN_W + 20.0),
                                                   0,
                                                   DOCTOR_TN_W,
                                                   DOCTOR_TN_H);
                    [signatureView setFrame:imageFrame];
//                    NSLog(@"Line: %d, signatureView:%@", __LINE__, NSStringFromCGRect(imageFrame));
//                    NSLog(@"Line: %d, cell.frame:%@", __LINE__, NSStringFromCGRect(cell.frame));
//                    NSLog(@"Line: %d, contentView.frame:%@", __LINE__, NSStringFromCGRect(cell.contentView.frame));
                    signatureView.contentMode = UIViewContentModeTopRight;
                    [cell.contentView addSubview:signatureView];
#ifdef DEBUG_COLOR_BG
                    [cell.contentView setBackgroundColor:[UIColor yellowColor]];
                    label.backgroundColor = [UIColor orangeColor];
#endif
                }
                break;
            case 1:
                label.text = prescription.doctor.postalAddress;
                break;
            case 2:
                    label.text = [NSString stringWithFormat:@"%@ %@",
                                  prescription.doctor.zipCode,
                                  prescription.doctor.city];
                break;
            case 3:
                    label.text = prescription.doctor.phoneNumber;
                break;
            case 4:
                    label.text = prescription.doctor.emailAddress;
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == kSectionPatient) {
        if (!prescription.patient) {
            cell.textLabel.text = @"";
            return cell;
        }

        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        switch (indexPath.row) {
            case 0:
                label.text = [NSString stringWithFormat:@"%@ %@",
                              prescription.patient.familyName,
                              prescription.patient.givenName];
                break;
            case 1:
            {
                NSString *gender = @"";
                if ([prescription.patient.gender isEqualToString:@"man"])
                    gender = NSLocalizedString(@"man", "Gender");
                else if ([prescription.patient.gender isEqualToString:@"woman"])
                    gender = NSLocalizedString(@"woman", "Gender");

                label.text = [NSString stringWithFormat:@"%dkg/%dcm %@ %@",
                              prescription.patient.weightKg,
                              prescription.patient.heightCm,
                              gender,
                              prescription.patient.birthDate];
            }
                break;
            case 2:
                label.text = prescription.patient.postalAddress;
                break;
            case 3:
                label.text = [NSString stringWithFormat:@"%@ %@ %@",
                              prescription.patient.zipCode,
                              prescription.patient.city,
                              prescription.patient.country];
                break;
            case 4:
                label.text = prescription.patient.phoneNumber;
                break;
            case 5:
                label.text = prescription.patient.emailAddress;
                break;
            default:
                break;
        }
    }
    else {
        Product * med = prescription.medications[indexPath.row];
        UILabel *packLabel = [self makeLabel:med.packageInfo
                                   textColor:[UIColor blackColor]];

        UILabel *eanLabel = [self makeLabel:med.eanCode
                                  textColor:[UIColor darkGrayColor]];

#ifdef DEBUG
        //NSLog(@"Line %d comment:<%@>", __LINE__, med.comment);
        //med.comment = [NSString stringWithFormat:@"Test comment for row %ld", indexPath.row];
#endif

        UITextView *commentTextField;
        UILabel *commentLabel;
        if (editingCommentIdx == indexPath.row) {
            CGRect frame = CGRectMake(kMedCellHorMargin,
                                      kMedCellVerMargin,
                                      mainFrame.size.width - 2*kMedCellHorMargin,
                                      kMedCellHeight);
            commentTextField = [[UITextView alloc] initWithFrame:frame];
            commentTextField.text = med.comment;
            commentTextField.font = [UIFont systemFontOfSize:12.2];
            UIColor *lightRed = [UIColor colorWithRed:1.0
                                                green:0.6
                                                 blue:0.6
                                                alpha:1.0];
            commentTextField.backgroundColor = lightRed;
            commentTextField.tintColor = [UIColor blackColor];
            [commentTextField sizeToFit];
            commentTextField.delegate = self;
#ifdef DEBUG
            commentTextField.tag = 123;
#endif
        }
        else {
            commentLabel = [self makeLabel:med.comment
                                 textColor:[UIColor darkGrayColor]];
        }

        // layout
        CGRect eanFrame = CGRectMake(kMedCellHorMargin,
                                     packLabel.frame.origin.y + packLabel.frame.size.height + kLabelVerMargin,
                                     eanLabel.frame.size.width,
                                     eanLabel.frame.size.height);
        [eanLabel setFrame:eanFrame];
        

#ifdef DEBUG_COLOR_BG
        [cell.contentView setBackgroundColor:[UIColor yellowColor]];
#endif
        [cell.contentView addSubview:packLabel];
        [cell.contentView insertSubview:eanLabel belowSubview:packLabel];
        if (editingCommentIdx == indexPath.row) {
            CGRect commentFrame = CGRectMake(kMedCellHorMargin,
                                             eanLabel.frame.origin.y + eanLabel.frame.size.height + kLabelVerMargin,
                                             tableView.bounds.size.width - 2*kMedCellHorMargin,  //commentTextField.frame.size.width
                                             commentTextField.frame.size.height);
            [commentTextField setFrame:commentFrame];
            [cell.contentView insertSubview:commentTextField belowSubview:eanLabel];
            [commentTextField becomeFirstResponder];
        }
        else {
            CGRect commentFrame = CGRectMake(kMedCellHorMargin,
                                             eanLabel.frame.origin.y + eanLabel.frame.size.height + kLabelVerMargin,
                                             commentLabel.frame.size.width,
                                             commentLabel.frame.size.height);
            [commentLabel setFrame:commentFrame];
            [cell.contentView insertSubview:commentLabel belowSubview:eanLabel];
        }

        return cell;
    }

    if (label.text) { // 1 cell per row
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.preferredMaxLayoutWidth = frame.size.width;
        [label sizeToFit];
        [cell.contentView addSubview:label];
    }
    
    return cell;
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    if ((indexPath.section == kSectionOperator) &&
        !prescription.doctor)
    {
        UIViewController *nc_rear = self.revealViewController.rearViewController;
        MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
        [vc_rear switchToDoctorEditView];
    }
}

#pragma mark - Actions

- (IBAction)myRightRevealToggle:(id)sender
{
    SWRevealViewController *revealController = [self revealViewController];
    
    // Check that the right controller class is AmkListViewController
    UIViewController *vc_right = revealController.rightViewController;
    
#ifdef DEBUG
    //NSLog(@"%s vc: %@", __FUNCTION__, [vc_right class]);
#endif
    
    if (![vc_right isKindOfClass:[AmkListViewController class]] ) {
        // Replace right controller
        AmkListViewController *amkListViewController =
        [[AmkListViewController alloc] initWithNibName:@"AmkListViewController"
                                                       bundle:nil];
        [revealController setRightViewController:amkListViewController];
        NSLog(@"Replaced right VC");
    }
    
#ifdef CONTACTS_LIST_FULL_WIDTH
    float frameWidth = self.view.frame.size.width;
    revealController.rightViewRevealWidth = frameWidth;
#endif
    
    if ([revealController frontViewPosition] == FrontViewPositionLeft)
        [revealController setFrontViewPosition:FrontViewPositionLeftSide animated:YES];
    else
        [revealController setFrontViewPosition:FrontViewPositionLeft animated:YES];  // Center
}

- (IBAction) showPatientDbList:(id)sender
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDel switchRigthToPatientDbList];
}

#pragma mark - Toolbar actions

- (IBAction) newPrescription:(id)sender
{
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;
    //NSLog(@"%s tag:%ld, title:%@", __FUNCTION__, (long)btn.tag, btn.title);
    [self loadDefaultDoctor];
    prescription.patient = nil;
    [prescription.medications removeAllObjects];
    [self updateButtons];
    [infoView reloadData];
    possibleToOverwrite = false;
    lastUsedURL = nil;
}

// See AmiKo OSX onCheckForInteractions
- (IBAction) checkForInteractions:(id)sender
{
    //NSLog(@"%s", __FUNCTION__);
    
    NSMutableDictionary *medBasket = [[NSMutableDictionary alloc] init];
    // pushToMedBasket
    for (Product *p in prescription.medications) {
        NSString *title = [p title];
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([title length]>30) {
            title = [title substringToIndex:30];
            title = [title stringByAppendingString:@"..."];
        }
        //NSLog(@"%d title. <%@>", __LINE__, title);

        // Add med to medication basket
        // We must build a dictionary of MLMedication, not of Product
        MLMedication *m = [[MLMedication alloc] init];
        m.regnrs = p.regnrs;
        m.auth = p.auth;        // owner
        m.atccode = p.atccode;  // We only need this one for interactions
        m.title = p.title;
        [medBasket setObject:m forKey:title];
    }
    
    //NSLog(@"%s %d, count:%ld, %@", __FUNCTION__, __LINE__, [medBasket count], medBasket);

    UIViewController *nc_rear = self.revealViewController.rearViewController;
    MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
    [vc_rear switchToDrugInteractionViewFromPrescription: medBasket];
}

- (IBAction) savePrescription:(id)sender
{
    NSString *alertMessage = nil;
    NSString *alertTitle = nil;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    if (possibleToOverwrite)
    {
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:NSLocalizedString(@"Overwrite Prescription", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         [self overwritePrescription];
                                                     }];
    [alertController addAction:actionOk];
    }
    
    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save as New Prescription", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                             // New hash and new prescription
                                                             prescription.hash = [self makeNewUniqueHash];
                                                             [self saveNewPrescription];
                                                         }];
    [alertController addAction:actionNo];

    // Cancel buttons are removed from popovers automatically, because tapping outside the popover represents "cancel", in a popover context
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alertController addAction:actionCancel];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //UIBarButtonItem *button = (UIBarButtonItem *)sender;
        alertController.popoverPresentationController.barButtonItem = sender;
        alertController.popoverPresentationController.sourceView = self.view;
    }

    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

- (IBAction) sendPrescription:(id)sender
{
#if 0
    // Offer the choice: overwrite or new
    [self savePrescription:sender];
#else
    // Handle the choice automatically
    // TODO: (TBC) skip the following if the prescription has not been edited
    if (possibleToOverwrite) {
        [self overwritePrescription];
    }
    else {
        // New hash and new prescription
        prescription.hash = [self makeNewUniqueHash];
        [self saveNewPrescription];
    }
#endif
    
    [self sharePrescription:lastUsedURL];
}

#pragma mark -

// Check if any of the prescriptions for the current patient has this hash
- (NSURL *) prescriptionUrlWithHash: (NSString *)hash
{
    NSString *amkDir = [MLUtility amkDirectory];
#ifdef DEBUG
    //NSLog(@"%s %p %@", __FUNCTION__, self, amkDir);
#endif
    NSError *error;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:amkDir error:&error];
    NSArray *amkFilesArray = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.amk'"]];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
    amkFilesArray = [amkFilesArray sortedArrayUsingDescriptors:@[sd]];
    NSMutableArray *amkFiles = [[NSMutableArray alloc] initWithArray:amkFilesArray];
    
    //NSLog(@"documentsDir:%@", amkFiles);
    Prescription *p = [[Prescription alloc] init];
    for (NSString* f in amkFiles) {
        NSString *fullFilePath = [[MLUtility amkDirectory] stringByAppendingPathComponent:f];

        NSURL *url = [NSURL fileURLWithPath:fullFilePath];
        [p importFromURL:url];
        //NSLog(@"Hash:%@", p.hash);
        if ([p.hash isEqualToString:hash]) {
            //NSLog(@"Found:%@", p.hash);
            return url;
        }
    }
    return nil;
}

- (BOOL) validatePrescription
{
    if (![self checkDefaultDoctor])
        return FALSE;
    
    if ((!self.prescription.medications) ||
        ([self.prescription.medications count] < 1)) {
        NSLog(@"Cannot save prescription with no medications");
        return FALSE;
    }
    
    return TRUE;
}

- (void) overwritePrescription
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    
    if (![self validatePrescription])
        return;
    
    NSURL *url = [self prescriptionUrlWithHash:prescription.hash];

    //NSLog(@"url:%@", url);
    if (url) {
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtURL:url
                                                                 error:&error];
        if (!success)
            NSLog(@"Error removing file at path: %@", error.localizedDescription);

#ifdef DEBUG
        // Extra check
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
            NSLog(@"file <%@> not yet deleted", [url path]);
#endif
        
        // If the right view is a AmkListViewController also delete from array and refresh
        id right = self.revealViewController.rightViewController;
        if ([right isKindOfClass:[AmkListViewController class]] ) {
            AmkListViewController *vc = right;
            [vc removeFromListByFilename:[url lastPathComponent]];
        }
    }

    // Use the same prescription.hash for a new prescription
    [self saveNewPrescription];
}

// The prescription.hash is defined before calling this function
- (void) saveNewPrescription
{
    if (![self validatePrescription])
        return;
    
    [self loadDefaultDoctor];
    [infoView reloadData];
    
    NSString *amkDir;
    NSString *uid = [self.prescription.patient uniqueId];
    if (uid)
        amkDir = [MLUtility amkDirectoryForPatient:uid];
    else
        amkDir = [MLUtility amkDirectory];
    
    NSError *error;
//    [[NSFileManager defaultManager] createDirectoryAtPath:amkDir
//                              withIntermediateDirectories:YES
//                                               attributes:nil
//                                                    error:&error];
//    if (error) {
//        NSLog(@"%@", error.localizedDescription);
//        return;
//    }

    prescription.placeDate = [NSString stringWithFormat:@"%@, %@",
                              prescription.doctor.city,
                              [MLUtility prettyTime]];

    NSMutableDictionary *prescriptionDict = [[NSMutableDictionary alloc] init];
    [prescriptionDict setObject:prescription.hash forKey:KEY_AMK_HASH];
    [prescriptionDict setObject:prescription.placeDate forKey:KEY_AMK_PLACE_DATE];
    [prescriptionDict setObject:[prescription makePatientDictionary] forKey:KEY_AMK_PATIENT];
    [prescriptionDict setObject:[prescription makeOperatorDictionary] forKey:KEY_AMK_OPERATOR];
    [prescriptionDict setObject:[prescription makeMedicationsArray] forKey:KEY_AMK_MEDICATIONS];
    
    //NSLog(@"Line %d, prescriptionDict:%@", __LINE__, prescriptionDict);

#ifdef DEBUG
    //NSLog(@"%s hash:%@", __FUNCTION__, prescription.hash);

//    if ([NSJSONSerialization isValidJSONObject:prescriptionDict]) {
//        NSLog(@"Invalid JSON object:%@", prescriptionDict);
//        //return;
//    }
#endif
    
    // Map cart array to json
    NSData *jsonObject = [NSJSONSerialization dataWithJSONObject:prescriptionDict
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:&error];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonObject encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    //NSLog(@"Line %d, jsonStr:%@", __LINE__, jsonStr);
#endif
    NSString *base64Str = [MLUtility encodeStringToBase64:jsonStr];
    
#if 1
    // Prescription file name like AmiKo
    NSString *currentTime = [[MLUtility currentTime] stringByReplacingOccurrencesOfString:@":" withString:@""];
    currentTime = [currentTime stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *amkFile = [NSString stringWithFormat:@"RZ_%@.amk", currentTime];
    NSString *amkFilePath = [amkDir stringByAppendingPathComponent:amkFile];
#else
    // Prescription file name like Generika
    time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];
    NSString *amkFile = [NSString stringWithFormat:@"%@_%d.amk", @"RZ", (int)timestamp];
    NSString *amkFilePath = [amkDir stringByAppendingPathComponent:amkFile];
#endif

    BOOL amkSaved = [base64Str writeToFile:amkFilePath
                                atomically:YES
                                  encoding:NSUTF8StringEncoding
                                     error:&error];
    if (!amkSaved)
        NSLog(@"Error: %@", [error userInfo]);
    else {
        NSLog(@"Saved to file <%@>", amkFilePath);
        lastUsedURL = [NSURL fileURLWithPath:amkFilePath];
    }
    
    possibleToOverwrite = true;

    // Refresh the AMK list
    id right = self.revealViewController.rightViewController;
    if ([right isKindOfClass:[AmkListViewController class]] ) {
        AmkListViewController *vc = right;
        [vc refreshList];
    }
}

- (UILabel *)makeLabel:(NSString *)text textColor:(UIColor *)color
{
    CGRect frame = CGRectMake(kMedCellHorMargin,
                              kMedCellVerMargin,
                              mainFrame.size.width - 2*kMedCellHorMargin,
                              kMedCellHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.font = [UIFont systemFontOfSize:12.2];
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = color;
    label.text = text;
#ifdef DEBUG_COLOR_BG
    label.backgroundColor = [UIColor orangeColor];
#else
    label.backgroundColor = [UIColor clearColor];
#endif
    label.highlighted = NO;
    // use multiple lines for wrapped text as required
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = frame.size.width;
    // this line must be after `numberOfLines`
    [label sizeToFit];
    return label;
}

#pragma mark - Notifications

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
//    // Convert it to the same view coords as the tableView it might be occluding
//    CGRect keyboardRect2 = [self.infoView convertRect:keyboardRect fromView:nil];
//    NSLog(@"keyboardRect2:%@", NSStringFromCGRect(keyboardRect2));
    
    if (self.infoView.isFirstResponder) {
        UIEdgeInsets contentInset = self.infoView.contentInset;
        contentInset.bottom = keyboardRect.size.height;
        self.infoView.contentInset = contentInset;
        self.infoView.scrollIndicatorInsets = contentInset;
    }
    else {
        savedKeyboardY = keyboardRect.origin.y;
        [self recalculateSavedOffset];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    if (self.infoView.isFirstResponder) {
        UIEdgeInsets contentInset = self.infoView.contentInset;
        contentInset.bottom = 0;
        self.infoView.contentInset = contentInset;
        self.infoView.scrollIndicatorInsets = contentInset;
    }
    else {
        // Comment it out to leave it at the current offset
        //[self.infoView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)amkListDidChangeSelection:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[aNotification object] forKey:@"lastUsedPrescription"];
    [defaults synchronize];
    
    NSString *amkDir = [MLUtility amkDirectory];
    NSString *fullFilePath = [amkDir stringByAppendingPathComponent:[aNotification object]];
    lastUsedURL = [NSURL fileURLWithPath:fullFilePath];
    [prescription importFromURL:lastUsedURL];
    [self updateButtons];
    [infoView reloadData];
    possibleToOverwrite = true;
    
    [self.revealViewController rightRevealToggleAnimated:YES];
}

- (void)amkDeleted:(NSNotification *)aNotification
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    prescription.hash = nil;
    prescription.placeDate = nil;
    prescription.medications = nil;
    prescription.patient = nil;
    
    [infoView reloadData];
    
    [self.revealViewController rightRevealToggleAnimated:YES];
}

- (void)patientDbListDidChangeSelection:(NSNotification *)aNotification
{
    [prescription setPatient:[aNotification object]];
    [infoView reloadData];
    
    // GitHub issue #21
    possibleToOverwrite = false;
    
    // TODO: (TBC) make sure the right view is back to the AMK list, for the sake of the swiping action
    
    [self updateButtons];
}

- (void)addMedication:(Product *)p
{
    if (!prescription)
        prescription = [[Prescription alloc] init];
    
    if (!prescription.medications)
        prescription.medications = [[NSMutableArray alloc] init];
    
    [prescription.medications addObject:p];
    editedMedicines = true;
    [self updateButtons];
    [infoView reloadData];
}

- (void) updateButtons
{
    if (prescription.doctor &&
        prescription.patient &&
        [prescription.medications count] > 0)
    {
        [self saveButtonOn];
    }
    else
        [self saveButtonOff];
    
    if ([prescription.medications count] > 1)
        self.interactionButton.enabled = YES;
    else
        self.interactionButton.enabled = NO;
}

- (void) saveButtonOn
{
    self.saveButton.enabled = YES;
    self.sendButton.enabled = YES;
}

- (void) saveButtonOff
{
    self.saveButton.enabled = NO;
    self.sendButton.enabled = NO;
}

- (void) showCameraForHealthCardOCR
{
    NSLog(@"%s", __FUNCTION__);
    // Initialize the patient DB in the singleton ahead of time
    PatientViewController *patientVC = [PatientViewController sharedInstance];

    UIViewController *nc_rear = self.revealViewController.rearViewController;
    MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];

    [vc_rear switchToPatientEditView :NO]; // No animation so it becomes visible faster
    
    // Ideally, wait for patient view to be visible
    //NSLog(@"Line %d patientVC.isViewLoaded. %d", __LINE__, patientVC.isViewLoaded);

    [patientVC handleCameraButton:nil];
}

- (void) showCameraForBarcodeAcquisition
{
    NSLog(@"%s", __FUNCTION__);

#if 1 // with VC
    // Make sure front is PrescriptiopnViewController
    UIViewController *nc_front = self.revealViewController.frontViewController; // UINavigationController
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];   // PrescriptionViewController
//    NSLog(@"nc_front %@", [nc_front class]);
//    NSLog(@"vc_front %@", [vc_front class]);
    
    if (!self.videoVC)
        self.videoVC = nil; // So that it will be reinitialized with the current orientation
    
    self.videoVC = [[videoViewController alloc] initWithNibName:@"videoViewController"
                                                         bundle:nil];

    self.videoVC.delegate = self;
    
    [vc_front presentViewController:self.videoVC
                           animated:NO
                         completion:NULL];
#else
    captureSession = [AVCaptureSession new];
    NSError *error;
    AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:&error];
    
    if(error){
        NSLog(@"error configuring camera input: %@", [error localizedDescription]);
        return;
    }

    if ([captureSession canAddInput:cameraDeviceInput]) {
        [captureSession addInput:cameraDeviceInput];
    }

    #if 0
    AVCaptureMovieFileOutput *movieFileOutput = [AVCaptureMovieFileOutput new];
    if ([captureSession canAddOutput:movieFileOutput]) {
        [captureSession addOutput:movieFileOutput];
    }
    #else
    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.videoSettings = nil;
    _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    [captureSession addOutput:self.videoDataOutput]; // @@@
    #endif

    NSLog(@"%s line %d", __FUNCTION__, __LINE__);
    [captureSession startRunning];
#endif
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint p = [gesture locationInView:infoView];
    NSIndexPath *indexPath = [infoView indexPathForRowAtPoint:p];
    CGRect rectPatientSection = [infoView rectForSection:kSectionPatient];
    CGRect rectMedicineSection = [infoView rectForSection:kSectionMedicines];

    if (indexPath == nil) {
        // If p is in the patient header section rect, show the camera, else return
        if (CGRectContainsPoint(rectPatientSection, p))
        {
            [self showCameraForHealthCardOCR];
            return;
        }
        else if (CGRectContainsPoint(rectMedicineSection, p))
        {
            [self showCameraForBarcodeAcquisition];
            return;
        }
        else {
#ifdef DEBUG
            NSLog(@"long press on table view but not on a row, point: %@, rect: %@ state:%ld",
                  NSStringFromCGPoint(p),
                  NSStringFromCGRect(rectPatientSection),
                  (long)gesture.state);
#endif
            return;
        }
    }
    
    if (indexPath.section == kSectionPatient) {
        NSLog(@"%s line %d", __FUNCTION__, __LINE__);
        [self showCameraForHealthCardOCR];
        return;
    }
    else if (indexPath.section != kSectionMedicines) {
#ifdef DEBUG
        // No long taps for Meta and Operator sections
        NSLog(@"Wrong section %ld", indexPath.section);
#endif
        return;
    }

    NSLog(@"long press at row %ld", indexPath.row);

    if (editingCommentIdx != -1) {
#ifdef DEBUG
        NSLog(@"Already editing comment %ld. Force termination of edit mode.", editingCommentIdx);
#endif
        [self btnClickedDone:nil];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

#if 1
    UIAlertAction *actionEdit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit comment", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         
                                                           editingCommentIdx = indexPath.row;
                                                           [infoView reloadData];
                                                       }];
    [alertController addAction:actionEdit];
#endif
    
#if 1
    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete package", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                             [prescription.medications removeObjectAtIndex:indexPath.row];
                                                             editedMedicines = true;
                                                             [infoView reloadData];
                                                         }];
    [alertController addAction:actionDelete];
#endif
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             }];
        [alertController addAction:actionCancel];
    }
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [infoView cellForRowAtIndexPath:indexPath];
        alertController.popoverPresentationController.sourceView = cell.contentView;
        alertController.popoverPresentationController.sourceRect = cell.contentView.bounds;
        alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown;
    }
    
    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
#if 0
    [textView setReturnKeyType:UIReturnKeyDone];
#else
    UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolBar.barStyle = UIBarStyleBlackOpaque;
    toolBar.tintColor = MAIN_TINT_COLOR;
    
    UIBarButtonItem *flex =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:self
                                                  action:nil];

    UIBarButtonItem *btnDone =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(btnClickedDone:)];
    
    [toolBar setItems:[NSArray arrayWithObjects:flex, btnDone, nil]];
    [textView setInputAccessoryView:toolBar];
#endif
    
    return YES;
}

-(IBAction)btnClickedDone:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s %@", __FUNCTION__, [sender class]); // UIBarButtonItem
#endif

    commentEditingActive = NO;
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    commentEditingActive = YES;
    activeTextView = textView;
    
    //infoView.scrollEnabled = NO;  // Not needed after using commentEditingActive
}

//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//{
//    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
//#ifdef DEBUG
//    NSLog(@"%s <%@> %@ <%@> --> <%@>", __FUNCTION__, textView.text, NSStringFromRange(range), text, newString);
//#endif
//
//    return YES;
//}

- (void)textViewDidChange:(UITextView *)textView
{
#ifdef DEBUG
    //NSLog(@"%s", __FUNCTION__);
#endif
    // Get current width
    CGRect r = textView.frame;
    CGSize before = r.size;
    
    // Dynamically adjust cell frame
    [textView sizeToFit];
    
    // Restore width, otherwise it gets too narrow
    r = textView.frame;
    r.size.width = before.width;
    textView.frame = r;
    
    // Update the cell height in the table view, but do it only if the height
    // has changed, otherwise we could see an unpleasant "dancing" when
    // adjusting the offset for each character
    if (before.height != r.size.height)
    {
#ifdef DEBUG
        //NSLog(@"%s Line:%d height has changed", __FUNCTION__, __LINE__);
#endif
        Product * med = prescription.medications[editingCommentIdx];
        med.comment = textView.text;
        [prescription.medications replaceObjectAtIndex:editingCommentIdx
                                            withObject:med];
        
        // Force UITableView to reload cell sizes only, but not cell contents
        // Unfortunately this also changes infoView.contentOffset
        [self.infoView beginUpdates];
        [self.infoView endUpdates];

        // Restore offset
        [self recalculateSavedOffset];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
    //NSLog(@"%s <%@>", __FUNCTION__, textView.text);
#endif

    if (commentEditingActive)
        return NO;
    
    [textView resignFirstResponder];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
#ifdef DEBUG
    NSLog(@"%s idx:%ld", __FUNCTION__, editingCommentIdx);
    //NSLog(@"%s idx:%ld, <%@>", __FUNCTION__, editingCommentIdx, textView.text);
#endif
    if (editingCommentIdx == -1) {
        NSLog(@"%s line:%d unexpected index value", __FUNCTION__, __LINE__);
        // TODO: debug why this happens. It also makes the keyboard disappear ?
        return; // Prevent crash accessing medications
    }

    Product * med = prescription.medications[editingCommentIdx];
    med.comment = textView.text;
    [prescription.medications replaceObjectAtIndex:editingCommentIdx
                                        withObject:med];
    editingCommentIdx = -1;
    editedMedicines = true;
    [infoView reloadData];
    activeTextView = nil;
    
    //infoView.scrollEnabled = YES;  // Not needed after using commentEditingActive
}

- (void) recalculateSavedOffset
{
#ifdef DEBUG
    //NSLog(@"%s savedOffset before:%@", __FUNCTION__, NSStringFromCGPoint(savedOffset));
#endif
    CGRect r = [infoView convertRect:activeTextView.frame fromView:activeTextView];
    CGPoint offset = infoView.contentOffset;
    
#ifdef DEBUG
//    NSLog(@"commentView:%@", NSStringFromCGRect(r));
//    NSLog(@"infoView frame:%@", NSStringFromCGRect(infoView.frame));
//    NSLog(@"contentSize:%@", NSStringFromCGSize(infoView.contentSize));
//    NSLog(@"contentOffset:%@", NSStringFromCGPoint(offset));
#endif
    
    CGFloat margin;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        margin = 100.0;
    else
        margin = 50.0;
    
    CGFloat yAdjustment = savedKeyboardY - (r.origin.y + r.size.height + margin - offset.y);
    //NSLog(@"yAdjustment:%f, savedKeyboardY:%f", yAdjustment, savedKeyboardY);
    if (yAdjustment < 0.0)
    {
        savedOffset = CGPointMake(0.0f, offset.y - yAdjustment);
        [self.infoView setContentOffset:savedOffset animated:NO];
    }
    else {
        savedOffset = offset;
    }
}

- (void)sharePrescription:(NSURL *)urlAttachment
{
#ifdef DEBUG
    NSLog(@"%s sharing <%@>", __FUNCTION__, urlAttachment);
#endif

    NSString *mailBody = [NSString stringWithFormat:@"%@\n\niOS: %@\nAndroid: %@\n",
                          NSLocalizedString(@"Open with", nil),
                          @"https://itunes.apple.com/ch/app/generika/id520038123?mt=8",
                          @"https://play.google.com/store/apps/details?id=org.oddb.generika"];
    //NSString *mailBody2 = [NSString stringWithFormat:@"Your prescription from Dr.:%@", prescription.doctor.familyName];

    NSArray *objectsToShare = @[mailBody, urlAttachment];
    
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypePrint,
                                   UIActivityTypeCopyToPasteboard,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    NSString * subjectLine =
    [NSString stringWithFormat:NSLocalizedString(@"Prescription to patient from doctor",nil),
                              prescription.patient.givenName,
                              prescription.patient.familyName,
                              prescription.patient.birthDate,
                              prescription.doctor.title,
                              prescription.doctor.givenName,
                              prescription.doctor.familyName];
    [activityVC setValue:subjectLine forKey:@"subject"];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        activityVC.modalPresentationStyle = UIModalPresentationPopover;

    [self presentViewController:activityVC animated:YES completion:nil];
    
#if 1
    UIPopoverPresentationController *popController = [activityVC popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    activityVC.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        // react to the completion
        if (completed) {
            // user shared an item
            NSLog(@"We used activity type%@", activityType);
            if ([activityType isEqualToString:UIActivityTypeMail]) {
                //return @"Your subject goes here";
            }
        }
        else {
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
        }
        
        if (error)
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
    };
#endif
}

#pragma mark - SampleBufferDelegate methods
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// See videoCaptureDemo and Generika
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    static int frameNUmber = 1;
    NSLog(@"%s frame %d", __FUNCTION__, frameNUmber++);
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    // TODO: detection of barcode with Vision framework
}

@end
