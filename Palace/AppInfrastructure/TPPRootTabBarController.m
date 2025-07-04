#import "TPPCatalogNavigationController.h"
#import "TPPRootTabBarController.h"
#import "Palace-Swift.h"

@interface TPPRootTabBarController () <UITabBarControllerDelegate>

@property (nonatomic) TPPCatalogNavigationController *catalogNavigationController;
@property (nonatomic) LoansAndHoldsViewController *loansAndHoldsNavigationController;
@property (nonatomic) FavoritesMainViewController *favoritesMainNavigationController;
@property (nonatomic) EkirjastoMagazineNavigationController *magazineViewController;
@property (nonatomic) UIViewController *settingsViewController;
@property (readwrite) TPPR2Owner *r2Owner;
@property (nonatomic) NSUInteger previousIndex;
@property (nonatomic) NSArray *viewControllerNames;

@end

@implementation TPPRootTabBarController

+ (instancetype)sharedController
{
  static dispatch_once_t predicate;
  static TPPRootTabBarController *sharedController = nil;
  
  dispatch_once(&predicate, ^{
    sharedController = [[self alloc] init];
    if(!sharedController) {
      TPPLOG(@"Failed to create shared controller.");
    }
  });
  
  return sharedController;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.delegate = self;
  
  self.catalogNavigationController = [
    [TPPCatalogNavigationController alloc] init
  ];
  
  self.loansAndHoldsNavigationController = (LoansAndHoldsViewController *) [
    LoansAndHoldsViewController makeSwiftUIViewWithDismissHandler:^{
      [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
    }
  ];
  
  self.favoritesMainNavigationController = (FavoritesMainViewController *) [
    FavoritesMainViewController makeSwiftUIViewWithDismissHandler:^{
      [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
    }
  ];
  
  self.magazineViewController = [
    [EkirjastoMagazineNavigationController alloc] initWithRootViewController:
      [[DigitalMagazineBrowserViewController alloc] init]
  ];
  
  self.settingsViewController =  [
    TPPSettingsViewController makeSwiftUIViewWithDismissHandler:^{
      [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
    }
  ];

  [self setTabViewControllers];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setTabViewControllers)
                                               name:NSNotification.TPPCurrentAccountDidChange
                                             object:nil];
  
  self.r2Owner = [[TPPR2Owner alloc] init];
  
  self.previousIndex = 0;
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Finland: interface orientation and auto rotate functionalities were moved to be
// handled programmatically, because the DigitalMagazineReaderViewController is allowed
// to rotate with all orientations even on iPhone device.
- (BOOL)shouldAutorotate {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return NO;
  }
  return YES;
}

// Finland: interface orientation and auto rotate functionalities were moved to be
// handled programmatically, because the DigitalMagazineReaderViewController is allowed
// to rotate with all orientations even on iPhone device.
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskPortrait;
  }
  return UIInterfaceOrientationMaskAll;
}

- (void)setTabViewControllers
{
  [TPPMainThreadRun asyncIfNeeded:^{
    [self setTabViewControllersInternal];
  }];
}

- (void)setTabViewControllersInternal
{
    // E-kirjasto supports reservations (==holds) so it's check has been removed.
    
  self.viewControllers = @[
    self.catalogNavigationController,
    self.loansAndHoldsNavigationController,
    self.favoritesMainNavigationController,
    self.magazineViewController,
    self.settingsViewController
  ];
    
  self.viewControllerNames = @[
      @"catalogNavigationController",
      @"loansAndHoldsNavigationController",
      @"favoritesAndReadNavigationController",
      @"magazineViewController",
      @"settingsViewController"
    ];
  
}

- (void)showAndReloadCatalogViewController
{
  [self.catalogNavigationController updateFeedAndRegistryOnAccountChange];
  self.selectedViewController = self.catalogNavigationController;
}

- (NSString*)selectedViewControllerName
{
  return self.viewControllerNames[self.selectedIndex];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
  // selectedIndex is not yet changed, so we take it to the previousIndex variable.
  self.previousIndex = self.selectedIndex;
}

- (BOOL)tabBarController:(UITabBarController *)__unused tabBarController
shouldSelectViewController:(nonnull UIViewController *)viewController
{
  return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {

  // Call the web app's "popToRoot" method if the user re-selects the current tab to emulate native behavior
  NSUInteger magazineIndex = [self.viewControllers indexOfObject: self.magazineViewController];
  if (viewController == self.magazineViewController && self.previousIndex == magazineIndex) {
    [self.magazineViewController popToRoot];
  }
}

#pragma mark -

- (void)safelyPresentViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                         completion:(void (^)(void))completion
{
  UIViewController *baseController = self;
  
  while(baseController.presentedViewController) {
    baseController = baseController.presentedViewController;
  }
  
  [baseController presentViewController:viewController animated:animated completion:completion];
}
- (void)changeToPreviousIndex
{
  self.selectedIndex = self.previousIndex;
}

- (void)pushViewController:(UIViewController *const)viewController
                  animated:(BOOL const)animated
{
  if(![self.selectedViewController isKindOfClass:[UINavigationController class]]) {
    TPPLOG(@"Selected view controller is not a navigation controller.");
    return;
  }
  
  if(self.presentedViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  [(UINavigationController *)self.selectedViewController
   pushViewController:viewController
   animated:animated];
}

  // Detects changes in the app user interface environment
  // such as rotating the device, switching to dark mode etc.
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  TPPLOG(@"App trait collection did change.");
  
  [super traitCollectionDidChange:previousTraitCollection];
  [self handleTraitCollectionChange:previousTraitCollection];
}

@end
