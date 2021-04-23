//
//  AccountStatementsHandler.swift
//  Pecunia
//
//  Created by Frank Emminghaus on 03.04.21.
//  Copyright © 2021 Frank Emminghaus. All rights reserved.
//

import Foundation

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
    
    func getStatementsForYear(year:Int, fromNumber:Int) ->Bool {
        var number = fromNumber
       
        while true {
            guard let statement = HBCIBackend.backend.getAccountStatement(number, year: year, bankAccount: self.account) else {
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
    
    @objc func getAccountStatements() {
        
        if let (year, number) = getLastStatement() {
           _ = getStatementsForYear(year: year, fromNumber: number+1);
        } else {
            // we start with the current year and then go back
            var startYear = Int(ShortDate.current()!.year);
            
            while getStatementsForYear(year: startYear, fromNumber: 1) {
                startYear -= 1
            }
        }
        
        do {
            try self.context.save()
        }
        catch let error as NSError {
            let alert = NSAlert(error: error);
            alert.runModal();
        }

    }
    
    
}
