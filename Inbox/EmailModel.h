/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface EmailModel : NSManagedObject{
    NSString* uid;
    NSString* subject;
    NSDate* sentDate; /* GMT time */
    NSNumber* skippedIndex;
    NSString* senderName;
    NSString* senderEmail;
    NSString* path; /* path from the server*/ 
    NSString* newPath; /* next path of the email, will be update during the next round*/
    NSString* htmlBody;    
}
@property(nonatomic,retain) NSString* uid;
@property(nonatomic,retain) NSString* subject;
@property(nonatomic,retain) NSDate* sentDate;
@property(nonatomic,retain) NSNumber* skippedIndex;
@property(nonatomic,retain) NSString* senderName;
@property(nonatomic,retain) NSString* senderEmail;
@property(nonatomic,retain) NSString* path;
@property(nonatomic,retain) NSString* newPath;
@property(nonatomic,retain) NSString* htmlBody;
+(NSString*)entityName;
@end
