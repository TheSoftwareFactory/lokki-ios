//
//  SignupViewController.m
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "SignupViewController.h"
#import "ServerApi+messages.h"
#import "LocalStorage.h"
#import "Checks.h"
#import "StandaloneGPSReporter.h"
#import "LocMapAppDelegate.h"
#import "FSConstants.h"
#import "Contacts.h"

@interface SignupViewController () <ServerApiDelegate, UITextFieldDelegate>
    @property (weak, nonatomic) IBOutlet UITextField *email;
    @property (weak, nonatomic) IBOutlet UILabel *invalidEmailNote;
    @property (weak, nonatomic) IBOutlet UIButton *signupButton;
    @property (weak, nonatomic) IBOutlet UILabel *errorNote;
    @property (weak, nonatomic) IBOutlet UILabel *helpLabel;

    @property (atomic, strong) ServerApi* serverApi;

@end

@implementation SignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self localize];
    
    self.email.delegate = self;
	// Do any additional setup after loading the view.
    self.serverApi = [[ServerApi alloc] initWithDelegate:self];
    
    self.signupButton.hidden = YES;
    self.invalidEmailNote.hidden = NO;
    self.errorNote.hidden = YES;
    
    [[FSConstants instance] applyGradientToView:self.view];
}

-(void)localize {
    self.helpLabel.text = _LOCALIZE(@"SignupEnterYourEmailAddress");
    self.email.placeholder = _LOCALIZE(@"your email address");
    self.invalidEmailNote.text = _LOCALIZE(@"Please enter a valid email");
    [self.signupButton setTitle:_LOCALIZE(@"Signup") forState:UIControlStateNormal];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.email resignFirstResponder];
    return NO;
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    // load contacts once just to ask user's permission immediately and avoid hangs later
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Contacts *contacts = [[Contacts alloc] init];
        [contacts loadContacts];
    });

    
    if (![LocalStorage privacyPolicyAccepted]) {
        [self performSegueWithIdentifier:@"ShowPrivacyPolicy" sender:self.navigationController];
    }
    
    NSString* cachedEmail = [LocalStorage getValueForKey:@"SignupViewCachedEmail"];
    if (cachedEmail) {
        self.email.text = cachedEmail;
        [self onEmailChanged:nil];
    }
}


// support only single orientation in this view
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
    
-(BOOL)emailIsValid
{
    return [Checks emailIsValid:self.email.text];
}

- (IBAction)onEmailChanged:(UITextField *)sender
{
    self.errorNote.hidden = YES;
    
    if ([self emailIsValid]) {
        self.signupButton.hidden = NO;
        self.invalidEmailNote.hidden = YES;
    } else {
        self.signupButton.hidden = YES;
        self.invalidEmailNote.hidden = NO;
    }
}

- (IBAction)onEmailValueChanged:(UITextField *)sender
{
    [self onEmailChanged:sender];
}
- (IBAction)onEmailEditingChanged:(UITextField *)sender
{
    [self onEmailChanged:sender];
}

-(NSString*)getDeviceID
{
    NSString *UUID = [[NSUUID UUID] UUIDString];
    // TODO: store it in keychain to reuse on next start?
    return UUID;
}

- (IBAction)onSignup:(id)sender
{
    self.signupButton.hidden = YES;
    NSString* email = [self.email.text lowercaseString];
    [LocalStorage setValue:email forKey:@"SignupViewCachedEmail"];
    
    
    [self.serverApi signupWithEmail:email andDeviceId:[self getDeviceID]];
}


- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
#ifdef DEBUG
    NSLog(@"Operation %d finished with status: %d and response %@", (int)type, (int)success, response);
#endif
    
    if (success && [self storeSignupResult:response]) {
        [self dismissViewControllerAnimated: YES completion: nil];
    } else {
        NSInteger errorCode = [self.serverApi getErrorCodeFromResponse:response];
        NSString* errorText;
        if (errorCode == SERVER_ERROR_SIGNUP_WRONG_AUTH_CODE) {
            errorText = [NSString stringWithFormat:_LOCALIZE(@"AccountDisabledForSecurityReasons"), self.email.text];
        } else {
            errorText = _LOCALIZE(@"SignupGenericError");
            
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:errorText
                                                           delegate:nil
                                                  cancelButtonTitle:_LOCALIZE(@"OK")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        //self.errorNote.hidden = NO;
        //self.errorNote.text = @"Signup failed!";
        
        [self onEmailChanged:self.email];// to enable or disable signup button
    }
    
}


-(BOOL)storeSignupResult:(NSDictionary *)response
{
    NSString* userId = response[@"id"];
    NSString* token = response[@"authorizationtoken"];
    if (!userId || !token) {
        NSLog(@"Server response does not contain id and token: %@", response);
        return NO;
    }
    
    [LocalStorage setLoggedInUserId:userId withAuthToken:token];
    [[StandaloneGPSReporter getInstance] quicklyQueryLocationAndSendToServer];
    LocMapAppDelegate* delegate = [UIApplication sharedApplication].delegate;
    [delegate onSuccessfulLogin];
    return YES;
}


@end
