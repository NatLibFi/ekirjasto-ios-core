@import PureLayout;
#import "Palace-Swift.h"

#import "TPPConfiguration.h"
#import "TPPLinearView.h"
#import "UIView+TPPViewAdditions.h"
#import "UIFont+TPPSystemFontOverride.h"
#import "TPPBookDetailDownloadFailedView.h"

@interface TPPBookDetailDownloadFailedView ()

@property (nonatomic) TPPRoundedButton *cancelButton;
@property (nonatomic) TPPLinearView *cancelTryAgainLinearView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) TPPRoundedButton *tryAgainButton;

@end

@implementation TPPBookDetailDownloadFailedView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.backgroundColor = [TPPConfiguration backgroundColor]; //Edited by Ellibs
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.textColor = [TPPConfiguration ekirjastoBlack]; //Edited by Ellibs
  self.messageLabel.text = NSLocalizedString(@"The download could not be completed.\nScroll down to 'View Issues' to see details.", nil);
  self.messageLabel.numberOfLines = 0;
  [self addSubview:self.messageLabel];
  [self.messageLabel autoPinEdgesToSuperviewEdges];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePreferredContentSize)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  
  return self;
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
  
  UIColor *aColor = [TPPConfiguration ekirjastoLightGrey]; //Edited by Ellibs
  [aColor setFill];
  CGContextAddPath(context, visiblePath);
  CGContextFillPath(context);
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, NULL, CGRectInset(bounds, -42, -42));
  CGPathAddPath(path, NULL, visiblePath);
  CGPathCloseSubpath(path);
  CGContextAddPath(context, visiblePath);
  CGContextClip(context);
  
  //Disabled by Ellibs
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

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didChangePreferredContentSize
{
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
}

- (void)configureFailMessageWithProblemDocument:(TPPProblemDocument *)problemDoc {
  if (problemDoc != nil) {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.\nScroll down to 'View Issues' to see details.", nil);
  } else {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.", nil);
  }
}

@end
