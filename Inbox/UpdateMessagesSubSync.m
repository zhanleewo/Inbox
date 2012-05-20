//
//  UpdateMessagesSynchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UpdateMessagesSubSync.h"
#import <CoreData/CoreData.h>
#import "EmailModel.h"
#import "FolderModel.h"
#import "errorCodes.h"
#import "CTCoreFolder.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "EmailAccountModel.h"
#import "EmailSynchronizer.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#define DL_PAGE_SIZE 100

@interface UpdateMessagesSubSync ()
@end



@implementation UpdateMessagesSubSync

-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc periodicCall:(void(^)()) periodic{
    if (!error){
        NSError* err;
        error = &err;
    }
    *error = nil;
    foldersMessageCount = [[NSMutableDictionary alloc] init];
    onStateChanged = [osc retain];
    periodicCall = [periodic retain];
    [self updateLocalMessagesWithError:error];
    [onStateChanged release];
    onStateChanged = nil;
    [periodicCall release];
    periodicCall = nil;
}

-(void)dealloc{
    [foldersMessageCount release];
    [super dealloc];
}

-(void)updateLocalMessagesWithError:(NSError**)error {

    /* get the folders model */
    NSFetchRequest *foldersRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderDescription = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    foldersRequest.entity =folderDescription;

    NSMutableArray* folders = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:foldersRequest error:error]];
    [foldersRequest release];
    
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        return;
    }

    int currentFolderIndex = 0;
    int page = 0;
    int pageSize = 100;
    int updateRemoteCounter = 0;
    NSMutableDictionary* totalMessageCount = [NSMutableDictionary dictionary];
    
    while ([folders count] != 0) {
        if (updateRemoteCounter++%30 == 0){
            periodicCall();
        }

        FolderModel* folderModel = [folders objectAtIndex:currentFolderIndex];

        CTCoreFolder* coreFolder = [self coreFolderForFolder:folderModel error:error];
        if (*error) {
            return;
        }
        
        NSSet *messagesBuffer = [self nextCoreMessagesForFolder:folderModel coreFolder:coreFolder page:page error:error];
        if (*error) {
            return;
        }
        
        for (CTCoreMessage* message in messagesBuffer) {
            [self processCoreEmail:message folder:folderModel coreFolder:coreFolder error:error];
            if (*error){
                return;
            }
        }
    
        if ([messagesBuffer count] == 0) {
            [folders removeObject:[folders objectAtIndex:currentFolderIndex]];
        }

        [self.context save:error];
        
        if (*error){
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
            return;
        }
        
        onStateChanged();

        currentFolderIndex = currentFolderIndex+1;
        currentFolderIndex = currentFolderIndex % [folders count];
        
        if (currentFolderIndex==0){
            page++;
        }
    }
}


-(void)processCoreEmail:(CTCoreMessage*)message folder:(FolderModel*)folder coreFolder:(CTCoreFolder*)coreFolder error:(NSError**)error {
    
    
    // Get the exisiting email or create a new one
    NSFetchRequest *emailRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    emailRequest.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [emailRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    EmailModel* emailModel = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@ AND folder = %@", message.uid,folder];
    [emailRequest setPredicate:predicate];
    
    NSArray* matchingEmails = [self.context executeFetchRequest:emailRequest error:error];
    [emailRequest release];
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        return;   
    }
    
    if ([matchingEmails count]>0){
        emailModel = [matchingEmails objectAtIndex:0];
    }else{
        @try {
            emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:self.context];
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return;   
        }
    }
    
    // update the current email
    
    NSEnumerator* enumerator = [message.from objectEnumerator];
    CTCoreAddress* from;
    
    // The "sender" field is not valid
    if ([message.from count]>0){
        from = [enumerator nextObject];
    }else{
        from = message.sender;
    }
    
    emailModel.senderName = from.name;
    emailModel.senderEmail = from.email;
    emailModel.subject=message.subject;
    emailModel.sentDate = message.sentDateGMT;
    emailModel.uid = message.uid;
    emailModel.serverPath = folder.path;
    emailModel.read = !message.isUnread;
    emailModel.folder = folder;
}

-(CTCoreFolder*)coreFolderForFolder:(FolderModel*)folder error:(NSError**)error{
    if (!error){
        NSError* err = nil;
        error = &err;        
    }
    *error = nil;
    
    CTCoreFolder* coreFolder;
    
    @try {
        CTCoreAccount* account = [self coreAccountWithError:error];
        if (*error){
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
            return nil;
        }   
        
        // Check this : http://github.com/mronge/MailCore/issues/2
        coreFolder = [account folderWithPath:folder.path]; 
        [coreFolder connect];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return nil;
    }
    return coreFolder;

}

-(NSSet*) nextCoreMessagesForFolder:(FolderModel*)folder coreFolder:(CTCoreFolder*)coreFolder page:(int)page error:(NSError**)error{
        int coreFolderMessageCount = 0;
    if (![foldersMessageCount objectForKey:folder.objectID]){
        [foldersMessageCount setObject:[NSNumber numberWithInt:[coreFolder totalMessageCount]] forKey:folder.objectID];
    }
    coreFolderMessageCount = [[foldersMessageCount objectForKey:[NSNumber numberWithInt:[coreFolder totalMessageCount]]] intValue];

    NSSet* messages = [NSSet set];
    @try {
        int start = coreFolderMessageCount - (page+1) * DL_PAGE_SIZE; 
        if (start<0) start = 0;
        int end = coreFolderMessageCount - (page) * DL_PAGE_SIZE;
        if (end<0) end = 0;
        messages = [coreFolder messageObjectsFromIndex:start toIndex:end];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return [NSSet set];
    }

    return messages;
}

@end