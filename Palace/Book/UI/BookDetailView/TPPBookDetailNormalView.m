@import PureLayout;

#import "NSDate+NYPLDateAdditions.h"
#import "TPPConfiguration.h"
#import "TPPOPDS.h"
#import "UIView+TPPViewAdditions.h"
#import "UIFont+TPPSystemFontOverride.h"
#import "TPPBookDetailNormalView.h"

@interface TPPBookDetailNormalView ()

typedef NS_ENUM (NSInteger, NYPLProblemReportButtonState) {
  NYPLProblemReportButtonStateNormal,
  NYPLProblemReportButtonStateSent
};

@property (nonatomic) UILabel *messageLabel;

@end

@implementation TPPBookDetailNormalView

#pragma mark UIView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont palaceFontOfSize: 16]; //Edited by Ellibs
  self.messageLabel.textColor = [TPPConfiguration ekirjastoBlack]; //Edited by Ellibs
  self.messageLabel.numberOfLines = 0;
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  [self addSubview:self.messageLabel];
  [self.messageLabel autoCenterInSuperview];
  [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:12 relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:12 relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewMargin:ALEdgeTop relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom relation:NSLayoutRelationGreaterThanOrEqual];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePreferredContentSize)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(__unused CGRect)rect
{
  //Inner drop-shadow
  CGRect bounds = [self bounds];
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  UIGraphicsPushContext(context); //Added By Ellibs
  CGContextSetFillColorWithColor(context, [TPPConfiguration backgroundColor].CGColor); //Added By Ellibs
  CGContextFillRect(context, rect); //Added By Ellibs
  UIGraphicsPopContext(); //Added By Ellibs

  CGMutablePathRef visiblePath = CGPathCreateMutable();
  CGPathMoveToPoint(visiblePath, NULL, bounds.origin.x, bounds.origin.y);
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width - 20, bounds.origin.y); //Edited by Ellibs
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width - 20, bounds.origin.y + bounds.size.height); //Edited by Ellibs
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + 20, bounds.origin.y + bounds.size.height); //Edited by Ellibs
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + 20, bounds.origin.y); //Edited by Ellibs
  CGPathCloseSubpath(visiblePath);
  
  UIColor *aColor = [TPPConfiguration ekirjastoYellow]; //Edited by Ellibs
  if((_state != TPPBookButtonsStateCanBorrow ) && (_state != TPPBookButtonsStateDownloadNeeded) && (_state != TPPBookButtonsStateHoldingFOQ) && (_state != TPPBookButtonsStateDownloadSuccessful) && (_state != TPPBookButtonsStateUsed)) {
    aColor =  [TPPConfiguration ekirjastoLightGrey];
  } //Added by Ellibs
  [aColor setFill];
  CGContextAddPath(context, visiblePath);
  CGContextFillPath(context);
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, NULL, CGRectInset(bounds, -42, -42));
  CGPathAddPath(path, NULL, visiblePath);
  CGPathCloseSubpath(path);
  CGContextAddPath(context, visiblePath);
  CGContextClip(context);
  
  //Disable by Ellibs
  //aColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
  //CGContextSaveGState(context);
  //CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 5.0f, [aColor CGColor]);
  //[aColor setFill];
  //CGContextSaveGState(context);
  //CGContextAddPath(context, path);
  //CGContextEOFillPath(context);
  CGPathRelease(path);
  CGPathRelease(visiblePath);
}

- (void)didChangePreferredContentSize
{
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1 multiplier:1.2];
}

#pragma mark -

- (void)setState:(TPPBookButtonsState const)state
{
  _state = state;
  
  NSString *newMessageString = @"";
  switch(state) {
    case TPPBookButtonsStateCanBorrow:
      newMessageString = [self messageStringForStateCanBorrow];
      break;
    case TPPBookButtonsStateCanHold:
      newMessageString = [self messageStringForStateCanHold];
      break;
    case TPPBookButtonsStateDownloadNeeded:
      newMessageString = [self messageStringForStateDownloadNeeded];
      break;
    case TPPBookButtonsStateDownloadSuccessful:
      newMessageString = [self messageStringForNYPLBookButtonStateSuccessful];
      break;
    case TPPBookButtonsStateHolding:
      newMessageString = [self messageStringForNYPLBookButtonsStateHolding];
      break;
    case TPPBookButtonsStateHoldingFOQ:
      newMessageString = [self messageStringForStateHoldingFOQ];
      break;
    case TPPBookButtonsStateUsed:
      newMessageString = [self messageStringForStateUsed];
      break;
    case TPPBookButtonsStateDownloadInProgress:
      break;
    default:
      break;
  }
  
  if (!self.messageLabel.text) {
    self.messageLabel.text = newMessageString;
  } else if (![self.messageLabel.text isEqualToString:newMessageString]){
    CGFloat duration = 0.3f;
    [UIView animateWithDuration:duration animations:^{
      self.messageLabel.alpha = 0.0f;
    } completion:^(__unused BOOL finished) {
      self.messageLabel.alpha = 0.0f;
      self.messageLabel.text = newMessageString;
      [UIView animateWithDuration:duration animations:^{
        self.messageLabel.alpha = 1.0f;
      } completion:^(__unused BOOL finished) {
        self.messageLabel.alpha = 1.0f;
      }];
    }];
  }
}

#pragma mark - Book availability messages

// This function formats a message string
// that is used to info if a book can be borrowed.
// It can also contain info about the number of available
// and total copies of book.
// The message is visible in the book detail view
// for both authenticated and non-authenticated users
-(NSString *)messageStringForStateCanBorrow
{
  // initialize the variables that store availability information
  // we use NSNotFound as initial value for safety
  __block TPPOPDSAcquisitionAvailabilityCopies copiesAvailable = NSNotFound; // number of available copies of the book
  __block TPPOPDSAcquisitionAvailabilityCopies copiesTotal = NSNotFound; // total number of copies of the book

  // define the basic string for a book that is available to borrow
  NSString *basicMessage = NSLocalizedString(@"This book is available to borrow.", nil);

  // extract availability data using the limited state of the book's acquisition
  [self.book.defaultAcquisition.availability
   matchUnavailable:nil
   limited:^(TPPOPDSAcquisitionAvailabilityLimited *const _Nonnull limited) {
    copiesAvailable = limited.copiesAvailable;
    copiesTotal = limited.copiesTotal;
   }
   unlimited:nil
   reserved:nil
   ready:nil];
  
  // check if we have the valid data available in the book
  // show we can show the number of books available to the user
  if (copiesAvailable == NSNotFound || copiesTotal == NSNotFound) {
    
    // just return the basic message without availability
    // "This book is available to borrow."
    // because for some reason we do not have
    // the correct data for this book's availability
    return basicMessage;
  }

  // // create book availability strings
  NSString *copiesAvailableString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesAvailable];
  NSString *copiesTotalString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesTotal];

  // define a message for the book's availability status
  // Example: "Available: 4 / 10"
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"Available: %@ / %@", nil),
                                copiesAvailableString,
                                copiesTotalString];
  
  // define a linebreak string
  NSString *lineBreak = @"\n";

  // combine the basic message and detailed message with a line break
  // and return the complete info text
  return [NSString stringWithFormat:@"%@%@%@",
          basicMessage,
          lineBreak,
          detailedMessage];

}

// This function formats a message string
// that is used to info that the book can be reserved.
// It also contains info about how many copies we have
// of the book and how many of them are currently reserved.
// The message is visible in the book detail view
// for both authenticated and non-authenticated users.
-(NSString *)messageStringForStateCanHold
{

  // initialize the variables that store availability information
  // we use NSNotFound as initial value for safety
  __block TPPOPDSAcquisitionAvailabilityCopies holdsTotal = NSNotFound; // total number of holds for the book
  __block TPPOPDSAcquisitionAvailabilityCopies copiesAvailable = NSNotFound; // number of available copies of the book
  __block TPPOPDSAcquisitionAvailabilityCopies copiesTotal = NSNotFound; // total number of copies of the book
  
  // define the basic message for a book that is available to be reserved
  NSString *basicMessage = NSLocalizedString(@"This book is available to place on hold.", nil);

  // extract availability data using the unavailable state of the book's acquisition.
  [self.book.defaultAcquisition.availability
   matchUnavailable:^(TPPOPDSAcquisitionAvailabilityUnavailable *const _Nonnull unavailable) {
    holdsTotal = unavailable.holdsTotal;
    copiesAvailable = unavailable.copiesAvailable;
    copiesTotal = unavailable.copiesTotal;
  }
   limited:nil
   unlimited:nil
   reserved:nil
   ready:nil
  ];
  
  // check if any of the required availability data is NSNotFound
  // so we can inform the user about the number of books available
  // and the length of the hold queue.
  // note that the copiesAvailable should logically always be 0,
  // but we do not check it here and we let every non-zero value pass
  if (holdsTotal == NSNotFound || copiesAvailable == NSNotFound
      || copiesTotal == NSNotFound) {
    
    // availability data is not valid,
    // just return the basic message
    return basicMessage;
  }

  // create holdsTotal, copiesAvailable, copiesTotal strings
  NSString *holdsTotalString = [NSString stringWithFormat:@"%ld", (unsigned long)holdsTotal];
  NSString *copiesAvailableString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesAvailable];
  NSString *copiesTotalString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesTotal];
  
  // define a message for the book's  queue and availability status "Hold queue: 6, available: 0 / 25"
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"Hold queue: %@, available: %@ / %@", nil),
                                holdsTotalString,
                                copiesAvailableString,
                                copiesTotalString];
  
  // define a linebreak string
  NSString *lineBreak = @"\n";

  // combine the basic message and detailed message with a line break
  // and return the complete info text
  return [NSString stringWithFormat:@"%@%@%@",
          basicMessage,
          lineBreak,
          detailedMessage];
  
}

// This function formats a message string
// that is used to info that the book is on loan.
// It can also contain info about remaining loan time.
// The message is visible in the book detail view
// only for the authenticated user.
-(NSString *)messageStringForStateDownloadNeeded
{
  // extract the until date for reservation
  NSDate *expirationDate = self.book.defaultAcquisition.availability.until;
  
  // check if the loan has ending date
  if (!expirationDate) {
    
    // define the basic string for a book that is borrowed to user
    NSString *basicMessage = NSLocalizedString(@"You have this book on loan.", nil);
    
    // just return the basic message without expiration time
    // "You have this book on loan."
    // because for some reason we do not have
    // the correct data for this book's until date
    return basicMessage;
  }
  
  // create a String for the time until the loan expires
  NSString *timeUntilString = [expirationDate longTimeUntilString];
  
  // create a message that informs the user when the loan  will expire
  // Example: 'You have this book on loan for 5 days'
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"You have this book on loan for %@.", nil),
                                   timeUntilString];
  
  // return the formatted message with expiration date
  return detailedMessage;
}

// This function formats a message string
// that is used to info that the book is on loan.
// It can also contain info about remaining loan time.
// The message is visible in the book detail view
// only for the authenticated user.
-(NSString *)messageStringForNYPLBookButtonStateSuccessful
{
  
  // extract the until date for loan
  NSDate *expirationDate = self.book.defaultAcquisition.availability.until;
  
  // check if the loan has ending date
  if (!expirationDate) {
    // define the basic string for a book that is borrowed to user
    NSString *basicMessage = NSLocalizedString(@"You have this book on loan.", nil);
    
    // just return the basic message without expiration time
    // "You have this book on loan."
    // because for some reason we do not have
    // the correct data for this book's until date
    return basicMessage;
  }

  // create a String for the time until the loan expires
  NSString *timeUntilString = [expirationDate longTimeUntilString];
  
  // create a message that informs the user when the loan  will expire
  // Example: 'You have this book on loan for 5 days'
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"You have this book on loan for %@.", nil),
                                   timeUntilString];
  
  // return the formatted message with expiration date
  return detailedMessage;
}

// This function formats a message string
// that is used to info that the book is on hold for the user.
// It can also contain info about the user's position
// in the hold queue and book availability.
// The message is visible in the book detail view
// only for the authenticated user who has reserved a book.
-(NSString *)messageStringForNYPLBookButtonsStateHolding
{
  
  // initialize the variables that store availability information
  // we use NSNotFound as initial value for safety
  __block NSUInteger holdsPosition = NSNotFound; // user's position in the hold queue
  __block NSUInteger holdsTotal = NSNotFound; // total number of holds for the book
  __block TPPOPDSAcquisitionAvailabilityCopies copiesAvailable = NSNotFound; // number of available copies of the book
  __block TPPOPDSAcquisitionAvailabilityCopies copiesTotal = NSNotFound; // total number of copies of the book

  // extract availability data using the reserved state of the book's acquisition
  [self.book.defaultAcquisition.availability
   matchUnavailable:nil
   limited:nil
   unlimited:nil
   reserved:^(TPPOPDSAcquisitionAvailabilityReserved *const _Nonnull reserved) {
    holdsPosition = reserved.holdsPosition;
    holdsTotal = reserved.holdsTotal;
    copiesAvailable = reserved.copiesAvailable;
    copiesTotal = reserved.copiesTotal;
   }
   ready:nil];
  
  // define the basic message for a book that the user has on hold
  NSString *basicMessage = NSLocalizedString(@"You have this book on hold.", nil);
  
  // check if any of the required availability data is NSNotFound
  if (holdsPosition == NSNotFound || holdsTotal == NSNotFound ||
      copiesAvailable == NSNotFound || copiesTotal == NSNotFound) {
    
    // availability data is not valid,
    // just return the basic message
    return basicMessage;
  }

  // create book hold and availability strings
  NSString *holdsPositionString = [NSString stringWithFormat:@"%ld", (unsigned long)holdsPosition];
  NSString *holdsTotalString = [NSString stringWithFormat:@"%ld", (unsigned long)holdsTotal];
  NSString *copiesAvailableString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesAvailable];
  NSString *copiesTotalString = [NSString stringWithFormat:@"%ld", (unsigned long)copiesTotal];

  // format the detailed message with hold position and availability info
  // Example: 'Your hold position: 3 / 7, available: 0 / 25'
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"Your hold position: %@ / %@, available: %@ / %@", nil),
                                       holdsPositionString,
                                       holdsTotalString,
                                       copiesAvailableString,
                                       copiesTotalString];

  // define a linebreak string
  NSString *lineBreak = @"\n";
  
  // combine the basic message and detailed message with a line break
  // and return the complete info text
  return [NSString stringWithFormat:@"%@%@%@",
          basicMessage,
          lineBreak,
          detailedMessage];
  
}

// This function formats a message string
// that is used to info that the a book can be borrowed.
// It can also contain info about the resevation expiration time
// (= how much time user has left to borrow the book).
// The message is visible in the book detail view
// only for the authenticated user who has previously
// reserved a book that has now become ready to be borrowed.
-(NSString *)messageStringForStateHoldingFOQ
{
  
  // define the basic string for a book that is available to borrow
  NSString *basicMessage = NSLocalizedString(@"This book is available to borrow.", nil);

  // extract the until date for reservation
  NSDate *expirationDate = self.book.defaultAcquisition.availability.until;
  
  // check if the reservation has expiration date
  if (!expirationDate) {
    // just return the basic message without expiration time
    // "This book is available to borrow."
    // because for some reason we do not have
    // the correct data for this book's until date
    return basicMessage;
  }
  
  // create a String for the time until the reservation expires
  NSString *timeUntilString = [expirationDate longTimeUntilString];
  
  // create a message that informs the user when the reservation will expire
  // Example: 'Your reservation will expire in 5 days.'
  NSString *detailedMessage = [NSString stringWithFormat:NSLocalizedString(@"Your reservation will expire in %@.",  nil),
                               timeUntilString];
  
  // define a linebreak string
  NSString *lineBreak = @"\n";

  // combine the basic message and detailed message with a line break
  // and return the complete info text
  return [NSString stringWithFormat:@"%@%@%@",
          basicMessage,
          lineBreak,
          detailedMessage];
  
}

-(NSString *)messageStringForStateUsed
{
  NSString *message = NSLocalizedString(@"Your book is ready to read!", nil);
  return message;
}

@end
