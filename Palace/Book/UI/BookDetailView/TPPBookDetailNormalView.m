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

-(NSString *)messageStringForStateCanBorrow
{
  NSString *message = NSLocalizedString(@"This book is available to borrow.", nil);
  return message;
}

-(NSString *)messageStringForStateCanHold
{
  NSString *message = NSLocalizedString(@"All licenses of this book are currently checked out.", nil);
  return message;
}

-(NSString *)messageStringForStateDownloadNeeded
{
  NSString *message = NSLocalizedString(@"Your book has not yet been downloaded.", nil);

  if (self.book.defaultAcquisition.availability.until) {
    NSString *timeUntilString = [self.book.defaultAcquisition.availability.until longTimeUntilString];
    NSString *timeEstimateMessage = [NSString stringWithFormat:NSLocalizedString(@"It will expire in %@.", @"Tell the user how much time they have left for the book they have borrowed."),timeUntilString];
    return [NSString stringWithFormat:@"%@\n%@",message,timeEstimateMessage];
  } else {
    return message;
  }
}

-(NSString *)messageStringForNYPLBookButtonStateSuccessful
{
  NSString *message = NSLocalizedString(@"Your book is ready to read!", nil);
  if (self.book.defaultAcquisition.availability.until) {
    NSString *timeUntilString = [self.book.defaultAcquisition.availability.until longTimeUntilString];
    NSString *timeEstimateMessage = [NSString stringWithFormat:NSLocalizedString(@"It will expire in %@.", @"Tell the user how much time they have left for the book they have borrowed."),timeUntilString];
    return [NSString stringWithFormat:@"%@\n%@",message,timeEstimateMessage];
  } else {
    return message;
  }
}

-(NSString *)messageStringForNYPLBookButtonsStateHolding
{
  __block NSUInteger holdPosition = 0;
  __block TPPOPDSAcquisitionAvailabilityCopies copiesTotal = 0;

  [self.book.defaultAcquisition.availability
   matchUnavailable:nil
   limited:nil
   unlimited:nil
   reserved:^(TPPOPDSAcquisitionAvailabilityReserved *const _Nonnull reserved) {
     holdPosition = reserved.holdPosition;
     copiesTotal = reserved.copiesTotal;
   }
   ready:nil];
  
  NSString *message = NSLocalizedString(@"You have this book on hold.", nil);

  if (holdPosition > 0) {
    if (copiesTotal > 0) {
      NSString *positionAndCopiesString = [NSString stringWithFormat:NSLocalizedString(@"\nYou are %ld in line for %ld copies.", @"Describe the line that a person is waiting in for a total number of books that are available for everyone to check out, to help tell them how long they will be waiting."), (unsigned long)holdPosition, (unsigned long)copiesTotal];
      return [message stringByAppendingString:positionAndCopiesString];
    }
    NSString *positionString = [NSString stringWithFormat:NSLocalizedString(@"You are %ld in line.", nil), (long)holdPosition];
    return [message stringByAppendingString:positionString];
  } else {
    return message;
  }
}

-(NSString *)messageStringForStateHoldingFOQ
{
  NSString *message = NSLocalizedString(@"This book is available to borrow.", nil);

  if (self.book.defaultAcquisition.availability.until) {
    NSString *timeUntilString = [self.book.defaultAcquisition.availability.until longTimeUntilString];
    NSString *timeEstimateMessage = [NSString stringWithFormat:NSLocalizedString(@"This reservation will be automatically cancelled in %@.", nil),timeUntilString];
    return [NSString stringWithFormat:@"%@\n%@",message,timeEstimateMessage];
  } else {
    return message;
  }
}

-(NSString *)messageStringForStateUsed
{
  NSString *message = NSLocalizedString(@"Your book is ready to read!", nil);
  return message;
}

@end
