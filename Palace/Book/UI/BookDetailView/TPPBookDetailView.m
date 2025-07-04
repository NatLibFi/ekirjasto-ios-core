#import "TPPAttributedString.h"
#import "TPPBookCellDelegate.h"
#import "TPPBookButtonsView.h"
#import "BookSelectionButtonsView.h"
#import "TPPBookDetailDownloadFailedView.h"
#import "TPPBookDetailDownloadingView.h"
#import "TPPBookDetailNormalView.h"
#import "TPPCatalogGroupedFeed.h"
#import "TPPCatalogGroupedFeedViewController.h"
#import "TPPCatalogLaneCell.h"
#import "TPPCatalogUngroupedFeed.h"
#import "TPPConfiguration.h"
#import "TPPBookDetailView.h"
#import "TPPConfiguration.h"
#import "TPPRootTabBarController.h"
#import "TPPOPDSAcquisition.h"
#import "TPPOPDSFeed.h"
#import "Palace-Swift.h"
#import "UIFont+TPPSystemFontOverride.h"
#import <PureLayout/PureLayout.h>

@interface TPPBookDetailView () <TPPBookDownloadCancellationDelegate, TPPBookButtonsSampleDelegate, BookDetailTableViewDelegate>

@property (nonatomic, weak) id<TPPBookDetailViewDelegate, TPPCatalogLaneCellDelegate> detailViewDelegate;

@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *audiobookSampleToolbar;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIVisualEffectView *visualEffectView;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UILabel *bookFormatLabel;
@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) UIImageView *blurCoverImageView;
@property (nonatomic) TPPContentBadgeImageView *contentTypeBadge;
@property (nonatomic) UIButton *closeButton;

@property (nonatomic) TPPBookButtonsView *buttonsView;
@property (nonatomic) BookSelectionButtonsView *selectionButtonsView;
@property (nonatomic) TPPBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) TPPBookDetailDownloadingView *downloadingView;
@property (nonatomic) TPPBookDetailNormalView *normalView;

@property (nonatomic) EkirjastoRoundedLabel *summarySectionLabel; //Edited by Ellibs
@property (nonatomic) UITextView *summaryTextView;
@property (nonatomic) NSLayoutConstraint *textHeightConstraint;
@property (nonatomic) UIButton *readMoreLabel;

@property (nonatomic) EkirjastoRoundedLabel *infoSectionLabel;
@property (nonatomic) UILabel *publishedLabelKey;
@property (nonatomic) UILabel *publisherLabelKey;
@property (nonatomic) UILabel *categoriesLabelKey;
//@property (nonatomic) UILabel *distributorLabelKey;
@property (nonatomic) UILabel *bookFormatLabelKey;
@property (nonatomic) UILabel *narratorsLabelKey;
@property (nonatomic) UILabel *bookDurationLabelKey;
@property (nonatomic) UILabel *bookLanguageLabelKey;
@property (nonatomic) UILabel *isbnLabelKey;
@property (nonatomic) UILabel *translatorsLabelKey;
@property (nonatomic) UILabel *illustratorsLabelKey;
@property (nonatomic) UILabel *accessibilityFeaturesLabelKey;
@property (nonatomic) UILabel *accessibilitySummaryLabelKey;
@property (nonatomic) UILabel *accessModeLabelKey;
@property (nonatomic) UILabel *publishedLabelValue;
@property (nonatomic) UILabel *publisherLabelValue;
@property (nonatomic) UILabel *categoriesLabelValue;
//@property (nonatomic) UILabel *distributorLabelValue;
@property (nonatomic) UILabel *bookFormatLabelValue;
@property (nonatomic) UILabel *narratorsLabelValue;
@property (nonatomic) UILabel *bookDurationLabelValue;
@property (nonatomic) UILabel *bookLanguageLabelValue;
@property (nonatomic) UILabel *isbnLabelValue;
@property (nonatomic) UILabel *translatorsLabelValue;
@property (nonatomic) UILabel *accessibilityFeaturesLabelValue;
@property (nonatomic) UILabel *accessibilitySummaryLabelValue;
@property (nonatomic) UILabel *accessModeLabelValue;
@property (nonatomic) UILabel *illustratorsLabelValue;

@property (nonatomic) TPPBookDetailTableView *footerTableView;

@property (nonatomic) UIView *topFootnoteSeparater;
@property (nonatomic) UIView *bottomFootnoteSeparator;

@end

static CGFloat const SubtitleBaselineOffset = 25;
static CGFloat const AuthorBaselineOffset = 12;
static CGFloat const CoverImageAspectRatio = 0.9;
static CGFloat const CoverImageMaxWidth = 130;
static CGFloat const TabBarHeight = 80.0;
static CGFloat const SampleToolbarHeight = 80.0;
static CGFloat const TitleLabelMinimumWidth = 185.0;
static CGFloat const SelectionButtonMinimumWidth = 25.0;
static CGFloat const NormalViewMinimumHeight = 38.0;
static CGFloat const VerticalPadding = 20.0;
static CGFloat const MainTextPaddingLeft = 30.0;
static NSString *DetailHTMLTemplate = nil;

@implementation TPPBookDetailView

// designated initializer
- (instancetype)initWithBook:(TPPBook *const)book
                    delegate:(id)delegate
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.book = book;
  self.detailViewDelegate = delegate;
  self.backgroundColor = [TPPConfiguration backgroundColor];
  self.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.scrollView = [[UIScrollView alloc] init];
  self.scrollView.alwaysBounceVertical = YES;
  
  self.containerView = [[UIView alloc] init];

  [self createHeaderLabels];
  [self createButtonsView];
  [self createSelectionButtonsView];
  [self createBookDescriptionViews];
  [self createFooterLabels];
  [self createDownloadViews];
  [self updateFonts];
  
  [self addSubview:self.scrollView];
  [self.scrollView addSubview:self.containerView];
  
  if (self.book.showAudiobookToolbar) {
    self.audiobookSampleToolbar = [[AudiobookSampleToolbarWrapper createWithBook:self.book] view];
    [self addSubview: self.audiobookSampleToolbar];
  }

  [self.containerView addSubview:self.blurCoverImageView];
  [self.containerView addSubview:self.visualEffectView];
  [self.containerView addSubview:self.coverImageView];
  [self.containerView addSubview:self.contentTypeBadge];
  [self.containerView addSubview:self.titleLabel];
  [self.containerView addSubview:self.subtitleLabel];
  [self.containerView addSubview:self.bookFormatLabel];
  [self.containerView addSubview:self.authorsLabel];
  [self.containerView addSubview:self.buttonsView];
  [self.containerView addSubview:self.selectionButtonsView];
  [self.containerView addSubview:self.summarySectionLabel];
  [self.containerView addSubview:self.summaryTextView];
  [self.containerView addSubview:self.readMoreLabel];
  [self.containerView addSubview:self.topFootnoteSeparater];
  [self.containerView addSubview:self.infoSectionLabel];
  [self.containerView addSubview:self.publishedLabelKey];
  [self.containerView addSubview:self.publisherLabelKey];
  [self.containerView addSubview:self.bookLanguageLabelKey];
  [self.containerView addSubview:self.categoriesLabelKey];
  //[self.containerView addSubview:self.distributorLabelKey];
  [self.containerView addSubview:self.bookFormatLabelKey];
  [self.containerView addSubview:self.isbnLabelKey];
  [self.containerView addSubview:self.translatorsLabelKey];
  [self.containerView addSubview:self.narratorsLabelKey];
  [self.containerView addSubview:self.illustratorsLabelKey];
  [self.containerView addSubview:self.accessModeLabelKey];
  [self.containerView addSubview:self.accessibilityFeaturesLabelKey];
  [self.containerView addSubview:self.accessibilitySummaryLabelKey];

  if (self.book.isAudiobook) {
    [self.containerView addSubview:self.bookDurationLabelKey];
  }

  [self.containerView addSubview:self.publishedLabelValue];
  [self.containerView addSubview:self.publisherLabelValue];
  [self.containerView addSubview:self.bookLanguageLabelValue];
  [self.containerView addSubview:self.categoriesLabelValue];
  //[self.containerView addSubview:self.distributorLabelValue];
  [self.containerView addSubview:self.bookFormatLabelValue];
  [self.containerView addSubview:self.isbnLabelValue];
  [self.containerView addSubview:self.translatorsLabelValue];
  [self.containerView addSubview:self.narratorsLabelValue];
  [self.containerView addSubview:self.illustratorsLabelValue];
  [self.containerView addSubview:self.accessModeLabelValue];
  [self.containerView addSubview:self.accessibilityFeaturesLabelValue];
  [self.containerView addSubview:self.accessibilitySummaryLabelValue];
  
  if (self.book.isAudiobook) {
    [self.containerView addSubview:self.bookDurationLabelValue];
  }
  
  [self.containerView addSubview:self.footerTableView];
  [self.containerView addSubview:self.bottomFootnoteSeparator];
  
  if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad &&
     [[TPPRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[TPPConfiguration mainColor] forState:UIControlStateNormal];
    [self.closeButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [self.closeButton setContentEdgeInsets:UIEdgeInsetsMake(0, 2, 0, 0)];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchDown];
    [self.containerView addSubview:self.closeButton];
  }

  self.containerView.layoutMargins = UIEdgeInsetsMake(self.layoutMargins.top,
                                                    self.layoutMargins.left+12,
                                                    self.layoutMargins.bottom,
                                                    self.layoutMargins.right+12);
  
  return self;
}

- (void)updateFonts
{
  self.titleLabel.font = [UIFont palaceFontOfSize:18]; //Edited by Ellibs
  self.subtitleLabel.font = [UIFont palaceFontOfSize:14]; //Edited by Ellibs
  self.bookFormatLabel.font = [UIFont palaceFontOfSize:12];
  self.authorsLabel.font = [UIFont palaceFontOfSize:14]; //Edited by Ellibs
  self.readMoreLabel.titleLabel.font = [UIFont palaceFontOfSize:18];
  self.summarySectionLabel.font = [UIFont palaceFontOfSize:18]; //Edited by Ellibs
  self.infoSectionLabel.font = [UIFont palaceFontOfSize:16]; //Edited by Ellibs
  [self.footerTableView reloadData];
}

- (void)createButtonsView
{
  self.buttonsView = [[TPPBookButtonsView alloc] initWithSamplesEnabled: NO];
  [self.buttonsView configureForBookDetailsContext];
  self.buttonsView.translatesAutoresizingMaskIntoConstraints = NO;
  self.buttonsView.showReturnButtonIfApplicable = YES;
  self.buttonsView.delegate = [TPPBookCellDelegate sharedDelegate];
  self.buttonsView.downloadingDelegate = self;
  self.buttonsView.sampleDelegate = self;
  self.buttonsView.book = self.book;
}

- (void)createSelectionButtonsView
{
  self.selectionButtonsView = [[BookSelectionButtonsView alloc]
                               initWithBook:self.book
                               delegate:[TPPBookCellDelegate sharedDelegate]
  ];
  self.selectionButtonsView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)createBookDescriptionViews
{
  self.summarySectionLabel = [[EkirjastoRoundedLabel alloc] init]; //Edited by Ellibs
  self.summarySectionLabel.text = NSLocalizedString(@"Description", nil);
  self.infoSectionLabel = [[EkirjastoRoundedLabel alloc] init];
  self.infoSectionLabel.text = NSLocalizedString(@"Information", nil);
  
  self.summaryTextView = [[UITextView alloc] init];
  self.summaryTextView.backgroundColor = [UIColor clearColor];
  self.summaryTextView.scrollEnabled = NO;
  self.summaryTextView.editable = NO;
  self.summaryTextView.clipsToBounds = YES;
  self.summaryTextView.textContainer.lineFragmentPadding = 0;
  self.summaryTextView.textContainerInset = UIEdgeInsetsZero;
  self.summaryTextView.adjustsFontForContentSizeCategory = YES;

  NSString *htmlString = [[NSString stringWithFormat:DetailHTMLTemplate,
                           [UIFont palaceFontOfSize:18], //Edited by Ellibs
                           self.book.summary ?: @""] stringByDecodingHTMLEntities];

  NSData *htmlData = [htmlString dataUsingEncoding:NSUnicodeStringEncoding];
  NSAttributedString *attrString;
  if (htmlData) {
    NSError *error = nil;
    attrString = [[NSAttributedString alloc]
                  initWithData:htmlData
                  options:@{NSDocumentTypeDocumentAttribute:
                              NSHTMLTextDocumentType}
                  documentAttributes:nil
                  error:&error];
    if (error) {
      TPPLOG_F(@"Attributed string rendering error for %@ book description: %@",
                [self.book loggableShortString], error);
    }
  } else {
    attrString = [[NSAttributedString alloc] initWithString:@""];
  }
  self.summaryTextView.attributedText = attrString;
  self.summaryTextView.font = [UIFont palaceFontOfSize:16];
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    // this needs to happen asynchronously because the HTML text may overwrite
    // our color
    self.summaryTextView.textColor = UIColor.defaultLabelColor;
  }];

  self.readMoreLabel = [[UIButton alloc] init];
  self.readMoreLabel.hidden = YES;
  self.readMoreLabel.titleLabel.textAlignment = NSTextAlignmentRight;
  self.readMoreLabel.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft; //Added by Ellibs
  UIImage *readmoreArrow = [UIImage imageNamed:@"ArrowRight"]; //Added by Ellibs
  [self.readMoreLabel setImage:readmoreArrow forState:UIControlStateNormal]; //Added by Ellibs
  self.readMoreLabel.tintColor = [TPPConfiguration iconColor]; //Added by Ellibs
  self.readMoreLabel.imageEdgeInsets = UIEdgeInsetsMake(1, 10, -1, 0); //Added by Ellibs
  self.readMoreLabel.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10); //Added by Ellibs
  [self.readMoreLabel setTitleColor:[TPPConfiguration compatiblePrimaryColor] forState:UIControlStateNormal]; //Added by Ellibs
  [self.readMoreLabel addTarget:self action:@selector(readMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.readMoreLabel setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
  [self.readMoreLabel setTitle:NSLocalizedString(@"Read more", nil) forState:UIControlStateNormal]; //Edited by Ellibs
  [self.readMoreLabel setTitleColor:[TPPConfiguration mainColor] forState:UIControlStateNormal];
}

- (void)createHeaderLabels
{
  //UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
  //self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  if (@available(iOS 11.0, *)) {
    self.coverImageView.accessibilityIgnoresInvertColors = YES;
  }
  self.blurCoverImageView = [[UIImageView alloc] init];
  self.blurCoverImageView.contentMode = UIViewContentModeScaleAspectFit;
  if (@available(iOS 11.0, *)) {
    self.blurCoverImageView.accessibilityIgnoresInvertColors = YES;
  }
  self.blurCoverImageView.alpha = 0.4f;

  [[TPPBookRegistry shared]
   coverImageFor:self.book handler:^(UIImage *image) {
    self.coverImageView.image = image;
    self.blurCoverImageView.image = image;
  }];

  self.contentTypeBadge = [[TPPContentBadgeImageView alloc] initWithBadgeImage:TPPBadgeImageAudiobook];
  self.contentTypeBadge.hidden = YES;

  if ([self.book defaultBookContentType] == TPPBookContentTypeAudiobook) {
    self.contentTypeBadge.hidden = NO;
  }

  self.bookFormatLabel = [[UILabel alloc] init];
  self.bookFormatLabel.text = self.book.generalBookFormat;

  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.numberOfLines = 0;
  self.titleLabel.attributedText = TPPAttributedStringForTitleFromString(self.book.title);

  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.attributedText = TPPAttributedStringForSubtitleFromString(self.book.subtitle);
  self.subtitleLabel.numberOfLines = 0;

  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authorsLabel.numberOfLines = 0;

  if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad &&
      [[TPPRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    self.authorsLabel.text = self.book.authors;
  } else {
    self.authorsLabel.attributedText = TPPAttributedStringForAuthorsFromString(self.book.authors);
  }
}

- (void)createDownloadViews
{
  self.normalView = [[TPPBookDetailNormalView alloc] init];
  self.normalView.translatesAutoresizingMaskIntoConstraints = NO;
  self.normalView.book = self.book;
  self.normalView.hidden = YES;

  self.downloadFailedView = [[TPPBookDetailDownloadFailedView alloc] init];
  self.downloadFailedView.hidden = YES;

  self.downloadingView = [[TPPBookDetailDownloadingView alloc] init];
  self.downloadingView.hidden = YES;

  [self.containerView addSubview:self.normalView];
  [self.containerView addSubview:self.downloadFailedView];
  [self.containerView addSubview:self.downloadingView];
}

- (void)createFooterLabels
{
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeStyle = NSDateFormatterNoStyle;
  dateFormatter.dateStyle = NSDateFormatterLongStyle;
  dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

  NSString *const publishedKeyString =
  self.book.published
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Published", nil)]
  : nil;

  NSString *const publisherKeyString =
  self.book.publisher
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Publisher", nil)]
  : nil;

  NSString *const categoriesKeyString =
  self.book.categoryStrings.count
  ? [NSString stringWithFormat:@"%@: ",
     (self.book.categoryStrings.count == 1
      ? NSLocalizedString(@"Category", nil)
      : NSLocalizedString(@"Categories", nil))]
  : nil;

  NSString *const bookLanguageKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"Language", "")];
  NSString *const bookFormatKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"Book format", nil)];
  NSString *const isbnKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"ISBN", nil)];
  NSString *const narratorsKeyString =
    self.book.narrators ? [NSString stringWithFormat:@"%@: ", NSLocalizedString(@"Narrators", nil)] : nil;
  NSString *const translatorsKeyString = self.book.translators ? [NSString stringWithFormat:@"%@: ", NSLocalizedString(@"Translators", nil)] : nil;
  
  NSString *const accessModeKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"Access mode", nil)];
  NSString *const accessibilityFeaturesKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"Accessibility features", nil)];
  NSString *const accessibilitySummaryKeyString = [NSString stringWithFormat:@"%@: ",NSLocalizedString(@"Accessibility summary", nil)];
  
  NSString *const illustratorsKeyString = self.book.illustrators ? [NSString stringWithFormat:@"%@: ", NSLocalizedString(@"Illustrators", nil)] : nil;
  NSString *const bookDurationKeyString = [NSString stringWithFormat:@"%@:", NSLocalizedString(@"Duration", nil)];

  NSString *const categoriesValueString = self.book.categories;
  NSString *const bookLanguageValueString = self.book.language;
  NSDateComponents* publishedComponents = self.book.publishedComponents;
  NSString *publishedValueString;
  
  if(publishedComponents != nil && publishedComponents.day == 1 && publishedComponents.month == 1) {
    publishedValueString = [NSString stringWithFormat:@"%ld",  publishedComponents.year];
  }else{
    publishedValueString = self.book.published ? [dateFormatter stringFromDate:self.book.published] : nil;
  }

  NSString *const publisherValueString = self.book.publisher;
  //NSString *const distributorKeyString = self.book.distributor ? [NSString stringWithFormat:NSLocalizedString(@"Distributed by: ", nil)] : nil;
  NSString *const bookFormatValueString = self.book.format;
  NSString *isbn = self.book.identifier;
  if([isbn containsString:@"urn:isbn:"]){
    isbn = [isbn substringFromIndex:9];
  }
  NSString *const isbnValueString = isbn;//self.book.identifier;
  NSString *const narratorsValueString = self.book.narrators;
  NSString *const illustratorsValueString = self.book.illustrators;
  NSString *const translatorsValueString = self.book.translators;
  
  NSString *const accessModeValueString = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Not yet available", nil)];
  NSString *const accessibilityFeaturesValueString = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Not yet available", nil)];
  NSString *const accessibilitySummaryValueString = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Not yet available", nil)];
  
  NSString *const bookDurationValueString = [self displayStringForDuration: self.book.bookDuration];
  
  if (!categoriesValueString && !publishedValueString && !publisherValueString && !self.book.distributor) {
    self.topFootnoteSeparater.hidden = YES;
    self.bottomFootnoteSeparator.hidden = YES;
  }

  self.bookLanguageLabelKey = [self createFooterLabelWithString:bookLanguageKeyString alignment:NSTextAlignmentRight];
  self.categoriesLabelKey = [self createFooterLabelWithString:categoriesKeyString alignment:NSTextAlignmentRight];
  self.publisherLabelKey = [self createFooterLabelWithString:publisherKeyString alignment:NSTextAlignmentRight];
  self.publishedLabelKey = [self createFooterLabelWithString:publishedKeyString alignment:NSTextAlignmentRight];
  //self.distributorLabelKey = [self createFooterLabelWithString:distributorKeyString alignment:NSTextAlignmentRight];
  self.bookFormatLabelKey = [self createFooterLabelWithString:bookFormatKeyString alignment:NSTextAlignmentRight];
  self.isbnLabelKey = [self createFooterLabelWithString:isbnKeyString alignment:NSTextAlignmentRight];
  self.narratorsLabelKey = [self createFooterLabelWithString:narratorsKeyString alignment:NSTextAlignmentRight];
  self.illustratorsLabelKey = [self createFooterLabelWithString:illustratorsKeyString alignment:NSTextAlignmentRight];
  self.translatorsLabelKey = [self createFooterLabelWithString:translatorsKeyString alignment:NSTextAlignmentRight];
  
  self.accessModeLabelKey = [self createFooterLabelWithString:accessModeKeyString alignment:NSTextAlignmentRight];
  self.accessibilityFeaturesLabelKey = [self createFooterLabelWithString:accessibilityFeaturesKeyString alignment:NSTextAlignmentRight];
  self.accessibilitySummaryLabelKey = [self createFooterLabelWithString:accessibilitySummaryKeyString alignment:NSTextAlignmentRight];
  
  self.bookDurationLabelKey = [self createFooterLabelWithString:bookDurationKeyString alignment:NSTextAlignmentRight];

  self.bookLanguageLabelValue = [self createFooterLabelWithString:bookLanguageValueString alignment:NSTextAlignmentLeft];
  self.categoriesLabelValue = [self createFooterLabelWithString:categoriesValueString alignment:NSTextAlignmentLeft];
  self.categoriesLabelValue.numberOfLines = 2;
  self.publisherLabelValue = [self createFooterLabelWithString:publisherValueString alignment:NSTextAlignmentLeft];
  self.publisherLabelValue.numberOfLines = 2;
  self.publishedLabelValue = [self createFooterLabelWithString:publishedValueString alignment:NSTextAlignmentLeft];
  //self.distributorLabelValue = [self createFooterLabelWithString:self.book.distributor alignment:NSTextAlignmentLeft];
  self.bookFormatLabelValue = [self createFooterLabelWithString:bookFormatValueString alignment:NSTextAlignmentLeft];
  self.isbnLabelValue = [self createFooterLabelWithString:isbnValueString alignment:NSTextAlignmentLeft];
  self.narratorsLabelValue = [self createFooterLabelWithString:narratorsValueString alignment:NSTextAlignmentLeft];
  self.translatorsLabelValue = [self createFooterLabelWithString:translatorsValueString alignment:NSTextAlignmentLeft];
  self.illustratorsLabelValue = [self createFooterLabelWithString:illustratorsValueString alignment:NSTextAlignmentLeft];
  self.accessModeLabelValue = [self createFooterLabelWithString:accessModeValueString alignment:NSTextAlignmentRight];
  self.accessibilityFeaturesLabelValue = [self createFooterLabelWithString:accessibilityFeaturesValueString alignment:NSTextAlignmentRight];
  self.accessibilitySummaryLabelValue = [self createFooterLabelWithString:accessibilitySummaryValueString alignment:NSTextAlignmentRight];
  self.bookDurationLabelValue = [self createFooterLabelWithString:bookDurationValueString alignment:NSTextAlignmentLeft];
  self.narratorsLabelValue.numberOfLines = 0;

  self.topFootnoteSeparater = [[UIView alloc] init];
  self.topFootnoteSeparater.backgroundColor = [TPPConfiguration inactiveIconColor]; //Edited by Ellibs
  self.bottomFootnoteSeparator = [[UIView alloc] init];
  self.bottomFootnoteSeparator.backgroundColor = [TPPConfiguration inactiveIconColor]; //Edited by Ellibs

  self.footerTableView = [[TPPBookDetailTableView alloc] init];
  self.footerTableView.isAccessibilityElement = NO;
  self.tableViewDelegate = [[TPPBookDetailTableViewDelegate alloc] init:self.footerTableView book:self.book];
  self.tableViewDelegate.viewDelegate = self;
  self.tableViewDelegate.laneCellDelegate = self.detailViewDelegate;
  self.footerTableView.delegate = self.tableViewDelegate;
  self.footerTableView.dataSource = self.tableViewDelegate;
  [self.tableViewDelegate load];
}

- (UILabel *)createFooterLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment
{
  UILabel *label = [[UILabel alloc] init];
  label.textAlignment = alignment;
  label.text = string;
  label.font = [UIFont palaceFontOfSize:14]; //Edited by Ellibs
  return label;
}

  // Returns the book's duration as a localized string, formatted from its total duration in seconds.
- (NSString *) displayStringForDuration: (NSString *) durationInSeconds {
  double totalSeconds = [durationInSeconds doubleValue];
  
  int hours = (int)(totalSeconds / 3600);
  int minutes = (int)((totalSeconds - (hours * 3600)) / 60);
  
  NSString *hoursAsString = [NSString stringWithFormat:@"%d", hours];
  NSString *minutesAsString = [NSString stringWithFormat:@"%d", minutes];
  
  // Checks whether to use the singular form instead of the plural (hour or hours, minute or minutes)
  // and then formats the hour and minute units accordingly
  NSString *hourTimeUnit = hours == 1 ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);
  NSString *minuteTimeUnit = minutes == 1 ? NSLocalizedString(@"minute", nil) : NSLocalizedString(@"minutes", nil);
  
  NSString *durationAsString;
  
  if (hours > 0) {
    // Always show minutes if the book is at least 1 hour long (even if it is just 1 hour, 0 minutes)
    // Examples: "3 hours, 33 minutes" "1 hour, 33 minutes" "1 hour, 1 minute"
    durationAsString = [NSString stringWithFormat:@"%@ %@, %@ %@", hoursAsString, hourTimeUnit, minutesAsString, minuteTimeUnit];
  } else {
    // but if the book is less than an hour long, only show the minutes (don't show zero hours)
    // Example: "33 minutes" "1 minute"
    durationAsString = [NSString stringWithFormat:@"%@ %@", minutesAsString, minuteTimeUnit];
  }
  
  return durationAsString;
}

- (void)setupAutolayoutConstraints
{
  [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];

  if ([self.book showAudiobookToolbar]) {
    [self.audiobookSampleToolbar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.audiobookSampleToolbar autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.audiobookSampleToolbar autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:TabBarHeight];
    [self.audiobookSampleToolbar autoSetDimension:ALDimensionHeight toSize:SampleToolbarHeight relation:NSLayoutRelationLessThanOrEqual];
    [self.audiobookSampleToolbar autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    [self.scrollView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView: self.audiobookSampleToolbar];
  } else {
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
  }

  [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.scrollView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView];

  [self.containerView autoPinEdgesToSuperviewEdges];
  [self.containerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];

  [self.visualEffectView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
  [self.visualEffectView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.normalView];

  [self.coverImageView autoPinEdgeToSuperviewMargin:ALEdgeLeft]; //Edited by Ellibs
  [self.coverImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:VerticalPadding];
  [self.coverImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.coverImageView withMultiplier:CoverImageAspectRatio];
  [self.coverImageView autoSetDimension:ALDimensionWidth toSize:CoverImageMaxWidth relation:NSLayoutRelationLessThanOrEqual];
  [self.blurCoverImageView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  [self.blurCoverImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.coverImageView];

  [TPPContentBadgeImageView pinWithBadge:self.contentTypeBadge toView:self.coverImageView isLane:NO];

  [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  [self.titleLabel autoSetDimension:ALDimensionWidth toSize:TitleLabelMinimumWidth relation:NSLayoutRelationGreaterThanOrEqual];
  [self.titleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.selectionButtonsView];

  [self.selectionButtonsView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.titleLabel];
  [self.selectionButtonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  [self.selectionButtonsView autoSetDimension:ALDimensionWidth toSize:SelectionButtonMinimumWidth]; //relation:NSLayoutRelationGreaterThanOrEqual];
  NSLayoutConstraint *selectionButtonConstraint = [self.selectionButtonsView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];

  [self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.subtitleLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel withOffset:10]; //Edited by Ellibs
  [self.subtitleLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.titleLabel withOffset:SubtitleBaselineOffset];

  [self.bookFormatLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.bookFormatLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
  if (self.subtitleLabel.text) {
    [self.bookFormatLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.subtitleLabel withOffset:AuthorBaselineOffset];
  } else {
    [self.bookFormatLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.titleLabel withOffset:AuthorBaselineOffset];
  }

  [self.authorsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.authorsLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
  if (self.bookFormatLabel.text) {
    [self.authorsLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.bookFormatLabel withOffset:AuthorBaselineOffset];
  } else if (self.subtitleLabel.text) {
    [self.authorsLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.subtitleLabel withOffset:AuthorBaselineOffset];
  } else {
    [self.authorsLabel autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBaseline ofView:self.titleLabel withOffset:AuthorBaselineOffset];
  }

  [self.buttonsView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.buttonsView autoPinEdgeToSuperviewMargin:ALEdgeRight];

  double fontMultiplier = [[NSUserDefaults standardUserDefaults] doubleForKey:@"fontMultiplier"];

  // This workaround that handles the user setting a font size preference via app settings
  // might also add some visually unnecessary extra space between coverimage and buttonsview
  // when the default text size is used
  if (fontMultiplier == 2.0) {
    [self.buttonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorsLabel withOffset:50 relation:NSLayoutRelationGreaterThanOrEqual];
  } else {
    [self.buttonsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorsLabel withOffset:85 relation:NSLayoutRelationGreaterThanOrEqual];
  }

  [self.normalView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.normalView autoSetDimension:ALDimensionHeight toSize:NormalViewMinimumHeight relation:NSLayoutRelationGreaterThanOrEqual];

  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadingView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.downloadingView autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:self.normalView];

  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadFailedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.buttonsView withOffset:VerticalPadding];
  [self.downloadFailedView autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:self.normalView];

  [self.summarySectionLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.summarySectionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.normalView withOffset:VerticalPadding + 4];

  [self.summaryTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summarySectionLabel withOffset:VerticalPadding];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  self.textHeightConstraint = [self.summaryTextView autoSetDimension:ALDimensionHeight toSize:SummaryTextAbbreviatedHeight relation:NSLayoutRelationLessThanOrEqual];

  [self.readMoreLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.readMoreLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.readMoreLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summaryTextView];
  [self.readMoreLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.topFootnoteSeparater withOffset:-15]; //Edited by Ellibs

  [self.infoSectionLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];

  [self.publishedLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.publishedLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bookLanguageLabelValue];
  [self.publishedLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.publishedLabelKey withOffset:MainTextPaddingLeft];

  [self.publisherLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.publisherLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publishedLabelValue];
  [self.publisherLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.publisherLabelKey withOffset:MainTextPaddingLeft];

  if (self.bookLanguageLabelValue.text) {
    [self.bookLanguageLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
    [self.bookLanguageLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.infoSectionLabel withOffset:VerticalPadding];
    [self.bookLanguageLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.bookLanguageLabelKey withOffset:MainTextPaddingLeft];
  }

  [self.categoriesLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.categoriesLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publisherLabelValue];
  [self.categoriesLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.categoriesLabelKey withOffset:MainTextPaddingLeft];

  /*[self.distributorLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.distributorLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.categoriesLabelValue];
  [self.distributorLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.distributorLabelKey withOffset:MainTextPaddingLeft];*/

  [self.bookFormatLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.bookFormatLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.categoriesLabelValue];
  [self.bookFormatLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.bookFormatLabelKey withOffset:MainTextPaddingLeft];

  [self.isbnLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.isbnLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bookFormatLabelValue];
  [self.isbnLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.isbnLabelKey withOffset:MainTextPaddingLeft];

  [self.translatorsLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.translatorsLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.isbnLabelValue];
  [self.translatorsLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.translatorsLabelKey withOffset:MainTextPaddingLeft];

  [self.narratorsLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.narratorsLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.translatorsLabelValue];
  [self.narratorsLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.narratorsLabelKey withOffset:MainTextPaddingLeft];

  [self.illustratorsLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.illustratorsLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.narratorsLabelValue];
  [self.illustratorsLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey withOffset:MainTextPaddingLeft];
  
  [self.accessModeLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.accessModeLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.illustratorsLabelValue];
  [self.accessModeLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.accessModeLabelKey withOffset:MainTextPaddingLeft];
  
  [self.accessibilityFeaturesLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.accessibilityFeaturesLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accessModeLabelValue];
  [self.accessibilityFeaturesLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.accessibilityFeaturesLabelKey withOffset:MainTextPaddingLeft];
  
  [self.accessibilitySummaryLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
  [self.accessibilitySummaryLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accessibilityFeaturesLabelValue];
  [self.accessibilitySummaryLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.accessibilitySummaryLabelKey withOffset:MainTextPaddingLeft];

  if (self.book.hasDuration) {
    [self.bookDurationLabelValue autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
    [self.bookDurationLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accessibilitySummaryLabelValue];
    [self.bookDurationLabelValue autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.bookDurationLabelKey withOffset:MainTextPaddingLeft];
  }

  //[self.publishedLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.publishedLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.publishedLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.publisherLabelKey];
  [self.publishedLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publishedLabelValue];
  [self.publishedLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.publisherLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.publisherLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.bookLanguageLabelKey];
  [self.publisherLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publisherLabelValue];
  [self.publisherLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.bookLanguageLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.bookLanguageLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.bookFormatLabelKey];
  [self.bookLanguageLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.bookLanguageLabelValue];
  [self.bookLanguageLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.categoriesLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.categoriesLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.bookFormatLabelKey];
  [self.categoriesLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.categoriesLabelValue];
  [self.categoriesLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  /*[self.distributorLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.distributorLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.bookFormatLabelKey];
  [self.distributorLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.distributorLabelValue];
  [self.distributorLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];*/

  [self.bookFormatLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.bookFormatLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.isbnLabelKey];
  [self.bookFormatLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.bookFormatLabelValue];
  [self.bookFormatLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.isbnLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.isbnLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.translatorsLabelKey];
  [self.isbnLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.isbnLabelValue];
  [self.isbnLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.translatorsLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.translatorsLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.narratorsLabelKey];
  [self.translatorsLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.translatorsLabelValue];
  [self.translatorsLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.narratorsLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.narratorsLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey];
  [self.narratorsLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.narratorsLabelValue];
  [self.narratorsLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  [self.illustratorsLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.illustratorsLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.translatorsLabelKey];
  [self.illustratorsLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.illustratorsLabelValue];
  [self.illustratorsLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  
  [self.accessModeLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.accessModeLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey];
  [self.accessModeLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.accessModeLabelValue];
  [self.accessModeLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  
  [self.accessibilityFeaturesLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.accessibilityFeaturesLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey];
  [self.accessibilityFeaturesLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.accessibilityFeaturesLabelValue];
  [self.accessibilityFeaturesLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  
  [self.accessibilitySummaryLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.accessibilitySummaryLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey];
  [self.accessibilitySummaryLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.accessibilitySummaryLabelValue];
  [self.accessibilitySummaryLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  if (self.book.hasDuration) {
    [self.bookDurationLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeading];
    [self.bookDurationLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.bookDurationLabelValue];
    [self.bookDurationLabelKey autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.illustratorsLabelKey];
    [self.bookDurationLabelKey setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  }

  if (self.closeButton) {
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    [self.closeButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.titleLabel];
    [self.closeButton autoSetDimension:ALDimensionWidth toSize:80 relation:NSLayoutRelationLessThanOrEqual];
    [NSLayoutConstraint deactivateConstraints:@[selectionButtonConstraint]];
    [self.closeButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.titleLabel withOffset:MainTextPaddingLeft];
    [self.closeButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  }

  [self.topFootnoteSeparater autoSetDimension:ALDimensionHeight toSize: 1.0f / [UIScreen mainScreen].scale];
  [self.topFootnoteSeparater autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.topFootnoteSeparater autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.topFootnoteSeparater autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.infoSectionLabel withOffset:-VerticalPadding];

  [self.bottomFootnoteSeparator autoSetDimension:ALDimensionHeight toSize: 1.0f / [UIScreen mainScreen].scale];
  [self.bottomFootnoteSeparator autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.bottomFootnoteSeparator autoPinEdgeToSuperviewMargin:ALEdgeLeft];

  if (self.book.hasDuration) {
    [self.bottomFootnoteSeparator autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bookDurationLabelKey withOffset:VerticalPadding];
  } else {
    [self.bottomFootnoteSeparator autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accessibilitySummaryLabelValue withOffset:VerticalPadding];
  }

  [self.footerTableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 0) excludingEdge:ALEdgeTop];
  [self.footerTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accessibilitySummaryLabelValue withOffset:VerticalPadding];

}

#pragma mark NSObject

+ (void)initialize
{
  DetailHTMLTemplate = [NSString
                        stringWithContentsOfURL:[[NSBundle mainBundle]
                                                 URLForResource:@"DetailSummaryTemplate"
                                                 withExtension:@"html"]
                        encoding:NSUTF8StringEncoding
                        error:NULL];
  
  assert(DetailHTMLTemplate);
}

- (void)updateConstraints
{
  if (!self.didSetupConstraints) {
    [self setupAutolayoutConstraints];
    self.didSetupConstraints = YES;
  }
  [super updateConstraints];
}

#pragma mark TPPBookDownloadCancellationDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(__attribute__((unused)) TPPBookDetailDownloadingView *)bookDetailDownloadingView
{
  [self.detailViewDelegate didSelectCancelDownloadingForBookDetailView:self];
}

- (void)didSelectCancelForBookDetailDownloadFailedView:
(__attribute__((unused)) TPPBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView
{
  [self.detailViewDelegate didSelectCancelDownloadFailedForBookDetailView:self];
}

#pragma mark TPPBookSampleDelegate

NSString *PlaySampleNotification = @"ToggleSampleNotification";

- (void)didSelectPlaySample:(TPPBook *)book {
  if ([self.book defaultBookContentType] == TPPBookContentTypeAudiobook) {
    if ([self.book.sampleAcquisition.type isEqualToString: @"text/html"]) {
      [self presentWebView: self.book.sampleAcquisition.hrefURL];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:PlaySampleNotification object:self];
    }
  } else {
    [EpubSampleFactory createSampleWithBook:self.book completion:^(EpubLocationSampleURL *sampleURL, NSError *error) {
      if (error) {
         TPPLOG_F(@"Attributed string rendering error for %@ book description: %@",
                  [self.book loggableShortString], error);
       } else if ([sampleURL isKindOfClass:[EpubSampleWebURL class]]) {
         [self presentWebView:sampleURL.url];
       } else {
         [TPPRootTabBarController.sharedController presentSample:self.book url:sampleURL.url];
       }
    }];
  }
}
  
- (void)presentWebView:(NSURL *)url {
  BundledHTMLViewController *webController = [[BundledHTMLViewController alloc] initWithFileURL:url title:AccountsManager.shared.currentAccount.name];
  webController.hidesBottomBarWhenPushed = true;
  [TPPRootTabBarController.sharedController pushViewController:webController animated:YES];
}

#pragma mark -

- (void)setState:(TPPBookState)state
{
  _state = state;
  
  switch(state) {
    case TPPBookStateUnregistered:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsViewStateWithAvailability(self.book.defaultAcquisition.availability);
      self.buttonsView.state = self.normalView.state;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateDownloadNeeded:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsStateDownloadNeeded;
      self.buttonsView.state = TPPBookButtonsStateDownloadNeeded;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateSAMLStarted:
      self.downloadingView.downloadProgress = 0;
      self.downloadingView.downloadStarted = false;
    case TPPBookStateDownloading:
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:NO];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.buttonsView.state = TPPBookButtonsStateDownloadInProgress;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateDownloadFailed:
      [self.downloadFailedView configureFailMessageWithProblemDocument:[[TPPProblemDocumentCacheManager shared] getLastCachedDoc:self.book.identifier]];
      self.downloadFailedView.hidden = NO;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.buttonsView.state = TPPBookButtonsStateDownloadFailed;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateDownloadSuccessful:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsStateDownloadSuccessful;
      self.buttonsView.state = TPPBookButtonsStateDownloadSuccessful;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateHolding:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsViewStateWithAvailability(self.book.defaultAcquisition.availability);
      self.buttonsView.state = self.normalView.state;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateUsed:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsStateUsed;
      self.buttonsView.state = TPPBookButtonsStateUsed;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
    case TPPBookStateUnsupported:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      [self hideDownloadingView:YES];
      self.buttonsView.hidden = NO;
      self.selectionButtonsView.hidden = NO;
      self.normalView.state = TPPBookButtonsStateUnsupported;
      self.buttonsView.state = TPPBookButtonsStateUnsupported;
      self.selectionButtonsView.selectionState = BookSelectionButtonsViewStateWithBook(self.book);
      break;
  }
}

- (void)hideDownloadingView:(BOOL)shouldHide
{
  CGFloat duration = 0.5f;
  if (shouldHide) {
    if (!self.downloadingView.isHidden) {
      [UIView transitionWithView:self.downloadingView
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
        self.downloadingView.hidden = YES;
      } completion:^(__unused BOOL finished) {
        self.downloadingView.hidden = YES;
      }];
    }
  } else {
    if (self.downloadingView.isHidden) {
      [UIView transitionWithView:self.downloadingView
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
        self.downloadingView.hidden = NO;
      } completion:^(__unused BOOL finished) {
        self.downloadingView.hidden = NO;
      }];
    }
  }
}

- (void)setBook:(TPPBook *)book
{
  _book = book;
  self.normalView.book = book;
  self.buttonsView.book = book;
  self.selectionButtonsView.book = book;
}

- (double)downloadProgress
{
  return self.downloadingView.downloadProgress;
}

- (void)setDownloadProgress:(double)downloadProgress
{
  self.downloadingView.downloadProgress = downloadProgress;
}

- (BOOL)downloadStarted
{
  return self.downloadingView.downloadStarted;
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  self.downloadingView.downloadStarted = downloadStarted;
}

- (void)closeButtonPressed
{
  [self.detailViewDelegate didSelectCloseButton:self];
}

-(BOOL)accessibilityPerformEscape {
  [self.detailViewDelegate didSelectCloseButton:self];
  return YES;
}

- (void)reportProblemTapped
{
  [self.detailViewDelegate didSelectReportProblemForBook:self.book sender:self];
}

- (void)moreBooksTappedForLane:(TPPCatalogLane *)lane
{
  [self.detailViewDelegate didSelectMoreBooksForLane:lane];
}

- (void)readMoreTapped:(__unused UIButton *)sender
{
  self.textHeightConstraint.active = NO;
  [self.readMoreLabel removeFromSuperview];
  [self.topFootnoteSeparater autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summaryTextView withOffset:VerticalPadding];
}

- (void)viewIssuesTapped {
  [self.detailViewDelegate didSelectViewIssuesForBook:self.book sender:self];
}

- (void)stateChangedWithIsPlaying:(BOOL)isPlaying {}
@end
