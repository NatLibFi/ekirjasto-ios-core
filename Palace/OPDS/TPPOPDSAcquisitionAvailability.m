#import "NSDate+NYPLDateAdditions.h"
#import "TPPNull.h"
#import "TPPXML.h"
#import "TPPOPDSAcquisitionAvailability.h"

// Constants for dictionary keys and values

static NSString *const caseKey = @"case";
static NSString *const copiesAvailableKey = @"copiesAvailable";
static NSString *const copiesTotalKey = @"copiesTotal";
static NSString *const holdsPositionKey = @"holdsPosition";
static NSString *const holdsTotalKey = @"holdsTotal";
static NSString *const reservedSinceKey = @"reservedSince";
static NSString *const reservedUntilKey = @"reservedUntil";
static NSString *const sinceKey = @"since";
static NSString *const untilKey = @"until";

static NSString *const limitedCase = @"limited";
static NSString *const readyCase = @"ready";
static NSString *const reservedCase = @"reserved";
static NSString *const unavailableCase = @"unavailable";
static NSString *const unlimitedCase = @"unlimited";

static NSString *const availabilityName = @"availability";
static NSString *const copiesName = @"copies";
static NSString *const holdsName = @"holds";

static NSString *const availableAttribute = @"available";
static NSString *const positionAttribute = @"position";
static NSString *const sinceAttribute = @"since";
static NSString *const statusAttribute = @"status";
static NSString *const totalAttribute = @"total";
static NSString *const untilAttribute = @"until";

TPPOPDSAcquisitionAvailabilityCopies const TPPOPDSAcquisitionAvailabilityCopiesUnknown = NSUIntegerMax;

#pragma mark - Unavailable interface
@interface TPPOPDSAcquisitionAvailabilityUnavailable ()

// Example of book entry XML containing availability status 'unavailable'
// <opds:availability status="unavailable"/>
// <opds:holds total="0"/>
// <opds:copies total="1" available="0"/>

@property (nonatomic) NSUInteger holdsTotal;
@property (nonatomic) NSUInteger copiesAvailable;
@property (nonatomic) NSUInteger copiesTotal;

@end

#pragma mark - Limited interface
@interface TPPOPDSAcquisitionAvailabilityLimited ()

@property (nonatomic) TPPOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic) TPPOPDSAcquisitionAvailabilityCopies copiesTotal;
@property (nonatomic, nullable) NSDate *since;
@property (nonatomic, nullable) NSDate *until;


@end

#pragma mark - Unlimited interface
@interface TPPOPDSAcquisitionAvailabilityUnlimited ()

@end

#pragma mark - Reserved interface
@interface TPPOPDSAcquisitionAvailabilityReserved ()

// Example of book entry XML containing availability status 'reserved'
// <opds:availability status="reserved" since="2026-01-13T12:24:46+00:00" until="2027-01-13T12:24:46+00:00"/>
// <opds:holds total="1" position="1"/>
// <opds:copies total="1" available="0"/>

@property (nonatomic) NSUInteger holdsPosition;
@property (nonatomic) TPPOPDSAcquisitionAvailabilityCopies holdsTotal;
@property (nonatomic) TPPOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic) TPPOPDSAcquisitionAvailabilityCopies copiesTotal;
@property (nonatomic, nullable) NSDate *since;
@property (nonatomic, nullable) NSDate *until;

@end


#pragma mark - Ready interface
@interface TPPOPDSAcquisitionAvailabilityReady ()

@property (nonatomic, nullable) NSDate *since;
@property (nonatomic, nullable) NSDate *until;

@end


#pragma mark - Create availability objects and dictionaries
// These are probably the book availability
// related functions you are looking for

// Function that parses XML data given as parameter
// and returns TPPOPDSAcquisitionAvailability instance
id<TPPOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(TPPXML *const _Nonnull linkXML)
{
  // initialize variables to predefined type TPPOPDSAcquisitionAvailabilityCopiesUnknown
  TPPOPDSAcquisitionAvailabilityCopies copiesTotal = TPPOPDSAcquisitionAvailabilityCopiesUnknown;
  TPPOPDSAcquisitionAvailabilityCopies copiesAvailable = TPPOPDSAcquisitionAvailabilityCopiesUnknown;
  TPPOPDSAcquisitionAvailabilityCopies holdsTotal = TPPOPDSAcquisitionAvailabilityCopiesUnknown;
  
  // initialize variables to default values
  NSUInteger holdsPosition = 0;
  NSDate *since = nil; //optional
  NSDate *until = nil; //optional

  // extract the availability status from the XML,
  // for example book entry's XML element <opds:availability status="unavailable"/>
  // contains the status 'unavailable' as String
  NSString *const statusString = [linkXML firstChildWithName:availabilityName].attributes[statusAttribute];
  
  // extract other availability details from the XML
  // create a String for every detail
  NSString *const copiesTotalString = [linkXML firstChildWithName:copiesName].attributes[totalAttribute];
  NSString *const copiesAvailableString = [linkXML firstChildWithName:copiesName].attributes[availableAttribute];
  NSString *const holdsPositionString = [linkXML firstChildWithName:holdsName].attributes[positionAttribute];
  NSString *const holdsTotalString = [linkXML firstChildWithName:holdsName].attributes[totalAttribute];
  NSString *const sinceString = [linkXML firstChildWithName:availabilityName].attributes[sinceAttribute];
  NSString *const untilString = [linkXML firstChildWithName:availabilityName].attributes[untilAttribute];

  // parse total copies from the string
  if (copiesTotalString) {
    // make sure the value is not negative
    copiesTotal = MAX(0, [copiesTotalString integerValue]);
  }
  
  // parse available copies from the string
  if (copiesAvailableString) {
    // make sure the value is not negative using MAX
    copiesAvailable = MAX(0, [copiesAvailableString integerValue]);
  }
  
  // parse hold position from the string
  if (holdsPositionString) {
    // make sure the value is not negative using MAX
    holdsPosition = MAX(0, [holdsPositionString integerValue]);
  }

  // parse holds total from the string
  if (holdsTotalString) {
    // make sure the value is not negative using MAX
    holdsTotal = MAX(0, [holdsTotalString integerValue]);
  }

  // parse since from the string
  if (sinceString) {
    // convert string into an NSDate object using RFC3339 format
    since = [NSDate dateWithRFC3339String:sinceString];
  }
  
  // parse until from the string
  if (untilString) {
    // convert string into an NSDate object using RFC3339 format
    until = [NSDate dateWithRFC3339String:untilString];
  }

  
  // next, determine the availability type based on the extracted statusString
  // and then return the correct instance of TPPOPDSAcquisitionAvailability

  // availability status is 'unavailable'
  // (this book cannot be borrowed at the moment)
  if ([statusString isEqual:@"unavailable"]) {
    
    // Example of book entry XML containing availability status 'unavailable'
    // <opds:availability status="unavailable"/>
    // <opds:holds total="3"/>
    // <opds:copies total="1" available="0"/>
    
    // create and return an instance of TPPOPDSAcquisitionAvailabilityUnavailable
    // with the number of total and hold copies
    return [[TPPOPDSAcquisitionAvailabilityUnavailable alloc]
            initWithHoldsTotal:holdsTotal
            copiesAvailable:copiesAvailable
            copiesTotal:copiesTotal];
  }
  
  // availability status is 'available'
  // (this book can be borrowed)
  if ([statusString isEqual:@"available"]) {
    
    // Examples of book entry XML containing availability status 'available'
    //
    // <opds:availability status="available" since="2026-01-13T12:17:41+00:00" until="2026-01-16T12:17:41+00:00"/>
    // <opds:holds total="0"/>
    // <opds:copies total="6" available="5"/>
    //
    // <opds:availability status="available"/>
    // <opds:holds total="0"/>
    // <opds:copies total="27" available="27"/>
    
    if (copiesAvailable == TPPOPDSAcquisitionAvailabilityCopiesUnknown
        && copiesTotal == TPPOPDSAcquisitionAvailabilityCopiesUnknown) {
      // if both copiesAvailable and copiesTotal are unknown
      // the book availability is considered unlimited
      // create and return an instance of TPPOPDSAcquisitionAvailabilityUnlimited
      return [[TPPOPDSAcquisitionAvailabilityUnlimited alloc] init];
    }

    // create and return an instance of TPPOPDSAcquisitionAvailabilityLimited
    // with number of copies available, total number of copies
    // and the availaibility period
    return [[TPPOPDSAcquisitionAvailabilityLimited alloc]
            initWithCopiesAvailable:copiesAvailable
            copiesTotal:copiesTotal
            since:since
            until:until];
  }

  // availability status is 'reserved'
  // (this book is reserved for the user)
  if ([statusString isEqual:@"reserved"]) {
    
    // Example of book entry XML containing availability status 'reserved'
    // <opds:availability status="reserved" since="2026-01-13T12:24:46+00:00" until="2027-01-13T12:24:46+00:00"/>
    // <opds:holds total="1" position="1"/>
    // <opds:copies total="1" available="0"/>
    
    // create and return an instance of TPPOPDSAcquisitionAvailabilityReserved.
    // with user's position in the hold queue, total number of copiesa
    // and the reservation period
    return [[TPPOPDSAcquisitionAvailabilityReserved alloc]
            initWithHoldsPosition:holdsPosition
            holdsTotal:holdsTotal
            copiesAvailable:copiesAvailable
            copiesTotal:copiesTotal
            since:since
            until:until];
    
  }

  // availability status is 'ready'
  // (this book is reserved by the user and now ready to be borrowed)
  if ([statusString isEqualToString:@"ready"]) {
    
    // Example of book entry XML containing availability status 'ready'
    // <opds:availability status="ready" until="2026-01-16T23:59:59+00:00"/>
    // <opds:holds total="2"/>
    // <opds:copies total="1" available="0"/>
    
    // create and return an instance of TPPOPDSAcquisitionAvailabilityReady
    // with period of time, that the book is ready to be borrowed
    return [[TPPOPDSAcquisitionAvailabilityReady alloc]
            initWithSince:since
            until:until];
  }

  // all other statuses go here, we assume the book availibity is unlimited
  // create and return an instance of TPPOPDSAcquisitionAvailabilityUnlimited
  return [[TPPOPDSAcquisitionAvailabilityUnlimited alloc] init];
}


// Function that parses a dictionary to create an instance of TPPOPDSAcquisitionAvailability.
// Dictionary given as parameter contains the book's availability data (total copies, total number of held copies etc.)
// Function maps the data to a suitable TPPOPDSAcquisitionAvailability instance based on the "case" key.
// Returns an instance of TPPOPDSAcquisitionAvailability (or nil if the data is invalid).
id<TPPOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithDictionary(NSDictionary *_Nonnull dictionary)
{
  
  NSString *const caseString = dictionary[caseKey];
  if (!caseString) {
    return nil;
  }

  NSString *const sinceString = TPPNullToNil(dictionary[sinceKey]);
  NSDate *const since = sinceString ? [NSDate dateWithRFC3339String:sinceString] : nil;

  NSString *const untilString = TPPNullToNil(dictionary[untilKey]);
  NSDate *const until = untilString ? [NSDate dateWithRFC3339String:untilString] : nil;

  if ([caseString isEqual:unavailableCase]) {
    
    NSNumber *const holdsTotalNumber = dictionary[holdsTotalKey];
    if (![holdsTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }
    
    NSNumber *const copiesAvailableNumber = dictionary[copiesAvailableKey];
    if (![copiesAvailableNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    return [[TPPOPDSAcquisitionAvailabilityUnavailable alloc]
            initWithHoldsTotal:MAX(0, [holdsTotalNumber integerValue])
            copiesAvailable:MAX(0, [copiesAvailableNumber integerValue])
            copiesTotal:MAX(0, [copiesTotalNumber integerValue])];
    
  } else if ([caseString isEqual:limitedCase]) {
    NSNumber *const copiesAvailableNumber = dictionary[copiesAvailableKey];
    if (![copiesAvailableNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    return [[TPPOPDSAcquisitionAvailabilityLimited alloc]
            initWithCopiesAvailable:MAX(0, [copiesAvailableNumber integerValue])
            copiesTotal:MAX(0, [copiesTotalNumber integerValue])
            since:since
            until:until];
    
  } else if ([caseString isEqual:unlimitedCase]) {
    return [[TPPOPDSAcquisitionAvailabilityUnlimited alloc] init];
    
  } else if ([caseString isEqual:reservedCase]) {
    
    NSNumber *const holdsPositionNumber = dictionary[holdsPositionKey];
    if (![holdsPositionNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }
    
    NSNumber *const holdsTotalNumber = dictionary[holdsTotalKey];
    if (![holdsTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }
    
    NSNumber *const copiesAvailableNumber = dictionary[copiesAvailableKey];
    if (![copiesAvailableNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    return [[TPPOPDSAcquisitionAvailabilityReserved alloc]
            initWithHoldsPosition:MAX(0, [holdsPositionNumber integerValue])
            holdsTotal:MAX(0, [holdsTotalNumber integerValue])
            copiesAvailable:MAX(0, [copiesAvailableNumber integerValue])
            copiesTotal:MAX(0, [copiesTotalNumber integerValue])
            since:since
            until:until];
    
  } else if ([caseString isEqual:readyCase]) {
    return [[TPPOPDSAcquisitionAvailabilityReady alloc] initWithSince:since until:until];
    
  } else {
    return nil;
  }
  
}


// Function that creates a dictionary representation
// from the TPPOPDSAcquisitionAvailability instance given as parameter
// Returns a dictionary containing keys and values for availability types (unavailable, reserved etc.)
// and their details (copies available, hold position etc.)
NSDictionary *_Nonnull
NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation(id<TPPOPDSAcquisitionAvailability> const _Nonnull availability)
{
  __block NSDictionary *result;

  [availability
   matchUnavailable:^(TPPOPDSAcquisitionAvailabilityUnavailable *const _Nonnull unavailable) {
     result = @{
       caseKey: unavailableCase,
       holdsTotalKey: @(unavailable.holdsTotal),
       copiesAvailableKey: @(unavailable.copiesAvailable),
       copiesTotalKey: @(unavailable.copiesTotal)
     };
   } limited:^(TPPOPDSAcquisitionAvailabilityLimited *const _Nonnull limited) {
     result = @{
       caseKey: limitedCase,
       copiesAvailableKey: @(limited.copiesAvailable),
       copiesTotalKey: @(limited.copiesTotal),
       sinceKey: TPPNullFromNil([limited.since RFC3339String]),
       untilKey: TPPNullFromNil([limited.until RFC3339String])
     };
   } unlimited:^(__unused TPPOPDSAcquisitionAvailabilityUnlimited *const _Nonnull unlimited) {
     result = @{
       caseKey: unlimitedCase
     };
   } reserved:^(TPPOPDSAcquisitionAvailabilityReserved * _Nonnull reserved) {
     result = @{
       caseKey: reservedCase,
       holdsPositionKey: @(reserved.holdsPosition),
       holdsTotalKey: @(reserved.holdsTotal),
       copiesAvailableKey: @(reserved.copiesAvailable),
       copiesTotalKey: @(reserved.copiesTotal),
       sinceKey: TPPNullFromNil([reserved.since RFC3339String]),
       untilKey: TPPNullFromNil([reserved.until RFC3339String])
     };
   } ready:^(__unused TPPOPDSAcquisitionAvailabilityReady * _Nonnull ready) {
     result = @{
       caseKey: readyCase
     };
   }];

  return result;
}


#pragma mark - Unavailable implementation
@implementation TPPOPDSAcquisitionAvailabilityUnavailable

- (instancetype _Nonnull)initWithHoldsTotal:(TPPOPDSAcquisitionAvailabilityCopies const)holdsTotal
                                copiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies const)copiesAvailable
                                copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies const)copiesTotal
{
  self = [super init];

  self.holdsTotal = holdsTotal;
  self.copiesAvailable = copiesAvailable;
  self.copiesTotal = copiesTotal;

  return self;
}

- (NSDate *_Nullable)since
{
  return nil;
}

- (NSDate *_Nullable)until
{
  return nil;
}

- (void)
matchUnavailable:(void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (unavailable) {
    unavailable(self);
  }
}

@end

#pragma mark - Limited implementation
@implementation TPPOPDSAcquisitionAvailabilityLimited

- (instancetype _Nonnull)initWithCopiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies)copiesAvailable
                                     copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies)copiesTotal
                                           since:(NSDate *const _Nullable)since
                                           until:(NSDate *const _Nullable)until
{
  self = [super init];

  self.copiesAvailable = copiesAvailable;
  self.copiesTotal = copiesTotal;
  self.since = since;
  self.until = until;

  return self;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (limited) {
    limited(self);
  }
}

@end

#pragma mark - Unlimited implementation
@implementation TPPOPDSAcquisitionAvailabilityUnlimited

- (NSDate *_Nullable)since
{
  return nil;
}

- (NSDate *_Nullable)until
{
  return nil;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (unlimited) {
    unlimited(self);
  }
}

@end

#pragma mark - Reserved implementation
@implementation TPPOPDSAcquisitionAvailabilityReserved

- (instancetype _Nonnull)initWithHoldsPosition:(NSUInteger const)holdsPosition
                                  holdsTotal:(TPPOPDSAcquisitionAvailabilityCopies const)holdsTotal
                              copiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies const)copiesAvailable
                                  copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies const)copiesTotal
                                        since:(NSDate *const _Nullable)since
                                        until:(NSDate *const _Nullable)until
{
  self = [super init];

  self.holdsPosition = holdsPosition;
  self.holdsTotal = holdsTotal;
  self.copiesAvailable = copiesAvailable;
  self.copiesTotal = copiesTotal;
  self.since = since;
  self.until = until;

  return self;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (reserved) {
    reserved(self);
  }
}

@end

#pragma mark - Ready implementation
@implementation TPPOPDSAcquisitionAvailabilityReady

- (instancetype _Nonnull)initWithSince:(NSDate *const _Nullable)since
                                 until:(NSDate *const _Nullable)until
{
  self = [super init];

  self.since = since;
  self.until = until;

  return self;
}

- (void)matchUnavailable:(__unused void (^ _Nullable const) (TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(void (^ _Nullable const)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (ready) {
    ready(self);
  }
}

@end
