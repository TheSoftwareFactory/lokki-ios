//
//  PrivacyPolicyViewController.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "PrivacyPolicyViewController.h"
#import "LocalStorage.h"
#import "FSConstants.h"

@interface PrivacyPolicyViewController ()

    @property (weak, nonatomic) IBOutlet UITextView *textView;
    @property (strong) UITapGestureRecognizer* tap;
    @property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@end

@implementation PrivacyPolicyViewController

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

    [[FSConstants instance] applyGradientToView:self.view];

    if (!self.tap) {
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTextTap)];
        self.tap.numberOfTapsRequired = 2;
        self.textView.userInteractionEnabled = YES;
        [self.textView addGestureRecognizer:self.tap];
    }
}


-(void)localize {
    self.textView.text = _LOCALIZE(@"PrivacyPolicyText");
    [self.agreeButton setTitle:_LOCALIZE(@"I have read and agree to the terms") forState:UIControlStateNormal];
}

// support only single orientation in this view
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


-(void)onTextTap
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.f-secure.com/en/web/home_global/privacy/privacy-summary"]];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)agree:(id)sender {
    [LocalStorage acceptPrivacyPolicy];
    [self dismissViewControllerAnimated: YES completion: nil];
}




@end
