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

#import "MLDataStore.h"

@implementation MLDataStore

@synthesize favMedsSet;
@synthesize favFTEntrySet;  // Full Text Entry

#pragma mark - Class methods

+ (MLDataStore *) initWithFavMedsSet: (NSMutableSet *)favMedsSet
{
    MLDataStore *favMeds = [MLDataStore new];
    favMeds.favMedsSet = [NSSet setWithSet:favMedsSet];
    return favMeds;
}

+ (MLDataStore *) initWithFavFTEntrySet:(NSMutableSet *)favFTEntrySet
{
    MLDataStore *favFTEntry = [MLDataStore new];
    favFTEntry.favFTEntrySet = [NSSet setWithSet:favFTEntrySet];
    return favFTEntry;
}

#pragma mark - Delegate methods

/** Returns a coder used as a dictionary
 */
- (void) encodeWithCoder: (NSCoder *)encoder
{
    // In a dictionary -> setValue:forKey:
    [encoder encodeObject:favMedsSet forKey:KEY_FAV_MED_SET];
    [encoder encodeObject:favFTEntrySet forKey:KEY_FAV_FTE_SET];
}

/** Called when you try to unarchive class using NSKeyedUnarchiver
 */
- (id) initWithCoder: (NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        // In a dictionary -> objectForKey:
        favMedsSet = [decoder decodeObjectForKey:KEY_FAV_MED_SET];
        favFTEntrySet = [decoder decodeObjectForKey:KEY_FAV_FTE_SET];
    }

    return self;
}

@end
