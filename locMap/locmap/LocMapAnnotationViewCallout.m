//
//  LocMapAnnotationViewCallout.m
//  Lokki
//
//  Created by Oleg Fedorov on 11/27/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapAnnotationViewCallout.h"
#import "LocMapAnnotation.h"
#import <QuartzCore/QuartzCore.h>
#import "LocMapFormatters.h"
#import "Contacts.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "FSConstants.h"

//popup 268x92
//triangle - 16


#define LABEL1_HEIGHT 24
#define LABEL1_FONT_SIZE 20
#define LABEL2_HEIGHT 16
#define LABEL2_FONT_SIZE 12
#define BUTTON_SIZE 40


@interface  LocMapAnnotationViewCallout() <MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>

@property (strong) LocMapAnnotation* annotation;
@property (strong) UILabel* name;// user's name with time
@property (strong) UILabel* description;// description with time

@end

@implementation LocMapAnnotationViewCallout

- (id)initWithAnnotation:(id)ann
{
    self = [super initWithFrame:CGRectMake(-CALLOUT_WIDTH/2 + PIN_WIDTH/2, -CALLOUT_HEIGHT - CALLOUT_TRIANGLE_SIZE, CALLOUT_WIDTH, CALLOUT_HEIGHT + CALLOUT_TRIANGLE_SIZE)];
    if (self) {
        self.annotation = ann;
        [self setOpaque:NO];
        
        self.name = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, CALLOUT_WIDTH - 32, LABEL1_HEIGHT)];
        self.name.font = [UIFont boldSystemFontOfSize:LABEL1_FONT_SIZE];
        self.name.text = self.annotation.userName;
        [self addSubview:self.name];

        self.description = [[UILabel alloc] initWithFrame:CGRectMake(16, LABEL1_HEIGHT + 12, CALLOUT_WIDTH - 32, LABEL2_HEIGHT)];
        self.description.font = [UIFont systemFontOfSize:LABEL2_FONT_SIZE];
        self.description.text = [LocMapFormatters dateDescription:self.annotation.userLastReportTime];
        self.description.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [self addSubview:self.description];
        
        
        int buttonPosY = LABEL1_HEIGHT + 10 + LABEL2_HEIGHT + 16;
        int buttonPosX = (CALLOUT_WIDTH/4);
        UIButton* b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(buttonPosX - BUTTON_SIZE/2, buttonPosY, BUTTON_SIZE, BUTTON_SIZE);
        [b setImage:[UIImage imageNamed:@"call"] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(buttonCallClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b];

        UIButton* b2 = [UIButton buttonWithType:UIButtonTypeCustom];
        b2.frame = CGRectMake(buttonPosX*2 - BUTTON_SIZE/2, buttonPosY, BUTTON_SIZE, BUTTON_SIZE);
        [b2 setImage:[UIImage imageNamed:@"text"] forState:UIControlStateNormal];
        [b2 addTarget:self action:@selector(buttonTextClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b2];

        UIButton* b3 = [UIButton buttonWithType:UIButtonTypeCustom];
        b3.frame = CGRectMake(buttonPosX*3 - BUTTON_SIZE/2, buttonPosY, BUTTON_SIZE, BUTTON_SIZE);
        [b3 setImage:[UIImage imageNamed:@"card"] forState:UIControlStateNormal];
        [b3 addTarget:self action:@selector(buttonCardClick:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b3];
        
    }
    return self;
}

-(void)updateInfo
{
    self.name.text = self.annotation.userName;
    self.description.text = [LocMapFormatters dateDescription:self.annotation.userLastReportTime];
}


-(NSString*)getCleanPhoneNumberForEmail:(NSString*)email inContacts:(Contacts*)contacts
{
    NSString* phoneNumber = [contacts getPhoneNumberForEmail:email];
    if (!phoneNumber) {
        NSLog(@"Unknown phone number for %@", self.annotation.userEmail);
        return nil;
    }
    
    NSString *cleanedString = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789+"] invertedSet]] componentsJoinedByString:@""];
    return cleanedString;
}
    
    
-(void)buttonCallClick:(id)where
{
    NSString* email = self.annotation.userEmail;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Contacts* contacts = [[Contacts alloc] init];
        [contacts loadContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self handleIfContactIfEmailExists:email inContacts:contacts]) {
                return;
            }
            
            NSString* phoneNumber = [self getCleanPhoneNumberForEmail:email inContacts:contacts];
            if (!phoneNumber) {
                UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                                message:_LOCALIZE(@"PhoneNumberNotFoundInContacts")
                                                                delegate:nil
                                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                                otherButtonTitles:nil, nil];
                [alertView show];
                
                NSLog(@"Unknown phone number for %@", email);
                return;
            }
            phoneNumber = [@"telprompt://" stringByAppendingString:phoneNumber];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
        });
    });
    

}

    
-(void)buttonTextClick:(id)where
{
    NSString* email = self.annotation.userEmail;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Contacts* contacts = [[Contacts alloc] init];
        [contacts loadContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self handleIfContactIfEmailExists:email inContacts:contacts]) {
                return;
            }
            
            NSString* phoneNumber = [self getCleanPhoneNumberForEmail:email inContacts:contacts];
            if (!phoneNumber) {
                UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                                message:_LOCALIZE(@"PhoneNumberNotFoundInContacts")
                                                                delegate:nil
                                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                                otherButtonTitles:nil, nil];
                [alertView show];
                
                NSLog(@"Unknown phone number for %@", email);
                return;
            }
            
            MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
            picker.messageComposeDelegate = self;
            
            [picker setRecipients:@[phoneNumber]];
            
            //[(UINavigationController*)self.window.rootViewController pushViewController:picker animated:YES];
            [self.window.rootViewController presentViewController:picker animated:TRUE completion:nil];
        });
    });
    
    
    

}
    
    
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:TRUE completion:nil];
}


// if returns YES - contact exists and you can try to call or SMS or open details.
// if returns NO - contact doe not exist and user gets question to add contact.
-(BOOL)handleIfContactIfEmailExists:(NSString*)email inContacts:(Contacts*)contacts {
    if ([contacts contactWithEmailExists:email]) {
        return YES;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                    message:_LOCALIZE(@"AddNewContactQuestion")
                                                    delegate:self
                                                    cancelButtonTitle:_LOCALIZE(@"Don't add")
                                                    otherButtonTitles:_LOCALIZE(@"Add"), nil];
    [alertView show];
    return NO;
}

-(void)buttonCardClick:(id)where
{
    NSString* email = self.annotation.userEmail;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Contacts* contacts = [[Contacts alloc] init];
        [contacts loadContacts];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self handleIfContactIfEmailExists:email inContacts:contacts]) {
                return;
            }
            
            if (![contacts showPersonContactPageForEmail:email fromViewController:self.window.rootViewController]) {
            }
        });
    });
    
    
    
    
}

#define ADD_BUTTON_INDEX 1

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == ADD_BUTTON_INDEX) {
        Contacts* contacts = [[Contacts alloc] init];
        if (![contacts createPersonContactForEmail:self.annotation.userEmail fromViewController:self.window.rootViewController]) {
            UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                            message:_LOCALIZE(@"FailedToCreateContact")
                                                            delegate:nil
                                                            cancelButtonTitle:_LOCALIZE(@"OK")
                                                            otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    }
}

    
    
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    CGRect bubble = CGRectMake(0, 0, CALLOUT_WIDTH, CALLOUT_HEIGHT);

    UIBezierPath* borders = [UIBezierPath bezierPathWithRoundedRect:bubble cornerRadius:CALLOUT_BORDER_WIDTH];
    [[UIColor whiteColor] setFill];
    [borders fill];

    [[UIColor colorWithRed:0xEA/255.0 green:0xEA/255.0 blue:0xEA/255.0 alpha:1] setStroke];
    [borders stroke];
    
    [self drawTriangleAndMiddleLine];

    [borders addClip];// add clip after we drawn triangle because triangle is outside of clip area!
    
    UIGraphicsPopContext();
}

    
-(void)drawTriangleAndMiddleLine
{
    UIBezierPath* triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:CGPointMake(CALLOUT_WIDTH/2 - CALLOUT_TRIANGLE_SIZE/2, CALLOUT_HEIGHT - 1)];
    [triangle addLineToPoint:CGPointMake(CALLOUT_WIDTH/2 + CALLOUT_TRIANGLE_SIZE/2, CALLOUT_HEIGHT - 1)];
    [triangle addLineToPoint:CGPointMake(CALLOUT_WIDTH/2, CALLOUT_HEIGHT + CALLOUT_TRIANGLE_SIZE)];
    [triangle addLineToPoint:CGPointMake(CALLOUT_WIDTH/2 - CALLOUT_TRIANGLE_SIZE/2, CALLOUT_HEIGHT - 1)];
    [triangle closePath];
    [triangle fill];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, CALLOUT_WIDTH/2 - CALLOUT_TRIANGLE_SIZE/2, CALLOUT_HEIGHT); //start at this point
    CGContextAddLineToPoint(context, CALLOUT_WIDTH/2, CALLOUT_HEIGHT + CALLOUT_TRIANGLE_SIZE); //draw to this point
    CGContextAddLineToPoint(context, CALLOUT_WIDTH/2 + CALLOUT_TRIANGLE_SIZE/2, CALLOUT_HEIGHT); //draw to this point
    CGContextStrokePath(context);
    
    
    int middleLineY = LABEL1_HEIGHT + 8 + LABEL2_HEIGHT + 16;
    UIBezierPath* line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(0, middleLineY)];
    [line addLineToPoint:CGPointMake(CALLOUT_WIDTH, middleLineY)];
    [line closePath];
    [[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.2] setStroke];
    [line stroke];

}
    
    

@end
