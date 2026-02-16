@import Foundation;

@class TPPXML;

#pragma mark - Type definitions

// defining a type alias helper
typedef NSUInteger TPPOPDSAcquisitionAvailabilityCopies;

// defining a constant called TPPOPDSAcquisitionAvailabilityCopiesUnknown
// it's type is TPPOPDSAcquisitionAvailabilityCopies it is extern (used globally)
extern TPPOPDSAcquisitionAvailabilityCopies const TPPOPDSAcquisitionAvailabilityCopiesUnknown;

#pragma mark - Availability classes
// defining book availability classes
@class TPPOPDSAcquisitionAvailabilityUnavailable;
@class TPPOPDSAcquisitionAvailabilityLimited;
@class TPPOPDSAcquisitionAvailabilityUnlimited;
@class TPPOPDSAcquisitionAvailabilityReserved;
@class TPPOPDSAcquisitionAvailabilityReady;


#pragma mark - TPPOPDSAcquisitionAvailability protocol definition

// protocol for shared properties and functions
// for book's availability states
@protocol TPPOPDSAcquisitionAvailability

// property representing the date
// when this availability state began.
// See https://git.io/JmCQT for full semantics.
@property (nonatomic, readonly, nullable) NSDate *since;

// property representing the date
// when this availability state will end.
// See https://git.io/JmCQT for full semantics.
@property (nonatomic, readonly, nullable) NSDate *until;

// Function for matching availability state of the book's acquisition
// to a specific type given as parameter and then executing the corresponding block.
// The possible types are unavailable, limited, unlimited, reserved or ready.
// Reminder: Objective-C combines function name with following parameter name,
// so the first parameter here is unavailable, not matchUnavailable.
//
// Note: parameter and it's block and the parameter given to a block are all named the same
// For example if the availability state is of type reserved,
// then a block called reserved is executed.
// This block also receives a parameter called reserved
// that is an instance of `TPPOPDSAcquisitionAvailabilityReserved`
//
- (void)matchUnavailable:(void (^ _Nullable)(TPPOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(void (^ _Nullable)(TPPOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(void (^ _Nullable)(TPPOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(void (^ _Nullable)(TPPOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(void (^ _Nullable)(TPPOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready;

@end


#pragma mark - Create TPPOPDSAcquisitionAvailability instances and dictionaries

// Create an acquisition availability object from XML data.
// The parameter linkXML is of type TPPXML.
// The return type is TPPOPDSAcquisitionAvailability.
//
/// @param linkXML XML from an OPDS entry where @c linkXML.name == @c @"link".
/// @return A value of one of the three availability information types. If the
/// input is not valid, @c NYPLOPDSAcquisitionAvailabilityUnlimited is returned.
id<TPPOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(TPPXML *_Nonnull linkXML);

// Create an acquisition availability object from dictionary.
// The parameter dictionary is of type NSDictionary.
// The return type is TPPOPDSAcquisitionAvailability.
//
/// @param dictionary Serialized availability information created with
/// @c NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation.
/// @return Availability information or @c nil if the input is not sensible.
id<TPPOPDSAcquisitionAvailability> _Nullable
NYPLOPDSAcquisitionAvailabilityWithDictionary(NSDictionary *_Nonnull dictionary);

// Function NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation
// converts the acquisition availability object to a dictionary representation.
// The parameter availability is of type TPPOPDSAcquisitionAvailability
// The function returns type NSDictionary.
//
/// @param availability The availability information to serialize.
/// @return The serialized result for use with
/// @c NYPLOPDSAcquisitionAvailabilityWithDictionary.
NSDictionary *_Nonnull
NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation(id<TPPOPDSAcquisitionAvailability> _Nonnull availability);


#pragma mark - Unavailable interface
@interface TPPOPDSAcquisitionAvailabilityUnavailable : NSObject <TPPOPDSAcquisitionAvailability>

// number of copies currently reserved
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies holdsTotal;

// number of available copies
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesAvailable;

// total number of copies
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

// initializes the unavailable state with 3 parameters:
// - number of copies reserved
// - copies available
// - copies total
- (instancetype _Nonnull)initWithHoldsTotal:(TPPOPDSAcquisitionAvailabilityCopies)holdsTotal
                              copiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies)copiesAvailable
                              copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies)copiesTotal
  NS_DESIGNATED_INITIALIZER;

@end


#pragma mark - Limited interface
@interface TPPOPDSAcquisitionAvailabilityLimited : NSObject <TPPOPDSAcquisitionAvailability>

// number of copies available for acquisition
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesAvailable;

// total number of copies
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

// initializes the limited state with 4 parameters:
// - copies available
// - copies total
// - since date (optional)
// - until date (optional)
- (instancetype _Nonnull)initWithCopiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies)copiesAvailable
                                     copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies)copiesTotal
                                           since:(NSDate *_Nullable)since
                                           until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end


#pragma mark - Unlimited interface
@interface TPPOPDSAcquisitionAvailabilityUnlimited : NSObject <TPPOPDSAcquisitionAvailability>
// nothing here
@end


#pragma mark - Reserved interface
@interface TPPOPDSAcquisitionAvailabilityReserved : NSObject <TPPOPDSAcquisitionAvailability>

// the position where user is in the hold queue
// If equal to @c 1, the user is next in line. This value is never @c 0.
@property (nonatomic, readonly) NSUInteger holdsPosition;

// number of copies currently reserved
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies holdsTotal;

// number of copies available
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesAvailable;

// total number of copies
@property (nonatomic, readonly) TPPOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

// initializes the reserved state with 6 parameters:
// - hold position
// - holds total
// - copies available
// - copies total
// - since date (optional)
// - until date (optional)
- (instancetype _Nonnull)initWithHoldsPosition:(NSUInteger)holdsPosition
                                   holdsTotal:(TPPOPDSAcquisitionAvailabilityCopies)holdsTotal
                              copiesAvailable:(TPPOPDSAcquisitionAvailabilityCopies)copiesAvailable
                                  copiesTotal:(TPPOPDSAcquisitionAvailabilityCopies)copiesTotal
                                        since:(NSDate *_Nullable)since
                                        until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end


#pragma mark - Ready interface
@interface TPPOPDSAcquisitionAvailabilityReady : NSObject <TPPOPDSAcquisitionAvailability>

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

// initializes the ready state with 2 parameters:
// - since date (optional)
// - until date (optional)
- (instancetype _Nonnull)initWithSince:(NSDate *_Nullable)since
                                 until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end
