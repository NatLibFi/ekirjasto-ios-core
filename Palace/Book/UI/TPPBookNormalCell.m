@import PureLayout;
#import "TPPAttributedString.h"

#import "TPPConfiguration.h"
#import "TPPBookButtonsView.h"
#import "Palace-Swift.h"

#import "TPPBookNormalCell.h"

@interface TPPBookNormalCell ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) TPPBookButtonsView *buttonsView;
@property (nonatomic) UILabel *title;
@property (nonatomic) UIImageView *unreadImageView;
@property (nonatomic) UIImageView *contentBadge;

@end

@implementation TPPBookNormalCell

#pragma mark UIView

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  self.cover.frame = CGRectMake((20 / UIScreen.mainScreen.scale),
                                (20 / UIScreen.mainScreen.scale),
                                (CGRectGetHeight([self contentFrame]) - 60) * (10 / 12.0),
                                (CGRectGetHeight([self contentFrame]) - 60)
                                );
  
  // The extra five height pixels account for a bug in |sizeThatFits:| that does not properly take
  // into account |lineHeightMultiple|.
  CGFloat const titleWidth = CGRectGetWidth([self contentFrame]) - 155;         //Edited by Ellibs
  self.title.frame = CGRectMake(145,                                            //Edited by Ellibs
                                (10 / UIScreen.mainScreen.scale),               //Edited by Ellibs
                                titleWidth,
                                [self.title sizeThatFits:
                                 CGSizeMake(titleWidth, CGFLOAT_MAX)].height + 5);
  
  [self.authors sizeToFit];
  CGSize authorsSize = [self.authors sizeThatFits:CGSizeMake(titleWidth, CGFLOAT_MAX)];
  CGRect authorsRect = CGRectMake(0, 0, authorsSize.width, authorsSize.height);
  self.authors.frame = authorsRect;
  CGRect authorFrame = self.authors.frame;
  authorFrame.origin = CGPointMake(145, CGRectGetMaxY(self.title.frame) + 10);  //Edited by Ellibs
  authorFrame.size.width = CGRectGetWidth([self contentFrame]) - 155;           //Edited by Ellibs
  self.authors.frame = authorFrame;
  
  [self.buttonsView sizeToFit];
  CGRect frame = self.buttonsView.frame;
  frame.origin = CGPointMake(185,
                             (CGRectGetHeight([self contentFrame]) - CGRectGetHeight(frame) - 5)
                             );
  self.buttonsView.frame = frame;

  CGRect unreadImageViewFrame = self.unreadImageView.frame;
  unreadImageViewFrame.origin.x = (CGRectGetMinX(self.cover.frame) -
                                   CGRectGetWidth(unreadImageViewFrame) - 5);
  unreadImageViewFrame.origin.y = 5;
  self.unreadImageView.frame = unreadImageViewFrame;
  [self.unreadImageView setHidden:YES];
}

#pragma mark -

- (void)setBook:(TPPBook *const)book
{
  _book = book;
  
  if(!self.authors) {
    self.authors = [[UILabel alloc] init];
    self.authors.font = [UIFont palaceFontOfSize:12];
    [self.contentView addSubview:self.authors];
  }
  
  if(!self.cover) {
    self.cover = [[UIImageView alloc] init];
    if (@available(iOS 11.0, *)) {
      self.cover.accessibilityIgnoresInvertColors = YES;
    }
    [self.contentView addSubview:self.cover];
  }

  if(!self.title) {
    self.title = [[UILabel alloc] init];
    self.title.numberOfLines = 2;
    self.title.font = [UIFont palaceFontOfSize:17];
    [self.contentView addSubview:self.title];
    [self.contentView setNeedsLayout];
  }

  if(!self.buttonsView) {
    self.buttonsView = [[TPPBookButtonsView alloc] init];
    self.buttonsView.delegate = self.delegate;
    self.buttonsView.showReturnButtonIfApplicable = YES;
    [self.contentView addSubview:self.buttonsView];
    self.buttonsView.translatesAutoresizingMaskIntoConstraints = NO;
   
    [self.buttonsView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.cover];
    [self.buttonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.cover withOffset:15];
    [self.buttonsView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.contentView withOffset:-15];
    [self.buttonsView layoutIfNeeded];
  }
  self.buttonsView.book = book;
  
  if(!self.unreadImageView) {
    self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
    self.unreadImageView.image = [self.unreadImageView.image
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.unreadImageView.tintColor = [TPPConfiguration accentColor];
    [self.contentView addSubview:self.unreadImageView];
  }
  
  self.authors.attributedText = TPPAttributedStringForAuthorsFromString(book.authors);
  self.cover.image = nil;
  self.title.attributedText = TPPAttributedStringForTitleFromString(book.title);
  
  if (!self.contentBadge) {
    self.contentBadge = [[TPPContentBadgeImageView alloc] initWithBadgeImage:TPPBadgeImageAudiobook];
  }
  if ([book defaultBookContentType] == TPPBookContentTypeAudiobook) {
    self.title.accessibilityLabel = [book.title stringByAppendingString:@". Audiobook."];
    [TPPContentBadgeImageView pinWithBadge:self.contentBadge toView:self.cover isLane:NO];
    self.contentBadge.hidden = NO;
  } else {
    self.title.accessibilityLabel = nil;
    self.contentBadge.hidden = YES;
  }
  
  // This avoids hitting the server constantly when scrolling within a category and ensures images
  // will still be there when the user scrolls back up. It also avoids creating tasks and refetching
  // images when the collection view reloads its data in response to an additional page being
  // fetched (which otherwise would cause a flickering effect and pointless bandwidth usage).
  self.cover.image = [[TPPBookRegistry shared] cachedThumbnailImageFor:book];
  
  if(!self.cover.image) {
    [[TPPBookRegistry shared]
     thumbnailImageFor:book
     handler:^(UIImage *const image) {
       // This check prevents old operations from overwriting cover images in the case of cells
       // being reused before those operations completed.
       if([book.identifier isEqualToString:self.book.identifier]) {
         self.cover.image = image;
       }
     }];
  }
  
  if([book defaultBookContentType] == TPPBookContentTypeAudiobook) {
    self.cover.contentMode = UIViewContentModeScaleToFill;
  } else {
    self.cover.contentMode = UIViewContentModeScaleAspectFit;
  }
  
  [self setNeedsLayout];
}

- (void)setDelegate:(id<TPPBookButtonsDelegate>)delegate
{
  _delegate = delegate;
  self.buttonsView.delegate = delegate;
}

- (void)setState:(TPPBookButtonsState const)state
{
  _state = state;
  self.buttonsView.state = state;
  self.unreadImageView.hidden = (state != TPPBookButtonsStateDownloadSuccessful);
  [self setNeedsLayout];
}

@end
