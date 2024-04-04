//
//  TPPSettingsView.swift
//  Palace
//
//  Created by Maurice Carrier on 12/2/21.
//  Copyright © 2021 The Palace Project. All rights reserved.
//

import SwiftUI

struct TPPSettingsView: View {
  typealias DisplayStrings = Strings.Settings

  @AppStorage(TPPSettings.showDeveloperSettingsKey) private var showDeveloperSettings: Bool = false
  @State private var selectedView: Int? = 0
  @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation


  //private var signInBusinessLogic = TPPSignInBusinessLogic.shared
  
  private var sideBarEnabled: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
      &&  UIDevice.current.orientation != .portrait
      &&  UIDevice.current.orientation != .portraitUpsideDown
  }

  var body: some View {
    if sideBarEnabled {
      NavigationView {
        
        listView
          .onAppear {
            //selectedView = 1
          }

      }.navigationViewStyle(.stack)
    } else {
      listView
        .onAppear {
          selectedView = 0
        }
    }
  }

  @ViewBuilder private var listView: some View {
    List {
      if AccountsManager.shared.accounts().count == 1 {
        //librariesSection
        if TPPUserAccount.sharedAccount().authToken != nil {
          loginSection
          syncBookmarksSection
        }
        reportIssueSection
      }else{
        librariesSection
      }
      infoSection
      developerSettingsSection
    }
    .navigationBarTitle(DisplayStrings.settings)
    .listStyle(GroupedListStyle())
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      self.orientation = UIDevice.current.orientation
    }
  }
  
  
  @ViewBuilder private var librariesSection: some View {
    let viewController = TPPSettingsAccountsTableViewController(accounts: TPPSettings.shared.settingsAccountsList)
    let navButton = Button(DisplayStrings.addLibrary) {
      viewController.addAccount()
    }

    let wrapper = UIViewControllerWrapper(viewController) { _ in }
      .navigationBarTitle(Text(DisplayStrings.libraries))
      .navigationBarItems(trailing: navButton)

    Section {
      row(title: DisplayStrings.libraries, index: 1, selection: self.$selectedView, destination: wrapper.anyView())
    }
  }
  /*CellKindAdvancedSettings,
  CellKindAgeCheck,
  CellKindLogInSignOut,
  CellKindPromptLogin,
  CellKindSyncButton,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellReportIssue,*/
  @State private var toggleSyncBookmarks = false
  @State private var toggleLogoutWarning = false
  @State private var syncEnabled = AccountsManager.shared.accounts().first?.details?.syncPermissionGranted ?? false
  @State private var logoutText = ""
  @ViewBuilder private var syncBookmarksSection: some View {
    Section(footer: Text(NSLocalizedString("Save your reading position and bookmarks to all your other devices.",comment: "Explain to the user they can save their bookmarks in the cloud across all their devices."))){
      Toggle(isOn:$toggleSyncBookmarks){
        Text(DisplayStrings.syncBookmarks)
      }.disabled(!syncEnabled)
        .onChange(of: toggleSyncBookmarks) { value in
          
          TPPSignInBusinessLogic.getShared { logic in
            logic?.changeSyncPermission(to: value, postServerSyncCompletion: { value in
              toggleSyncBookmarks = value
            })
          }
          
        }.onAppear{
          TPPSignInBusinessLogic.getShared { logic in
            logic?.checkSyncPermission(preWork: {
              
            }, postWork: { enableSync in
              syncEnabled = enableSync
            })
          }
        }
    }
  }
  @ViewBuilder private var loginSection: some View {
    Section{
      Button(action: {
        TPPSignInBusinessLogic.getShared { logic in
          if let _logic = logic {
            if _logic.shouldShowSyncButton() && !self.toggleSyncBookmarks{
              self.logoutText = NSLocalizedString("If you sign out without enabling Sync, your books and any saved bookmarks will be removed.", comment: "")
            }else{
              self.logoutText = NSLocalizedString("If you sign out, your books and any saved bookmarks will be removed.", comment: "")
            }
            
          }
          
          toggleLogoutWarning = true
        }
        
        
      }){
        Text(DisplayStrings.signOut)
      }.alert(Strings.TPPSigninBusinessLogic.signout, isPresented: $toggleLogoutWarning){
        Button(DisplayStrings.signOut, role: .destructive) {
          TPPSignInBusinessLogic.getShared { logic in
            if let _logic = logic {
              if let alert = _logic.logOutOrWarn() {
                TPPRootTabBarController.shared().settingsViewController.present(alert, animated: true)
              }
              
            }
          }
        }
        
      } message: {
        Text(self.logoutText)
      }
      Button(action: {
        EkirjastoLoginViewController.show(dismissHandler: nil)
      }){
        Text(DisplayStrings.promptLogin)
      }
    }
  }
  
  @ViewBuilder private var reportIssueSection: some View {
    
    Section{
      if let supportEmail = AccountsManager.shared.currentAccount?.supportEmail {
        Button(action: {
          ProblemReportEmail.sharedInstance.beginComposing(to: supportEmail.rawValue, presentingViewController: TPPRootTabBarController.shared().settingsViewController, book: nil)
        }){
          Text(DisplayStrings.reportIssue)
        }
      }else {
        let viewController = BundledHTMLViewController(fileURL: AccountsManager.shared.currentAccount!.supportURL!, title: AccountsManager.shared.currentAccount!.name)
        
        let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
        row(title: DisplayStrings.reportIssue, index: 1, selection: self.$selectedView, destination: wrapper.anyView())
      }
    }
  }

  @ViewBuilder private var infoSection: some View {
    let view: AnyView = showDeveloperSettings ? EmptyView().anyView() : versionInfo.anyView()
      Section(footer: view) {
        feedbackRow
        accessibilityRow
        privacyRow
        softwareLicenseRow
      }
  }

  @ViewBuilder private var aboutRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPAboutPalaceURLString)!,
      title: Strings.Settings.aboutApp,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.aboutApp))

    row(title: DisplayStrings.aboutApp, index: 2, selection: self.$selectedView, destination: wrapper.anyView())
  }
  
  @ViewBuilder private var feedbackRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPFeedbackURLString)!,
      title: Strings.Settings.feedback,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.feedback))

    row(title: DisplayStrings.feedback, index: 2, selection: self.$selectedView, destination: wrapper.anyView())
  }
  
  @ViewBuilder private var accessibilityRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPAccessibilityURLString)!,
      title: Strings.Settings.accessibility,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.accessibility))

    row(title: DisplayStrings.accessibility, index: 2, selection: self.$selectedView, destination: wrapper.anyView())
  }


  @ViewBuilder private var privacyRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPPrivacyPolicyURLString)!,
      title: Strings.Settings.privacyPolicy,
      failureMessage: Strings.Error.loadFailedError
    )

    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.privacyPolicy))

    row(title: DisplayStrings.privacyPolicy, index: 3, selection: self.$selectedView, destination: wrapper.anyView())

  }

  @ViewBuilder private var userAgreementRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPUserAgreementURLString)!,
      title: Strings.Settings.eula,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.eula))

    row(title: DisplayStrings.eula, index: 4, selection: self.$selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var softwareLicenseRow: some View {
    let viewController = BundledHTMLViewController(
      fileURL: Bundle.main.url(forResource: "software-licenses", withExtension: "html")!,
      title: Strings.Settings.softwareLicenses
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.softwareLicenses))

    row(title: DisplayStrings.softwareLicenses, index: 5, selection: self.$selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var developerSettingsSection: some View {
    if (TPPSettings.shared.customMainFeedURL == nil && showDeveloperSettings) {
      Section(footer: versionInfo) {
        let viewController = TPPDeveloperSettingsTableViewController()
          
        let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
          .navigationBarTitle(Text(DisplayStrings.developerSettings))
        
        row(title: DisplayStrings.developerSettings, index: 6, selection: self.$selectedView, destination: wrapper.anyView())
      }
    }
  }

  @ViewBuilder private var versionInfo: some View {
    let productName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build = Bundle.main.object(forInfoDictionaryKey: (kCFBundleVersionKey as String)) as! String
    
    Text("\(productName) version \(version) (\(build))")
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
      .gesture(
        LongPressGesture(minimumDuration: 5.0)
          .onEnded { _ in
            self.showDeveloperSettings.toggle()
          }
      )
      .frame(height: 40)
      .horizontallyCentered()
  }
  
  private func row(title: String, index: Int, selection: Binding<Int?>, destination: AnyView) -> some View {
    NavigationLink(
      destination: destination,
      tag: index,
      selection: selection,
      label: { Text(title) }
    )
  }
}
