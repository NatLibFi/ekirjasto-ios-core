// TODO: This class duplicates much of the functionality of TPPCatalogUngroupedFeedViewController.
// After it is complete, the common portions must be factored out.

#import "NSString+TPPStringAdditions.h"

#import "TPPBookCell.h"
#import "TPPBookDetailViewController.h"
#import "TPPCatalogUngroupedFeed.h"
#import "TPPOpenSearchDescription.h"
#import "TPPReloadView.h"
#import "UIView+TPPViewAdditions.h"
#import <PureLayout/PureLayout.h>
#import "Palace-Swift.h"

#import "TPPCatalogSearchViewController.h"

@interface TPPCatalogSearchViewController ()
  <TPPCatalogUngroupedFeedDelegate, TPPEntryPointViewDataSource, TPPEntryPointViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate>

@property (nonatomic) TPPOpenSearchDescription *searchDescription;
@property (nonatomic) TPPCatalogUngroupedFeed *feed;
@property (nonatomic) NSArray *books;

@property (nonatomic) UIActivityIndicatorView *searchActivityIndicatorView;
@property (nonatomic) UILabel *searchActivityIndicatorLabel;
@property (nonatomic) TPPReloadView *reloadView;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) UILabel *noResultsLabel;
@property (nonatomic) UILabel *startSearchLabel;
@property (nonatomic) TPPFacetBarView *facetBarView;
@property (nonatomic) NSTimer *debounceTimer;

@end

@implementation TPPCatalogSearchViewController

- (instancetype)initWithOpenSearchDescription:(TPPOpenSearchDescription *)searchDescription
{
  self = [super init];
  if(!self) return nil;

  self.searchDescription = searchDescription;
  
  return self;
}

- (NSArray *)books
{
  return _books ? _books : self.feed.books;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;

  if (@available(iOS 11.0, *)) {
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }

  self.searchActivityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.searchActivityIndicatorView.hidden = YES;
  [self.view addSubview:self.searchActivityIndicatorView];
  
  self.searchActivityIndicatorLabel = [[UILabel alloc] init];
  self.searchActivityIndicatorLabel.font = [UIFont palaceFontOfSize:14.0];
  self.searchActivityIndicatorLabel.text = NSLocalizedString(@"Loading... Please wait.", @"Message explaining that the download is still going");
  self.searchActivityIndicatorLabel.hidden = YES;
  [self.view addSubview:self.searchActivityIndicatorLabel];
  [self.searchActivityIndicatorLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.searchActivityIndicatorView];
  [self.searchActivityIndicatorLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.searchActivityIndicatorView withOffset:8.0];
  
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.delegate = self;
  
  // Create an attribute with desired color for the placeholder text
  NSDictionary *attributes = @{
    NSForegroundColorAttributeName: [UIColor colorNamed:@"ColorEkirjastoAlwaysBlack"]
  };
  // Create placeholder with attributes
  NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Search", nil) attributes:attributes];
  // Set the attributed placeholder
  self.searchBar.searchTextField.attributedPlaceholder = attributedPlaceholder;
  // The magnifying glass color
  self.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:@"ColorEkirjastoAlwaysBlack"];
  // The user-written text color
  self.searchBar.searchTextField.textColor = [UIColor colorNamed:@"ColorEkirjastoAlwaysBlack"];
  // The blinking line color
  self.searchBar.searchTextField.tintColor = [UIColor colorNamed:@"ColorEkirjastoSearchBarText"];
  // Color of search background
  self.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:@"ColorEkirjastoSearchBar"];
  [self.searchBar sizeToFit];
  [self.searchBar becomeFirstResponder];
  
  [self addSearchBarAsTitleViewOrSubview];
  
  self.noResultsLabel = [[UILabel alloc] init];
  self.noResultsLabel.text = NSLocalizedString(@"No Results Found", nil);
  self.noResultsLabel.font = [UIFont palaceFontOfSize:17];
  [self.noResultsLabel sizeToFit];
  self.noResultsLabel.hidden = YES;
  [self.view addSubview:self.noResultsLabel];
  
  // Show instructions for user how to search books or authors.
  // This message is shown in the empty search view before first search,
  // and is replaced with actual search results (or "no results found") after search
  self.startSearchLabel = [[UILabel alloc] init];
  self.startSearchLabel.text = NSLocalizedString(@"You can search for a book or an author using the search bar above.\n\nIf you want to search through all books, ensure you are on the Browse Books tab with 'All' selected.", nil);
  self.startSearchLabel.font = [UIFont palaceFontOfSize:18];
  self.startSearchLabel.textColor = [UIColor colorNamed:@"ColorEkirjastoBlack"];
  self.startSearchLabel.numberOfLines = 0;
  self.startSearchLabel.textAlignment = NSTextAlignmentCenter;
  self.startSearchLabel.hidden = NO;
  
  [self.view addSubview:self.startSearchLabel];
  
  self.startSearchLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.startSearchLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.startSearchLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [self.startSearchLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
    [self.startSearchLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20]
  ]];
  
  __weak TPPCatalogSearchViewController *weakSelf = self;
  self.reloadView = [[TPPReloadView alloc] init];
  self.reloadView.handler = ^{
    weakSelf.reloadView.hidden = YES;
    // |weakSelf.searchBar| will always contain the last search because the reload view is hidden as
    // soon as editing begins (and thus cannot be clicked if the search bar text has changed).
    [weakSelf searchBarSearchButtonClicked:weakSelf.searchBar];
  };
  self.reloadView.hidden = YES;
  [self.view addSubview:self.reloadView];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];

  self.searchActivityIndicatorView.center = self.view.center;
  [self.searchActivityIndicatorView integralizeFrame];

  self.noResultsLabel.center = self.view.center;
  self.noResultsLabel.frame = CGRectMake(CGRectGetMinX(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.view.frame) * 0.333,
                                         CGRectGetWidth(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.noResultsLabel.frame));
  [self.noResultsLabel integralizeFrame];

  [self.reloadView centerInSuperview];
  

}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self updateSearchResultContentInsets];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    return 0.0;
  } {
    return 25.0;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.searchBar resignFirstResponder];
}

- (void)addActivityIndicatorLabel:(NSTimer*)timer
{
  if (!self.searchActivityIndicatorView.isHidden) {
    [UIView transitionWithView:self.searchActivityIndicatorLabel
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.searchActivityIndicatorLabel.hidden = NO;
                    } completion:nil];
  }
  [timer invalidate];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.books.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.feed prepareForBookIndex:indexPath.row];
  
  TPPBook *const book = self.books[indexPath.row];
  
  return TPPBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  TPPBook *const book = self.books[indexPath.row];
  
  [[[TPPBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark NYPLCatalogUngroupedFeedDelegate

- (void)catalogUngroupedFeed:(__attribute__((unused))
                              TPPCatalogUngroupedFeed *)catalogUngroupedFeed
              didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

- (void)catalogUngroupedFeed:(__unused TPPCatalogUngroupedFeed *)catalogUngroupedFeed
                 didAddBooks:(__unused NSArray *)books
                       range:(__unused NSRange const)range
{
  // FIXME: This is not ideal but we were having double-free issues with
  // `insertItemsAtIndexPaths:`. See issue #144 for more information.

  // Debounce timer reduces content flickering on each reload
  if (!self.debounceTimer) {
    self.debounceTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
      #pragma unused(timer)
      [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
      self.debounceTimer = nil;
    }];
  }
}

#pragma mark UISearchBarDelegate

- (void)configureUIForActiveSearchState
{
  self.collectionView.hidden = YES;
  self.noResultsLabel.hidden = YES;
  self.startSearchLabel.hidden = YES;
  self.reloadView.hidden = YES;
  self.searchActivityIndicatorView.hidden = NO;
  [self.searchActivityIndicatorView startAnimating];

  self.searchActivityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: 10.0 target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];

  self.searchBar.userInteractionEnabled = NO;
  self.searchBar.alpha = 0.5;
  [self.searchBar resignFirstResponder];
}

- (void)fetchUngroupedFeedFromURL:(NSURL *)URL
{
  [self.debounceTimer invalidate];
  self.debounceTimer = nil;
  [TPPCatalogUngroupedFeed
   withURL:URL
   handler:^(TPPCatalogUngroupedFeed *const category) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       if(category) {
         self.feed = category;
         self.feed.delegate = self;
       }
       [self updateUIAfterSearchSuccess:(category != nil)];
     }];
   }];
}

- (void)searchBarSearchButtonClicked:(__attribute__((unused)) UISearchBar *)searchBar
{
  [self configureUIForActiveSearchState];
  
  if(self.searchDescription.books) {
    self.books = [self.searchDescription.books filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TPPBook *book, __unused NSDictionary *bindings) {
      BOOL titleMatch = [book.title.lowercaseString containsString:self.searchBar.text.lowercaseString];
      BOOL authorMatch = [book.authors.lowercaseString containsString:self.searchBar.text.lowercaseString];
      return titleMatch || authorMatch;
    }]];
    [self updateUIAfterSearchSuccess:YES];
  } else {
    NSURL *searchURL = [self.searchDescription
                        OPDSURLForSearchingString:self.searchBar.text];
    [self fetchUngroupedFeedFromURL:searchURL];
  }
}

- (void)updateUIAfterSearchSuccess:(BOOL)success
{
  [self createAndConfigureFacetBarView];

  self.collectionView.alpha = 0.0;
  self.searchActivityIndicatorView.hidden = YES;
  [self.searchActivityIndicatorView stopAnimating];
  self.searchActivityIndicatorLabel.hidden = YES;
  self.searchBar.userInteractionEnabled = YES;

  if(success) {
    [self.debounceTimer invalidate];
    self.debounceTimer = nil;
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.collectionView reloadData];
    
    if(self.books.count > 0) {
      self.collectionView.hidden = NO;
    } else {
      self.noResultsLabel.hidden = NO;
    }
  } else {
    self.reloadView.hidden = NO;
  }

  [UIView animateWithDuration:0.3 animations:^{
    self.searchBar.alpha = 1.0;
    self.facetBarView.alpha = 1.0;
    self.collectionView.alpha = 1.0;
  }];
}

- (BOOL)searchBarShouldBeginEditing:(__attribute__((unused)) UISearchBar *)searchBar
{
  self.reloadView.hidden = YES;
  
  return YES;
}

- (void)createAndConfigureFacetBarView
{
  if (self.facetBarView) {
    [self.facetBarView removeFromSuperview];
  }

  //Disable by Ellibs
  //self.facetBarView = [[TPPFacetBarView alloc] initWithOrigin:CGPointZero width:self.view.bounds.size.width];
  //self.facetBarView.entryPointView.delegate = self;
  //self.facetBarView.entryPointView.dataSource = self;
  //self.facetBarView.alpha = 0;

  //[self.view addSubview:self.facetBarView];
  //[self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
  //[self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
  //[self.facetBarView autoPinEdgeToSuperviewMargin:ALEdgeTop];
}

- (void)addSearchBarAsTitleViewOrSubview
{
  // Set some defaults and checks
  // to help handle all different cases of
  // how searchbars and searchsheets are shown in the app
  BOOL isRunningiOS18OrLater = NO;
  BOOL hasParentCatalogNavigationController = [[self parentViewController] isKindOfClass:[TPPCatalogNavigationController class]];
  BOOL isUsingPadDevice = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
  BOOL isUsingRegularSizeClass = [[TPPRootTabBarController sharedController] traitCollection].horizontalSizeClass == UIUserInterfaceSizeClassRegular;
  
  if (@available(iOS 18, *)) {
    isRunningiOS18OrLater = YES;
  }
  
  // Because of the floating tab bar we can not use the default approach
  BOOL shouldAddSearchBarAsSubview = hasParentCatalogNavigationController && isUsingPadDevice && isUsingRegularSizeClass && isRunningiOS18OrLater;

  // Determine the display style for the search bar:
  // a) As a subview in the current view, keeping the top bar intact
  // b) Integrated into the top bar, the default
  // Note: In MyBooks views, the search sheet is already opened within the view,
  // so option b) is used there also
  if (shouldAddSearchBarAsSubview) {
    [self.view addSubview:self.searchBar];
    [self updateSearchBarFrame];
  } else {
    // use the default approach
    self.navigationItem.titleView = self.searchBar;
  }
  
}

- (void)updateSearchBarFrame
{
  CGFloat searchBarOffsetX= 0.0;
  CGFloat searchBarWidth = self.view.frame.size.width;
  CGFloat searchBarHeight = self.searchBar.frame.size.height;
  // This default is just an approximation
  // to position the search bar in catalog Objective-C views
  // similarly to the MyBooks SwiftUI views.
  CGFloat searchBarOffsetY = 86.0;
  
  self.searchBar.frame = CGRectMake(searchBarOffsetX,
                                    searchBarOffsetY,
                                    searchBarWidth,
                                    searchBarHeight);
}

- (void)updateSearchResultContentInsets
{
  // Set some defaults first
  BOOL isRunningiOS18OrLater = NO;
  CGFloat bottomContentInset = self.view.safeAreaInsets.bottom;
  CGFloat leftContentInset = 0.0;
  CGFloat rightContentInset = 0.0;
  // Top inset value 75.0 is the default
  // and used for search sheets opened from MyBooks (SwiftUI) views
  CGFloat topContentInset = 75.0;

  // Then some checks to help handle all different cases of
  // how searchbars and searchsheets are shown in the app
  BOOL hasParentCatalogNavigationController = [[self parentViewController] isKindOfClass:[TPPCatalogNavigationController class]];
  BOOL isUsingPadDevice = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
  BOOL isUsingRegularSizeClass = [[TPPRootTabBarController sharedController] traitCollection].horizontalSizeClass == UIUserInterfaceSizeClassRegular;
  
  if (@available(iOS 18, *)) {
    isRunningiOS18OrLater = YES;
  }
  
  BOOL isFloatingTabBarVisibleOnPad = isUsingRegularSizeClass && isRunningiOS18OrLater;
  
  // If user is in MyBooks views and opens search sheet from there,
  // the parent controller is different, these are skipped.
  // and the default topContentInsent is used instead.
  if (hasParentCatalogNavigationController) {
    // User has navigated to the Browse Books (Objective-C) view
    // and opened the search sheet
    
    if (isUsingPadDevice) {
      // Device is iPad
      
      if (isFloatingTabBarVisibleOnPad) {
        [self updateSearchBarFrame];
        topContentInset = 150.0;
      } else {
        // Device interface is compact (or unspecified) OR iOS is older than 18.
        // Bottom tab bar is visible.
        topContentInset = 100.0;
      }
      
    } else {
      // Device is iPhone
      topContentInset = 120.0;
    }
    
  }
  
  // Set insets around content in search sheet (around the search results).
  // Top inset varies based on device and style of search bar.
  self.collectionView.contentInset = UIEdgeInsetsMake(topContentInset,
                                                      leftContentInset,
                                                      bottomContentInset,
                                                      rightContentInset);
}

#pragma mark NYPLEntryPointViewDelegate

- (void)entryPointViewDidSelectWithEntryPointFacet:(TPPCatalogFacet *)facet
{
  [self configureUIForActiveSearchState];
  NSURL *const newURL = facet.href;
  [self fetchUngroupedFeedFromURL:newURL];
}

- (NSArray<TPPCatalogFacet *> *)facetsForEntryPointView
{
  return self.feed.entryPoints;
}

@end
