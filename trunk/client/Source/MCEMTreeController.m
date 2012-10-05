//
//  MCEMTreeController.m
//  Pecunia
//
//  Created by Frank Emminghaus on 13.04.09.
//  Copyright 2009 Frank Emminghaus. All rights reserved.
//

#import "MCEMTreeController.h"


@implementation MCEMTreeController

-(NSIndexPath*)reverseIndexPathForObject: (id)obj inArray: (NSArray*)nodes
{
	for (NSUInteger i = 0; i < [nodes count]; i++) {
		NSTreeNode *node = [nodes objectAtIndex: i];
		id nodeObj = [node representedObject ];
		if(nodeObj == obj) return [NSIndexPath indexPathWithIndex: i ];
		else {
			NSArray *children = [node childNodes ];
			if(children == nil) continue;
			NSIndexPath *p = [self reverseIndexPathForObject: obj inArray: children ];
			if(p) return [p indexPathByAddingIndex: i ];
		}
	}
	return nil;
}

-(NSIndexPath*)indexPathForObject: (id)obj
{
	int i;
	
	NSArray *nodes = [[self arrangedObjects ] childNodes ];
	NSIndexPath *path = [self reverseIndexPathForObject: obj inArray: nodes ];
	if(path == nil) return nil;
	// IndexPath umdrehen
	NSIndexPath *newPath = [[[NSIndexPath alloc ] init] autorelease];
	for(i=[path length ]-1; i>=0; i--) newPath = [newPath indexPathByAddingIndex: [path indexAtPosition:i ] ]; 
	return newPath;
}

-(BOOL)setSelectedObject: (id)obj
{
	NSIndexPath *path = [self indexPathForObject: obj ];
	if(path == nil) return NO;
	return [self setSelectionIndexPath: path ];
}

-(void)resort
{
	NSArray *sds = [self sortDescriptors ];
	if(sds == nil) return;
	
	NSArray* nodes = [[self arrangedObjects ] childNodes ];
	NSTreeNode *node;
	for(node in nodes) {
		[node sortWithSortDescriptors:sds recursively:YES ];
	}
}


@end
