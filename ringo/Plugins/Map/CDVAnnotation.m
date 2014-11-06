#import "CDVAnnotation.h"

@implementation CDVAnnotation

@synthesize title = _title;
@synthesize index = _index;
@synthesize	coordinate = _coordinate;
@synthesize	editable = _editable;
@synthesize diameter = _diameter;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate index:(NSInteger)index title:(NSString*)title  diameter:(CLLocationDistance)diameter editable:(BOOL)editable {
    if ((self = [super init])) {
        _coordinate = coordinate;
        _title = [title retain];
		_index = index;
        _diameter = diameter;
        _editable = editable;
    }
    return self;
}

- (NSString *)title {
    return _title;
}

-(void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinate = coordinate;
}


- (void)dealloc {
    [_title release], _title = nil;
    [super dealloc];
}

@end
