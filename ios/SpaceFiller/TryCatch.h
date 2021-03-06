//
//  TryCatch.h
//  SpaceFiller
//
//  Created by Jesus Lopez on 4/9/15.
//  Copyright (c) 2015 JLA. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef SpaceFiller_TryCatch_h
#define SpaceFiller_TryCatch_h

extern void _try( void (^tryBlock)() );
extern void _catch( void (^catchBlock)( NSException *e ) );
extern void _throw( NSException *e );
extern void _synchronized( id object, void (^syncBlock)() );

#endif
