//
//  TryCatch.m
//  SpaceFiller
//
//  Created by Jesus Lopez on 4/9/15.
//  Copyright (c) 2015 JLA. All rights reserved.
//

#import "TryCatch.h"

static NSString *kLastExceptionKey = @"lastTryCatchException";

void _try( void (^tryBlock)() ) {
  [[NSThread currentThread].threadDictionary removeObjectForKey:kLastExceptionKey];
  @try {
    tryBlock();
  }
  @catch (NSException *e) {
    [NSThread currentThread].threadDictionary[kLastExceptionKey] = e;
  }
}

void _catch( void (^catchBlock)( NSException *e ) ) {
  NSException *e = [NSThread currentThread].threadDictionary[kLastExceptionKey];
  if ( e ) {
    catchBlock( e );
  }
}

void _throw( NSException *e ) {
  @try {
    @throw e;
  }
  @catch ( NSException *e ) {
    NSLog( @"%@ %@\n%@", e.name, e.reason, e.callStackSymbols );
    @throw e;
  }
}