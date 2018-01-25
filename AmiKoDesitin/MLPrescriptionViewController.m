//
//  MLPrescriptionViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 22 Jan 2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionViewController.h"
#import "SWRevealViewController.h"
#import "MLUtility.h"

static const float kInfoCellHeight = 20.0;  // fixed
static const float kItemCellHeight = 44.0;  // minimum height

static const float kSectionHeaderHeight = 27.0;
static const float kLabelMargin = 2.4;

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
    CGSize boundSize = [label.text
                        boundingRectWithSize:constraint
                        options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:@{NSFontAttributeName:label.font}
                        context:context].size;
    return CGSizeMake(ceil(boundSize.width), ceil(boundSize.height));
}

#pragma -

@interface MLPrescriptionViewController ()

@end

@implementation MLPrescriptionViewController
{
#ifdef DEBUG
    NSArray *tableData;
#endif
    CGRect mainFrame;
}

- (void)viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // SWRevealViewController extends UIViewController!
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];

    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:revealController
                                                                        action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    // TODO: add button on the right for old prescriptions
    
    // PanGestureRecognizer goes here
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];

#ifdef DEBUG
    tableData = [NSArray arrayWithObjects:@"Ponstan", @"Marcoumar", @"Abilify", nil];
#endif
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int statusBarHeight = [
                           UIApplication sharedApplication].statusBarFrame.size.height;
    int navBarHeight = self.navigationController.navigationBar.frame.size.height;
    int barHeight = statusBarHeight + navBarHeight;
    mainFrame = CGRectMake(0,
                                  barHeight,
                                  screenBounds.size.width,
                                  CGRectGetHeight(screenBounds) - barHeight);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumSections;
}

- (nullable NSString *)tableView:(UITableView *)tableView
         titleForHeaderInSection:(NSInteger)section
{
#ifdef DEBUG
    NSLog(@"%s section:%ld", __FUNCTION__, section);
#endif
    if (section == kSectionMeta)
        return nil; //NSLocalizedString(@"Meta", nil);
    
    if (section == kSectionOperator)
        return NSLocalizedString(@"Doctor", nil);
    
    if (section == kSectionPatient)
        return NSLocalizedString(@"Patient", nil);
    
    return [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"Medicines", nil) , [tableData count]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // default value: UITableViewAutomaticDimension;
    if (section == kSectionMeta)
        return kSectionHeaderHeight / 2.5;

    // operator|patient
    return kSectionHeaderHeight;
}

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
#ifdef DEBUG
    NSLog(@"%s section:%ld", __FUNCTION__, section);
#endif
    // Return the number of rows in the section.
    if (section == kSectionMeta)
        return 1;

    if (section == kSectionOperator)
        return 5;

    if (section == kSectionPatient)
        return 6;
    
    //if (section == kSectionMedicines)
        return [tableData count];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kSectionMedicines)
        return kInfoCellHeight;

    //Product *product = [self.receipt.products objectAtIndex:indexPath.row];
    //if (product)
    {
        CGFloat height = 0.0;
        CGFloat width = tableView.frame.size.width - 24.0;

        // package name label
        UILabel *packLabel = [self makeLabel:@"Pack"
                                   textColor:[UIColor clearColor]];
        height += getSizeOfLabel(packLabel, width).height;
        height += kLabelMargin;
        // ean label
        UILabel *eanLabel = [self makeLabel:@"Ean"
                                  textColor:[UIColor clearColor]];
        height += getSizeOfLabel(eanLabel, width).height;
        height += kLabelMargin;
        height += 8.0;
        // comment label
        UILabel *commentLabel = [self makeLabel:@"Comment"
                                      textColor:[UIColor clearColor]];
        height += getSizeOfLabel(commentLabel, width).height;
        height += kLabelMargin;
        height += 8.0;
        if (height > kItemCellHeight) {
            return height;
        }
    }
    return kItemCellHeight;
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
    //NSLog(@"%s section:%ld, row:%ld", __FUNCTION__, indexPath.section, indexPath.row);
    //NSLog(@"size: %@", NSStringFromCGSize(tableView.frame.size));
#endif

    static NSString *tableIdentifier = @"PrescriptionTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 //UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    }
    
    CGRect frame = CGRectMake(12.0, 0, tableView.frame.size.width, 25.0);

    if (indexPath.section == kSectionMedicines)
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    else
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    if (indexPath.section == kSectionMeta) {
        cell.textLabel.text = @"meta data";
    }
    else if (indexPath.section == kSectionOperator) {
        // TODO: create MLOperator.m with retrieveOperatorAsString
        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        switch (indexPath.row) {
            case 0:
                label.text = @"title givenName familyName";
                // TODO: signature image
                break;
            case 1:
                label.text = @"postalAddress";
                break;
            case 2:
                label.text = @"zipCode city";
                break;
            case 3:
                label.text = @"phoneNumber";
                break;
            case 4:
                label.text = @"emailAddress";
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == kSectionPatient) {
        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        switch (indexPath.row) {
            case 0:
                label.text = @"givenName familyName";
                break;
            case 1:
                label.text = @"kg/cm gender birth_date";
                break;
            case 2:
                label.text = @"postal address";
                break;
            case 3:
                label.text = @"city country";
                break;
            case 4:
                label.text = @"phoneNumber";
                break;
            case 5:
                label.text = @"emailAddress";
                break;
            default:
                break;
        }
    }
    else {
        // TODO: get product
        UILabel *packLabel = [self makeLabel:[tableData objectAtIndex:indexPath.row]
                                   textColor:[UIColor blackColor]];

        UILabel *eanLabel = [self makeLabel:@"eanLabel"
                                  textColor:[UIColor darkGrayColor]];

        UILabel *commentLabel = [self makeLabel:@"commentLabel"
                                      textColor:[UIColor darkGrayColor]];

        // layout
        CGRect eanFrame = CGRectMake(12.0,
                                     packLabel.frame.origin.y + packLabel.frame.size.height + kLabelMargin,
                                     eanLabel.frame.size.width,
                                     eanLabel.frame.size.height);
        [eanLabel setFrame:eanFrame];
        
        CGRect commentFrame = CGRectMake(12.0,
                                         eanLabel.frame.origin.y + eanLabel.frame.size.height + kLabelMargin,
                                         commentLabel.frame.size.width,
                                         commentLabel.frame.size.height);
        [commentLabel setFrame:commentFrame];
        [cell.contentView addSubview:packLabel];
        [cell.contentView insertSubview:eanLabel belowSubview:packLabel];
        [cell.contentView insertSubview:commentLabel belowSubview:eanLabel];
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

#pragma mark - Toolbar

- (IBAction) newPrescription:(id)sender
{
    UIBarButtonItem *btn = (UIBarButtonItem *)sender;
#ifdef DEBUG
    NSLog(@"%s tag:%ld, title:%@", __FUNCTION__, btn.tag, btn.title);
#endif
}

- (IBAction) checkForInteractions:(id)sender
{
    // TODO:
}

- (IBAction) savePrescription:(id)sender
{
    NSString *alertMessage = nil;
    NSString *alertTitle = nil;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:NSLocalizedString(@"Overwrite Prescription", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         [self overwritePrescription];
                                                     }];
    
    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save as New Prescription", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                             [self saveNewPrescription];
                                                         }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alertController addAction:actionOk];
    [alertController addAction:actionNo];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil]; // It returns immediately
}

- (IBAction) sendPrescription:(id)sender
{
    [self savePrescription:sender];
    // TODO:
}

#pragma -

- (void) overwritePrescription
{
    NSString *documentsDir = [MLUtility documentsDirectory];
#ifdef DEBUG
    NSLog(@"documentsDir:%@", documentsDir);
#endif
    
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

- (void) saveNewPrescription
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

- (UILabel *)makeLabel:(NSString *)text textColor:(UIColor *)color
{
    CGRect frame = CGRectMake(12.0, 8.0,
                              (mainFrame.size.width - 24.0),
                              kItemCellHeight);
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

@end
