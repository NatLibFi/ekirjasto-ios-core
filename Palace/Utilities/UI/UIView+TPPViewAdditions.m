#import "UIView+TPPViewAdditions.h"

@implementation UIView (TPPViewAdditions)

- (CGFloat)preferredHeight
{
  return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
}

- (CGFloat)preferredWidth
{
  return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
}

- (void)centerInSuperview
{
  [self centerInSuperviewWithOffset:CGPointZero];
}

- (void)centerInSuperviewWithOffset:(CGPoint)offset
{
  // Compute the final (integralized) centered frame and only assign it when it
  // actually changes. Assigning center + integralizing on every pass sets a
  // fractional frame and then rounds it to a *different* value, so each layout
  // pass changed the frame, and every -setFrame: triggers a safe-area-inset
  // update that re-invalidates layout — an infinite loop at window geometries
  // where the fractional/rounded values never agree (seen on iPad multitasking
  // resize, esp. very small or short windows). Making this idempotent lets a
  // stable pass be a no-op so the layout settles. See TPPRemoteViewController.
  CGPoint const center = CGPointMake(CGRectGetWidth(self.superview.bounds) * 0.5 + offset.x,
                                     CGRectGetHeight(self.superview.bounds) * 0.5 + offset.y);
  CGRect frame = self.frame;
  frame.origin = CGPointMake(center.x - CGRectGetWidth(frame) * 0.5,
                             center.y - CGRectGetHeight(frame) * 0.5);
  frame = CGRectIntegral(frame);
  if (!CGRectEqualToRect(self.frame, frame)) {
    self.frame = frame;
  }
}

- (void)integralizeFrame
{
  CGRect const frame = CGRectIntegral(self.frame);
  if (!CGRectEqualToRect(self.frame, frame)) {
    self.frame = frame;
  }
}

@end
