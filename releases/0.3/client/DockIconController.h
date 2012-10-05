//
//  DockIconController.h
//  Pecunia
//
//  Created by Eike Wolgast on 04.06.11.
//  Copyright 2011 Frank Emminghaus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BankStatement.h>

@interface DockIconController : NSObject {

	NSManagedObjectContext *managedObjectContext;
	NSInteger				badgeValue;
}

-(DockIconController*)initWithManagedObjectContext: (NSManagedObjectContext *) objectContext;
-(void)managedObjectContextChanged:(NSNotification *)notification;
-(NSInteger)numberUnread;
-(void)drawIconBadge;
@end
