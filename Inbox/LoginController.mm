//
//  LoginController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import "LoginController.h"
#import "AppDelegate.h"
#import "DeskController.h"
#import "GmailModel.h"
@implementation LoginController
@synthesize desk;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    self.desk = nil;
    [emailField release];
    [passwordField release];
    [submitButton release];
    [emailField release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad{
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistPath){
        emailField.text = [plistDic valueForKey:@"email"];
        passwordField.text = [plistDic valueForKey:@"password"];
    }
    [super viewDidLoad];
}

-(void)linkToModel{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:ERROR object:nil];
}

-(void)unlinkToModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    [self linkToModel];
}


-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self unlinkToModel];
}

- (void)viewDidUnload{
    [passwordField release];
    passwordField = nil;
    [submitButton release];
    submitButton = nil;
    [emailField release];
    emailField = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@gmail\\.com";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}


#pragma mark - IBActions

- (IBAction)onLogin:(id)sender {
    if (![self validateEmail:emailField.text]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.invalidemail.title", @"title of the alert shown when the login email is invalid") message:NSLocalizedString(@"login.invalidemail.message", @"message of the alert shown when the login email is invalid") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.invalidemail.button", @"button title of the alert shown when the login email is invalid") otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    }else if ([passwordField.text isEqualToString:@""]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.emptypassword.title","title of the alert shown when the login password is empty") message:NSLocalizedString(@"login.emptypassword.message", @"message of the alert shown when the login password is empty") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.emptypassword.button", @"button title of the alert shown when the login password is empty") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }else{
        NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
        NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        BOOL reset = false;
        if (![[plistDic valueForKey:@"email"] isEqualToString:emailField.text]){
            reset = true;
        }
        [plistDic setValue:emailField.text forKey:@"email"];
        [plistDic setValue:passwordField.text forKey:@"password"];
        [plistDic writeToFile:plistPath atomically:YES];
        [self unlinkToModel];
        [self.desk linkToModel];
        if (reset){
            [self.desk resetModel];
        }else{
            [self.desk.model sync];
        }
        [plistDic release];
        [self dismissModalViewControllerAnimated:YES];
    }
}
@end
