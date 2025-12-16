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
#import "LegacyPatientDBAdapter.h"
#import "PatientViewController.h"
#import "MLDBAdapter.h"
#import "MLPersistenceManager.h"
#import "MLHINClient.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "MLHINADSwissAuthHandle.h"
#import "EPrescription.h"
#import "MLSendToZurRoseActivity.h"

@import Vision;

////////////////////////////////////////////////////////////////////////////////
// Label Printing

// Mutually exclusive:
//#define LABEL_PRINT_PIC_USES_FORMATTER        // NG using UIView
//#define LABEL_PRINT_PIC_USES_PAGE_RENDERER    // NG
//#define LABEL_PRINT_PIC_USES_PRINTING_ITEM    // OK UIImage derived from UIView
#define LABEL_PRINT_PIC_USES_PRINTING_ITEM_PDF  // OK PDF derived from UIView

// Use UIPrintInteractionController, or UIPrinterPickerController if commented out
#define LABEL_PRINTER_SELECTION_WITH_PREVIEW

//#define USE_DEFAULTS_FOR_SELECTED_PRINTER
#ifdef USE_DEFAULTS_FOR_SELECTED_PRINTER
#define DEFAULTS_KEY_PRINTER_URL            @"printer.url"
#endif

#define kSizeA4                 CGSizeMake(mm2pix(210),mm2pix(297))
#define kSizeDymoLabel          CGSizeMake(mm2pix(36),mm2pix(89))

////////////////////////////////////////////////////////////////////////////////

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
    NSStringDrawingContext *context = [NSStringDrawingContext new];
    CGSize boundSize = [label.text boundingRectWithSize:constraint
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:label.font}
                                                context:context].size;
    return CGSizeMake(ceil(boundSize.width), ceil(boundSize.height));
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface PrintItemProvider: UIActivityItemProvider
@property (nonatomic, strong) NSMutableData *pdfData;
@end

@implementation PrintItemProvider

- (instancetype)initWithPlaceholderItem:(id)placeholderItem
{
    self.pdfData = placeholderItem;
    return [super initWithPlaceholderItem:placeholderItem];
}

#pragma mark - UIActivityItemSource

// (required)
- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(UIActivityType)activityType
{
    if (([self.activityType isEqualToString:UIActivityTypePrint]) ||        // Print
        ([self.activityType isEqualToString:UIActivityTypeMarkupAsPDF]))    // Create PDF
    {
        return self.pdfData;
    }
    
    return nil;
}

// (required)
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    if (self.placeholderItem == nil)
        return @"";
    
    return self.placeholderItem;
}

- (id)item
{
    if (([self.activityType isEqualToString:UIActivityTypePrint]) ||        // Print
        ([self.activityType isEqualToString:UIActivityTypeMarkupAsPDF]))    // Create PDF
    {
        return [self.pdfData class];
    }
    
    return nil; // email won't get this attachment
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@interface PrescriptionViewController ()<ASWebAuthenticationPresentationContextProviding>
{
    UITextView *activeTextView;
    CGPoint savedOffset;
    CGFloat savedKeyboardY;
    bool commentEditingActive;
    NSURL *lastUsedURL;
    bool barcodeHandled; // prevent processing the same scan multiple times

    UIPrintInteractionController *pic;
    NSIndexPath *indexPath; // for iPad
}

@property (nonatomic, strong) NSMetadataQuery *query;

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
- (void) showAlertForBarcodeNotFound;

- (void) selectLabelPrinterAndPrint;
- (void) checkPrinterAndPrint:(UIPrinter *)printer;
- (NSMutableData *)renderPdfForPrintingWithEPrescriptionQRCode:(UIImage * _Nullable)image;
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
@synthesize medicineLabelView, labelDoctor, labelPatient, labelMedicine, labelComment, labelPrice, labelSwissmed;

+ (PrescriptionViewController *)sharedInstance
{
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[PrescriptionViewController alloc] init];
    });
    
    return sharedObject;
}

- (instancetype)init {
    if (self = [super initWithNibName:@"PrescriptionViewController" bundle:nil]) {
        self.query = [[NSMetadataQuery alloc] init];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        [self reloadQueryPredicate];
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:NO]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadDoctor)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:self.query];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadQueryPredicate)
                                                     name:PERSISTENCE_SOURCE_CHANGED_NOTIFICATION
                                                   object:nil];
    }
    return self;
}

- (void)reloadQueryPredicate {
    self.query.predicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@",
                            NSMetadataItemURLKey,
                            [[MLPersistenceManager shared] doctorDictionaryURL],
                            NSMetadataItemURLKey,
                            [[MLPersistenceManager shared] doctorSignatureURL]];
    [self reloadDoctor];
}

- (void)layoutFrames
{
    [self updateMainframeRect];
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
    [NSFileCoordinator removeFilePresenter:self];
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
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_LEFT]
                                     style:UIBarButtonItemStylePlain
                                    target:revealController
                                    action:@selector(revealToggle:)];
    // A single button on the left
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
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

    // Right button
    // First ensure the "right" is a ContactsListViewController
    id aTarget = self;
    SEL aSelector = @selector(myRightRevealToggle:);

    UIBarButtonItem *rightRevealButtonItem =
    [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:NAVIGATION_ICON_RIGHT]
                                     style:UIBarButtonItemStylePlain
                                    target:aTarget
                                    action:aSelector];
    self.navigationItem.rightBarButtonItem = rightRevealButtonItem;

    [self updateMainframeRect];
    
    if (!prescription) {
        prescription = [Prescription new];
        lastUsedURL = nil;
    }
    
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newLabelPrinterWasSelected:)
                                                 name:@"labelPrinterSelection"
                                               object:nil];
    if (![[NSFileCoordinator filePresenters] containsObject:self]) {
        [NSFileCoordinator addFilePresenter:self];
    }
    if (@available(iOS 26, *)) {
        for (UIBarButtonItem *item in self.toolbar.items) {
            item.sharesBackground = NO;
            item.hidesSharedBackground = YES;
        }
    }
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
        if ([gr isKindOfClass:[UIPanGestureRecognizer class]] ) {
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
        [self loadDefaultDoctor];

        // GitHub issue #86: from now on we allow changing the patient even if the
        // prescription is in an unsaved state.
        //
        // Note that for the case of changing the patient from the patient list
        // we don't come here, because there is no reloading of this view.
        [self loadDefaultPatient];
    }
    else {
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
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
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // willRotateToInterfaceOrientation
    }
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
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
    return [[MLPersistenceManager shared] doctorDictionary] != nil;
}

- (void) reloadDoctor {
    [self loadDefaultDoctor];
    [self updateButtons];
    [infoView reloadData];
}

- (void) loadDefaultDoctor
{
    // Init from defaults
    // See also Operator importFromDict
    NSDictionary *doctorDictionary = [[MLPersistenceManager shared] doctorDictionary];
    if (!doctorDictionary) {
        // Maybe there was a doctor imported from an AMK,
        // but it's not the default doctor, so clear it.
        if (prescription.doctor)
            self.prescription.doctor = nil;

        return;
    }

    if (!prescription.doctor)
        self.prescription.doctor = [Operator new];
    
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
        NSLog(@"%s Default prescription not yet defined", __FUNCTION__);
        return FALSE;
    }

    NSURL *url = [[[MLPersistenceManager shared] amkDirectory] URLByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [defaults removeObjectForKey:@"lastUsedPrescription"];
        [defaults synchronize];
        NSLog(@"%s %d", __FUNCTION__, __LINE__);
        return FALSE;
    }

    prescription = [[Prescription alloc] initWithURL:url];
    lastUsedURL = url;
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

    Patient *pat = [[MLPersistenceManager shared] getPatientWithUniqueID:patientId];
    [prescription setPatient:pat];
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
    label.textColor = [UIColor labelColor];
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
        [view setBackgroundColor:[UIColor systemGroupedBackgroundColor]];
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
    static NSString *tableIdentifier = @"PrescriptionTableItem";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
    cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    if (indexPath.section != kSectionMedicines)
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    CGRect frame = CGRectMake(12.0, 0, tableView.frame.size.width, 25.0);  // TODO: remove magic numbers
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    if (indexPath.section == kSectionMeta) {
        label.font = [UIFont systemFontOfSize:13.8];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor labelColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = prescription.placeDate;
    }
    else if (indexPath.section == kSectionOperator) {
        MLPersistenceFileState doctorFileState = [[MLPersistenceManager shared] doctorFileState];
        if (doctorFileState == MLPersistenceFileStateDownloading) {
            label.font = [UIFont systemFontOfSize:13.0];
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = MAIN_TINT_COLOR;
            label.backgroundColor = [UIColor clearColor];
            label.text = NSLocalizedString(@"Syncing doctor's info from iCloud", nil);
            
            label.preferredMaxLayoutWidth = frame.size.width;
            [label sizeToFit];
            [cell.contentView addSubview:label];
            return cell;
        } else if (doctorFileState == MLPersistenceFileStateNotFound) {
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
        label.textColor = [UIColor labelColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"";  // Initialize for appending
        cell.backgroundColor = [UIColor clearColor];  // Allow the signature to show over multiple cells

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
                    signatureView.contentMode = UIViewContentModeTopRight;
                    [cell.contentView addSubview:signatureView];
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
        label.textColor = [UIColor labelColor];
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
                                   textColor:[UIColor labelColor]];

        UILabel *eanLabel = [self makeLabel:med.eanCode
                                  textColor:[UIColor secondaryLabelColor]];

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
            commentTextField.tintColor = [UIColor labelColor];
            [commentTextField sizeToFit];
            commentTextField.delegate = self;
#ifdef DEBUG
            commentTextField.tag = 123;
#endif
        }
        else {
            commentLabel = [self makeLabel:med.comment
                                 textColor:[UIColor labelColor]];
        }

        // layout
        CGRect eanFrame = CGRectMake(kMedCellHorMargin,
                                     packLabel.frame.origin.y + packLabel.frame.size.height + kLabelVerMargin,
                                     eanLabel.frame.size.width,
                                     eanLabel.frame.size.height);
        [eanLabel setFrame:eanFrame];
        
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
    MLAppDelegate *appDel = (MLAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDel switchRigthToPatientDbList];
}

#pragma mark - Toolbar actions

- (IBAction) newPrescription:(id)sender
{
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
    NSMutableDictionary *medBasket = [NSMutableDictionary new];
    // pushToMedBasket
    for (Product *p in prescription.medications) {
        NSString *title = [p title];
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([title length]>30) {
            title = [title substringToIndex:30];
            title = [title stringByAppendingString:@"..."];
        }

        // Add med to medication basket
        // We must build a dictionary of MLMedication, not of Product
        if (p.medication) {
            [medBasket setObject:p.medication forKey:title];
        } else {
            MLDBAdapter *db = [MLDBAdapter sharedInstance];
            MLMedication *m = [db getMediWithRegnr:p.regnrs];
            [medBasket setObject:m forKey:title];
        }
    }

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
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save as New Prescription", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                             // New hash and new prescription
                                                             weakSelf.prescription.hash = [weakSelf makeNewUniqueHash];
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

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //UIBarButtonItem *button = (UIBarButtonItem *)sender;
        alertController.popoverPresentationController.barButtonItem = sender;
        alertController.popoverPresentationController.sourceView = self.view;
    }

    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

- (IBAction) sendPrescription:(id)sender
{
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
    
    [self sharePrescription:lastUsedURL];
}

#pragma mark - Printing

// If we get here we already checked that printing is available
- (void) printMedicineLabel
{
    NSInteger row = self->indexPath.row;
    pic = [UIPrintInteractionController sharedPrintController];
    if (!pic) {
        NSLog(@"Couldn't get shared UIPrintInteractionController!");
        return;
    }
    
    pic.delegate = self;

    ////////////////////////////////////////////////////////////////////////////
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    NSLog(@"line %d, printInfo.jobName %@", __LINE__, printInfo.jobName);

    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.orientation = UIPrintInfoOrientationLandscape; // same result as UIPrintInfoOrientationPortrait
    // The orientation seems to be handled only from the handyPrint settings
//#ifdef DEBUG
//    printInfo.jobName = @"AirPrint label";
//#endif
    pic.printInfo = printInfo;
    
    ////////////////////////////////////////////////////////////////////////////
    // Setup print contents

    NSString *firstLine = [prescription.doctor getStringForLabelPrinting];
    firstLine = [firstLine stringByAppendingString:[self getPlaceDateForPrinting]];
    self.labelDoctor.text = firstLine;

    self.labelPatient.text = [prescription.patient getStringForLabelPrinting];
    
    Product *med = prescription.medications[row];
    NSString *package = [med packageInfo];
    NSArray *packageArray = [package componentsSeparatedByString:@", "];
    labelMedicine.text = [packageArray objectAtIndex:0];

    labelComment.text = [prescription.medications[row] comment];
    
    NSArray *swissmedArray = [package componentsSeparatedByString:@" ["];
    labelSwissmed.text = @"";
    if (swissmedArray.count >= 2)
        labelSwissmed.text = [NSString stringWithFormat:@"[%@", [swissmedArray objectAtIndex:1]];
    
    labelPrice.text = @"";
    if (packageArray.count >= 2) {
        NSArray *priceArray = [[packageArray objectAtIndex:2] componentsSeparatedByString:@" "];
        if ([[priceArray objectAtIndex:0] isEqualToString:@"PP"])
            labelPrice.text = [NSString stringWithFormat:@"CHF\t%@", [priceArray objectAtIndex:1]];
    }
    
    ////////////////////////////////////////////////////////////////////////////
    
#ifdef LABEL_PRINT_PIC_USES_FORMATTER
    UIViewPrintFormatter *formatter = [self.medicineLabelView viewPrintFormatter];
    NSLog(@"line %d, formatter %@, startPage %ld, frame %@", __LINE__,
          formatter,
          (long)formatter.startPage, // -1 = 0x7FFF FFFF FFFF FFFF = 9223372036854775807
          NSStringFromCGRect(formatter.view.frame));

    //formatter.startPage = 1;
    //formatter.perPageContentInsets = UIEdgeInsetsMake(0, 0, 0, 0); // TLBR
    pic.printFormatter = formatter;
#endif
    
#ifdef LABEL_PRINT_PIC_USES_PAGE_RENDERER
    UIViewPrintFormatter *formatter = [self.medicineLabelView viewPrintFormatter];
    NSLog(@"line %d, formatter %@, startPage %ld, frame %@", __LINE__,
          formatter,
          (long)formatter.startPage, // -1 = 0x7FFF FFFF FFFF FFFF = 9223372036854775807
          NSStringFromCGRect(formatter.view.frame));
    //formatter.startPage = 1;
    formatter.perPageContentInsets = UIEdgeInsetsMake(0, 0, 0, 0); // TLBR

    UIPrintPageRenderer *myRenderer = [UIPrintPageRenderer new];

    /*
    float topPadding = 0.0f;
    float bottomPadding = 0.0f;
    float leftPadding = 0.0f;
    float rightPadding = 0.0f;
    CGRect printableRect = CGRectMake(leftPadding,
                                      topPadding,
                                      kSizeDymoLabel.width-leftPadding-rightPadding,
                                      kSizeDymoLabel.height-topPadding-bottomPadding);
    CGRect paperRect = CGRectMake(0, 0, kSizeDymoLabel.width, kSizeDymoLabel.height);
    [myRenderer setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
    [myRenderer setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];
     */

    [myRenderer addPrintFormatter:formatter startingAtPageAtIndex:0];
    [myRenderer prepareForDrawingPages:NSMakeRange(0, 1)]; // loc len
    //[myRenderer drawPrintFormatter:formatter forPageAtIndex:0];
    NSLog(@"line %d, numberOfPages %ld, printableRect%@", __LINE__,
          (long)myRenderer.numberOfPages,                   // FIXME: 0 pages
          NSStringFromCGRect(myRenderer.printableRect));    // FIXME: null rect
    pic.printPageRenderer = myRenderer;
#endif
    
#ifdef LABEL_PRINT_PIC_USES_PRINTING_ITEM
    // https://stackoverflow.com/questions/19725033/air-printing-of-a-uiview-generates-white-pages
    UIGraphicsBeginImageContextWithOptions(self.medicineLabelView.bounds.size, NO, 0.0);
    [self.medicineLabelView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    pic.printingItem = snapshotImage;
#endif

#ifdef LABEL_PRINT_PIC_USES_PRINTING_ITEM_PDF
    // https://stackoverflow.com/questions/5443166/how-to-convert-uiview-to-pdf-within-ios
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, medicineLabelView.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    [medicineLabelView.layer renderInContext:pdfContext];
    UIGraphicsEndPDFContext();

    pic.printingItem = pdfData;
#endif

    //pic.showsNumberOfCopies = FALSE;
    //pic.showsPaperSelectionForLoadedPapers = TRUE;

    ////////////////////////////////////////////////////////////////////////////

#ifdef USE_DEFAULTS_FOR_SELECTED_PRINTER
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *printerURL = [defaults URLForKey:DEFAULTS_KEY_PRINTER_URL];
  #ifdef DEBUG
    NSLog(@"line %d defaults printer URL\n\t rel: %@\n\t abs: %@\n\t abs: %@", __LINE__,
          printerURL.relativeString,
          printerURL.absoluteString,
          [printerURL.absoluteString stringByRemovingPercentEncoding]); // change %2520 to %20
  #endif
    
    if (printerURL) {
        UIPrinter *printer = [UIPrinter printerWithURL:printerURL];
        [self checkPrinterAndPrint:printer];
    }
    else {
        [self selectLabelPrinterAndPrint];
    }
#else
    if (self.SavedPrinter)
        [self checkPrinterAndPrint:self.SavedPrinter];
    else
        [self selectLabelPrinterAndPrint];
#endif
}

- (void) selectLabelPrinterAndPrint
{
    NSLog(@"%s", __FUNCTION__);
    
#ifdef LABEL_PRINTER_SELECTION_WITH_PREVIEW
    // Show a preview from which we can select the printer and print
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
        else {
            NSString *pid = [NSString stringWithFormat:@"%@", printController.printInfo.printerID];
            NSURL *url = [NSURL URLWithString:pid];  // nil
            // "My\032virtual\032printer._ipp._tcp.local."
            NSLog(@"%s %d, pid: %@, url: <%@", __FUNCTION__, __LINE__, pid, url);
            // FIXME: the url of the printer is nil, which means we cannot save the printer selection
//            [[NSUserDefaults standardUserDefaults] setURL:url
//                                                   forKey:DEFAULTS_KEY_PRINTER_URL];
//            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    };
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CGRect r = [infoView rectForRowAtIndexPath:indexPath];
        [pic presentFromRect:r inView:infoView animated:YES completionHandler:completionHandler];
    }
    else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
    
    [pic presentAnimated:YES completionHandler:completionHandler];
#else
    // Show a printer selection picker, without preview
    
    void (^completionHandler)(UIPrinterPickerController *, BOOL, NSError *) =
    ^(UIPrinterPickerController *controller, BOOL userDidSelect, NSError *err) {
        if (userDidSelect) {
            self.SavedPrinter = controller.selectedPrinter;
            
//#ifdef DEBUG
//            // Test if the selected printer can be contacted (YES)
//            [self tryContactPrinter:self.SavedPrinter message:@"selected"];
//
//            // Test if the printer from just the URL can be contacted (NO)
//            UIPrinter *testPrinter = [UIPrinter printerWithURL:self.SavedPrinter.URL];
//            [self tryContactPrinter:testPrinter message:@"test"];
//#endif
            
#ifdef USE_DEFAULTS_FOR_SELECTED_PRINTER
            [[NSUserDefaults standardUserDefaults] setURL:SavedPrinter.URL
                                                   forKey:DEFAULTS_KEY_PRINTER_URL];
            [[NSUserDefaults standardUserDefaults] synchronize];
#endif
            
            // The notification handler will print the label without preview
            [[NSNotificationCenter defaultCenter] postNotificationName:@"labelPrinterSelection"
                                                                object:self.SavedPrinter];
        }
    };

    UIPrinterPickerController *picker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:self.SavedPrinter];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CGRect r = [infoView rectForRowAtIndexPath:indexPath];
        [picker presentFromRect:r
                         inView:infoView
                       animated:YES
              completionHandler:completionHandler];
     }
     else
         [picker presentAnimated:YES
               completionHandler:completionHandler];

    // Note: without semaphore it returns immediately and SavePrinter is null at this time
    // with semaphore it deadlocks
#endif
}

#ifdef DEBUG
- (void) tryContactPrinter:(UIPrinter *)printer
                   message:(NSString *)aMessage
{
    NSLog(@"%s line %d, %@ printer\n\t displayName:<%@>\n\t displayLocation:<%@>\n\t makeAndModel:<%@>\n\t URL:<%@>", __FUNCTION__, __LINE__, aMessage,
          printer.displayName,
          printer.displayLocation,
          printer.makeAndModel,
          printer.URL);

    [printer contactPrinter:^(BOOL available) {  // up to 30 sseconds
        if (available)
            NSLog(@"line %d, %@ printer available", __LINE__, aMessage);
        else
            NSLog(@"%s line %d, %@ printer NOT available", __FUNCTION__, __LINE__, aMessage);
    }
     ];
}
#endif

- (void) checkPrinterAndPrint:(UIPrinter *)printer
{
    NSLog(@"%s line %d\n\t displayName:<%@>\n\t displayLocation:<%@>\n\t makeAndModel:<%@>\n\t URL:<%@>", __FUNCTION__, __LINE__,
          printer.displayName, // read only
          printer.displayLocation,
          printer.makeAndModel, // undefined until successful contactPrinter
          printer.URL);

    // FIXME: the printer from defaults is always unavailable
    [printer contactPrinter:^(BOOL available) {  // up to 30 sseconds
        if (available) {
            NSLog(@"line %d, printer available, %@", __LINE__,
                  printer.makeAndModel);
            // The notification handler will print the label without preview
            [[NSNotificationCenter defaultCenter] postNotificationName:@"labelPrinterSelection"
                                                                object:printer];
        }
        else {
            NSLog(@"%s line %d, printer NOT available", __FUNCTION__, __LINE__);
            [self selectLabelPrinterAndPrint];
        }
    }
     ];
}

#pragma mark - UIPrintInteractionControllerDelegate

#ifdef DEBUG
- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)pic
{
    NSLog(@"%s", __func__);
    NSLog(@"line %d, using paper size: %@\n\t printable rect: %@", __LINE__,
          NSStringFromCGSize(pic.printPaper.paperSize), // 841 x 595
          NSStringFromCGRect(pic.printPaper.printableRect));
}
#endif

// called after user selects a printer
- (UIPrintPaper *)printInteractionController:(UIPrintInteractionController *)pIC
                                 choosePaper:(NSArray *)paperList
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"line %d paperList count:%lu", __LINE__, (unsigned long)paperList.count);
    for (UIPrintPaper *aPaper in paperList) {
        NSLog(@"line %d paper size: %@\n\t printable rect: %@", __LINE__,
              NSStringFromCGSize(aPaper.paperSize),
              NSStringFromCGRect(aPaper.printableRect));
    }
#endif
    
    CGSize desiredSize = kSizeDymoLabel;
    UIPrintPaper *printPaper = [UIPrintPaper bestPaperForPageSize:desiredSize
                                              withPapersFromArray:paperList];
#ifdef DEBUG
    NSLog(@"line %d, desired size %@ pixels, best paper size %@", __LINE__,
          NSStringFromCGSize(desiredSize),       // 102 x 252
          NSStringFromCGSize(printPaper.paperSize));
#endif
    return printPaper;
}

// https://stackoverflow.com/questions/28321679/custom-print-size-in-ios
//- (CGFloat)printInteractionController:(UIPrintInteractionController *)printInteractionController
//                    cutLengthForPaper:(UIPrintPaper *)paper
//{
//    NSLog(@"%s", __FUNCTION__);
//    return 89.0;
//}
#pragma mark -

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
    if (![self validatePrescription])
        return;

    if (lastUsedURL) {
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtURL:lastUsedURL
                                                                 error:&error];
        if (!success)
            NSLog(@"Error removing file at path: %@", error.localizedDescription);
        
        // If the right view is a AmkListViewController also delete from array and refresh
        id right = self.revealViewController.rightViewController;
        if ([right isKindOfClass:[AmkListViewController class]] ) {
            AmkListViewController *vc = right;
            [vc removeFromListByFilename:[lastUsedURL lastPathComponent]];
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
    
    NSURL *savedURL = [[MLPersistenceManager shared] savePrescription:self.prescription];
    
    if (savedURL) {
        NSLog(@"Saved to file <%@>", savedURL);
        lastUsedURL = savedURL;
    }
    
    possibleToOverwrite = true;

    // Refresh the AMK list
    id right = self.revealViewController.rightViewController;
    if ([right isKindOfClass:[AmkListViewController class]] ) {
        AmkListViewController *vc = right;
        [vc refreshFileList];
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
    label.backgroundColor = [UIColor clearColor];
    label.highlighted = NO;
    // use multiple lines for wrapped text as required
    label.numberOfLines = 0;
    label.preferredMaxLayoutWidth = frame.size.width;
    // this line must be after `numberOfLines`
    [label sizeToFit];
    return label;
}

#pragma mark - Notifications

- (void) newLabelPrinterWasSelected:(NSNotification *)notification
{
    UIPrinter *printer = notification.object;
    NSURL *printerURL = printer.URL;
#ifdef DEBUG
    NSLog(@"%s %@", __FUNCTION__, printerURL);
    
    NSLog(@"line %d, notification with printer\n\t displayName:<%@>,\n\t makeAndModel:<%@>,\n\t URL:<%@>", __LINE__,
          printer.displayName,
          printer.makeAndModel,
          printer.URL);
#endif

    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    
    if (!pic) {
        NSLog(@"%s PrintInteractionController not yet defined", __FUNCTION__);
        return;
    }

    [pic printToPrinter:printer completionHandler:completionHandler];
}

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
}

- (void)amkListDidChangeSelection:(NSNotification *)aNotification
{
    NSURL *url = [aNotification object];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:url.lastPathComponent forKey:@"lastUsedPrescription"];
    [defaults synchronize];

    lastUsedURL = url;
    prescription = [[Prescription alloc] initWithURL:lastUsedURL];
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
    id right = self.revealViewController.rightViewController;
    if ([right isKindOfClass:[AmkListViewController class]] ) {
        AmkListViewController *vc = right;
        [vc refreshList];
    }
}

- (void)addMedication:(Product *)p
{
    if (!prescription) {
        prescription = [Prescription new];
        lastUsedURL = nil;
    }
    
    if (!prescription.medications)
        prescription.medications = [NSMutableArray new];
    
    [prescription.medications addObject:p];
    self.editedMedicines = true;
    
    // Update GUI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateButtons];
        [self.infoView reloadData];
    });
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

    [patientVC handleCameraButton:nil];
}


- (void) showCameraForBarcodeAcquisition
{
    // Make sure front is PrescriptionViewController
    UIViewController *nc_front = self.revealViewController.frontViewController; // UINavigationController
    UIViewController *vc_front = [nc_front.childViewControllers firstObject];   // PrescriptionViewController

    barcodeHandled = false;

    if (!self.videoVC)
        self.videoVC = nil; // So that it will be reinitialized with the current orientation
    
    self.videoVC = [[VideoViewController alloc] initWithNibName:@"VideoViewController"
                                                         bundle:nil];
    self.videoVC.delegate = self;
    [vc_front presentViewController:self.videoVC
                           animated:NO
                         completion:NULL];
}

#pragma mark - File presenter

- (NSURL *)presentedItemURL {
    return lastUsedURL;
}

- (NSOperationQueue *)presentedItemOperationQueue {
    return [NSOperationQueue mainQueue];
}

- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    if (possibleToOverwrite) {
        [self overwritePrescription];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(nil);
    });
}

- (void)presentedItemDidChange {
    prescription = [[Prescription alloc] initWithURL:lastUsedURL];
    [self updateButtons];
    [infoView reloadData];
    possibleToOverwrite = true;
}

#pragma mark - UIGestureRecognizerDelegate

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint p = [gesture locationInView:infoView];
    NSIndexPath *indexPath = [infoView indexPathForRowAtPoint:p];
    CGRect rectPatientSection = [infoView rectForSection:kSectionPatient];
    CGRect rectMedicineHeader = [infoView rectForHeaderInSection:kSectionMedicines];

//    NSLog(@"%s line %d, indexPath %@, section %ld", __FUNCTION__, __LINE__,
//          indexPath, (long)indexPath.section);

    if (CGRectContainsPoint(rectPatientSection, p))
    {
        [self showCameraForHealthCardOCR];
        return;
    }

    if (CGRectContainsPoint(rectMedicineHeader, p))
    {
        [self showCameraForBarcodeAcquisition];
        return;
    }
 
    if (!indexPath) {
#ifdef DEBUG
        NSLog(@"%s line %d", __FUNCTION__, __LINE__);
#endif
        return;
    }
    
    if (indexPath.section == kSectionPatient) {
#ifdef DEBUG
        NSLog(@"%s line %d", __FUNCTION__, __LINE__);
#endif
        [self showCameraForHealthCardOCR];
        return;
    }

    if (indexPath.section != kSectionMedicines) {
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

    if ([UIPrintInteractionController isPrintingAvailable]) {
        UIAlertAction *actionPrintLabel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Print Label", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     [alertController dismissViewControllerAnimated:YES completion:nil];
                                                                     
                                                                     self->indexPath = indexPath;
                                                                     [self printMedicineLabel];
                                                                 }];
        [alertController addAction:actionPrintLabel];
    }
#ifdef DEBUG
    else {
        NSLog(@"%s line %d, printing not available", __FUNCTION__, __LINE__);
    }
#endif
    
    UIAlertAction *actionEdit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit comment", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         
                                                           self->editingCommentIdx = indexPath.row;
                                                           [self.infoView reloadData];
                                                       }];
    [alertController addAction:actionEdit];

    UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete package", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             
                                                             [self.prescription.medications removeObjectAtIndex:indexPath.row];
                                                             self.editedMedicines = true;
                                                             [self.infoView reloadData];
                                                         }];
    [alertController addAction:actionDelete];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             }];
        [alertController addAction:actionCancel];
    }
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
    UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolBar.barStyle = UIBarStyleBlack;
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
    if (commentEditingActive)
        return NO;
    
    [textView resignFirstResponder];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
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
    self.editedMedicines = true;
    [infoView reloadData];
    activeTextView = nil;
    
    //infoView.scrollEnabled = YES;  // Not needed after using commentEditingActive
}

- (void) recalculateSavedOffset
{
    CGRect r = [infoView convertRect:activeTextView.frame fromView:activeTextView];
    CGPoint offset = infoView.contentOffset;
    
    CGFloat margin;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        margin = 100.0;
    else
        margin = 50.0;
    
    CGFloat yAdjustment = savedKeyboardY - (r.origin.y + r.size.height + margin - offset.y);
    if (yAdjustment < 0.0)
    {
        savedOffset = CGPointMake(0.0f, offset.y - yAdjustment);
        [self.infoView setContentOffset:savedOffset animated:NO];
    }
    else {
        savedOffset = offset;
    }
}

- (NSString *)getPlaceDateForPrinting
{
    NSString *placeDate = prescription.placeDate;// placeDateField.stringValue;
    NSArray *placeDateArray = [placeDate componentsSeparatedByString:@" ("];
    return [NSString stringWithFormat:@"%@", [placeDateArray objectAtIndex:0]];
}

- (void)addPdfPageNumber:(CGFloat)pageOriginY pageNumber:(NSInteger)pn
{
    const CGFloat margin = 50.0;
    const CGFloat fontSize = 11.0;

    const CGFloat pageNumberY = mm2pix(50);
    
    NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyleRight.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyleRight.alignment = NSTextAlignmentRight;
    
    NSDictionary * attrPN = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                               NSParagraphStyleAttributeName: paragraphStyleRight};
    
    NSString *strPage = [NSString stringWithFormat:@"%@ %ld",
                         NSLocalizedString(@"Page", nil),
                         (long)pn];

    CGSize sizePN = [strPage sizeWithAttributes:attrPN];
    CGFloat pageNumberX = kSizeA4.width - sizePN.width - margin;
    
    [strPage drawAtPoint:CGPointMake(pageNumberX, pageOriginY + pageNumberY)
          withAttributes:attrPN];
}

- (void)drawPdfHeader:(CGFloat)pageOriginY withEPrescriptionQRCode:(UIImage *)qrCode
{
    const CGFloat margin = 50.0;
    const CGFloat fontSize = 11.0;
    
    const CGFloat filenameY = mm2pix(50);
    const CGFloat docY = mm2pix(60);
    const CGFloat patY = mm2pix(60);
    const CGFloat placeDateY = mm2pix(95);
    
    // Doctor
    NSString *strDoctor = [prescription.doctor getStringForPrescriptionPrinting];
    
    NSMutableParagraphStyle *paragraphStyleRight = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyleRight.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyleRight.alignment = NSTextAlignmentRight;
    
    NSDictionary * attrDoc = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
#ifdef DEBUG
                               NSBackgroundColorAttributeName:[UIColor systemGreenColor],
#endif
                               NSParagraphStyleAttributeName: paragraphStyleRight};
    CGSize sizeDoc = [strDoctor sizeWithAttributes:attrDoc]; // FIXME: single line
    CGFloat doctorX = kSizeA4.width - sizeDoc.width - margin;
    [strDoctor drawAtPoint:CGPointMake(doctorX, pageOriginY+docY)
            withAttributes:attrDoc];
    
    // Patient
    NSString *strPat = [prescription.patient getStringForPrescriptionPrinting];
    
    NSMutableParagraphStyle *paragraphStylePatient = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStylePatient.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStylePatient.alignment = NSTextAlignmentLeft;
    
    NSDictionary *attrPat = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                              NSParagraphStyleAttributeName: paragraphStylePatient};
    [strPat drawAtPoint:CGPointMake(margin, pageOriginY + patY)
         withAttributes:attrPat];
    
    // Signature
    if (qrCode) {
        CGFloat shorterSide = MIN(DOCTOR_TN_W, DOCTOR_TN_H);
        CGFloat signatureX = doctorX; // left aligned with doctor
        CGRect signatureRect = CGRectMake(signatureX,
                                          pageOriginY+docY+sizeDoc.height,
                                          shorterSide,
                                          shorterSide);
        [qrCode drawInRect:signatureRect];
    } else {
        UIImage *img = [prescription.doctor thumbnailFromSignature:CGSizeMake(DOCTOR_TN_W, DOCTOR_TN_H)];
        CGFloat signatureX = doctorX; // left aligned with doctor
        CGRect signatureRect = CGRectMake(signatureX,
                                          pageOriginY+docY+sizeDoc.height,
                                          img.size.width,
                                          img.size.height);
        [img drawInRect:signatureRect];
#ifdef DEBUG
        // Show a border to verify the alignment
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, [UIColor labelColor].CGColor);
        CGContextStrokeRect(context, signatureRect);
#endif
    }
    
    // Place and date
    [prescription.placeDate drawAtPoint:CGPointMake(margin, pageOriginY + placeDateY)
                         withAttributes:attrPat];
    
    // Document filename
    // FIXME: if the prescription is shared a second time this filename is nil
    //  hint: why is fileExistsAtPath returning false in loadDefaultPrescription ?
    NSString *fileName = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastUsedPrescription"];
    fileName = [fileName stringByDeletingPathExtension]; // drop .amk
    [fileName drawAtPoint:CGPointMake(margin, pageOriginY + filenameY)
           withAttributes:attrPat];
}

- (NSMutableData *)renderPdfForPrintingWithEPrescriptionQRCode:(UIImage * _Nullable)qrCode
{
    const CGFloat margin = mm2pix(18);
    const CGFloat fontSize = 11.0;

    const CGFloat medY = mm2pix(110);
    const CGFloat medSpacing = mm2pix(8);

    CGSize fittedSize = kSizeA4;
    CGRect pdfPageBounds = CGRectMake(0, 0, kSizeA4.width, kSizeA4.height);
    NSInteger nMed = [prescription.medications count];

    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, pdfPageBounds,nil);
    CGFloat pageOriginY = 0;
    NSInteger pageNumber = 1;
    while (pageOriginY < fittedSize.height) // TODO: obsolete this while loop
    {
        // Start a new page
        UIGraphicsBeginPDFPageWithInfo(pdfPageBounds, nil);
        CGContextSaveGState(UIGraphicsGetCurrentContext());
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, -pageOriginY);

        [self drawPdfHeader:pageOriginY withEPrescriptionQRCode:qrCode];

        // Medicines
        CGFloat medYOffset = medY;

        NSMutableParagraphStyle *paragraphStyleLeft = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyleLeft.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyleLeft.alignment = NSTextAlignmentLeft;

        NSMutableParagraphStyle *paragraphStyleComment = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyleComment.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyleComment.alignment = NSTextAlignmentLeft;
        
        NSDictionary *attrEan = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                  NSForegroundColorAttributeName:[UIColor systemGrayColor],
                                  NSParagraphStyleAttributeName: paragraphStyleLeft};

        NSDictionary *attrMedPackage = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                         NSForegroundColorAttributeName:[UIColor systemBlueColor],
                                         NSParagraphStyleAttributeName: paragraphStyleLeft};
        
        NSDictionary *attrMedComment = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                         NSForegroundColorAttributeName:[UIColor systemGrayColor],
                                         NSParagraphStyleAttributeName: paragraphStyleComment};

        for (NSInteger i=0; i<nMed; i++) {
            Product *med = prescription.medications[i];

            NSString *packInfo = med.packageInfo;
            NSString *ean = med.eanCode;
            NSString *comment = med.comment;

            CGSize sizePackInfo = [packInfo sizeWithAttributes:attrMedPackage];
            CGSize sizeEan = [ean sizeWithAttributes:attrEan];
            CGSize sizeComment = CGSizeZero;

            if (comment.length > 0) {
                // multi-line
                CGFloat desiredWidth = kSizeA4.width - 2*margin;
                CGRect neededRect =
                [comment boundingRectWithSize:CGSizeMake(desiredWidth, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                   attributes:attrMedComment
                                      context:nil];
                sizeComment = CGSizeMake(desiredWidth, neededRect.size.height);
            }
            
            CGFloat currentY = medYOffset + sizePackInfo.height + sizeEan.height + sizeComment.height;
#ifdef DEBUG
            NSLog(@"PDF page %ld, med[%ld], pageY: %f, currentY: %f",
                  (long)pageNumber, (long)i,
                  pdfPageBounds.size.height,
                  currentY);
#endif
            // Check if the total size fits the page
            if (currentY > (pdfPageBounds.size.height - margin)) {
                // Add page number to current page
                [self addPdfPageNumber:pageOriginY pageNumber:pageNumber];

                // Terminate current page
                CGContextRestoreGState(UIGraphicsGetCurrentContext());
                pageOriginY += pdfPageBounds.size.height;
                
                // Start new page
                UIGraphicsBeginPDFPageWithInfo(pdfPageBounds, nil);
                CGContextSaveGState(UIGraphicsGetCurrentContext());
                CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, -pageOriginY);
                
                // TODO: draw header
                [self drawPdfHeader:pageOriginY withEPrescriptionQRCode:qrCode];
                medYOffset = medY;
                pageNumber++;
            }

            [packInfo drawAtPoint:CGPointMake(margin, pageOriginY + medYOffset) withAttributes:attrMedPackage];
            medYOffset += sizePackInfo.height;

            [ean drawAtPoint:CGPointMake(margin, pageOriginY + medYOffset) withAttributes:attrEan];
            medYOffset += sizeEan.height;

            if (comment.length > 0) {
                CGPoint commentPoint = CGPointMake(margin, pageOriginY + medYOffset);
                CGRect commentRect = {commentPoint, sizeComment};
                [comment drawInRect:commentRect withAttributes:attrMedComment];
                medYOffset += sizeComment.height;
            }

            medYOffset += medSpacing;
        }   // nMed for loop
        
        // Terminate current page

        // Add page number to last page
        if (pageNumber > 1)
            [self addPdfPageNumber:pageOriginY pageNumber:pageNumber];

        CGContextRestoreGState(UIGraphicsGetCurrentContext());
        pageOriginY += pdfPageBounds.size.height;
    } // while loop (to be obsoleted)

    UIGraphicsEndPDFContext();
    
    return pdfData;
}

- (void)sharePrescription:(NSURL *)urlAttachment
{
#ifdef DEBUG
    NSLog(@"%s sharing <%@>", __FUNCTION__, urlAttachment);
#endif
    if ([[MLPersistenceManager shared] HINADSwissAuthHandle]) {
        [self sharePrescription:urlAttachment withEPrescription:YES];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"Do you want to sign your prescription?", @"")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self sharePrescription:urlAttachment withEPrescription:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self sharePrescription:urlAttachment withEPrescription:NO];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)getADSwissAuthHandleWithCallback:(void(^)(NSError *_Nullable error, MLHINADSwissAuthHandle *_Nullable authHandle))callback {
    MLHINADSwissAuthHandle *handle = [[MLPersistenceManager shared] HINADSwissAuthHandle];
    if (handle) {
        callback(nil, handle);
        return;
    }
    typeof(self) __weak _self = self;
    MLHINTokens *tokens = [[MLPersistenceManager shared] HINADSwissTokens];
    [[MLHINClient shared] fetchADSwissSAMLWithToken:tokens completion:^(NSError * _Nullable error, MLHINADSwissSaml * _Nullable result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                callback(error, nil);
                return;
            }
            ASWebAuthenticationSession *session = [[ASWebAuthenticationSession alloc] initWithURL:[NSURL URLWithString:result.epdAuthUrl]
                                                                                callbackURLScheme:[[MLHINClient shared] oauthCallbackScheme]
                                                                                completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                if (error) {
                    if ([[error domain] isEqual:@"com.apple.AuthenticationServices.WebAuthenticationSession"] && error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin) {
                        // User cancelled is not an error
                        callback(nil, nil);
                    } else {
                        callback(error, nil);
                    }
                    return;
                }
                if (callbackURL) {
                    NSURLComponents *components = [NSURLComponents componentsWithURL:callbackURL
                                                             resolvingAgainstBaseURL:NO];
                    for (NSURLQueryItem *query in [components queryItems]) {
                        if ([query.name isEqual:@"auth_code"]) {
                            [[MLHINClient shared] fetchADSwissAuthHandleWithToken:[[MLPersistenceManager shared] HINADSwissTokens]
                                                                         authCode:query.value
                                                                       completion:^(NSError * _Nullable error, NSString * _Nullable authHandle) {
                                NSLog(@"received Auth Handle1 %@ %@", error, authHandle);
                                if (error) {
                                    callback(error, nil);
                                    return;
                                }
                                if (!authHandle) {
                                    callback([NSError errorWithDomain:@"com.ywesee.AmikoDesitin"
                                                                            code:0
                                                                        userInfo:@{
                                        NSLocalizedDescriptionKey: @"Invalid authHandle"
                                    }], nil);
                                    return;
                                }
                                MLHINADSwissAuthHandle *handle = [[MLHINADSwissAuthHandle alloc] initWithToken:authHandle];
                                [[MLPersistenceManager shared] setHINADSwissAuthHandle:handle];
                                callback(nil, handle);
                            }];
                            break;
                        }
                    }
                }
            }];
            session.presentationContextProvider = _self;
            [session start];
        });
    }];
}

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.view.window;
}

- (void)getEPrescriptionQRCodeWithCallback:(void(^)(NSError *_Nullable error, UIImage *_Nullable qrCode))callback {
    typeof(self) __weak _self = self;
    [[MLHINClient shared] performADSwissOAuthWithViewController:self
                                                       callback:^(NSError * _Nullable error) {
        if (error) {
            callback(error, nil);
            return;
        }
        if ([[MLPersistenceManager shared] HINADSwissTokens]) {
            [self getADSwissAuthHandleWithCallback:^(NSError * _Nullable error, MLHINADSwissAuthHandle * _Nullable authHandle) {
                if (error) {
                    callback(error, nil);
                    return;
                }
                if (authHandle) {
                    [[MLHINClient shared] makeQRCodeWithAuthHandle:authHandle
                                                     ePrescription:_self.prescription
                                                          callback:callback];
                } else {
                    callback(nil, nil);
                }
            }];
        } else {
            callback(nil, nil);
        }
    }];
}

- (void)displayError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sharePrescription:(NSURL *)urlAttachment withEPrescription:(BOOL)useEPrescription {
    typeof(self) __weak _self = self;
    if (useEPrescription) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Generating E-Prescription", @"")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        [self getEPrescriptionQRCodeWithCallback:^(NSError * _Nullable error, UIImage * _Nullable qrCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:^{
                    if (error) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                                       message:error.localizedDescription
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil]];
                        [_self presentViewController:alert animated:YES completion:nil];
                        return;
                    }
                    NSMutableData *pdfData = [self renderPdfForPrintingWithEPrescriptionQRCode:qrCode];
                    [_self sharePrescription:urlAttachment withPdfData:pdfData];
                }];
            });
        }];
    } else {
        NSMutableData *pdfData = [self renderPdfForPrintingWithEPrescriptionQRCode:nil];
        [self sharePrescription:urlAttachment withPdfData:pdfData];
    }
}

- (void)sharePrescription:(NSURL *)urlAttachment withPdfData:(NSData *)pdfData {
    NSString *mailBody = [NSString stringWithFormat:@"%@\n\niOS: %@\nAndroid: %@\n",
                          NSLocalizedString(@"Open with", nil),
                          @"https://itunes.apple.com/ch/app/generika/id520038123?mt=8",
                          @"https://play.google.com/store/apps/details?id=org.oddb.generika"];
    //NSString *mailBody2 = [NSString stringWithFormat:@"Your prescription from Dr.:%@", prescription.doctor.familyName];
    
    NSString * subjectLine =
    [NSString stringWithFormat:NSLocalizedString(@"Prescription to patient from doctor",nil),
     prescription.patient.givenName,
     prescription.patient.familyName,
     prescription.patient.birthDate,
     prescription.doctor.title,
     prescription.doctor.givenName,
     prescription.doctor.familyName];
    
    // Prepare the objects to be shared

    // If we use the PDF object directly into the array it also gets added as a second attachment to the email.
    // Instead, we use it through an item provider so that we can make it return nil for email activity.
    PrintItemProvider *source3 = [[PrintItemProvider alloc] initWithPlaceholderItem:pdfData];

    NSArray *objectsToShare = @[mailBody, urlAttachment, source3];
    
    MLSendToZurRoseActivity *zurRoseActivity = [[MLSendToZurRoseActivity alloc] init];
    zurRoseActivity.zurRosePrescription = self.prescription.toZurRosePrescription;

    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:@[zurRoseActivity]];

    NSArray *excludeActivities = @[UIActivityTypeCopyToPasteboard,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    activityVC.excludedActivityTypes = excludeActivities;

    [activityVC setValue:subjectLine forKey:@"subject"];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        activityVC.modalPresentationStyle = UIModalPresentationPopover;

    [self presentViewController:activityVC animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [activityVC popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    activityVC.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
#ifdef DEBUG
        // react to the completion
        if (completed) {
            // user shared an item
            NSLog(@"We used activity type: <%@>", activityType);
            if ([activityType isEqualToString:UIActivityTypeMail]) {
                //return @"Your subject goes here";
            }
        }
        else {
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
        }
#endif
        
        if (error)
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
    };
}

#pragma mark - SampleBufferDelegate methods
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// See videoCaptureDemo and Generika
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (barcodeHandled) {
#ifdef DEBUG
        static int frameNumber = 1;
        NSLog(@"%s frame %d", __FUNCTION__, frameNumber++);
        
        NSLog(@"line %d, already handled", __LINE__);
#endif
        return;
    }

    if (!self.videoVC) {
#ifdef DEBUG
        NSLog(@"line %d, video view controller is nil", __LINE__);
#endif
        return;
    }
    
    if (self.videoVC &&
        !self.videoVC.isSessionRunning) {
        
#ifdef DEBUG
        NSLog(@"line %d, session not running", __LINE__); // Maybe we hit the Cancel button
#endif
        return;
    }
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef myImage = [context
                          createCGImage:ciImage
                          fromRect:CGRectMake(0, 0,
                                              CVPixelBufferGetWidth(pixelBuffer),
                                              CVPixelBufferGetHeight(pixelBuffer))];
    
    UIImage *image = [UIImage imageWithCGImage:myImage];
    CGImageRelease(myImage);
    
    if (!image) {
        NSLog(@"line %d: image is nil", __LINE__);
        return;
    }

    // Detection of barcode with Vision framework
    
    VNDetectBarcodesRequest *barcodeRequest = [VNDetectBarcodesRequest new];
    barcodeRequest.symbologies = @[VNBarcodeSymbologyEAN13, VNBarcodeSymbologyQR];
    
    CIImage *ciimage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    CGImagePropertyOrientation orient;
    if (image.imageOrientation == UIImageOrientationRight) {
        orient = kCGImagePropertyOrientationRight; // for portrait
    }
    else if (image.imageOrientation == UIImageOrientationUp) {
        orient = kCGImagePropertyOrientationUp; // for landscape L
    }
    else { //if (imageCard.imageOrientation == UIImageOrientationDown) {
        orient = kCGImagePropertyOrientationDown; // for landscape R
    }
    
    VNImageRequestHandler *handler =
    [[VNImageRequestHandler alloc] initWithCIImage:ciimage
                                       orientation:orient
                                           options:@{}];
    [handler performRequests:@[barcodeRequest] error:nil];
    
    if (barcodeRequest.results.count == 0) {
        return;
    }

    // We know we have at least one barcode, use the first one
    VNBarcodeObservation *firstObservation = barcodeRequest.results[0];
    NSString *s = firstObservation.payloadStringValue;
#ifdef DEBUG
    NSLog(@"%@ %@", s, firstObservation.symbology);
#endif

    // Dismisss the video
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%s line %d", __FUNCTION__, __LINE__);
        if (self.videoVC) {
            [self.videoVC dismissViewControllerAnimated:NO completion:NULL]; // ok
            self.videoVC = nil;
        }
    });
    
#ifdef DEBUG
    NSLog(@"%s line %d, set already handled", __FUNCTION__, __LINE__);
#endif
    barcodeHandled = true;
    
    if (firstObservation.symbology == VNBarcodeSymbologyQR) {
        EPrescription *prescription = [[EPrescription alloc] initWithCHMED16A1String:firstObservation.payloadStringValue];
        if (prescription) {
            [self didScanEPrescription:prescription];
        }
        return;
    }

    if (firstObservation.symbology != VNBarcodeSymbologyEAN13) {
        NSLog(@"%s line %d, barcode type is not EAN13", __FUNCTION__, __LINE__);
        [self showAlertForBarcodeNotFound];
        return;
    }
    // Look up the code in the DB
    
    MLDBAdapter *db = [MLDBAdapter sharedInstance];
    NSString *dbTitle, *dbAuth, *dbAtc, *dbRegnrs, *dbPackInfo, *dbPackages;
    NSString *packageInfo;  // 1st line in table infoView
    NSString *eancode;      // 2nd line in table infoView
    NSArray *queryResult = [db searchEan :s];

    BOOL found = FALSE;
    for (NSArray *cursor in queryResult) {
        dbTitle = (NSString *)[cursor objectAtIndex:0];
        dbAuth = (NSString *)[cursor objectAtIndex:1];
        dbAtc = (NSString *)[cursor objectAtIndex:2];
        dbRegnrs = (NSString *)[cursor objectAtIndex:3];
        dbPackInfo = (NSString *)[cursor objectAtIndex:4];
        dbPackages = (NSString *)[cursor objectAtIndex:5];

        // Some fields have multiple lines: split them into arrays
        NSArray *packInfoArray = [dbPackInfo componentsSeparatedByString:@"\n"];
        NSArray *packArray = [dbPackages componentsSeparatedByString:@"\n"];  // Note: there is also a \n after the last line, so the count is one more (last array element is empty)

        // Each line contains one EAN code (9th component)
        for (int i=0; i < [packArray count]; i++) {
            NSArray *p = [packArray[i] componentsSeparatedByString:@"|"];
            if ([p count] <= INDEX_EAN_CODE_IN_PACK)
                break;

            eancode = [p objectAtIndex:INDEX_EAN_CODE_IN_PACK];
            if ([eancode isEqualToString:s]) {
                found = TRUE;
                if (packInfoArray.count > i)
                    packageInfo = packInfoArray[i];

                break;
            }
        }
    }

    // Add medicine to prescription
    if (found) {
        NSMutableDictionary *medicationDict = [NSMutableDictionary new];
        [medicationDict setObject:packageInfo forKey:KEY_AMK_MED_PACKAGE];
        [medicationDict setObject:eancode     forKey:KEY_AMK_MED_EAN];

        [medicationDict setObject:dbTitle     forKey:KEY_AMK_MED_TITLE];
        [medicationDict setObject:dbAuth      forKey:KEY_AMK_MED_OWNER];
        [medicationDict setObject:dbRegnrs    forKey:KEY_AMK_MED_REGNRS];
        [medicationDict setObject:dbAtc       forKey:KEY_AMK_MED_ATC];
        Product *product = [[Product alloc] initWithDict:medicationDict]; // See Product initWithMedication
        
        [[PrescriptionViewController sharedInstance] addMedication:product];
    }
    else {
        [self showAlertForBarcodeNotFound];
    }
    
    // Cleanup
    ciimage = nil;
}

- (void) showAlertForBarcodeNotFound
{
    dispatch_async( dispatch_get_main_queue(), ^{
        NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSString *message = NSLocalizedString(@"No package found with this barcode. Please contact zdavatz@ywesee.com", nil);
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:bundleName
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:okAction];
      
        [self presentViewController:alertController animated:YES completion:nil];
    } );
}

- (void)didScanEPrescription:(EPrescription *)ePrescription {
    Prescription *prescription = [[Prescription alloc] initWithAMKDictionary:ePrescription.amkDict];
    [[MLPersistenceManager shared] upsertPatient:prescription.patient];
    NSURL *savedURL = [[MLPersistenceManager shared] savePrescription:prescription];
    NSLog(@"saved to: %@", savedURL);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Send to ZurRose?", @"")
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", @"")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
            [ePrescription.toZurRosePrescription sendToZurRoseWithCompletion:^(NSHTTPURLResponse * _Nonnull res, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error || res.statusCode != 200) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                                       message:[error localizedDescription] ?: [NSString stringWithFormat:NSLocalizedString(@"Error Code: %ld", @""), res.statusCode]
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                  style:UIAlertActionStyleDefault
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    } else {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:NSLocalizedString(@"Prescription is sent to ZurRose", @"")
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                  style:UIAlertActionStyleDefault
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                });
            }];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    });
}

@end
