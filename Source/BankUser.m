/**
 * Copyright (c) 2009, 2014, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "BankUser.h"
#import "MOAssistant.h"
#import "TanMethod.h"
#import "TanMedium.h"
#import "SigningOption.h"
#import "MessageLog.h"
#import "HBCIController.h"
#import "BankAccount.h"

@implementation BankUser

@dynamic bankCode;
@dynamic bankName;
@dynamic bankURL;
@dynamic checkCert;
@dynamic country;
@dynamic customerId;
@dynamic hbciVersion;
@dynamic name;
@dynamic port;
@dynamic userId;
@dynamic preferredTanMethod;
@dynamic tanMedia;
@dynamic tanMethods;
@dynamic noBase64;
@dynamic tanMediaFetched;
@dynamic ddvPortIdx;
@dynamic ddvReaderIdx;
@dynamic secMethod;
@dynamic chipCardId;
@dynamic accounts;

@synthesize isRegistered;
@synthesize updatedCustomerId;
@synthesize updatedUserId;

// user cache
static NSMutableDictionary *users = nil;

- (id)copyWithZone: (NSZone *)zone
{
    return self;
}

- (void)updateTanMethods: (NSArray *)methods
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSMutableSet           *oldMethods = [[self tanMethods] copy];
    NSEntityDescription    *entity = [NSEntityDescription entityForName: @"TanMethod" inManagedObjectContext: context];
    NSArray                *attributeKeys = [[entity attributesByName] allKeys];

    for (TanMethod *method in methods) {
        TanMethod    *newMethod = [NSEntityDescription insertNewObjectForEntityForName: @"TanMethod" inManagedObjectContext: context];
        NSDictionary *attributeValues = [method dictionaryWithValuesForKeys: attributeKeys];
        [newMethod setValuesForKeysWithDictionary: attributeValues];
        newMethod.user = self;

        // Daten aus alten Methoden übernehmen
        for (TanMethod *oldMethod in oldMethods) {
            if ([method.method isEqualToString: oldMethod.method]) {
                newMethod.preferredMedium = oldMethod.preferredMedium;
            }
        }
    }
    // alte TAN-Methoden löschen
    for (TanMethod *oldMethod in oldMethods) {
        [context deleteObject: oldMethod];
    }
    [context processPendingChanges];
}

- (void)updateTanMedia: (NSArray *)media
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSMutableSet           *oldMedia = [[self tanMedia] copy];
    NSEntityDescription    *entity = [NSEntityDescription entityForName: @"TanMedium" inManagedObjectContext: context];
    NSArray                *attributeKeys = [[entity attributesByName] allKeys];

    for (TanMedium *medium in media) {
        TanMedium    *newMedium = [NSEntityDescription insertNewObjectForEntityForName: @"TanMedium" inManagedObjectContext: context];
        NSDictionary *attributeValues = [medium dictionaryWithValuesForKeys: attributeKeys];
        [newMedium setValuesForKeysWithDictionary: attributeValues];
        newMedium.user = self;

        // Daten aus altem Medium
        for (TanMethod *method in [self tanMethods]) {
            if (method.preferredMedium != nil && [method.preferredMedium.name isEqualToString: newMedium.name]) {
                method.preferredMedium = newMedium;
            }
        }
    }
    // alte TAN-Media löschen
    for (TanMedium *oldMedium in oldMedia) {
        [context deleteObject: oldMedium];
    }
    [context processPendingChanges];
}

- (NSArray *)getTanSigningOptions
{
    if ([self.secMethod intValue] != SecMethod_PinTan) {
        return nil;
    }
    // first get TAN Media if not already fetched
    //if ([self.tanMediaFetched boolValue ] == NO) [[HBCIController controller ] updateTanMediaForUser:self ];

    NSSet          *methods = [self tanMethods];
    NSSet          *media = [self tanMedia];
    NSMutableArray *options = [NSMutableArray arrayWithCapacity: 10];

    for (TanMethod *method in methods) {
        SigningOption *option = [[SigningOption alloc] init];
        option.secMethod = SecMethod_PinTan;
        option.tanMethod = method.method;
        option.userId = self.userId;
        option.userName = self.name;
        option.tanMethodName = method.name;
        NSString *zkamethod = method.zkaMethodName;

        if ([method.needTanMedia isEqualToString: @"1"] || [method.needTanMedia isEqualToString: @"2"]) {
            // wenn es keine TAN-Medien gibt, nur die Methode angeben
            if ([media count] == 0) {
                //option.tanMediumName = [NSString stringWithFormat:@"%@ %@", method.zkaMethodName, method.zkaMethodVersion ];
                if (zkamethod && [zkamethod isEqualToString: @"mobileTAN"]) {
                    option.tanMediumCategory = @"M";
                }
                if (zkamethod && [[zkamethod substringToIndex: 3] isEqualToString: @"HHD"]) {
                    option.tanMediumCategory = @"G";
                }
                [options addObject: option];
            }

            // check which media fit
            for (TanMedium *medium in media) {
                BOOL added = NO;
                if ([zkamethod isEqualToString: @"mobileTAN"] && [medium.category isEqualToString: @"M"]) {
                    option.tanMediumName = medium.name;
                    option.mobileNumber = medium.mobileNumber;
                    option.tanMediumCategory = medium.category;
                    [options addObject: option];
                    added = YES;
                }
                if ([zkamethod isEqualToString: @"BestSign"] && [medium.category isEqualToString: @"G"] && [[medium.name substringToIndex: 3] isEqualToString: @"SO:"]) {
                    // Spezialfall Postbank Bestsign
                    option.tanMediumName = medium.name;
                    option.tanMediumCategory = medium.category;
                    [options addObject: option];
                    added = YES;
                }
                if ([[zkamethod substringToIndex: 3] isEqualToString: @"HHD"] && [medium.category isEqualToString: @"G"] && ![[medium.name substringToIndex: 3] isEqualToString: @"SO:"]) {
                    option.tanMediumName = medium.name;
                    option.tanMediumCategory = medium.category;
                    [options addObject: option];
                    added = YES;
                }
                if (added == YES) {
                    option = [[SigningOption alloc] init];
                    option.secMethod = SecMethod_PinTan;
                    option.tanMethod = method.method;
                    option.tanMethodName = method.name;
                    option.userId = self.userId;
                    option.userName = self.name;
                }
            }
        } else {
            [options addObject: option];
        }
    }
    // sortieren
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"tanMethodName" ascending: YES];
    NSArray          *sortDescriptors = @[sortDescriptor];
    return [options sortedArrayUsingDescriptors: sortDescriptors];
}

- (NSArray *)getSigningOptions
{
    if (self.userId == nil) {
        return nil;
    }
    if ([self.secMethod intValue] == SecMethod_PinTan) {
        return [self getTanSigningOptions];
    }

    // DDV
    NSMutableArray *options = [NSMutableArray arrayWithCapacity: 10];
    SigningOption  *option = [[SigningOption alloc] init];
    option.secMethod = SecMethod_DDV;
    option.userId = self.userId;
    option.userName = self.name;
    option.cardId = self.chipCardId;
    [options addObject: option];
    return options;
}

- (void)setpreferredSigningOption: (SigningOption *)option
{
    if (option == nil) {
        self.preferredTanMethod = nil;
        return;
    }
    NSSet *methods = [self tanMethods];
    for (TanMethod *method in methods) {
        if ([method.method isEqualToString: option.tanMethod]) {
            self.preferredTanMethod = method;
            NSSet *media = [self tanMedia];
            for (TanMedium *medium in media) {
                if ([medium.name isEqualToString: option.tanMediumName]) {
                    method.preferredMedium = medium;
                    break;
                }
            }
            break;
        }
    }
}

- (SigningOption *)preferredSigningOption
{
    TanMethod *method = self.preferredTanMethod;
    if (method == nil) {
        return nil;
    }
    TanMedium *medium = method.preferredMedium;

    SigningOption *option = [[SigningOption alloc] init];
    option.tanMethod = method.method;
    option.tanMethodName = method.name;
    option.userId = self.userId;
    option.userName = self.name;
    option.secMethod = SecMethod_PinTan;
    if (medium) {
        option.tanMediumName = medium.name;
        option.mobileNumber = medium.mobileNumber;
    }
    return option;
}

- (int)getpreferredSigningOptionIdx
{
    if ([self.secMethod intValue] == SecMethod_DDV) {
        return 0;
    }

    NSArray *options = [self getTanSigningOptions];

    if ([options count] == 1) {
        return 0;
    }

    SigningOption *option = [self preferredSigningOption];

    // Wenn nichts voreingestellt ist, Index des letzten Eintrags +1 zurückgeben, der zeigt dann automatisch auf den virtuellen Eintrag
    if (option == nil) {
        return [options count];
    }

    int idx = 0;
    for (SigningOption *opt in options) {
        if ([opt.tanMethod isEqualToString: option.tanMethod] && ((opt.tanMediumName == nil && option.tanMediumName == nil) || [opt.tanMediumName isEqualToString: option.tanMediumName])) {
            return idx;
        } else {idx++; }
    }
    return [options count];
}

- (void)setpreferredSigningOptionIdx: (NSIndexSet *)iSet
{
    int idx = [iSet firstIndex];
    if (idx < 0) {
        return;
    }
    NSArray *options = [self getTanSigningOptions];

    [self setpreferredSigningOption: options[idx]];
}

- (void)checkForUpdatedLoginData
{
    if (self.updatedUserId != nil) {
        self.userId = self.updatedUserId;
        for (BankAccount *account in self.accounts) {
            account.userId = self.updatedUserId;
        }
        self.updatedUserId = nil;
        self.isRegistered = NO;
    }
    if (self.updatedCustomerId != nil) {
        self.customerId = self.updatedCustomerId;
        self.updatedCustomerId = nil;
        self.isRegistered = NO;
    }
}

- (NSString*)description
{
    return [self descriptionWithIndent: @""];
}

/**
 * Description with a certain indentation. indent is added in front of each line (in addition to their individual indentation).
 */
- (NSString*)descriptionWithIndent: (NSString *)indent
{
    NSString *format = NSLocalizedString(@"AP1018", @"");
    NSMutableString *s = [NSMutableString stringWithFormat: format, indent, self.userId, self.bankCode, self.bankName];
    [s appendFormat: NSLocalizedString(@"AP1019", @""), indent, self.customerId, self.hbciVersion];
    [s appendFormat: NSLocalizedString(@"AP1020", @""), indent, self.bankURL];

    if (self.tanMethods.count > 0) {
        NSMutableString *temp = [NSMutableString string];
        NSArray *sortedMethods = [[self.tanMethods allObjects] sortedArrayUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
            TanMethod *method1 = (TanMethod *)obj1;
            TanMethod *method2 = (TanMethod *)obj2;
            return [method1.method compare: method2.method];
        }];
        for (TanMethod *method in sortedMethods) {
            [temp appendString: [method descriptionWithIndent: [NSString stringWithFormat: @"%@    ", indent]]];
        }

        [s appendFormat: NSLocalizedString(@"AP1021", @""), indent, temp, indent];
    } else {
        [s appendFormat: NSLocalizedString(@"AP1022", @""), indent];
    }

    if (self.tanMedia.count > 0) {
        NSMutableString *temp = [NSMutableString string];
        for (TanMedium *medium in self.tanMedia) {
            [temp appendString: [medium descriptionWithIndent: [NSString stringWithFormat: @"%@    ", indent]]];
        }

        [s appendFormat: NSLocalizedString(@"AP1023", @""), indent, temp, indent];
    } else {
        [s appendFormat: NSLocalizedString(@"AP1024", @""), indent];
    }

    if (self.accounts.count > 0) {
        NSMutableString *temp = [NSMutableString string];
        for (BankAccount *account in self.accounts) {
            [temp appendFormat: @"%@\n", [account descriptionWithIndent: [NSString stringWithFormat: @"%@    ", indent]]];
        }

        [s appendFormat: NSLocalizedString(@"AP1025", @""), indent, temp, indent];
    } else {
        [s appendFormat: NSLocalizedString(@"AP1026", @""), indent];
    }

    return s;
}

+ (NSArray *)allUsers
{
    NSError                *error = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant] context];
    NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankUser" inManagedObjectContext: context];
    NSFetchRequest         *request = [[NSFetchRequest alloc] init];
    [request setEntity: entityDescription];
    NSArray *bankUsers = [context executeFetchRequest: request error: &error];
    if (error) {
        LogError(@"Error retrieving all bank users: %@", error.localizedDescription);
        return nil;
    }
    return bankUsers;
}

// important: bankCode of BankUser and bankCode of accounts can be different!
// for that reason, if we don't find a user with the same bankCode we look for one with just the same
// userId
+ (BankUser *)userWithId: (NSString *)userId bankCode: (NSString *)bankCode
{
    NSError                *error = nil;
    
    if (userId == nil) {
        return nil;
    }
    
    if (users == nil) {
        users = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    NSArray *bankUsers = [users objectForKey:userId];
    if (bankUsers == nil) {
        NSManagedObjectContext *context = [[MOAssistant assistant] context];
        NSEntityDescription    *entityDescription = [NSEntityDescription entityForName: @"BankUser" inManagedObjectContext: context];
        NSFetchRequest         *request = [[NSFetchRequest alloc] init];
        [request setEntity: entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"userId = %@", userId];
        [request setPredicate: predicate];
        bankUsers = [context executeFetchRequest: request error: &error];
        if (error) {
            LogError(@"Retrieving bank user failed: %@", error.localizedDescription);
            return nil;
        }
        if ([bankUsers count] == 0) {
            NSRunAlertPanel(NSLocalizedString(@"AP201", nil),
                            NSLocalizedString(@"AP202", nil),
                            NSLocalizedString(@"AP1", nil),
                            nil, nil, userId, bankCode);
            return nil;
        }
        [users setObject:bankUsers forKey:userId];
    }
    
    // do we have a user with the right bankCode?
    for (BankUser *user in bankUsers) {
        if ([user.bankCode isEqualToString:bankCode]) {
            return user;
        }
    }
    
    // no - take the last one
    return [bankUsers lastObject];    
}

+ (void)removeUser:(BankUser*)user
{
    NSManagedObjectContext *context = [[MOAssistant assistant] context];

    if (user.userId != nil) {
        [users removeObjectForKey:user.userId];
    }
    
    [context deleteObject: user];
}


@end
