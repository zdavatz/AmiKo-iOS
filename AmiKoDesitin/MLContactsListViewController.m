//
//  MLContactsListViewController.m
//  AmikoDesitin
//
//  Created by Alex Bettarini on 8 Feb 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "MLContactsListViewController.h"
#import <Contacts/Contacts.h>
#import "MLPatient.h"
#import "SWRevealViewController.h"

@interface MLContactsListViewController ()

@end

@implementation MLContactsListViewController
{
    NSMutableArray *mFilteredArrayOfPatients;
    NSString *mPatientUUID;
    BOOL mSearchFiltered;

    NSArray *mArrayOfPatients;
    NSMutableArray *groupOfContacts;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    mFilteredArrayOfPatients = [[NSMutableArray alloc] init];
    mSearchFiltered = FALSE;
    mPatientUUID = nil;
    
    // Retrieves contacts from address book
    mArrayOfPatients = [self getAllContacts];
#ifdef DEBUG
//    NSLog(@"%s mArrayOfPatients count:%ld", __FUNCTION__, [mArrayOfPatients count]);
//    for (MLPatient *p in mArrayOfPatients)
//        NSLog(@"%s familyName: %@", __FUNCTION__, p.familyName);
#endif
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

- (MLPatient *) getContactAtRow:(NSInteger)row
{
    if (mSearchFiltered)
        return mFilteredArrayOfPatients[row];

    if (mArrayOfPatients!=nil)
        return mArrayOfPatients[row];

    return nil;
}

#pragma mark - MLContact

- (NSArray *) getAllContacts
{
    groupOfContacts = [@[] mutableCopy];
    [self addAllContactsToArray:groupOfContacts];
    return groupOfContacts;
}

- (NSArray *) addAllContactsToArray:(NSMutableArray *)arrayOfContacts
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusDenied) {
        NSLog(@"This app was refused permissions to contacts.");
    }
    
    if ([CNContactStore class]) {
        CNContactStore *addressBook = [[CNContactStore alloc] init];
        
        NSArray *keys = @[CNContactIdentifierKey,
                          CNContactFamilyNameKey,
                          CNContactGivenNameKey,
                          CNContactBirthdayKey,
                          CNContactPostalAddressesKey,
                          CNContactPhoneNumbersKey,
                          CNContactEmailAddressesKey];
        
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
        
        NSError *error;
        [addressBook enumerateContactsWithFetchRequest:request
                                                 error:&error
                                            usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
                                                if (error) {
                                                    NSLog(@"error fetching contacts %@", error);
                                                } else {
                                                    MLPatient *patient = [[MLPatient alloc] init];
                                                    patient.familyName = contact.familyName;
                                                    patient.givenName = contact.givenName;
                                                    // Postal address
                                                    patient.postalAddress = @"";
                                                    patient.zipCode = @"";
                                                    patient.city = @"";
                                                    patient.country = @"";
                                                    if ([contact.postalAddresses count]>0) {
                                                        CNPostalAddress *pa = [contact.postalAddresses[0] value];
                                                        patient.postalAddress = pa.street;
                                                        patient.zipCode = pa.postalCode;
                                                        patient.city = pa.city;
                                                        patient.country = pa.country;
                                                    }
                                                    // Email address
                                                    patient.emailAddress = @"";
                                                    if ([contact.emailAddresses count]>0)
                                                        patient.emailAddress = [contact.emailAddresses[0] value];
                                                    // Birthdate
                                                    patient.birthDate = @"";
                                                    if (contact.birthday.year>1900)
                                                        patient.birthDate = [NSString stringWithFormat:@"%ld-%ld-%ld", contact.birthday.day, contact.birthday.month, contact.birthday.year];
                                                    // Phone number
                                                    patient.phoneNumber = @"";
                                                    if ([contact.phoneNumbers count]>0)
                                                        patient.phoneNumber = [[contact.phoneNumbers[0] value] stringValue];
                                                    // Add only if patients names are meaningful
                                                    if ([patient.familyName length]>0 && [patient.givenName length]>0) {
                                                        //patient.databaseType = eAddressBook; // TODO
                                                        [arrayOfContacts addObject:patient];
                                                    }
                                                }
                                            }];
        // Sort alphabetically
        if ([arrayOfContacts count]>0) {
            NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES];
            [arrayOfContacts sortUsingDescriptors:[NSArray arrayWithObject:nameSort]];
        }
    }
    
    return arrayOfContacts;
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView: (UITableView *)tableView
  numberOfRowsInSection: (NSInteger)section
{
    return [mArrayOfPatients count]; // TODO: scroll bar
}

- (UITableViewCell *) tableView: (UITableView *)tableView
          cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"contactsListTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:tableIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    MLPatient *p = mArrayOfPatients[indexPath.row];
    cell.textLabel.text = p.familyName;
    //cell.detailTextLabel.text = [NSString stringWithFormat:@"example %ld", indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
#ifdef DEBUG
    //NSLog(@"%s selected row:%ld", __FUNCTION__, indexPath.row);
#endif
    
    MLPatient *p = [self getContactAtRow:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactSelectedNotification"
                                                        object:p];
    
    mPatientUUID = p.uniqueId;
}

@end
