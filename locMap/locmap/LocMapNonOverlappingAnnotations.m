//
//  LocMapNonOverlappingAnnotations.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/16/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapNonOverlappingAnnotations.h"
#import "FSConstants.h"
#import "LocMapAnnotation.h"
#import "LocMapAnnotationView.h"

@interface LocMapNonOverlappingAnnotations()
    @property (strong) MKMapView* map;

    @property float currentAnnotationOverlappingDisplacement;//PIN_WIDTH or PIN_WIDTH/N - how much do we displace overlapping annotations

@end

@implementation LocMapNonOverlappingAnnotations

-(id)initForMap:(MKMapView*)map
{
    self = [super init];
    self.map = map;
    self.currentAnnotationOverlappingDisplacement = PIN_WIDTH/8;
    
    return self;
}

-(void)decreaseOverlapDisplacementOnAnnotationDeselected {
    self.currentAnnotationOverlappingDisplacement = PIN_WIDTH/8;
    [self makeSureAnnotationsAreNotOverlapping];
}


-(void)increaseOverlapDisplacementOnAnnotationSelected {
    self.currentAnnotationOverlappingDisplacement = PIN_WIDTH*4/5;
    [self makeSureAnnotationsAreNotOverlapping];    
}


-(NSComparisonResult)comparePosOfAnnotationView:(LocMapAnnotationView*)v1 toView:(LocMapAnnotationView*)v2 {
    if ([v1 calloutVisible]) {
        if (![v2 calloutVisible]) {
            return NSOrderedAscending;
        }
    }
    if ([v2 calloutVisible]) {
        if (![v1 calloutVisible]) {
            return NSOrderedDescending;
        }
    }
    
    float x1 = v1.frame.origin.x;
    float x2 = v2.frame.origin.x;
    float y1 = v1.frame.origin.y;
    float y2 = v2.frame.origin.y;
    
    // trick: if dy is more than 10 then sort by y but if they are on the same horizontal line - by X
    if (y1 - y2 > 10 || y2 - y1 > 10) {
        return (y1 > y2)?NSOrderedAscending:NSOrderedDescending;
    }
    
    if (x1 > x2) {
        return NSOrderedDescending;
    } else if (x1 == x2) {
        return (v1.frame.origin.y < v2.frame.origin.y)?NSOrderedDescending:NSOrderedAscending;
    }
    return NSOrderedAscending;
    
}

-(void)makeSureAnnotationsAreNotOverlapping
{
    NSArray* annotations = self.map.annotations;
    NSArray* sortedAnnotations = [[NSArray alloc] init];
    
    for(NSObject* _ann in annotations) {
        if ([_ann isKindOfClass:[LocMapAnnotation class]]) {
            LocMapAnnotation* ann = (LocMapAnnotation*)_ann;
            if (ann.annotationView) {
                sortedAnnotations = [sortedAnnotations arrayByAddingObject:ann.annotationView];
            }
        }
    }
    
    sortedAnnotations = [sortedAnnotations sortedArrayUsingComparator:^NSComparisonResult(LocMapAnnotationView* obj1, LocMapAnnotationView* obj2) {
        return [self comparePosOfAnnotationView:obj1 toView:obj2];
        //return [obj1.userID compare:obj2.userID];
    }];
    NSArray* prevAnn = [[NSArray alloc] init];
    for(NSObject* ann in sortedAnnotations) {
        [self moveAnnotation:(LocMapAnnotationView*)ann ifOverlapsWith:prevAnn];
        prevAnn = [prevAnn arrayByAddingObject:ann];
    }
    
    [self makeCorrectZOrderForViews:sortedAnnotations];
}


-(float)distanceBetweenPoint:(CGPoint)p1 andPoint:(CGPoint)p2
{
    return sqrt((p1.x - p2.x)*(p1.x - p2.x) + (p1.y - p2.y)*(p1.y - p2.y));
}

-(void)moveAnnotation:(LocMapAnnotationView*)annView ifOverlapsWith:(NSArray*)annotations
{
    if (annView.hidden) {
        return;
    }
    
    [annView setHorizontalDisplacement:0];//clear if not moved
    for(LocMapAnnotationView* annNext in annotations) {
        if (annView == annNext || annNext.hidden) {
            continue;
        }
        CGRect annFrame = annView.frame;
        
        CGRect newAnnFrame = annNext.frame;
        
        float minDistanceBetweenAvatars = self.currentAnnotationOverlappingDisplacement;
        // we assume that half distance between avatars is enough to stay in place. it allows to avoid artifacts when people move 2 distances away
        if (CGRectIntersectsRect(annFrame, newAnnFrame) && [self distanceBetweenPoint:annFrame.origin andPoint:newAnnFrame.origin] < minDistanceBetweenAvatars/2) {
            
            // so, we need to move avatar if avatars intersect and centers are near
            // we just add +-minDistanceBetweenAvatars points until if it fine
            int i = 0;
            
            for(id it in @[@1,@2,@3,@4,@5,@6]) { // do it 6 times max for 6 max avatars in the same place
                ++i;
                CGRect f1 = CGRectMake(annFrame.origin.x + i*minDistanceBetweenAvatars, annFrame.origin.y, annFrame.size.width, annFrame.size.height);
                CGRect f2 = f1;//CGRectMake(annFrame.origin.x - i*minDistanceBetweenAvatars, annFrame.origin.y, annFrame.size.width, annFrame.size.height);
                BOOL f1Intersects = NO;
                BOOL f2Intersects = NO;
                
                for(LocMapAnnotationView* a in annotations) {
                    if (a == annNext || a == annView || a.hidden) {
                        continue;
                    }
                    CGRect aFrame = a.frame;
                    //aFrame.origin.x += [a.annotationView getHorizontalDisplacement];
                    
                    if (CGRectIntersectsRect(f1, aFrame) && [self distanceBetweenPoint:f1.origin andPoint:aFrame.origin] < minDistanceBetweenAvatars/2) {
                        f1Intersects = YES;
                    }
                    if (CGRectIntersectsRect(f2, aFrame) && [self distanceBetweenPoint:f2.origin andPoint:aFrame.origin] < minDistanceBetweenAvatars/2) {
                        f2Intersects = YES;
                    }
                }
                
                if (!f1Intersects) {
                    [annView setHorizontalDisplacement:i*minDistanceBetweenAvatars];
                    return;
                }
                if (!f2Intersects) {
                    [annView setHorizontalDisplacement:-i*minDistanceBetweenAvatars];
                    return;
                }
            }
        }
    }
    
    //    int notFound = 1;
}



-(void)makeCorrectZOrderForViews:(NSArray*)views
{
    NSArray* sortedAnnotations = [[NSArray alloc] init];
    for(MKAnnotationView* v in views) {
        if ([v isKindOfClass:[LocMapAnnotationView class]]) {
            LocMapAnnotationView* av = (LocMapAnnotationView*)v;
            sortedAnnotations = [sortedAnnotations arrayByAddingObject:av];
        }
    }
    
    sortedAnnotations = [sortedAnnotations sortedArrayUsingComparator:^NSComparisonResult(LocMapAnnotationView* obj1, LocMapAnnotationView* obj2) {
        return [self comparePosOfAnnotationView:obj1 toView:obj2];
    }];
    
  //  int pos = 1;
    for(MKAnnotationView* v in sortedAnnotations) {
        [[v superview] sendSubviewToBack:v];
//        v.layer.zPosition = pos++;
    }
    
}


@end
