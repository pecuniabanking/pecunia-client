/*
 *  LogLevel.h
 *  Pecunia
 *
 *  Created by Frank Emminghaus on 22.09.10.
 *  Copyright 2010 Frank Emminghaus. All rights reserved.
 *
 */

typedef enum {
	log_alert = 0,
	log_error,
	log_warning,
	log_notice,
	log_info,
	log_debug,
	log_all,
} LogLevel;

@protocol MessageLog

-(void)addLog:(NSString*)msg withLevel:(LogLevel)level;

@end


