//
//  EmailReader.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmailReader.h"
#import "CTCoreMessage.h"
#import "CTCoreFolder.h"

@implementation EmailReader



-(int)emailsCountInFolder:(NSManagedObjectID*)folderId error:(NSError**)error{
    error = nil;
    NSManagedObjectContext* context = [self newContext];    
    FolderModel* folder = (FolderModel*)[context objectWithID:folderId];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path = %@ AND newPath = nil) OR (newPath = %@)", folder.path, folder.path];          
    [request setPredicate:predicate];
    
    int count = [context countForFetchRequest:request error:error];
    [context release];
    [request release];
    if (error){
        return -1;
    }else{
        return count;
    }
}


-(NSArray*)foldersForAccount:(NSManagedObjectID*)accountId error:(NSError**)error{
    error = nil;
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];    
    EmailAccountModel* account = (EmailAccountModel*) [context objectWithID:accountId];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    [request setPropertiesToFetch:[NSArray arrayWithObject:[[entity propertiesByName] objectForKey:@"path"]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(account == %@)", account];          
    [request setPredicate:predicate];
    
    NSArray* folders = [context executeFetchRequest:request error:error];
    [context release];
    [request release];
    if (error){
        return [NSArray array];
    }else{
        NSMutableArray* results = [NSMutableArray array];
        folders = [folders sortedArrayUsingSelector:@selector(compare:)];
        for (FolderModel* folder in folders){
            [results addObject:folder.objectID];
        }
        return results;
    }
}


-(void)moveEmail:(NSManagedObjectID*)emailId toFolder:(NSManagedObjectID *)folderId error:(NSError**)error{
    NSManagedObjectContext* context = [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];
    FolderModel* folder = (FolderModel*) [context objectWithID:folderId];
    EmailModel* email = (EmailModel*)[context objectWithID:emailId];
    if ([folder.account isEqual:email.folder.account]){
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:DATA_INVALID userInfo:[NSDictionary dictionaryWithObject:@"folder.account != email.account" forKey:ROOT_MESSAGE]];
    }
    email.folder = folder;
    [context save:error];
}


-(NSManagedObjectID*)lastEmailFromFolder:(NSManagedObjectID *)folderId error:(NSError**)error{
    *error = nil;
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];    
    FolderModel* folder = (FolderModel*)[context objectWithID:folderId];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path = %@ AND newPath = nil) OR (newPath = %@)", folder.path, folder.path];          
    [request setPredicate:predicate];
    NSSortDescriptor *sortBySentDate = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortBySentDate, nil]];
    [sortBySentDate release];
    [request setPropertiesToFetch:[entity properties]];
    
    NSArray* objects = [context executeFetchRequest:request error:error];
    [context release];
    [request release];
    if (error){
        return nil;
    }else{
        if ([objects count]>0){
            EmailModel* model = [objects objectAtIndex:0];
            return [model objectID];
        }else{
            return nil;
        }
    }
}

-(void)fetchEmailBody:(NSManagedObjectID*)emailId error:(NSError**)error{
    NSManagedObjectContext* context = [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];
    EmailModel* email = (EmailModel*)[context objectWithID:emailId];
    CTCoreAccount* account = [[CTCoreAccount alloc] init];
    @try {
        //[account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        [account connectToServer:email.folder.account.serverAddr port:email.folder.account.port connectionType:email.folder.account.conType authType:email.folder.account.authType login:email.folder.account.login password:email.folder.account.password];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    CTCoreFolder *inbox  = nil;
    @try {
        inbox = [account folderWithPath:email.folder.path];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    
    CTCoreMessage* message = nil;
    @try {
        message = [inbox messageWithUID:email.uid];
        [message fetchBody];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    email.htmlBody = [message htmlBody];
    [context save:error];
    [account release];
}


@end
