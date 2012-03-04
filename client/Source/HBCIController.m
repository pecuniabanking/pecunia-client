//
//  HBCIController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 24.07.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import "HBCIController.h"

#import "BankInfo.h"
#import "PecuniaError.h"
#import "BankQueryResult.h"
#import "BankStatement.h"
#import "BankAccount.h"
#import "Transfer.h"
#import "MOAssistant.h"
#import "TransferResult.h"
#import "BankingController.h"
#import "WorkerThread.h"
#import "User.h"
#import "Account.h"
#import "StandingOrder.h"
#import "HBCIBridge.h"
#import "Passport.h"
#import "Account.h"
#import "TransactionLimits.h"
#import "Country.h"
#import "ShortDate.h"
#import "BankParameter.h"
#import "ProgressWindowController.h"
#import "CustomerMessage.h"
#import "MessageLog.h"
#import "BankSetupInfo.h"

@implementation HBCIController

-(id)init
{
    self = [super init ];
    if(self == nil) return nil;
    
    bridge = [[HBCIBridge alloc ] init ];
    [bridge startup ];
    
    users = [[NSMutableArray alloc ] initWithCapacity: 10 ];
    bankInfo = [[NSMutableDictionary alloc ] initWithCapacity: 10];
    countries = [[NSMutableDictionary alloc ] initWithCapacity: 50];
    [self readCountryInfos ]; 
    progressController = [[ProgressWindowController alloc ] init ];
    return self;
}

-(void)startProgress
{
    [progressController start ];
}

-(void)stopProgress
{
    [progressController stop ];
}

-(void)dealloc
{
    [users release ];
    [bridge release ];
    [bankInfo release ];
    [countries release ];
    [progressController release ];
    [super dealloc ];
}

-(void)readCountryInfos
{
    NSError *error = nil;
    
    NSString *path = [[NSBundle mainBundle ] pathForResource: @"CountryInfo" ofType: @"txt" ];
    NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error ];
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
        return;
    }
    NSArray *lines = [data componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet ] ];
    NSString *line;
    for(line in lines) {
        NSArray *infos = [line componentsSeparatedByString: @";" ];
        Country *country = [[[Country alloc ] init ] autorelease ];
        country.code = [infos objectAtIndex: 2 ];
        country.name = [infos objectAtIndex:0 ];
        country.currency = [infos objectAtIndex:3 ];
        [countries setObject:country forKey:country.code ];
    }
}

NSString *escapeSpecial(NSString *s)
{
    NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString:@"&<>'" ];
    NSRange range = [s rangeOfCharacterFromSet:cs ];
    if (range.location == NSNotFound) return s;
    NSString *res = [s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;" ];
    res = [res stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;" ];
    res = [res stringByReplacingOccurrencesOfString:@">" withString:@"&gt;" ];
    res = [res stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;" ];
    return res;
}

-(NSDictionary*)countries
{
    return countries;
}

-(NSArray*)supportedVersions
{
    NSMutableArray *versions = [NSMutableArray arrayWithCapacity:2 ];
    [versions addObject:@"220" ];
    [versions addObject:@"300" ];
    return versions;
}

-(void)appendTag:(NSString*)tag withValue:(NSString*)val to:(NSMutableString*)cmd
{
    if (val == nil) return;
    NSString *s = escapeSpecial(val);
    if(val) [cmd appendFormat:@"<%@>%@</%@>", tag, s, tag ];
}

-(NSArray*)initHBCI
{
    PecuniaError *error=nil;
    NSString *ppDir = [[MOAssistant assistant] passportDirectory ];
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"init\"><path>%@</path></command>", ppDir ];
    NSArray *usrs = [bridge syncCommand: cmd error: &error ];
    if(usrs == nil) {
        //  check for error (wrong password)
        if(error) {
            [error alertPanel ];
            [NSApp terminate:self ];
        }
    } else [users addObjectsFromArray: usrs ];
    
    // load all availabe accounts
    /*	
     for(User *user in users) {
     NSArray *accs = [self getAccountsForUser: user error:&error ];
     if(error) {
     [error alertPanel ];
     [NSApp terminate:self ];
     } else {
     [accounts addObjectsFromArray: accs ];
     }
     }
     */ 
    return users;
}

-(BankInfo*)infoForBankCode: (NSString*)bankCode inCountry:(NSString*)country
{
    PecuniaError *error=nil;
    
    BankInfo *info = [bankInfo objectForKey: bankCode ];
    if(info == nil) {
        NSString *cmd = [NSString stringWithFormat: @"<command name=\"getBankInfo\"><bankCode>%@</bankCode></command>", bankCode ];
        info = [bridge syncCommand: cmd error: &error ];
        if(error == nil && info) [bankInfo setObject: info forKey: bankCode ]; else return nil;
    }
    return info;
}

-(BankParameter*)getBankParameterForUser:(User*)user
{
    PecuniaError *error=nil;
    
    [self startProgress ];
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"getBankParameterRaw\"><bankCode>%@</bankCode><userId>%@</userId></command>", user.bankCode, user.userId ];
    BankParameter *bp = [bridge syncCommand:cmd error:&error ];
    [self stopProgress ];
    if (error) {
        [error alertPanel ];
        return nil;
    }
    return bp;
}

-(BankSetupInfo*)getBankSetupInfo:(NSString*)bankCode
{
    PecuniaError *error=nil;
    
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"getInitialBPD\"><bankCode>%@</bankCode></command>", bankCode ];
    BankSetupInfo *info = [bridge syncCommand:cmd error:&error ];
    if (error) {
        [error alertPanel ];
        return nil;
    }
    return info;
}


-(NSString*)bankNameForCode:(NSString*)bankCode inCountry:(NSString*)country
{
    BankInfo *info = [self infoForBankCode: bankCode inCountry:country ];
    if(info==nil || info.name == nil) return NSLocalizedString(@"unknown",@"- unknown -");
    return info.name;
}

-(NSString*)bankNameForBIC:(NSString*)bic inCountry:(NSString*)country
{
    // is not supported
    return @"";
}

-(NSArray*)users
{
    return users;
}

-(NSArray*)getAccountsForUser:(User*)user
{
    PecuniaError *error=nil;
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"getAccounts\"><bankCode>%@</bankCode><userId>%@</userId></command>", user.bankCode, user.userId ];
    NSArray *accs = [bridge syncCommand: cmd error:&error ];
    if (error != nil) {
        [error alertPanel ];
        return nil;
    }
    return accs;
}

-(PecuniaError*)addAccount: (BankAccount*)account forUser: (User*)user
{
    account.userId = user.userId;
    account.customerId = user.customerId;
    return [self setAccounts:[NSArray arrayWithObject:account ] ];
}

-(PecuniaError*)setAccounts:(NSArray*)bankAccounts
{
    PecuniaError	*error = nil;
    
    BankAccount	*acc;
    for(acc in bankAccounts) {
        NSMutableString	*cmd = [NSMutableString stringWithFormat: @"<command name=\"setAccount\">" ];
        [self appendTag: @"bankCode" withValue: acc.bankCode to: cmd ];
        [self appendTag: @"accountNumber" withValue: acc.accountNumber to: cmd ];
        [self appendTag: @"country" withValue: [acc.country uppercaseString] to: cmd ];
        [self appendTag: @"iban" withValue: acc.iban to: cmd ];
        [self appendTag: @"bic" withValue: acc.bic to: cmd ];
        [self appendTag: @"ownerName" withValue: acc.owner to: cmd ];
        [self appendTag: @"name" withValue: acc.name to: cmd ];
        [self appendTag: @"customerId" withValue: acc.customerId to: cmd ];
        [self appendTag: @"userId" withValue: acc.userId to: cmd ];
        [self appendTag: @"currency" withValue: acc.currency to: cmd ];
        [cmd appendString: @"</command>" ];
        [bridge syncCommand: cmd error: &error ];
        if(error != nil) return error;
    }
    return nil;
}

-(PecuniaError*)changeAccount:(BankAccount*)account
{
    PecuniaError	*error = nil;
    
    NSMutableString	*cmd = [NSMutableString stringWithFormat: @"<command name=\"changeAccount\">" ];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd ];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd ];
    [self appendTag: @"iban" withValue: account.iban to: cmd ];
    [self appendTag: @"bic" withValue: account.bic to: cmd ];
    [self appendTag: @"ownerName" withValue: account.owner to: cmd ];
    [self appendTag: @"name" withValue: account.name to: cmd ];
    [self appendTag: @"customerId" withValue: account.customerId to: cmd ];
    [self appendTag: @"userId" withValue: account.userId to: cmd ];
    [cmd appendString: @"</command>" ];
    [bridge syncCommand: cmd error: &error ];
    if(error != nil) return error;
    
    return nil;	
}


-(NSString*)jobNameForType: (TransferType)tt
{
    switch(tt) {
        case TransferTypeLocal: return @"Ueb"; break;
        case TransferTypeDated: return @"TermUeb"; break;
        case TransferTypeInternal: return @"Umb"; break;
        case TransferTypeEU: return @"UebForeign"; break;
        case TransferTypeLast: return @"Last"; break;
        case TransferTypeSEPA: return @"UebSEPA"; break;
    };
    return nil;
}

-(BOOL)isJobSupported:(NSString*)jobName forAccount:(BankAccount*)account
{
    PecuniaError *error=nil;
    if(account == nil) return NO;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"isJobSupported\">" ];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd ];
    [self appendTag: @"userId" withValue: account.userId to: cmd ];
    [self appendTag: @"jobName" withValue: jobName to: cmd ];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd ];
    [cmd appendString: @"</command>" ];
    NSNumber *result = [bridge syncCommand: cmd error: &error ];
    if(result) return [result boolValue ]; else return NO;
}

-(BOOL)isTransferSupported:(TransferType)tt forAccount:(BankAccount*)account
{
    NSString *jobName = [self jobNameForType: tt ];
    return [self isJobSupported: jobName forAccount: account ];
}

-(BOOL)isStandingOrderSupportedForAccount:(BankAccount*)account
{
    return [self isJobSupported:@"DauerNew" forAccount:account ];
}

-(NSDictionary*)getRestrictionsForJob:(NSString*)jobname account:(BankAccount*)account
{
    NSDictionary *result;
    PecuniaError *error=nil;
    if(account == nil) return nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getJobRestrictions\">" ];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd ];
    [self appendTag: @"userId" withValue: account.userId to: cmd ];
    [self appendTag: @"jobName" withValue: jobname to: cmd ];
    [cmd appendString: @"</command>" ];
    result = [bridge syncCommand: cmd error: &error ];
    return result;
}

-(NSArray*)allowedCountriesForAccount:(BankAccount*)account
{
    NSMutableArray *res = [NSMutableArray arrayWithCapacity:20 ];
    NSDictionary *restr = [self getRestrictionsForJob:@"UebForeign" account:account ];
    NSArray *countryInfo = [restr valueForKey: @"countryInfos" ];
    NSString *s;
    
    // get texts for allowed countries - build up PopUpButton data
    for(s in countryInfo) {
        NSArray *comps = [s componentsSeparatedByString: @";" ];
        Country  *country = [countries valueForKey:[comps objectAtIndex:0 ] ];
        if(country != nil) [res addObject:country ];
    }
    if ([res count ] == 0) {
        return [countries allValues ];
    }
    
    return res;
}

-(TransactionLimits*)limitsForType:(TransferType)tt account:(BankAccount*)account country:(NSString*)ctry
{
    TransactionLimits *limits = [[[TransactionLimits alloc ] init ] autorelease ];
    NSString *jobName = [self jobNameForType: tt ];
    NSDictionary *restr = [self getRestrictionsForJob:jobName account:account ];
    if (restr) {
        limits.allowedTextKeys = [restr valueForKey:@"textKeys" ];
        
        limits.maxLenPurpose = 27;
        limits.maxLenRemoteName = 27;
        limits.maxLinesRemoteName = 2;
        NSString *s = [restr valueForKey:@"maxusage" ];
        if (s) {
            limits.maxLinesPurpose = [s intValue ];
        } else {
            limits.maxLinesPurpose = 2;
        }
        s = [restr valueForKey:@"minpreptime" ];
        if (s) {
            limits.minSetupTime = [s intValue ];
        }
        s = [restr valueForKey:@"maxpreptime" ];
        if (s) {
            limits.maxSetupTime = [s intValue ];
        }
    }
    return limits;
}

-(TransactionLimits*)standingOrderLimitsForAccount:(BankAccount*)account action:(StandingOrderAction)action
{
    TransactionLimits *limits = [[[TransactionLimits alloc ] init ] autorelease ];
    NSString *jobName = nil;
    switch (action) {
        case stord_change: jobName = @"DauerEdit"; break;
        case stord_create: jobName = @"DauerNew"; break;
        case stord_delete: jobName = @"DauerDel"; break;
    }
    if (jobName == nil) return nil;
    NSDictionary *restr = [self getRestrictionsForJob:jobName account:account ];
    if (restr) {
        limits.allowedTextKeys = [restr valueForKey:@"textKeys" ];
        
        limits.maxLenPurpose = 27;
        limits.maxLenRemoteName = 27;
        limits.maxLinesRemoteName = 2;
        NSString *s = [restr valueForKey:@"maxusage" ];
        if (s) {
            limits.maxLinesPurpose = [s intValue ];
        } else {
            limits.maxLinesPurpose = 2;
        }
        s = [restr valueForKey:@"minpretime" ];
        if (s) {
            limits.minSetupTime = [s intValue ];
        }
        s = [restr valueForKey:@"maxpretime" ];
        if (s) {
            limits.maxSetupTime = [s intValue ];
        }
        
        s = [restr valueForKey:@"dayspermonth" ];
        if (s) {
            NSMutableArray *execDays = [NSMutableArray arrayWithCapacity:30 ];
            while ([s length ] > 0) {
                [execDays addObject: [s substringToIndex:2 ] ];
                s = [s substringFromIndex:2 ];
            }
            limits.execDaysMonth = execDays;
        }
        
        s = [restr valueForKey:@"daysperweek" ];
        if (s) {
            NSMutableArray *execDays = [NSMutableArray arrayWithCapacity:7 ];
            while ([s length ] > 0) {
                [execDays addObject: [s substringToIndex:1 ] ];
                s = [s substringFromIndex:1 ];
            }
            limits.execDaysWeek = execDays;
        }
        
        s = [restr valueForKey:@"turnusmonths" ];
        if (s) {
            NSMutableArray *cycles = [NSMutableArray arrayWithCapacity:12 ];
            while ([s length ] > 0) {
                [cycles addObject: [s substringToIndex:2 ] ];
                s = [s substringFromIndex:2 ];
            }
            limits.monthCycles = cycles;
        }
        
        s = [restr valueForKey:@"turnusweeks" ];
        if (s) {
            NSMutableArray *cycles = [NSMutableArray arrayWithCapacity:12 ];
            while ([s length ] > 0) {
                [cycles addObject: [s substringToIndex:2 ] ];
                s = [s substringFromIndex:2 ];
            }
            limits.weekCycles = cycles;
        }
        
        limits.allowMonthly = YES;
        if (limits.execDaysWeek == nil || limits.weekCycles == nil) limits.allowWeekly = NO; else limits.allowWeekly = YES;
        
        if (action == stord_change) {
            s = [restr valueForKey:@"recktoeditable" ];
            limits.allowChangeRemoteAccount = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeRemoteAccount = YES;
            }
            s = [restr valueForKey:@"recnameeditable" ];
            limits.allowChangeRemoteName = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeRemoteName = YES;
            }
            s = [restr valueForKey:@"usageeditable" ];
            limits.allowChangePurpose = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangePurpose = YES;
            }
            s = [restr valueForKey:@"firstexeceditable" ];
            limits.allowChangeFirstExecDate = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeFirstExecDate = YES;
            }
            s = [restr valueForKey:@"lastexeceditable" ];
            limits.allowChangeLastExecDate = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeLastExecDate = YES;
            }
            s = [restr valueForKey:@"timeuniteditable" ];
            limits.allowChangePeriod = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangePeriod = YES;
            }
            s = [restr valueForKey:@"turnuseditable" ];
            limits.allowChangeCycle = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeCycle = YES;
            }
            s = [restr valueForKey:@"execdayeditable" ];
            limits.allowChangeExecDay = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeExecDay = YES;
            }
            s = [restr valueForKey:@"valueeditable" ];
            limits.allowChangeValue = NO;
            if (s) {
                if ([s isEqualToString:@"J" ]) limits.allowChangeValue = YES;
            }
        } else {
            limits.allowChangeRemoteName = YES;
            limits.allowChangeRemoteAccount = YES;
            limits.allowChangePurpose = YES;
            limits.allowChangeValue = YES;
            limits.allowChangePeriod = YES;
            limits.allowChangeLastExecDate = YES;
            limits.allowChangeFirstExecDate = YES;
            limits.allowChangeExecDay = YES;
            limits.allowChangeCycle = YES;
        }
        
        
    }
    return limits;
}




-(BOOL)sendTransfers:(NSArray*)transfers 
{
    PecuniaError *err = nil;
    Transfer *transfer;
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO] autorelease];
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"sendTransfers\"><transfers type=\"list\">" ];
    NSString *type;
    
    [self startProgress ];
    for(transfer in transfers) {
        [cmd appendString: @"<transfer>" ];
        [self appendTag: @"bankCode" withValue: transfer.account.bankCode to: cmd ];
        [self appendTag: @"accountNumber" withValue: transfer.account.accountNumber to: cmd ];
        [self appendTag: @"customerId" withValue: transfer.account.customerId to: cmd ];
        [self appendTag: @"userId" withValue: transfer.account.userId to: cmd ];
        [self appendTag: @"remoteAccount" withValue: transfer.remoteAccount to: cmd ];
        [self appendTag: @"remoteBankCode" withValue: transfer.remoteBankCode to: cmd ];
        [self appendTag: @"remoteName" withValue: transfer.remoteName to: cmd ];
        [self appendTag: @"purpose1" withValue: transfer.purpose1 to: cmd ];
        [self appendTag: @"purpose2" withValue: transfer.purpose2 to: cmd ];
        [self appendTag: @"purpose3" withValue: transfer.purpose3 to: cmd ];
        [self appendTag: @"purpose4" withValue: transfer.purpose4 to: cmd ];
        [self appendTag: @"currency" withValue: transfer.currency to: cmd ];
        [self appendTag: @"remoteBIC" withValue: transfer.remoteBIC to: cmd ];
        [self appendTag: @"remoteIBAN" withValue: transfer.remoteIBAN to: cmd ];
        [self appendTag: @"remoteCountry" withValue: transfer.remoteCountry==nil?@"DE":[transfer.remoteCountry uppercaseString] to: cmd ];
        if([transfer.type intValue] == TransferTypeDated) {
            NSString *fromString = [dateFormatter stringFromDate:transfer.valutaDate ];
            [self appendTag: @"valutaDate" withValue: fromString to: cmd ];
        }
        TransferType tt = [transfer.type intValue];
        switch(tt) {
            case TransferTypeLocal: type = @"standard"; break;
            case TransferTypeDated: type = @"dated"; break;
            case TransferTypeInternal: type = @"internal"; break;
            case TransferTypeLast: type = @"last"; break;
            case TransferTypeSEPA: type = @"sepa"; break;
            case TransferTypeEU:	
                type = @"foreign";
                [self appendTag:@"chargeTo" withValue:[transfer.chargedBy description ]  to:cmd ];
                break;
        }
        
        [self appendTag: @"type" withValue: type to: cmd ];
        NSDecimalNumber *val = [transfer.value decimalNumberByMultiplyingByPowerOf10:2 ];
        [self appendTag: @"value" withValue: [val stringValue ] to: cmd ];
        
        NSURL *uri = [[transfer objectID] URIRepresentation];
        [self appendTag: @"transferId" withValue: [uri absoluteString ] to: cmd ];
        [cmd appendString: @"</transfer>" ];
    }
    [cmd appendString: @"</transfers></command>" ];
    
    NSArray *resultList = [bridge syncCommand: cmd error: &err ];
    [self stopProgress ];
    if (err) {
        [err alertPanel ];
        return NO;
    }
    
    TransferResult	*result;
    BOOL allSent = YES;
    for(result in resultList) {
        NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
        NSURL *uri = [NSURL URLWithString:result.transferId ];
        NSManagedObjectID *moID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: uri ];
        Transfer *transfer = (Transfer*)[context objectWithID: moID];
        transfer.isSent = [NSNumber numberWithBool: result.isOk ];
        if(transfer.isSent == NO) allSent = NO;
    }
    return allSent;
}

-(BOOL)checkAccount:(NSString*)accountNumber forBank:(NSString*)bankCode inCountry: (NSString*)country
{
    PecuniaError *error=nil;
    
    if(bankCode == nil || accountNumber == nil) return YES;
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"checkAccount\"><bankCode>%@</bankCode><accountNumber>%@</accountNumber></command>", bankCode, accountNumber ];
    NSNumber *result = [bridge syncCommand: cmd error: &error ];
    if (error) {
        // Bei Fehlern sollte die Prüfung nicht die Buchung verhindern
        [[MessageLog log ] addMessage:[NSString stringWithFormat:@"Error checking account %@, bankCode %@", accountNumber, bankCode ] withLevel:LogLevel_Warning ];
        return YES;
    }
    if(result) return [result boolValue ]; else return NO;
}

-(BOOL)checkIBAN:(NSString*)iban
{
    PecuniaError *error=nil;
    
    if(iban == nil) return YES;
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"checkAccount\"><iban>%@</iban></command>", iban ];
    NSNumber *result = [bridge syncCommand: cmd error: &error ];
    if (error) {
        // Bei Fehlern sollte die Prüfung nicht die Buchung verhindern
        [[MessageLog log ] addMessage:[NSString stringWithFormat:@"Error checking iban %@", iban ] withLevel:LogLevel_Warning ];
        return YES;
    }
    if(result) return [result boolValue ]; else return NO;
}

-(PecuniaError*)addBankUser:(User*)user
{
    PecuniaError *error=nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"addUser\">" ];
    [self appendTag: @"name" withValue: user.name to: cmd ];
    [self appendTag: @"bankCode" withValue: user.bankCode to: cmd ];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd ];
    [self appendTag: @"userId" withValue: user.userId to: cmd ];
    [self appendTag: @"host" withValue: [user.bankURL stringByReplacingOccurrencesOfString: @"https://" withString:@"" ] to: cmd ];
    [self appendTag: @"version" withValue: user.hbciVersion to: cmd ];
    [self appendTag: @"port" withValue: @"443" to: cmd ];
    if(user.noBase64 == NO) [self appendTag: @"filter" withValue: @"Base64" to: cmd ];
    [cmd appendString: @"</command>" ];
    
    User* usr = [bridge syncCommand: cmd error: &error ];
    if (error)
        return error;
    
    //	[users addObject: usr ];
    
    // delete any previously existing user first
    [users removeObject: usr ];
    [users addObject: usr ];
    
    // update external user data
    user.tanMethodNumber = usr.tanMethodNumber;
    user.tanMethodDescription = usr.tanMethodDescription;
    user.customerId = usr.customerId;
    
    return nil;
}

-(BOOL)deleteBankUser:(User*)user 
{
    PecuniaError *error=nil;
    NSString *cmd = [NSString stringWithFormat: @"<command name=\"deletePassport\"><bankCode>%@</bankCode><userId>%@</userId></command>", user.bankCode, user.userId ];
    [bridge syncCommand: cmd error:&error ];
    if(error == nil) {
        [users removeObject: user ];
    } else return NO;
    return YES;
}

-(PecuniaError*)setLogLevel:(LogLevel)level
{
    PecuniaError *error=nil;
    NSMutableString	*cmd = [NSMutableString stringWithFormat:@"<command name=\"setLogLevel\"><logLevel>%d</logLevel></command>", level+1 ];
    [bridge syncCommand: cmd error: &error ];
    if (error != nil) return error;
    return nil;
}


-(void)getStatements:(NSArray*)resultList
{
    bankQueryResults = [resultList retain ];
    NSMutableString	*cmd = [NSMutableString stringWithFormat:@"<command name=\"getAllStatements\"><accinfolist type=\"list\">" ];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO] autorelease];
    
    BankQueryResult *result;
    for(result in resultList) {
        [cmd appendFormat:@"<accinfo><bankCode>%@</bankCode><accountNumber>%@</accountNumber>", result.bankCode, result.accountNumber ];
        if (result.account.latestTransferDate != nil) {
            NSString *fromString = nil;
            NSDate *fromDate = [[NSDate alloc ] initWithTimeInterval:-605000 sinceDate:result.account.latestTransferDate ];
            fromString = [dateFormatter stringFromDate:fromDate ];
            if (fromString) [cmd appendFormat:@"<fromDate>%@</fromDate>", fromString ];
            [fromDate release ];
        }
        [cmd appendFormat:@"<userId>%@</userId></accinfo>", result.userId ];
    }
    [cmd appendString:@"</accinfolist></command>" ];
    [self startProgress ];
    [bridge asyncCommand: cmd sender: self ];
}

-(void)asyncCommandCompletedWithResult:(id)result error:(PecuniaError*)err
{
    if(err == nil && result != nil) {
        BankQueryResult *res;
        
        for(res in result) {
            // find corresponding incoming structure
            BankQueryResult *iResult;
            for(iResult in bankQueryResults) {
                if([iResult.accountNumber isEqualToString: res.accountNumber ] && [iResult.bankCode isEqualToString: res.bankCode ]) break;
            }
            // saldo of the last statement is current saldo
            if ([res.statements count ] > 0) {
                BankStatement *stat = [res.statements objectAtIndex: [res.statements count ] - 1 ];
                iResult.balance = stat.saldo;
                /*				
                 // ensure order by refining posting date
                 int seconds;
                 NSDate *oldDate = [NSDate distantPast ];
                 for(stat in res.statements) {
                 if([stat.date compare: oldDate ] != NSOrderedSame) {
                 seconds = 0;
                 oldDate = stat.date;
                 } else seconds += 100;
                 if(seconds > 0) stat.date = [[[NSDate alloc ] initWithTimeInterval: seconds sinceDate: stat.date ] autorelease ];
                 }
                 */ 
                iResult.statements = res.statements;
            }
            if ([res.standingOrders count ] > 0) {
                iResult.standingOrders = res.standingOrders;
            }
        }
    }
    
    [self stopProgress ];
    
    if(err) {
        [err alertPanel ];
        NSNotification *notification = [NSNotification notificationWithName:PecuniaStatementsNotification object:nil ];
        [[NSNotificationCenter defaultCenter ] postNotification:notification ];
    } else {
        NSNotification *notification = [NSNotification notificationWithName:PecuniaStatementsNotification object:bankQueryResults ];
        [[NSNotificationCenter defaultCenter ] postNotification:notification ];
    }
    [bankQueryResults release ];
}


-(void)getStandingOrders:(NSArray*)resultList
{
    bankQueryResults = [resultList retain ];
    NSMutableString	*cmd = [NSMutableString stringWithFormat:@"<command name=\"getAllStandingOrders\"><accinfolist type=\"list\">" ];
    
    for(BankQueryResult *result in resultList) {
        [cmd appendString:@"<accinfo>" ];
        [self appendTag: @"bankCode" withValue: result.bankCode to: cmd ];
        [self appendTag: @"accountNumber" withValue: result.accountNumber to: cmd ];
        [self appendTag: @"userId" withValue: result.userId to: cmd ];
        [cmd appendString:@"</accinfo>" ];
    }
    [cmd appendString:@"</accinfolist></command>" ];
    [self startProgress ];
    [bridge asyncCommand: cmd sender: self ];
}

-(void)prepareCommand:(NSMutableString*)cmd forStandingOrder:(StandingOrder*)stord
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO] autorelease];
    
    [self appendTag: @"bankCode" withValue: stord.account.bankCode to: cmd ];
    [self appendTag: @"accountNumber" withValue: stord.account.accountNumber to: cmd ];
    [self appendTag: @"customerId" withValue: stord.account.customerId to: cmd ];
    [self appendTag: @"userId" withValue: stord.account.userId to: cmd ];
    [self appendTag: @"remoteAccount" withValue: stord.remoteAccount to: cmd ];
    [self appendTag: @"remoteBankCode" withValue: stord.remoteBankCode to: cmd ];
    [self appendTag: @"remoteName" withValue: stord.remoteName to: cmd ];
    [self appendTag: @"purpose1" withValue: stord.purpose1 to: cmd ];
    [self appendTag: @"purpose2" withValue: stord.purpose2 to: cmd ];
    [self appendTag: @"purpose3" withValue: stord.purpose3 to: cmd ];
    [self appendTag: @"purpose4" withValue: stord.purpose4 to: cmd ];
    [self appendTag: @"currency" withValue: stord.currency to: cmd ];
    [self appendTag: @"remoteCountry" withValue: @"DE" to: cmd ];
    NSDecimalNumber *val = [stord.value decimalNumberByMultiplyingByPowerOf10:2 ];
    [self appendTag: @"value" withValue: [val stringValue ] to: cmd ];
    
    [self appendTag: @"firstExecDate" withValue: [dateFormatter stringFromDate:stord.firstExecDate ] to: cmd ];
    if (stord.lastExecDate) {
        ShortDate *sDate = [ShortDate dateWithDate:stord.lastExecDate ];
        if (sDate.year < 2100) {
            [self appendTag: @"lastExecDate" withValue: [dateFormatter stringFromDate:stord.lastExecDate ] to: cmd ];
        }
    }
    
    // time unit
    switch ([stord.period intValue ]) {
        case stord_weekly: [self appendTag: @"timeUnit" withValue: @"W" to: cmd ]; break;
        default: [self appendTag: @"timeUnit" withValue: @"M" to: cmd ]; break;
    }
    
    [self appendTag: @"turnus" withValue: [stord.cycle stringValue ] to: cmd ];
    [self appendTag: @"executionDay" withValue: [stord.executionDay stringValue ] to: cmd ];
}

-(PecuniaError*)sendStandingOrders:(NSArray*)orders
{
    PecuniaError *err = nil;
    NSManagedObjectContext *context = [[MOAssistant assistant ] context ];
    
    [self startProgress ];
    for(StandingOrder *stord in orders) {
        // todo: don't send unchanged orders
        if ([stord.isChanged boolValue] == NO && [stord.toDelete boolValue ] == NO) continue;
        
        // don't send sent orders without ID
        if ([stord.isSent boolValue ] == YES && stord.orderKey == nil) continue;
        
        if (stord.orderKey == nil) {
            // create standing order
            NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"addStandingOrder\">" ];
            [self prepareCommand:cmd forStandingOrder:stord ];			
            [cmd appendString: @"</command>" ];
            
            NSDictionary *result = [bridge syncCommand: cmd error: &err  ];
            if (err) {
                [self stopProgress ];
                return err;
            }
            stord.isSent = [result valueForKey:@"isOk" ];
            stord.orderKey = [result valueForKey:@"orderId" ];
            if (stord.isSent) {
				stord.isChanged = [NSNumber numberWithBool:NO ];
            }
        } else if ([stord.toDelete boolValue ] == YES) {
            // delete standing order
            NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"deleteStandingOrder\">" ];
            [self prepareCommand:cmd forStandingOrder:stord ];
            if (stord.orderKey) {
                [self appendTag:@"orderId" withValue:stord.orderKey to:cmd ];
            }
            [cmd appendString: @"</command>" ];
            
            NSNumber *result = [bridge syncCommand: cmd error: &err  ];
            if (err) {
                [self stopProgress ];
                return err;
            }
            stord.isSent = result;
            if ([result boolValue ] == YES) {
                [context deleteObject:stord ];
            }
        } else {
            // change standing order
            NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"changeStandingOrder\">" ];
            [self prepareCommand:cmd forStandingOrder:stord ];
            [self appendTag:@"orderId" withValue:stord.orderKey to:cmd ];			
            [cmd appendString: @"</command>" ];
            
            NSNumber *result = [bridge syncCommand: cmd error: &err  ];
            if (err) {
                [self stopProgress ];
                return err;
            }
            stord.isSent = result;
            if ([result boolValue ] == YES) {
                stord.isChanged = [NSNumber numberWithBool:NO ];
            }
        }		
    }
    [self stopProgress ];
    return nil;
}

-(PecuniaError*)updateBankDataForUser:(User*)user
{
    PecuniaError *error=nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"updateBankData\">" ];
    [self appendTag: @"bankCode" withValue: user.bankCode to: cmd ];
    [self appendTag: @"customerId" withValue: user.customerId to: cmd ];
    [self appendTag: @"userId" withValue: user.userId to: cmd ];
    [cmd appendString: @"</command>" ];
    
    User *newUser = [bridge syncCommand: cmd error: &error ];
    if(error) return error;
    
    // update user
    for(User *usr in users) {
        if ([usr isEqual:newUser ]) {
            usr.tanMethodNumber = newUser.tanMethodNumber;
            usr.tanMethodDescription = newUser.tanMethodDescription;
            break;
        }
    }
    
    return nil;
}

-(PecuniaError*)changePinTanMethodForUser:(User*)user
{
    PecuniaError *error=nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"resetPinTanMethod\">" ];
    [self appendTag: @"bankCode" withValue: user.bankCode to: cmd ];
    [self appendTag: @"userId" withValue: user.userId to: cmd ];
    [cmd appendString: @"</command>" ];
    
    User *newUser = [bridge syncCommand: cmd error: &error ];
    if(error) return error;
    
    // update user
    for(User *usr in users) {
        if ([usr isEqual:newUser ]) {
            usr.tanMethodNumber = newUser.tanMethodNumber;
            usr.tanMethodDescription = newUser.tanMethodDescription;
            break;
        }
    }
    return nil;
}

-(PecuniaError*)sendCustomerMessage:(CustomerMessage*)msg
{
    PecuniaError *error=nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"customerMessage\">" ];
    [self appendTag: @"bankCode" withValue: msg.account.bankCode to: cmd ];
    [self appendTag: @"accountNumber" withValue: msg.account.accountNumber to:cmd ];
    [self appendTag: @"userId" withValue: msg.account.userId to: cmd ];
    [self appendTag: @"head" withValue: msg.header to: cmd ];
    [self appendTag: @"body" withValue: msg.message to: cmd ];
    [self appendTag: @"recpt" withValue: msg.receipient to: cmd ];
    [cmd appendString: @"</command>" ];

    NSNumber *result = [bridge syncCommand: cmd error: &error ];
    if(error) return error;

    if ([result boolValue ] == YES) {
        msg.isSent = [NSNumber numberWithBool:YES ];
    } else {
        error = [PecuniaError errorWithCode:0 message: NSLocalizedString(@"AP172", @"") ];
    }
    return error;
}

-(NSArray*)getTanMethodsForUser:(User*)user
{
    PecuniaError *error=nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getTANMethods\">" ];
    [self appendTag: @"bankCode" withValue: user.bankCode to: cmd ];
    [self appendTag: @"userId" withValue: user.userId to: cmd ];
    [cmd appendString: @"</command>" ];
    
    NSArray *methods = [bridge syncCommand: cmd error: &error ];
    if (error) {
        [error alertPanel ];
        return nil;
    }
    return methods;
}

- (NSArray*)getSupportedBusinessTransactions: (BankAccount*)account
{
    PecuniaError *error = nil;
    NSMutableString *cmd = [NSMutableString stringWithFormat: @"<command name=\"getSupportedBusinessTransactions\">" ];
    [self appendTag: @"bankCode" withValue: account.bankCode to: cmd];
    [self appendTag: @"accountNumber" withValue: account.accountNumber to: cmd];
    [self appendTag: @"userId" withValue: account.userId to: cmd];
    [cmd appendString: @"</command>" ];

    NSArray* result = [bridge syncCommand: cmd error: &error];
    if (error) {
        [error alertPanel ];
        return nil;
    }

    return result;
}

@end
