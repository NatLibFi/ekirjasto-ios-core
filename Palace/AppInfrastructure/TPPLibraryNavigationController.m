//
//  TPPLibraryNavigationController.m
//  The Palace Project
//
//  Created by Ettore Pasquini on 9/18/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import "Palace-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

#import "TPPLibraryNavigationController.h"
#import "TPPRootTabBarController.h"
#import "TPPCatalogNavigationController.h"

@interface TPPLibraryNavigationController ()

@end

@implementation TPPLibraryNavigationController

#ifdef SIMPLYE
- (void)setNavigationLeftBarButtonForVC:(UIViewController *)vc
{
  // Finland: action disabled for E-kirjasto.
  vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                         initWithImage:[UIImage imageNamed:@"MyLibraryIcon"] style:(UIBarButtonItemStylePlain)
                                         target:nil
                                         action:nil];
  // Finland: This is not working as a button for E-kirjasto, instead this is just an icon.
  vc.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilityLibraryIconWithButtonDisabled", nil);
}

// for converting this to Swift, see https://bit.ly/3mM9QoH
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
- (void)switchLibrary
{
  // Finland: function disabled for E-kirjasto.
  return;
  
  UIViewController *viewController = self.visibleViewController;

  UIAlertControllerStyle style;
  if (viewController && viewController.navigationItem.leftBarButtonItem) {
    style = UIAlertControllerStyleActionSheet;
  } else {
    style = UIAlertControllerStyleAlert;
  }

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Find Your Library", nil) message:nil preferredStyle:style];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

  NSArray *accounts = [[TPPSettings sharedSettings] settingsAccountsList];

  for (Account* account in accounts) {
    [alert addAction:[UIAlertAction actionWithTitle:account.name style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
      [self loadAccount:account];
    }]];
  }

  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add Library", nil) style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    TPPAccountList *listVC = [[TPPAccountList alloc] initWithCompletion:^(Account * _Nonnull account) {
      [account loadAuthenticationDocumentUsingSignedInStateProvider:nil completion:^(BOOL success) {
        if (success) {
          dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![TPPSettings.shared.settingsAccountIdsList containsObject:account.uuid]) {
              TPPSettings.shared.settingsAccountIdsList = [TPPSettings.shared.settingsAccountIdsList arrayByAddingObject:account.uuid];
            }

            [self loadAccount:account];
          });
        }
      }];
    }];
    [self pushViewController:listVC animated:YES];
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:(UIAlertActionStyleCancel) handler:nil]];

  [[TPPRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
}
#pragma clang diagnostic pop

- (void) loadAccount:(Account *)account {
    BOOL workflowsInProgress;
  #if defined(FEATURE_DRM_CONNECTOR)
    if ([AdobeCertificate.defaultCertificate hasExpired] == NO) {
      workflowsInProgress = ([NYPLADEPT sharedInstance].workflowsInProgress || [TPPBookRegistry shared].isSyncing == YES);
    } else {
      workflowsInProgress = ([TPPBookRegistry shared].isSyncing == YES);
    }
  #else
    workflowsInProgress = ([TPPBookRegistry shared].isSyncing == YES);
  #endif
    
    if (workflowsInProgress) {
      [self presentViewController:[TPPAlertUtils
                                   alertWithTitle:@"Please Wait"
                                   message:@"Please wait a moment before switching library accounts."]
                         animated:YES
                       completion:nil];
    } else {
      [self updateCatalogFeedSettingCurrentAccount:account];
    }
}

- (void)updateCatalogFeedSettingCurrentAccount:(Account *)account
{
  [AccountsManager shared].currentAccount = account;
  TPPCatalogNavigationController * catalog = (TPPCatalogNavigationController*)[TPPRootTabBarController sharedController].viewControllers[0];
  [catalog updateFeedAndRegistryOnAccountChange];

  UIViewController *visibleVC = self.visibleViewController;
  visibleVC.navigationItem.title = [AccountsManager shared].currentAccount.name;
}
#endif

@end
