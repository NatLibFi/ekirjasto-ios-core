@import PureLayout;
#import "Palace-Swift.h"

#import "TPPConfiguration.h"
#import "TPPMyBooksDownloadCenter.h"
#import "UIView+TPPViewAdditions.h"
#import "TPPLocalization.h"
#import "TPPBookDetailDownloadingView.h"

@interface TPPBookDetailDownloadingView ()

@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation TPPBookDetailDownloadingView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  CGFloat const sidePadding = 30; //Edited by Ellibs
  
  self.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.progressLabel = [[UILabel alloc] init];
  self.progressLabel.font = [UIFont palaceFontOfSize:18]; //Edited by Ellibs
  self.progressLabel.text = NSLocalizedString(@"Requesting", nil);
  self.progressLabel.textColor = [TPPConfiguration compatiblePrimaryColor]; //Edited by Ellibs
  [self addSubview:self.progressLabel];
  [self.progressLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:sidePadding];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont palaceFontOfSize:18]; //Edited by Ellibs
  self.percentageLabel.textColor = [TPPConfiguration ekirjastoBlack]; //Edited by Ellibs
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = TPPLocalizationNotNeeded(@"0%");
  [self addSubview:self.percentageLabel];
  [self.percentageLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.percentageLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:sidePadding];
  
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [TPPConfiguration inactiveIconColor]; //Edited by Ellibs
  self.progressView.tintColor = [TPPConfiguration iconColor]; //Edited by Ellibs
  [self addSubview:self.progressView];
  [self.progressView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.progressLabel withOffset:sidePadding*2];
  [self.progressView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.percentageLabel withOffset:-sidePadding*2];
  
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
  
  UIColor *aColor = [TPPConfiguration ekirjastoYellow]; //Edited by Ellibs
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

#pragma mark -

- (double)downloadProgress
{
  return self.progressView.progress;
}

- (void)setDownloadProgress:(double const)downloadProgress
{
  self.progressView.progress = downloadProgress;
  
  self.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int) (downloadProgress * 100)];
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  _downloadStarted = downloadStarted;
  NSString *status = downloadStarted ? @"Downloading" : @"Requesting";
  self.progressLabel.text = NSLocalizedString(status, nil);
  self.progressLabel.textColor = [TPPConfiguration ekirjastoBlack]; //Added by Ellibs
  [self setNeedsLayout];
}

@end
