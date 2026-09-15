#import "TPPBookDetailViewController.h"

#import "TPPCatalogFeedViewController.h"
#import "TPPCatalogGroupedFeed.h"
#import "TPPCatalogLane.h"
#import "TPPCatalogLaneCell.h"
#import "TPPCatalogSearchViewController.h"
#import "TPPConfiguration.h"
#import "TPPIndeterminateProgressView.h"
#import "TPPOpenSearchDescription.h"
#import "TPPXML.h"
#import "UIView+TPPViewAdditions.h"

#import "TPPCatalogFacet.h"
#import "Palace-Swift.h"
#import "TPPCatalogGroupedFeedViewController.h"

#import <PureLayout/PureLayout.h>

static CGFloat const kRowHeight = 115.0;
static CGFloat const kSectionHeaderHeight = 50.0;
static CGFloat const kTableViewInsetAdjustmentWithEntryPoints = -8;
static CGFloat const kTableViewCrossfadeDuration = 0.3;


@interface TPPCatalogGroupedFeedViewController ()
  <TPPCatalogLaneCellDelegate, TPPEntryPointViewDelegate, TPPFacetBarViewDelegate, TPPEntryPointViewDataSource, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate>

@property (nonatomic, weak) TPPRemoteViewController *remoteViewController;
@property (nonatomic) NSMutableDictionary *bookIdentifiersToImages;
@property (nonatomic) NSMutableDictionary *cachedLaneCells;
@property (nonatomic) TPPCatalogGroupedFeed *feed;
@property (nonatomic) NSUInteger indexOfNextLaneRequiringImageDownload;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) TPPOpenSearchDescription *searchDescription;
@property (nonatomic) TPPFacetBarView *facetBarView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) TPPBook *mostRecentBookSelected;
@property (nonatomic) int tempBookPosition;
@property (nonatomic) UITraitCollection *previouslyProcessedTraits;
@end

@implementation TPPCatalogGroupedFeedViewController

#pragma mark NSObject

- (instancetype)initWithGroupedFeed:(TPPCatalogGroupedFeed *const)feed
               remoteViewController:(TPPRemoteViewController *const)remoteViewController
{
  self = [super init];
  if(!self) return nil;
  
  self.bookIdentifiersToImages = [NSMutableDictionary dictionary];
  self.cachedLaneCells = [NSMutableDictionary dictionary];
  self.feed = feed;
  self.remoteViewController = remoteViewController;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userDidCloseBookDetail:)
                                               name:NSNotification.TPPBookDetailDidClose
                                             object:nil];

  return self;
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [TPPConfiguration backgroundColor];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(userDidRefresh:) forControlEvents:UIControlEventValueChanged];

  UITableViewStyle tableStyle = UITableViewStylePlain;
  if (@available(iOS 26, *)) {
    // Grouped style disables sticky section headers,
    // which avoids opaque headers clashing with the nav bar area.
    tableStyle = UITableViewStyleGrouped;
  }
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:tableStyle];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.alpha = 0.0;
  self.tableView.backgroundColor = [TPPConfiguration backgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  if (@available(iOS 26, *)) {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
      self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
      // Hide the top scroll edge fade so section headers near the top
      // are not blurred by the Liquid Glass nav bar effect.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 260000
      self.tableView.topEdgeEffect.hidden = YES;
#endif
    } else {
      // On iPhone iOS 26, use Never so the table doesn't extend
      // under the nav bar (matching pre-iOS 26 behavior).
      self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
  } else if (@available(iOS 11.0, *)) {
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  [self.tableView addSubview:self.refreshControl];
  [self.view addSubview:self.tableView];
  self.facetBarView = [[TPPFacetBarView alloc] initWithOrigin:CGPointZero width:self.view.bounds.size.width];
  self.facetBarView.entryPointView.delegate = self;
  self.facetBarView.entryPointView.dataSource = self;
  self.facetBarView.delegate = self;
  
  // On iPad with iOS 26, move the segmented control into the navigation bar
  // titleView so it merges with the Liquid Glass bar, and hide the facet bar.
  BOOL useNavBarSegmentedControl = NO;
  if (@available(iOS 26, *)) {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
      useNavBarSegmentedControl = YES;
    }
  }

  if (useNavBarSegmentedControl) {
    // Don't add the facet bar to the view at all on iPad iOS 26.
    // Instead, create a segmented control in the navigation bar.
    [self setupNavBarSegmentedControl];
  } else {
    [self.view addSubview:self.facetBarView];

    [self.facetBarView autoPinEdgeToSuperviewSafeArea:ALEdgeTop];// Added by Ellibs

    [self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
  }
  
  if(self.feed.openSearchURL) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithImage:[UIImage imageNamed:@"Search"]
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(didSelectSearch)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = NSLocalizedString(@"Search", nil);
    self.navigationItem.rightBarButtonItem.enabled = NO;

    // prevent possible unusable Search box when going to Search page
    // self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
    //                                          initWithTitle:NSLocalizedString(@"Back", @"Back button text")
    //                                          style:UIBarButtonItemStylePlain
    //                                          target:nil action:nil]; //Disabled by Ellibs
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName:[TPPConfiguration compatiblePrimaryColor]}; //Added by Ellibs
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back Button")  style:UIBarButtonItemStylePlain target:nil action:nil]; //Added by Ellibs
    [backButton setTitleTextAttributes:titleAttributes forState:UIControlStateNormal]; //Added by Ellibs
    self.navigationItem.backBarButtonItem = backButton; //Added by Ellibs
    
    [self fetchOpenSearchDescription];
  }
  
  [self downloadImages];
  [self enable3DTouch];
}

/// On iPad iOS 26, place the entry point segmented control (All/Audiobooks/eBooks)
/// directly in the navigation bar's titleView so it integrates with Liquid Glass.
- (void)setupNavBarSegmentedControl
{
  NSArray<TPPCatalogFacet *> *facets = self.feed.entryPoints;
  if (facets.count < 2) {
    return;
  }

  NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithCapacity:facets.count];
  for (TPPCatalogFacet *facet in facets) {
    if (facet.title) {
      [titles addObject:facet.title];
    }
  }
  if (titles.count < 2) {
    return;
  }

  UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:titles];
  for (NSUInteger i = 0; i < facets.count; i++) {
    if (facets[i].active) {
      segmentedControl.selectedSegmentIndex = i;
      break;
    }
  }
  [segmentedControl addTarget:self
                       action:@selector(navBarSegmentDidChange:)
             forControlEvents:UIControlEventValueChanged];

  self.remoteViewController.navigationItem.titleView = segmentedControl;
}

- (void)navBarSegmentDidChange:(UISegmentedControl *)sender
{
  NSArray<TPPCatalogFacet *> *facets = self.feed.entryPoints;
  NSInteger index = sender.selectedSegmentIndex;
  if (index >= 0 && index < (NSInteger)facets.count) {
    [self entryPointViewDidSelectWithEntryPointFacet:facets[index]];
  }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
  [super didMoveToParentViewController:parent];

  if(parent) {
    // On iPad iOS 26, the facet bar is hidden (moved to nav bar) and
    // contentInsetAdjustmentBehavior handles insets. Skip manual calculation.
    // On iPhone iOS 26, the facet bar is still visible, so we still
    // need manual insets to push the table below it.
    if (@available(iOS 26, *)) {
      if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return;
      }
    }

    CGFloat top = parent.topLayoutGuide.length;

    if (self.facetBarView.frame.size.height > 0) {
      top = CGRectGetMaxY(self.facetBarView.frame) + kTableViewInsetAdjustmentWithEntryPoints;
    }

    CGFloat bottom = parent.bottomLayoutGuide.length;

    UIEdgeInsets insets = UIEdgeInsetsMake(top, 0, bottom, 0);
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
    [self.tableView setContentOffset:CGPointMake(0, -top) animated:NO];

  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  [self.cachedLaneCells removeAllObjects];
}

- (void)userDidRefresh:(UIRefreshControl *)refreshControl
{
  if ([[self.navigationController.visibleViewController class] isSubclassOfClass:[TPPCatalogFeedViewController class]] &&
      [self.navigationController.visibleViewController respondsToSelector:@selector(load)]) {
    TPPCatalogFeedViewController *viewController = (TPPCatalogFeedViewController *)self.navigationController.visibleViewController;
    [viewController load];
  }
  
  [refreshControl endRefreshing];
  [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.TPPSyncEnded object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  [UIView animateWithDuration:kTableViewCrossfadeDuration animations:^{
    self.tableView.alpha = 1.0;
    self.facetBarView.alpha = 1.0;
  }];

  if (!self.presentedViewController) {
    self.mostRecentBookSelected = nil;
  }
}

// Transition book detail view between Form Sheet and Nav Controller
// when changing between compact and regular size classes
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraits
{
  [super traitCollectionDidChange:previousTraits];

  // for some reason when we background the app this method is called twice.
  // So if we see that we already handled the previous traits, we bail early.
  if ([self.previouslyProcessedTraits isEqual:previousTraits]) {
    return;
  }
  self.previouslyProcessedTraits = previousTraits;
  
  // if there are no changes in size class traits, there's no need to adjust
  // the way we present the book details
  UITraitCollection *currentTraits = self.traitCollection;
  if (previousTraits.horizontalSizeClass == currentTraits.horizontalSizeClass
      && previousTraits.verticalSizeClass == currentTraits.verticalSizeClass) {
    return;
  }

  if (!self.mostRecentBookSelected) {
    return;
  }

  if (self.presentedViewController) {
    [self dismissViewControllerAnimated:NO completion:nil];
  } else if ([self.navigationController viewControllers].count > 1) {
    [self.navigationController popToRootViewControllerAnimated:NO];
  }

  TPPLOG_F(@"Presenting book: %@", [self.mostRecentBookSelected loggableShortString]);
  [[[TPPBookDetailViewController alloc] initWithBook:self.mostRecentBookSelected] presentFromViewController:self];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // Caching cells helps with performance and lets us retain horizontal scroll positions. Cells are
  // only stored in |self.cachedLaneCells| if they are final.
  UITableViewCell *const cachedCell = self.cachedLaneCells[indexPath];
  if(cachedCell) {
    return cachedCell;
  }
  
  if(indexPath.section < (NSInteger) self.indexOfNextLaneRequiringImageDownload) {
    TPPCatalogLaneCell *const cell =
    [[TPPCatalogLaneCell alloc]
     initWithLaneIndex:indexPath.section
     books:((TPPCatalogLane *) self.feed.lanes[indexPath.section]).books
     bookIdentifiersToImages:self.bookIdentifiersToImages];
    cell.delegate = self;
    self.cachedLaneCells[indexPath] = cell;
    return cell;
  } else {
    UITableViewCell *const cell = [[UITableViewCell alloc] init];
    CGRect const progressViewFrame = CGRectMake(5,
                                                0,
                                                CGRectGetWidth(cell.contentView.bounds) - 10,
                                                CGRectGetHeight(cell.contentView.bounds));
    TPPIndeterminateProgressView *const progressView = [[TPPIndeterminateProgressView alloc]
                                                         initWithFrame:progressViewFrame];
    progressView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
    progressView.color = [UIColor colorWithWhite:0.95 alpha:1.0];
    progressView.layer.borderWidth = 2;
    progressView.speedMultiplier = 2.0;
    [progressView startAnimating];
    [cell.contentView addSubview:progressView];
    return cell;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.feed.lanes.count;
}

#pragma mark UITableViewDelegate

// Sets the row height in the table view
- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return kRowHeight;
}

// Sets the section header height in the table view
- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForHeaderInSection:(__attribute__((unused)) NSInteger)section
{
  return kSectionHeaderHeight;
}

// Sets sections header properties.
- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForHeaderInSection:(NSInteger const)section

// Creates a section header view in a table view, with a fixed height and a width that spans the entire width of the table view. 
{
  CGRect const frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kSectionHeaderHeight);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  if (@available(iOS 26, *)) {
    // Use clear background — grouped style with non-sticky headers
    // means they scroll with content and don't need a background.
    view.backgroundColor = UIColor.clearColor;
  } else {
    view.backgroundColor = [[TPPConfiguration backgroundColor] colorWithAlphaComponent:0.9];
  }
  
  // Displays the lane title and lets the user tap to view more books in that
  // category. This is a plain UILabel (not a UIButton) on purpose: a UIButton
  // runs an expensive title + focus-system layout pass (-[UIControl state] ->
  // -[UIView isFocused] -> focus-environment ancestor walk) every time it is
  // laid out, and the iPad size-class transition force-relays-out every header,
  // which pegged the main thread. A UILabel has no such path.
  {
    UILabel *const titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont palaceFontOfSize:21];
    titleLabel.textColor = [UIColor labelColor];
    NSString *const title = ((TPPCatalogLane *) self.feed.lanes[section]).title;
    titleLabel.text = title;
    [titleLabel sizeToFit];
    if (CGRectGetWidth(titleLabel.frame) > self.tableView.frame.size.width - 100) {
      titleLabel.frame = CGRectMake(10, 5, self.tableView.frame.size.width - 100, CGRectGetHeight(titleLabel.frame));
    } else {
      titleLabel.frame = CGRectMake(10, 5, CGRectGetWidth(titleLabel.frame), CGRectGetHeight(titleLabel.frame));
    }
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.tag = section;
    titleLabel.userInteractionEnabled = YES;
    TPPCatalogLane *const lane = self.feed.lanes[titleLabel.tag];
    titleLabel.isAccessibilityElement = YES;
    titleLabel.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"%@ -lane", nil), lane.title];
    titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    titleLabel.accessibilityHint = NSLocalizedString(@"Tap to view more books in this category", "Descriptive label for screen readers");
    [titleLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectCategory:)]];
    [view addSubview:titleLabel];
  }

  // "More >" affordance: a UILabel + arrow UIImageView inside a plain UIView
  // (again, deliberately not a UIButton — see the note above).
  {
    UIView *const moreView = [[UIView alloc] init];
    moreView.userInteractionEnabled = YES;
    moreView.tag = section;

    UILabel *const moreLabel = [[UILabel alloc] init];
    moreLabel.font = [UIFont palaceFontOfSize:14];
    moreLabel.text = NSLocalizedString(@"More", nil);
    moreLabel.textColor = [TPPConfiguration compatiblePrimaryColor];
    [moreLabel sizeToFit];

    UIImage *const arrowImage = [[UIImage imageNamed:@"ArrowRight"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *const arrow = [[UIImageView alloc] initWithImage:arrowImage];
    arrow.tintColor = [TPPConfiguration iconColor];

    CGFloat const gap = 8.0;
    CGFloat const labelW = CGRectGetWidth(moreLabel.frame);
    CGFloat const labelH = CGRectGetHeight(moreLabel.frame);
    CGFloat const arrowH = labelH;
    CGFloat const arrowW = (arrowImage.size.height > 0) ? (arrowImage.size.width * (arrowH / arrowImage.size.height)) : arrowH;
    CGFloat const contentW = labelW + gap + arrowW;
    CGFloat const contentH = labelH;
    CGFloat const vpad = 8.0;

    moreView.frame = CGRectMake(CGRectGetWidth(view.frame) - contentW - 30,
                                13,
                                contentW,
                                contentH + vpad);
    moreView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    moreLabel.frame = CGRectMake(0, vpad / 2.0, labelW, labelH);
    arrow.frame = CGRectMake(labelW + gap, vpad / 2.0, arrowW, arrowH);
    [moreView addSubview:moreLabel];
    [moreView addSubview:arrow];

    TPPCatalogLane *const lane = self.feed.lanes[moreView.tag];
    moreView.isAccessibilityElement = YES;
    moreView.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"More %@ books", nil), lane.title];
    moreView.accessibilityHint = NSLocalizedString(@"Tap to view more books in this category", "Descriptive label for screen readers");
    moreView.accessibilityTraits = UIAccessibilityTraitButton;
    [moreView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectCategory:)]];
    [view addSubview:moreView];
  }
  return view;
}

#pragma mark TPPCatalogLaneCellDelegate

- (void)catalogLaneCell:(TPPCatalogLaneCell *const)cell
     didSelectBookIndex:(NSUInteger const)bookIndex
{
  TPPCatalogLane *const lane = self.feed.lanes[cell.laneIndex];
  TPPBook *const feedBook = lane.books[bookIndex];
  
  TPPBook *const localBook = [[TPPBookRegistry shared] bookForIdentifier:feedBook.identifier];
  TPPBook *const book = (localBook != nil) ? localBook : feedBook;
  TPPLOG_F(@"Presenting book: %@", [book loggableShortString]);
  [[[TPPBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
  self.mostRecentBookSelected = book;
}

#pragma mark TPPFacetBarViewDelegate

- (void)present:(UIViewController *)viewController
{
  [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - 3D Touch

- (void)enable3DTouch
{
  if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] &&
      (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
    [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
  }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
              viewControllerForLocation:(CGPoint)location
{
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  if (![cell isKindOfClass:[TPPCatalogLaneCell class]]) {
    return nil;
  }
  UIViewController *vc = [[UIViewController alloc] init];
  TPPCatalogLaneCell *laneCell = (TPPCatalogLaneCell *) cell;
  vc.view.tag = laneCell.laneIndex;
  
  for (UIImageView *coverView in laneCell.coverViews) {
    CGPoint referencePoint = [[coverView superview] convertPoint:location fromView:self.tableView];
    if (CGRectContainsPoint(coverView.frame, referencePoint)) {
      UIImageView *imgView = [[UIImageView alloc] initWithImage:coverView.image];
      imgView.contentMode = UIViewContentModeScaleAspectFill;
      [vc.view addSubview:imgView];
      [imgView autoPinEdgesToSuperviewEdges];
      vc.preferredContentSize = CGSizeZero;
      previewingContext.sourceRect = [self.tableView convertRect:coverView.frame fromView:[coverView superview]];

      self.tempBookPosition = (int)coverView.tag;

      return vc;
    }
  }
  return nil;
}

- (void)previewingContext:(__unused id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit
{
  TPPCatalogLane *const lane = self.feed.lanes[viewControllerToCommit.view.tag];
  TPPBook *const feedBook = lane.books[self.tempBookPosition];
  TPPBook *const localBook = [[TPPBookRegistry shared] bookForIdentifier:feedBook.identifier];
  TPPBook *const book = (localBook != nil) ? localBook : feedBook;
  TPPLOG_F(@"Presenting book: %@", [book loggableShortString]);
  [[[TPPBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark - TPPEntryPointViewDataSource

- (void)entryPointViewDidSelectWithEntryPointFacet:(TPPCatalogFacet *)entryPointFacet {
  NSURL *const newURL = entryPointFacet.href;

  if (newURL != nil) {
    [self.remoteViewController loadWithURL:newURL];
  } else {
    [TPPErrorLogger logErrorWithCode:TPPErrorCodeNoURL
                              summary:@"Catalog facet missing href URL"
                             metadata:nil];
    [self.remoteViewController showReloadViewWithMessage:NSLocalizedString(@"This URL cannot be found. Please close the app entirely and reload it. If the problem persists, please contact your library's Help Desk.", @"Generic error message indicating that the URL the user was trying to load is missing.")];
  }
}

- (NSArray<TPPCatalogFacet *> *)facetsForEntryPointView
{
  return self.feed.entryPoints;
}

#pragma mark -

- (void)downloadImages
{
  if(self.indexOfNextLaneRequiringImageDownload >= self.feed.lanes.count) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    return;
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  TPPCatalogLane *const lane = self.feed.lanes[self.indexOfNextLaneRequiringImageDownload];
  
  [[TPPBookRegistry shared]
   thumbnailImagesForBooks:[NSSet setWithArray:lane.books]
   handler:^(NSDictionary *const bookIdentifiersToImages) {
     [self.bookIdentifiersToImages addEntriesFromDictionary:bookIdentifiersToImages];
     // We update this before reloading so that the delegate accurately knows which lanes already
     // have had their covers downloaded.
     ++self.indexOfNextLaneRequiringImageDownload;
    [self.tableView reloadData];
    [self downloadImages];
   }];
}

- (void)didSelectCategory:(UITapGestureRecognizer *const)sender
{
  TPPCatalogLane *const lane = self.feed.lanes[sender.view.tag];

  NSURL *urlToLoad = lane.subsectionURL;
  if (urlToLoad == nil) {
    NSString *msg = [NSString stringWithFormat:@"Lane %@ has no subsection URL to display category",
                     lane.title];
    [TPPErrorLogger logErrorWithCode:TPPErrorCodeNoURL
                              summary:msg
                             metadata:@{
                               @"methodName": @"didSelectCategory:"
                             }];
  }

  UIViewController *const viewController = [[TPPCatalogFeedViewController alloc]
                                            initWithURL:urlToLoad];

  BOOL useStandardTitle = NO;
  if (@available(iOS 26, *)) {
    useStandardTitle = YES;
  }

  if (useStandardTitle) {
    // On iOS 26, use the standard title and prevent extending under
    // the top bar so content doesn't show through.
    viewController.title = lane.title;
    viewController.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeLeft | UIRectEdgeRight;
  } else {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont semiBoldPalaceFontOfSize: 16];
    label.text = lane.title;
    label.accessibilityTraits = UIAccessibilityTraitHeader;
    viewController.navigationItem.titleView = label;
  }

  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[TPPCatalogSearchViewController alloc]
                       initWithOpenSearchDescription:self.searchDescription]
   animated:YES];
}

- (void)fetchOpenSearchDescription
{
  [TPPOpenSearchDescription
   withURL:self.feed.openSearchURL
   shouldResetCache:NO
   completionHandler:^(TPPOpenSearchDescription *const description) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.searchDescription = description;
       self.navigationItem.rightBarButtonItem.enabled = YES;
     }];
   }];
}

- (void)userDidCloseBookDetail:(NSNotification *)notif
{
  if ([notif.object isKindOfClass:[TPPBook class]]) {
    TPPBook *book = notif.object;

    // if we closed the book detail page for the given book, we should no
    // longer track its ID because don't have to present it anymore.
    if ([self.mostRecentBookSelected.identifier isEqualToString:book.identifier]) {
      self.mostRecentBookSelected = nil;
    }
  }
}

@end
