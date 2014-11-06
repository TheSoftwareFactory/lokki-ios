//
//  LocMapViewController.m
//  locmap
//
//  Created by Oleg Fedorov on 11/14/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapViewController.h"
#import "MapKit/MapKit.h"
#import "LocalStorage.h"
#import "Users.h"
#import "LocMapAnnotation.h"
#import "LocMapAnnotationView.h"
#import "StandaloneGPSReporter.h"
#import "PeopleViewController.h"
#include "Contacts.h"
#include "Tutorial.h"
#import "ServerApi+messages.h"
#import "LocMapAvatarsAroundMap.h"
#import "LocMapNonOverlappingAnnotations.h"
#import "UIBottomToolbar.h"
#import "UITransparentToolbar.h"
#import "PlacesViewController.h"
#import "MapPlaceCircle.h"
#import "MapPlaceCircleOverlay.h"
#import "AppRater.h"

// 1 degree is about 110 km
#define DEGREES_IN_METER 1.0/110000.0
#define ADD_A_PLACE_ALERT_VIEW 1111


enum GreyOutViewMode {
    kGreyOutViewModeChangeVisibility,
    kGreyOutViewModeAddSomething
};

@interface LocMapViewController () <MKMapViewDelegate, ServerApiDelegate, TutorialDelegate, LocMapAvatarsAroundMapDelegate>

    @property (weak, nonatomic) IBOutlet UITransparentToolbar *transparentToolbar;
    @property (weak, nonatomic) IBOutlet UIBottomToolbar *bottomToolbar;
    @property (weak, nonatomic) IBOutlet MKMapView *map;
    @property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;

    @property (weak, nonatomic) IBOutlet UIButton *greyedOutViewSelectionTopButton;
    @property (weak, nonatomic) IBOutlet UIButton *greyedOutViewSelectionBottomButton;
    @property (weak, nonatomic) IBOutlet UIImageView *greyedOutViewSelectionTopImage;
    @property (weak, nonatomic) IBOutlet UIImageView *greyedOutViewSelectionBottomImage;
    @property enum GreyOutViewMode greyedOutViewMode;

    @property (strong) LocMapAvatarsAroundMap* avatarsAroundMap;
    @property (strong) LocMapNonOverlappingAnnotations* nonOverlappingAnnotations;
    @property (strong) PlacesViewController* placesViewController;

    @property (nonatomic) BOOL reportingOn;

    @property (atomic, strong) ServerApi* serverApi;
    @property (nonatomic, strong) NSTimer* dashboardUpdateTimer;
    @property (nonatomic, strong) NSTimer* dashboardUpdateTimerSingleShot;//update dashboard once. we use it to avoid constant dashboard updates - always postpone update with this timer and check if timer is not nil - dont add new timer

    @property (nonatomic) BOOL mapViewWasSetToShowEveryoneAlready;
    @property (nonatomic) BOOL hasShownNoFriendsTutorialAlready;


    @property (weak, nonatomic) IBOutlet UIView *grayOutView;
    @property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizerForGreyArea;

    @property (weak, nonatomic) IBOutlet UIView *visibilityButtons;

    @property (strong, nonatomic) NSArray* alreadyCachedUserIDS;//of NSString*
    @property BOOL clearAlreadyCachedUserIDSOnNextAppear;// clear alreadyCachedUserIDS in next viewDidAppear (can be set by emitting notification ReloadCachedContactsOnNextAppear
    @property (strong, nonatomic) NSString* centeredUserID;// if not nil then here is the current centered user id (dashboard updates follow this guy)

    @property CLLocationCoordinate2D creatingNewPlaceInThisCoordinate;// we keep coordinate for new place here while asking for the place name

    @property BOOL alreadyExecutedAppRater;
@end

@implementation LocMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSArray*)alreadyCachedUserIDS
{
    if (!_alreadyCachedUserIDS) {
        _alreadyCachedUserIDS = [[NSArray alloc] init];
    }
    return _alreadyCachedUserIDS;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.serverApi = [[ServerApi alloc] initWithDelegate:self];
    enum UIBottomToolbarSelectedItem initialBottomToolbarItem = [self getBottomToolbarActivateState];
    [self.bottomToolbar initOnce];
    [self.bottomToolbar createButtonsForMapView:self.map currentState:kUIBottomToolbarSelectedItemMap];

    [self.transparentToolbar createButtonsForMapView:self.map];
                      
    self.nonOverlappingAnnotations = [[LocMapNonOverlappingAnnotations alloc] initForMap:self.map];
    
    self.grayOutView.hidden = YES;
    self.visibilityButtons.hidden = YES;
    self.visibilityButtons.layer.cornerRadius = 7;
    self.visibilityButtons.layer.borderWidth = 0;
    self.visibilityButtons.clipsToBounds = YES;
    self.visibilityButtons.layer.borderColor = [UIColor grayColor].CGColor;
    
    self.map.delegate = self;
    
    [self loadCachedData];
    [self setStatusBarButtons];
    
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(dashboardNeedsUpdating:)
                                            name:@"DashboardNeedsUpdating"
                                            object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(onReloadCachedContacts:)
                                            name:@"ReloadCachedContacts"
                                            object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(onReloadCachedContacts:)
                                                   name:@"ReloadCachedContactsOnNextAppear"
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(onBottomToolbarSelectionChanged:)
                                                   name:NOTIFICATION_BOTTOM_TOOLBAR_SELECTED_ITEM_CHANGED
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(onActivateMapAndSelectUser:)
                                                   name:@"ActivateMapAndSelectUser"
                                                 object:nil];
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(onPlacesUpdated:)
                                                   name:@"PlacesUpdated"
                                                 object:nil];
    
    if (!self.tapRecognizerForGreyArea) {
        self.tapRecognizerForGreyArea = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGreyAreaTap)];
        self.tapRecognizerForGreyArea.numberOfTapsRequired = 1;
        self.grayOutView.userInteractionEnabled = YES;
        [self.grayOutView addGestureRecognizer:self.tapRecognizerForGreyArea];
    }
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressOnMap:)];
    lpgr.minimumPressDuration = 1.5; //user needs to press for 1.5 seconds
    [self.map addGestureRecognizer:lpgr];
    
    self.avatarsAroundMap = [[LocMapAvatarsAroundMap alloc] initForMap:self.map withDelegate:self];
    
    [self localize];

    // we should do it last as it sends some notifications
    if (kUIBottomToolbarSelectedItemMap != initialBottomToolbarItem) {
        [self.bottomToolbar setSelectedItem:initialBottomToolbarItem];
    }
}

-(void)localize {
    self.navigationBar.title = _LOCALIZE(@"Lokki");
    
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(enum UIBottomToolbarSelectedItem)getBottomToolbarActivateState {
    NSNumber* n = [LocalStorage getValueForKey:@"UIBottomToolbarActivateState"];
    enum UIBottomToolbarSelectedItem state = (enum UIBottomToolbarSelectedItem)[n integerValue];
    return state;
}



- (void)dashboardNeedsUpdating:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DashboardNeedsUpdating"]) {
        
#ifdef DEBUG
        NSLog(@"Application state in dashboardNeedsUpdating: %d", (int)[UIApplication sharedApplication].applicationState);
#endif
        
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            if (!self.dashboardUpdateTimerSingleShot) {
                self.dashboardUpdateTimerSingleShot = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateDashboardByTimer) userInfo:nil repeats:YES];
            }
            //[self.serverApi getDashboardFromServer];
        }
        
    }
}

- (void)onPlacesUpdated:(NSNotification *) notification
{
    [self buildMapViewFromDashboard];
}


-(void)onReloadCachedContacts:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"ReloadCachedContacts"]) {
        self.alreadyCachedUserIDS = [[NSArray alloc] init];// read new names and avatar pictures
    } else {
        self.clearAlreadyCachedUserIDSOnNextAppear = YES;
    }
}


-(void)onActivateMapAndSelectUser:(NSNotification *) notification {
    NSLog(@"onActivateMapAndSelectUser data received: %@", [notification userInfo]);
    
    NSString* userID = [notification userInfo][@"userID"];
    if (self.bottomToolbar.selectedItem != kUIBottomToolbarSelectedItemMap) {
        [self hidePlacesView];
    }
    
    [self selectUserAndCenterMap:userID];
}


-(void)onBottomToolbarSelectionChanged:(NSNotification *) notification
{
    enum UIBottomToolbarSelectedItem state = self.bottomToolbar.selectedItem;
    
    if (state == kUIBottomToolbarSelectedItemMap) {
        [self hidePlacesView];
    } else {
        [self showPlacesView];
    }
}

-(void)showPlacesView
{
    if (!self.placesViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        self.placesViewController = [storyboard  instantiateViewControllerWithIdentifier:@"PlacesViewController"];
        
        CGRect disappearFrame = self.view.frame;
        disappearFrame.origin.x = disappearFrame.size.width;
        disappearFrame.origin.y = 0;
        self.placesViewController.view.frame = disappearFrame;
    }
    self.bottomToolbar.selectedItem = kUIBottomToolbarSelectedItemPlaces;

    CGRect frame = self.view.frame;
    frame.origin.y = 0;//starts after toolbar
//    frame.size.height -= self.bottomToolbar.frame.size.height;// bottom toolbar must be still visible
    
    //[self addChildViewController:self.placesViewController];
    if (![self.view.subviews containsObject:self.placesViewController.view]) {
        [self.view addSubview:self.placesViewController.view];
        [self.view bringSubviewToFront:self.placesViewController.view];
        [self.view bringSubviewToFront:self.bottomToolbar];// toolbar on top
    }

    
    CGRect disappearFrame = self.view.frame;
    disappearFrame.origin.x = disappearFrame.size.width;
    //[self.placesViewController removeFromParentViewController];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn animations:^() {
        self.placesViewController.view.frame = frame;
    } completion:^(BOOL fin) {
    }];

    
    
}


-(void)hidePlacesView
{
    self.bottomToolbar.selectedItem = kUIBottomToolbarSelectedItemMap;
    
    CGRect disappearFrame = self.view.frame;
    disappearFrame.origin.x = disappearFrame.size.width;
    disappearFrame.origin.y = 0;
    //[self.placesViewController removeFromParentViewController];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn animations:^() {
        self.placesViewController.view.frame = disappearFrame;
    } completion:^(BOOL fin) {
        if (fin) {
            [self.placesViewController.view removeFromSuperview];
        }
    }];
    
    
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
    
-(void)viewDidAppear:(BOOL)animated
{
    if (![self.serverApi loggedIn]) {
        [self performSegueWithIdentifier:@"SignupSegue" sender:self.navigationController];
    } else {

#ifdef DEBUG
        NSLog(@"Application state in viewDidAppear: %d", (int)[UIApplication sharedApplication].applicationState);
#endif
        
       if (!self.dashboardUpdateTimer) {
            self.dashboardUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(updateDashboardByTimer) userInfo:nil repeats:YES];
        }

        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            [Tutorial triggerWelcomeToLokki];
            [Tutorial checkIfBackgroundRefreshEnabled];
            [Tutorial checkIfLocationServiceEnabled];
            
            if (!self.alreadyExecutedAppRater && ![self isAnyAlertVisible]) {
                self.alreadyExecutedAppRater = YES;
                [[AppRater instance] onTrigger];
            }
        }
    }
    
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        if (self.clearAlreadyCachedUserIDSOnNextAppear) {
            self.alreadyCachedUserIDS = [[NSArray alloc] init];
            [self cacheNewUsers:[LocalStorage getDashboard]];
            self.clearAlreadyCachedUserIDSOnNextAppear = NO;
        }
    }
}

-(void)updateDashboardByTimer {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self.serverApi getDashboardFromServer];
    }
    [self.dashboardUpdateTimerSingleShot invalidate];
    self.dashboardUpdateTimerSingleShot = nil;
}

// returns YES if any UIAlertView is currently shown
- (BOOL)isAnyAlertVisible {
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0){
            for (id cc in subviews) {
                if ([cc isKindOfClass:[UIAlertView class]]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.map.showsUserLocation = NO;
    self.map.mapType = (MKMapType)[LocalStorage getMapType];

#ifdef DEBUG
    NSLog(@"Application state in viewWillAppear: %d", (int)[UIApplication sharedApplication].applicationState);
#endif
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return;
    }
    
    
    if ([self.serverApi loggedIn]) {
        [self buildMapViewFromDashboard];
    }

    [self.serverApi getDashboardFromServer];
    
    if (self.reportingOn != [LocalStorage isReportingEnabled]) {
        //has been changed in settings probably
        [self changeReporting:[LocalStorage isReportingEnabled]];
    }
    
    [self positionMapIfOwnLocationIsNotYetKnown];
    
    [self.avatarsAroundMap recreateButtons];
}

-(void)positionMapIfOwnLocationIsNotYetKnown
{
    NSDictionary* dash = [LocalStorage getDashboard];
    if (!dash || ![dash objectForKey:@"location"] || ![dash[@"location"] objectForKey:@"time"])
    {
        CLLocationCoordinate2D coord;
        coord.latitude = 60.173594;
        coord.longitude = 24.942154;
        MKCoordinateSpan span = MKCoordinateSpanMake(DEGREES_IN_METER*1000, DEGREES_IN_METER*1000);
        MKCoordinateRegion region = {coord, span};
        [self.map setRegion:region];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)unwindToMapWhenPersonAvatarTappedInPeopleView:(UIStoryboardSegue *)unwindSegue
{
    PeopleViewController* peopleViewController = unwindSegue.sourceViewController;
    [self selectUserAndCenterMap:peopleViewController.userIDToCenterMap];
}


- (void)tutorialRequestToAddFriends
{
    if (self.grayOutView.hidden) {
        [self performSegueWithIdentifier:@"AddUserSegue" sender:self];
    }
}

- (IBAction)onAdd:(id)sender
{
    [self showOrHideAddSomethingButtonsWithAnimation:self.grayOutView.hidden];
    
//    if (self.grayOutView.hidden) {
  //      [self performSegueWithIdentifier:@"AddUserSegue" sender:self];
   // }
}

- (IBAction)onSettings:(id)sender
{
    if (self.grayOutView.hidden) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    }
}

- (IBAction)onGreyedOutViewTopButtonTap:(id)sender
{
    [self animateGreyOutView:NO];
    if (self.greyedOutViewMode == kGreyOutViewModeAddSomething) {
        [self performSegueWithIdentifier:@"AddUserSegue" sender:self];
    } else {
        [self changeReporting:YES];
    }
}

- (IBAction)onGreyedOutViewBottomButtonTap:(id)sender
{
    [self animateGreyOutView:NO];

    if (self.greyedOutViewMode == kGreyOutViewModeAddSomething) {
        [self onAddPlaceInTheUserPosition];
    } else {
        [self changeReporting:NO];
    }
}

-(void)onGreyAreaTap
{
    [self animateGreyOutView:NO];
}

-(void)handleLongPressOnMap:(UILongPressGestureRecognizer*)r {
    if (r.state == UIGestureRecognizerStateBegan) {
        CGPoint pos = [r locationInView:self.map];
        CLLocationCoordinate2D coord = [self.map convertPoint:pos toCoordinateFromView:self.map];
    
        [self onAddPlaceInPoint:coord];
    }
}

-(void)changeReporting:(BOOL)turnedOn
{
    if (self.reportingOn == turnedOn) {
        return;
    }
    
    self.reportingOn = turnedOn;
    [LocalStorage setReportingEnabled:self.reportingOn];
    [self.serverApi changeVisibility:self.reportingOn];
    
    [self setStatusBarButtons];
    
    if (self.reportingOn) {
        [[StandaloneGPSReporter getInstance] quicklyQueryLocationAndSendToServer];
    } else {
        [[StandaloneGPSReporter getInstance] stopLocationUpdates];
    }
    //self.map.showsUserLocation = [LocalStorage isReportingEnabled];
}


-(void)animateGreyOutView:(BOOL)show {
    if (show) {
        self.grayOutView.hidden = NO;
        self.visibilityButtons.hidden = NO;
        
        self.visibilityButtons.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.1, 0.1), CGAffineTransformMakeTranslation(140, -240));
        self.visibilityButtons.alpha = 0;
        self.grayOutView.alpha = 0;
        [UIView animateWithDuration:0.5 animations:^{
            self.visibilityButtons.transform = CGAffineTransformIdentity;
            self.visibilityButtons.alpha = 1;
            self.grayOutView.alpha = 0.6;
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5 animations:^{
            //self.visibilityButtons.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.1, 0.1), CGAffineTransformMakeTranslation(140, -240));;
            self.visibilityButtons.alpha = 0;
            self.grayOutView.alpha = 0;
        } completion:^(BOOL finished) {
            self.grayOutView.hidden = YES;
            self.visibilityButtons.hidden = YES;
        }];
    }
}

-(void)showOrHideVisibilityButtonsWithAnimation:(BOOL)show
{
    // return to map mode always when showing gray out view (because it does not work in places view)
    if (show && self.bottomToolbar.selectedItem != kUIBottomToolbarSelectedItemMap) {
        self.bottomToolbar.selectedItem = kUIBottomToolbarSelectedItemMap;
    }
    
    if (show) {
        self.greyedOutViewSelectionTopImage.image = [UIImage imageNamed:@"visibility_on"];
        self.greyedOutViewSelectionBottomImage.image = [UIImage imageNamed:@"visibility_off"];
    }
    self.greyedOutViewMode = kGreyOutViewModeChangeVisibility;
    
    [self.greyedOutViewSelectionTopButton setTitle:_LOCALIZE(@"You are visible") forState:UIControlStateNormal];
    [self.greyedOutViewSelectionBottomButton setTitle:_LOCALIZE(@"You are invisible") forState:UIControlStateNormal];
    [self animateGreyOutView:show];
}


-(void)showOrHideAddSomethingButtonsWithAnimation:(BOOL)show
{
    // return to map mode always when showing gray out view (because it does not work in places view)
    if (show && self.bottomToolbar.selectedItem != kUIBottomToolbarSelectedItemMap) {
        self.bottomToolbar.selectedItem = kUIBottomToolbarSelectedItemMap;
    }
    
    if (show) {
        self.greyedOutViewSelectionTopImage.image = [UIImage imageNamed:@"addpeople"];
        self.greyedOutViewSelectionBottomImage.image = [UIImage imageNamed:@"addplace"];
    }
    
    self.greyedOutViewMode = kGreyOutViewModeAddSomething;
    [self.greyedOutViewSelectionTopButton setTitle:_LOCALIZE(@"Add people") forState:UIControlStateNormal];
    [self.greyedOutViewSelectionBottomButton setTitle:_LOCALIZE(@"Add place") forState:UIControlStateNormal];
    [self animateGreyOutView:show];
}

- (IBAction)onReporting:(id)sender
{
    [self showOrHideVisibilityButtonsWithAnimation:self.grayOutView.hidden];
}

-(void)loadCachedData
{
    self.reportingOn = [LocalStorage isReportingEnabled];
}


-(void)setStatusBarButtons
{
    UIBarButtonItem *buttonAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd:)];
    UIBarButtonItem *buttonReporting = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:(self.reportingOn?@"visibility_on":@"visibility_off")] style:UIBarButtonItemStylePlain target:self action:@selector(onReporting:)];
    [[self navigationBar] setRightBarButtonItems:@[buttonReporting, buttonAdd]];

    UIBarButtonItem *buttonSettings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStylePlain target:self action:@selector(onSettings:)];
    [[self navigationBar] setLeftBarButtonItems:@[buttonSettings]];
}


    
- (void)setInitialMapRegion:(NSArray*)users
{
    for (UserData *user in users) {
        if (user.userID == [LocalStorage getLoggedInUserId]) {
            CLLocationCoordinate2D coord = user.coord;
            MKCoordinateSpan span = MKCoordinateSpanMake(DEGREES_IN_METER*1000, DEGREES_IN_METER*1000);
            MKCoordinateRegion region = {coord, span};
            [self.map setRegion:region];
        }
    }

    [self selectUserAndCenterMap:[LocalStorage getLoggedInUserId]];
}

-(LocMapAnnotation*)getAnnotationForUser:(UserData*)user fromAnnotations:(NSArray*)annotations
{
    for(NSObject* _ann in annotations) {
        if ([_ann isKindOfClass:[LocMapAnnotation class]]) {
            LocMapAnnotation* ann = (LocMapAnnotation*)_ann;
            if ([ann.userID isEqualToString:user.userID]) {
                return ann;
            }
        }
    }
    return nil;
}

-(UserData*)getUserForAnnotation:(LocMapAnnotation*)annotation fromUsers:(NSArray*)users
{
    for(UserData* user in users)
    {
        if ([user.userID isEqualToString:annotation.userID]) {
            return user;
        }
    }
    return nil;
}

-(void)showNoFriendsTutorialIfNeeded
{
    if ([self iAmTopViewController]) {
        if (!self.hasShownNoFriendsTutorialAlready && [LocalStorage getDashboard]) {
            self.hasShownNoFriendsTutorialAlready = YES;
            BOOL someoneCanSeeMe = [[[Users alloc] init] havePeopleWhoCanSeeMe];
            if (!someoneCanSeeMe) {
                [Tutorial triggerNoFriendsYet:self];
            }
        }
    }
    
}

-(void)buildMapViewFromDashboard
{
    // we need to move existing annotations, remove which disappeared and add which appeared
    // if we just recreate annotations - popup will be closed
//    [self.map removeAnnotations:self.map.annotations];
    [self.map removeOverlays:self.map.overlays];// just rebuild overlays
    
    if (!self.hasShownNoFriendsTutorialAlready) {
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(showNoFriendsTutorialIfNeeded) userInfo:nil repeats:NO];
    }
    
    NSArray* annotations = self.map.annotations;
    Users* u = [[Users alloc] init];
    NSArray* users = [u getUsersIncludingMyself:YES excludingOnesIDontWantToSee:YES];
    
    // remove disappeared
    for(NSObject* _ann in annotations) {
        if ([_ann isKindOfClass:[LocMapAnnotation class]]) {
            LocMapAnnotation* ann = (LocMapAnnotation*)_ann;
            if ([self getUserForAnnotation:ann fromUsers:users] == nil)
            {
                [self.map removeAnnotation:ann];
            }
        }
    }
    annotations = self.map.annotations;
    
    // add new
    for(UserData* user in users) {
        if ([self getAnnotationForUser:user fromAnnotations:annotations] == nil)
        {
            [self.map addAnnotation:[[LocMapAnnotation alloc] initWithUserData:user]];
            [self.map addOverlay:[MKCircle circleWithCenterCoordinate:user.coord radius:user.accuracy]];
        }
    }


    // update rest
    for(UserData* user in users) {
        LocMapAnnotation* ann = [self getAnnotationForUser:user fromAnnotations:annotations];

        [UIView animateWithDuration:1 animations:^{
            ann.userLastReportTime = user.userLastReportDate;
            ann.userIsReporting = user.isReporting;
            CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate:user.coord altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
            CLLocation *oldLocation = [[CLLocation alloc] initWithCoordinate:ann.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
            CLLocationDistance meters = [newLocation distanceFromLocation:oldLocation];
            
            ann.coordinate = user.coord;
            ann.userCoordinateAccuracy = user.accuracy;
            [ann.annotationView updateAnnotationInfo];
            
            // only center map if user moved more than 1 meter
            if (meters > 1) {
                if ([self.centeredUserID isEqualToString:user.userID]) {
                    [self centerMapOnUserCoordinate:user.coord];
                }
            }
        }];
        
        MKCircle* c = [MKCircle circleWithCenterCoordinate:user.coord radius:user.accuracy];
        //MapPlaceCircle* c = [MapPlaceCircle circleWithPlaceID:@"some" name:@"Place name" centerCoordinate:user.coord radius:user.accuracy];
        [self.map addOverlay:c];
    }
    
    // add places
    NSDictionary* places = [LocalStorage getPlaces];
    NSArray *placeIDS =  [places allKeys];
    for (int i=0; i < placeIDS.count; i++) {
        NSString* placeID = placeIDS[i];
        NSDictionary* place = places[placeID];
        NSString* name = place[@"name"];
        double lat = [place[@"lat"] doubleValue];
        double lon = [place[@"lon"] doubleValue];
        double rad = [place[@"rad"] doubleValue];
        MapPlaceCircle* c = [MapPlaceCircle circleWithPlaceID:placeID name:name centerCoordinate:CLLocationCoordinate2DMake(lat, lon) radius:rad];
        [self.map addOverlay:c];
    }
    
    
    if (!self.mapViewWasSetToShowEveryoneAlready && [users count] > 0) {
        [self setInitialMapRegion:users];
        self.mapViewWasSetToShowEveryoneAlready = YES;
    }
    
    [self.avatarsAroundMap recreateButtons];
    [self.nonOverlappingAnnotations makeSureAnnotationsAreNotOverlapping];
}


-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [self.nonOverlappingAnnotations makeCorrectZOrderForViews:views];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MapRegionWillChange" object:self];

}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MapRegionDidChange" object:self];
    [self.nonOverlappingAnnotations makeSureAnnotationsAreNotOverlapping];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MapPlaceCircle class]]) {
        MapPlaceCircleOverlay *circleView = [[MapPlaceCircleOverlay alloc] initWithMapPlaceCircle:(MapPlaceCircle *)overlay];
        circleView.fillColor = [UIColor colorWithRed:0xe2/255.0 green:0x2a/255.0 blue:0x2f/255.0 alpha:0.35];//e22a2f 35%
        return circleView;
    } else if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        circleView.fillColor = [UIColor colorWithRed:0.1 green:0.1 blue:1.0 alpha:0.2];
        return circleView;
    } else {
        return nil;
    }

}


- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) return nil;
    if (![annotation isKindOfClass:[LocMapAnnotation class]]) {
        NSLog(@"Unknown annotation class!");
        return nil;
    }
    
    //LocMapAnnotation* lmAnnotation = (LocMapAnnotation*)annotation;
    
    LocMapAnnotationView *pin = (LocMapAnnotationView *) [self.map dequeueReusableAnnotationViewWithIdentifier: @"lokkiPin"];
    if (pin == nil) {
        pin = [[LocMapAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"lokkiPin"];
    } else {
        pin.annotation = annotation;
        [pin updateAnnotationInfo];
    }

    
    return pin;
}

-(void)selectUserAndCenterMap:(NSString*)userID
{
    NSArray* annotations = self.map.annotations;
    for(LocMapAnnotation* ann in annotations) {
        if ([ann isKindOfClass:[LocMapAnnotation class]]) {
        
            if ([ann.userID isEqualToString:userID])
            {
                if (![self.centeredUserID isEqualToString:userID]) {
                    [self.map selectAnnotation:ann animated:YES];
                }
                [UIView animateWithDuration:1 animations:^{
                    [self centerMapOnUserCoordinate:ann.coordinate];
                }];
                self.centeredUserID = userID;
            } else {
                if (ann.annotationView.selected) {
                    [self.map deselectAnnotation:ann animated:YES];
                }
            }
        }
    }
   
}

 // center a bit below user so that custom callout will fit into screen
-(void)centerMapOnUserCoordinate:(CLLocationCoordinate2D)coord
{
    MKCoordinateSpan span = MKCoordinateSpanMake(DEGREES_IN_METER*1000, DEGREES_IN_METER*1000);
    MKCoordinateRegion region = {coord, span};
    [self.map setRegion:region];
    

    CGPoint p = [self.map convertCoordinate:coord toPointToView:self.map];
    p.y = p.y - 100;
    CLLocationCoordinate2D p2 = [self.map convertPoint:p toCoordinateFromView:self.map];
    self.map.centerCoordinate = p2;//coord;// center
    
    
}
    
    
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[LocMapAnnotationView class]]) {
        LocMapAnnotationView *annotationView = (LocMapAnnotationView *)view;
        LocMapAnnotation* ann = annotationView.annotation;
        self.centeredUserID = ann.userID;
        [UIView animateWithDuration:1 animations:^{
            [self centerMapOnUserCoordinate:ann.coordinate];
        }];
        [self.nonOverlappingAnnotations increaseOverlapDisplacementOnAnnotationSelected];
        //        [self.nonOverlappingAnnotations makeSureAnnotationsAreNotOverlapping];
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[LocMapAnnotationView class]]) {
        LocMapAnnotationView *annotationView = (LocMapAnnotationView *)view;
        LocMapAnnotation* ann = annotationView.annotation;
        if ([self.centeredUserID isEqualToString:ann.userID]) {
            self.centeredUserID = nil;
        };

        [self.nonOverlappingAnnotations decreaseOverlapDisplacementOnAnnotationDeselected];
//        [self.nonOverlappingAnnotations makeSureAnnotationsAreNotOverlapping];
        
        //[((LocMapAnnotationView *)view) setShowCustomCallout:NO animated:YES];
    }
}


-(BOOL)iAmTopViewController
{
    return self == [self topViewController];
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}
    
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

// server sent us new dashboard - show it
-(void)onNewDashboardReceivedFromServer:(NSDictionary*)response
{
    if ([response valueForKey:@"location"]) {
        [LocalStorage setDashboard:response];
        
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;//we should not update dashboard in background
        }
        
        [self cacheNewUsers:response];
        
        [self buildMapViewFromDashboard];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DashboardUpdated" object:self];
    }
}

// failed to get dashboard
-(void)onNewDashboardFailedToGetFromServer
{
}



-(void)cacheNewUsers:(NSDictionary*)dashboard
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        Users* u = [[Users alloc] init];
        NSArray* users = [u getUsersIncludingMyself:YES excludingOnesIDontWantToSee:NO];
        Contacts* contacts = [[Contacts alloc] init];
        [contacts loadContacts];

        dispatch_async(dispatch_get_main_queue(), ^{
            for(UserData* user in users) {
                if ([self.alreadyCachedUserIDS containsObject:user.userID]) {
                    continue;
                }
                
                self.alreadyCachedUserIDS = [self.alreadyCachedUserIDS arrayByAddingObject:user.userID];
                
                //if (![LocalStorage getUserNameByUserID:user.userID] || ![LocalStorage getAvatarDataByUserID:user.userID]) {
                NSDictionary* dict = [contacts getContactDataToCacheForEmail:user.userEmail];
                if (dict) {
                    [LocalStorage setAccountDataFromDict:dict];
                    
                    // update avatar and name
                    NSDictionary* userData = dict[user.userEmail];
                    LocMapAnnotation* ann = [self getAnnotationForUser:user fromAnnotations:self.map.annotations];
                    if (ann) {
                        ann.userName = userData[@"name"];
                        ann.userAvatarImageData = userData[@"imgData"];
                        [self.avatarsAroundMap reloadAvatarForUserID:user.userID];
                        if (ann.annotationView) {
                            [ann.annotationView updateAnnotationInfo];
                        }
                    }
                }
                //}
            }
        });
    });
    
}


-(CLLocationCoordinate2D)getUserLocation {
    Users* usersObj = [[Users alloc] init];
    NSArray* users = [usersObj getUsersIncludingMyself:YES excludingOnesIDontWantToSee:NO];
    for (UserData *user in users) {
        if (user.userID == [LocalStorage getLoggedInUserId]) {
            CLLocationCoordinate2D coord = user.coord;
            return coord;
        }
    }
    return CLLocationCoordinate2DMake(0, 0);
    
}


-(void)onAddPlaceInTheUserPosition {
    NSLog(@"onAddPlaceInTheUserPosition");
    CLLocationCoordinate2D coord = [self getUserLocation];
    if (fabsf(coord.latitude) < 0.001 && fabsf(coord.longitude) < 0.001) {
        NSLog(@"Place cannot be created because coord is unknown");
        return;
    }
    [self onAddPlaceInPoint:coord];
}


-(void)onAddPlaceInPoint:(CLLocationCoordinate2D)coord {
    NSLog(@"onAddPlaceInPoint: %f,%f", coord.latitude, coord.longitude);
    self.creatingNewPlaceInThisCoordinate = coord;
    
    // ask for name
    UIAlertView *alert = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Add a place")
                                                message:_LOCALIZE(@"Enter the name for the place")
                                                delegate:self
                                                cancelButtonTitle:_LOCALIZE(@"Cancel")
                                                otherButtonTitles:_LOCALIZE(@"Done"), nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = ADD_A_PLACE_ALERT_VIEW;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == ADD_A_PLACE_ALERT_VIEW) {
        if (buttonIndex == 1) {
            //create place, open places view
            NSString* placeName = [alertView textFieldAtIndex:0].text;
            NSLog(@"Create place with name: %@ in %f,%f", placeName, self.creatingNewPlaceInThisCoordinate.latitude, self.creatingNewPlaceInThisCoordinate.longitude);
            if ([placeName isEqualToString:@""]) {
                return;// place name must not be empty
            }
            
            [self.serverApi createPlaceWithName:placeName image:@"" lat:self.creatingNewPlaceInThisCoordinate.latitude lon:self.creatingNewPlaceInThisCoordinate.longitude radius:100];
            
        }
    }
}



- (void)onAvatarAroundMapClickForUserID:(NSString*)userID
{
    // crash
//    int* i = 0;
//    *i = 0;
    
    [self selectUserAndCenterMap:userID];
}

-(void)onSignupWrongAuthCode
{
    // clear map
    [self.map removeOverlays:self.map.overlays];
    [self.map removeAnnotations:self.map.annotations];
    
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:@""
                                                    message:_LOCALIZE(@"YourAccountRequiresSignupForSecurityReasons")
                                                    delegate:nil
                                                    cancelButtonTitle:_LOCALIZE(@"OK")
                                                    otherButtonTitles:nil, nil];
    [alertView show];
    
    [LocalStorage clearLoggedInUser];    
    [self performSegueWithIdentifier:@"SignupSegue" sender:self.navigationController];
}


-(void)showCreatePlaceError:(int)errorCode {
    BOOL placesLimitError = NO;
    if (errorCode == SERVER_ERROR_PLACES_LIMIT) {
        placesLimitError = YES;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Error")
                                                          message:_LOCALIZE(placesLimitError?@"You cannot have more places in free version":@"Failed to create place")
                                                         delegate:nil
                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                otherButtonTitles:nil, nil];
    [alertView show];
}



- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
#ifdef DEBUG
    NSLog(@"Operation %d finished with status: %d and response %@", (int)type, (int)success, response);
#endif
    int errorCode = 0;
    if (success == NO) {
        if (response && [response objectForKey:@"serverErrorCode"]) {
            NSNumber* err = response[@"serverErrorCode"];
            errorCode = (int)[err integerValue];
        }
    }
    
    switch(type) {
        case ServerOperationDashboard:
            if (success) {
                [self onNewDashboardReceivedFromServer:response];
            } else {
                [self onNewDashboardFailedToGetFromServer];
            }
        break;
        case ServerOperationChangeVisibility:
        break;
        case ServerOperationAddPlace:
            if (success) {
                [self showPlacesView];
            } else {
                [self showCreatePlaceError:errorCode];
            }
        break;
        default:
            NSLog(@"Unknown server operation finished!");
        break;
    }
    
    if (errorCode == SERVER_ERROR_SIGNUP_WRONG_AUTH_CODE) {
        [self onSignupWrongAuthCode];
    }
}


@end
