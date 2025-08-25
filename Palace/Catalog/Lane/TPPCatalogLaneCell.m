@import PureLayout;

#import "TPPConfiguration.h"
#import "Palace-Swift.h"

#import "TPPCatalogLaneCell.h"

@interface TPPCatalogLaneCell ()

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSUInteger laneIndex;
@property (nonatomic) UIScrollView *scrollView;

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
  
  NSMutableArray *const buttons = [NSMutableArray arrayWithCapacity:books.count];
  
  [books enumerateObjectsUsingBlock:^(TPPBook *const book,
                                      NSUInteger const bookIndex,
                                      __attribute__((unused)) BOOL *stop) {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = bookIndex;
    UIImage *const image = bookIdentifiersToImages[book.identifier];
    if(!image) {
//      NSDictionary *infodict = @{@"title":book.title, @"identifier":book.identifier};
      TPPLOG_F(@"Did not receive cover for '%@'.", book.title);
    }
    [button setImage:(image ? image : [UIImage imageNamed:@"NoCover"])
            forState:UIControlStateNormal];
    if (@available(iOS 11.0, *)) {
      button.accessibilityIgnoresInvertColors = YES;
    }
    [button addTarget:self
               action:@selector(didSelectBookButton:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [buttons addObject:button];
    //Add accessibilitylable for a book of unknown type
    button.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@", nil), book.title, book.authors];
    //Add hint telling what happens when title is tapped
    button.accessibilityHint = [NSString stringWithFormat:NSLocalizedString(@"Show book's page", nil)];
    [self.scrollView addSubview:button];
    
    if ([book defaultBookContentType] == TPPBookContentTypeAudiobook) {
      //Add accessibility label for audiobook
      button.accessibilityLabel = button.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, audiobook", nil), book.title, book.authors];;
      TPPContentBadgeImageView *badge = [[TPPContentBadgeImageView alloc] initWithBadgeImage:TPPBadgeImageAudiobook];
      [TPPContentBadgeImageView pinWithBadge:badge toView:button isLane:YES];
      button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 6, 0);
    } else if ([book defaultBookContentType] == TPPBookContentTypePdf) {
      //Add accessibility label for Pdf
      button.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, Pdf", nil), book.title, book.authors];
    } else if ([book defaultBookContentType] == TPPBookContentTypeEpub) {
      //Add accessibility label for Epub
      button.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, ebook", nil), book.title, book.authors];
    }
  }];
  
  self.buttons = buttons;
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 15.0;
  
  CGFloat x = padding;
  CGFloat const height = CGRectGetHeight(self.contentView.frame);
  
  // TODO: A guard against absurdly wide covers is needed.
  
  for(UIButton *const button in self.buttons) {
    CGFloat width = button.imageView.image.size.width;
    if(width > 10.0) {
      width *= height / button.imageView.image.size.height;
    } else {
      TPPLOG(@"Failing to correctly display cover with unusable width.");
      width = height * 0.75;
    }
    CGRect const frame = CGRectMake(x, 0.0, width, height);
    button.frame = frame;
    x += width + padding;
  }
  
  self.scrollView.contentSize = CGSizeMake(x, height);
}

#pragma mark -

- (void)didSelectBookButton:(UIButton *const)sender
{
  [self.delegate catalogLaneCell:self didSelectBookIndex:sender.tag];
}

@end
