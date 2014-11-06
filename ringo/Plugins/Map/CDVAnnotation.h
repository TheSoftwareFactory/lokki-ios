
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CDVAnnotation : NSObject <MKAnnotation> {
@private
    CLLocationCoordinate2D _coordinate;
    NSString *_title;
	NSInteger _index;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) CLLocationDistance diameter;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate index:(NSInteger)index title:(NSString*)title diameter:(CLLocationDistance)diameter  editable:(BOOL)editable;

@end

