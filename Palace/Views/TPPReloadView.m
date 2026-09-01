#import "UIView+TPPViewAdditions.h"

#import "TPPReloadView.h"
#import "Palace-Swift.h"

@interface TPPReloadView ()

@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) TPPRoundedButton *reloadButton;
@property (nonatomic) UILabel *titleLabel;

@end

static CGFloat const width = 280;

@implementation TPPReloadView

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 0)];
  if(!self) return nil;
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldPalaceFontOfSize:17];
  self.titleLabel.text = NSLocalizedString(@"Connection Failed", nil);
  self.titleLabel.textColor = [UIColor grayColor];
  [self addSubview:self.titleLabel];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.numberOfLines = 3;
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.font = [UIFont palaceFontOfSize:12];
  [self setDefaultMessage];
  self.messageLabel.textColor = [UIColor grayColor];
  [self addSubview:self.messageLabel];
  
  self.reloadButton = [[TPPRoundedButton alloc] initWithType:TPPRoundedButtonTypeNormal isFromDetailView:NO isReturnButton:NO];
  [self.reloadButton setTitle:NSLocalizedString(@"Try Again", nil)
                     forState:UIControlStateNormal];
  [self.reloadButton addTarget:self
                        action:@selector(didSelectReload)
              forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.reloadButton];
  
  [self layoutIfNeeded];
  
  self.frame = CGRectMake(0, 0, width, CGRectGetMaxY(self.reloadButton.frame));
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  [super layoutSubviews];

  // This view is hidden whenever content loaded successfully. Positioning its
  // subviews assigns frames, and doing that on every layout pass can
  // re-invalidate layout and spin into a loop at extreme iPad window geometries
  // on iOS 26. There is nothing to show while hidden, so skip it.
  if (self.hidden) {
    return;
  }

  CGFloat const padding = 5.0;

  // Frame writes below are guarded so a stable pass is a no-op — assigning the
  // same frame each pass would keep re-triggering layout (see the loop above).
  {
    [self.titleLabel sizeToFit];
    [self.titleLabel centerInSuperview];
    CGRect frame = self.titleLabel.frame;
    frame.origin.y = 0;
    if (!CGRectEqualToRect(self.titleLabel.frame, frame)) {
      self.titleLabel.frame = frame;
    }
  }

  {
    CGFloat h = [self.messageLabel sizeThatFits:
                 CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX)].height;

    CGRect const frame = CGRectMake(0,
                                    CGRectGetMaxY(self.titleLabel.frame) + padding,
                                    CGRectGetWidth(self.frame),
                                    h);
    if (!CGRectEqualToRect(self.messageLabel.frame, frame)) {
      self.messageLabel.frame = frame;
    }
  }

  {
    [self.reloadButton sizeToFit];
    [self.reloadButton centerInSuperview];
    CGRect frame = self.reloadButton.frame;
    frame.origin.y = CGRectGetMaxY(self.messageLabel.frame) + padding;
    if (!CGRectEqualToRect(self.reloadButton.frame, frame)) {
      self.reloadButton.frame = frame;
    }
  }
}

#pragma mark -

- (void)setDefaultMessage
{
  self.messageLabel.text = NSLocalizedString(@"Check Connection", nil);
  [self setNeedsLayout];
}

- (void)setMessage:(NSString *)msg
{
  self.messageLabel.text = msg;
  [self setNeedsLayout];
}

- (void)didSelectReload
{
  if(self.handler) {
    self.handler();
  }

  [self setDefaultMessage];
}

@end
