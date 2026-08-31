@import PureLayout;

#import "TPPConfiguration.h"
#import "Palace-Swift.h"

#import "TPPCatalogLaneCell.h"

@interface TPPCatalogLaneCell ()

@property (nonatomic) NSArray *coverViews;
@property (nonatomic) NSUInteger laneIndex;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) CGFloat lastLaidOutHeight;

@end

@implementation TPPCatalogLaneCell

- (instancetype)initWithLaneIndex:(NSUInteger const)laneIndex
                            books:(NSArray *const)books
          bookIdentifiersToImages:(NSDictionary *const)bookIdentifiersToImages
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  self.laneIndex = laneIndex;
  
  self.backgroundColor = [TPPConfiguration backgroundColor];
  
  self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                       | UIViewAutoresizingFlexibleHeight);
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.contentView.bounds];
  self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                      | UIViewAutoresizingFlexibleHeight);
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  self.scrollView.scrollsToTop = NO;
  [self.contentView addSubview:self.scrollView];
  
  NSMutableArray *const coverViews = [NSMutableArray arrayWithCapacity:books.count];

  [books enumerateObjectsUsingBlock:^(TPPBook *const book,
                                      NSUInteger const bookIndex,
                                      __attribute__((unused)) BOOL *stop) {
    // Covers are plain UIImageViews (not UIButtons) on purpose: a UIButton runs
    // an expensive title/image + focus-system layout pass every time it is laid
    // out (-[UIControl state] -> -[UIView isFocused] -> focus-environment
    // ancestor walk), which — multiplied across every cover during the
    // full-window relayout that iPad live resize / size-class changes force —
    // pegged the main thread for tens of seconds. A UIImageView has no such
    // path, so its layout is trivial. Selection is handled by a tap recognizer.
    UIImageView *const coverView = [[UIImageView alloc] init];
    coverView.tag = bookIndex;
    coverView.userInteractionEnabled = YES;
    coverView.contentMode = UIViewContentModeScaleToFill;
    UIImage *const image = bookIdentifiersToImages[book.identifier];
    if(!image) {
//      NSDictionary *infodict = @{@"title":book.title, @"identifier":book.identifier};
      TPPLOG_F(@"Did not receive cover for '%@'.", book.title);
    }
    coverView.image = (image ? image : [UIImage imageNamed:@"NoCover"]);
    if (@available(iOS 11.0, *)) {
      coverView.accessibilityIgnoresInvertColors = YES;
    }
    UITapGestureRecognizer *const tap =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(didTapCover:)];
    [coverView addGestureRecognizer:tap];
    [coverViews addObject:coverView];
    // Preserve the button-equivalent VoiceOver experience.
    coverView.isAccessibilityElement = YES;
    coverView.accessibilityTraits = UIAccessibilityTraitButton;
    //Add accessibilitylable for a book of unknown type
    coverView.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@", nil), book.title, book.authors];
    //Add hint telling what happens when title is tapped
    coverView.accessibilityHint = [NSString stringWithFormat:NSLocalizedString(@"Show book's page", nil)];
    [self.scrollView addSubview:coverView];

    if ([book defaultBookContentType] == TPPBookContentTypeAudiobook) {
      //Add accessibility label for audiobook
      coverView.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, audiobook", nil), book.title, book.authors];
      TPPContentBadgeImageView *badge = [[TPPContentBadgeImageView alloc] initWithBadgeImage:TPPBadgeImageAudiobook];
      [TPPContentBadgeImageView pinWithBadge:badge toView:coverView isLane:YES];
    } else if ([book defaultBookContentType] == TPPBookContentTypePdf) {
      //Add accessibility label for Pdf
      coverView.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, pdf", nil), book.title, book.authors];
    } else if ([book defaultBookContentType] == TPPBookContentTypeEpub) {
      //Add accessibility label for Epub
      coverView.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, ebook", nil), book.title, book.authors];
    }
  }];

  self.coverViews = coverViews;

  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 15.0;

  CGFloat x = padding;
  CGFloat const height = CGRectGetHeight(self.contentView.frame);

  // Cover frames depend only on the lane height (widths are derived from
  // height, x-offsets accumulate) — never on the cell's width. During an iPad
  // live window resize / size-class transition the whole window re-lays-out per
  // frame at a constant lane height, so re-running this loop would re-assign
  // every cover the frame it already has, needlessly re-triggering layout. Skip
  // when height is unchanged to avoid that per-frame work.
  if (height == self.lastLaidOutHeight) {
    return;
  }
  self.lastLaidOutHeight = height;

  // TODO: A guard against absurdly wide covers is needed.

  for(UIImageView *const coverView in self.coverViews) {
    CGFloat width = coverView.image.size.width;
    if(width > 10.0) {
      width *= height / coverView.image.size.height;
    } else {
      TPPLOG(@"Failing to correctly display cover with unusable width.");
      width = height * 0.75;
    }
    CGRect const frame = CGRectMake(x, 0.0, width, height);
    coverView.frame = frame;
    x += width + padding;
  }

  self.scrollView.contentSize = CGSizeMake(x, height);
}

#pragma mark -

- (void)didTapCover:(UITapGestureRecognizer *const)sender
{
  [self.delegate catalogLaneCell:self didSelectBookIndex:sender.view.tag];
}

@end
