//
//  AccountStatementsHandler.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 03.04.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation
import HBCI4Swift

class AccountStatementsHandler : NSObject {
    let account:BankAccount;
    let context:NSManagedObjectContext
    
    @objc init(_ account:BankAccount, context:NSManagedObjectContext) {
        self.account = account;
        self.context = context;
    }
    
    func getLastStatement() -> (year:Int, number:Int)? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>();
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "AccountStatement", in: self.context);
        fetchRequest.predicate = NSPredicate(format: "account = %@", self.account);
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)];
        
        do {
            if let statements = try context.fetch(fetchRequest) as? [AccountStatement] {
                if let statement = statements.first {
                    if let shortDate = ShortDate(date: statement.startDate) {
                        return (Int(shortDate.year), statement.number.intValue);
                    }
                }
            }
        }
        catch {
            return nil;
        }
        return nil;
    }
    
    func getStatementsForYear(year:Int, fromNumber:Int) throws ->Bool {
        var number = fromNumber
       
        while true {
            guard let statement = try HBCIBackend.backend.getAccountStatement(number, year: year, bankAccount: self.account) else {
                break;
            }
            guard statement.document != nil else {
                break;
            }
            
            if statement.format.intValue == AccountStatementFormat.MT940.rawValue {
                statement.convertStatementsToPDF(for: self.account);
            }
            let entity = statement.entity;
            let attributeKeys = Array<String>(entity.attributesByName.keys);
            let attributeValues = statement.dictionaryWithValues(forKeys: attributeKeys)
            
            let newStatement = NSEntityDescription.insertNewObject(forEntityName: "AccountStatement", into: self.context) as! AccountStatement
            newStatement.setValuesForKeys(attributeValues)
            newStatement.account = account
            if newStatement.number == nil || newStatement.number.intValue == 0 {
                newStatement.number = NSNumber(value: number)
            }
            number += 1
        }
        
        return number > fromNumber;
    }
    
    func getAccountStatements() throws {
        // AccountStatementList transaction (HKKAU) is not supported by all institutes. So we try to get the
        // account statements one by one
        var startYear = Int(ShortDate.current()!.year);

        do {
            if var (year, number) = getLastStatement() {
                while year <= startYear {
                    _ = try getStatementsForYear(year: year, fromNumber: number+1);
                    year += 1;
                    number = 0;
                }
            } else {
                // we start with the current year and then go back
                while try getStatementsForYear(year: startYear, fromNumber: 1) {
                    startYear -= 1
                }
            }

            try self.context.save()
        }
        catch HBCIError.userAbort {
            throw HBCIError.userAbort;
        }
        catch let error as NSError {
            let alert = NSAlert(error: error);
            alert.runModal();
        }
    }
    
    @objc func getAccountStatementsNoException() -> Bool {
        do {
            try self.getAccountStatements();
        }
        catch {
            return false;
        }
        return true;
    }
    
    
}
