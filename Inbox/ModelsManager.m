//
//  ModelsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelsManager.h"
#import "AppDelegate.h"
#import "NSObject+Queues.h"
#import "EmailSynchronizer.h"
#import "Synchronizer.h"
#import "EmailAccountModel.h"
@implementation ModelsManager

-(id)init{
    if (self = [super init]){
        synchronizers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers release];
    [super dealloc];
}

-(BOOL)refreshEmailAccounts{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    
    NSManagedObjectContext* context = [[AppDelegate sharedInstance].coreDataManager mainContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSError* fetchError = nil;
    NSArray* emailsModels = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        [request release];
        return false;
    }

    for (EmailAccountModel* account in emailsModels){
        EmailSynchronizer* sync = [[EmailSynchronizer alloc] initWithAccountId:account.objectID];
        [synchronizers addObject:sync];
    }
    [request release];
    return true;
}


-(void)startSync{
    if(![self refreshEmailAccounts]){
        [self onSyncFailed];
        return;
    }
    runningSync = [synchronizers count];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncFailed) name:INTERNAL_SYNC_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncDone) name:INTERNAL_SYNC_DONE object:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        for (Synchronizer* sync in synchronizers){
            [sync startSync];
        }
    });
}

-(void)abortSync{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    runningSync = 0;
}

-(void)onSyncDone{
    @synchronized(self){
        runningSync--;
        if (runningSync==0){
            [self executeOnMainQueueSync:^{
                [synchronizers removeAllObjects];
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
            }];
        }
    }
}


-(void)onSyncFailed{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    runningSync = 0;
    [self executeOnMainQueueSync:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_FAILED object:nil];
    }];
}

-(BOOL)isSyncing{
    return runningSync == 0;
}

@end
