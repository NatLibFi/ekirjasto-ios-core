//
//  TPPSettingsView.swift
//

import CloudKit
import SwiftUI

struct TPPSettingsView: View {
  @AppStorage(TPPSettings.showDeveloperSettingsKey) private var showDeveloperSettings: Bool = false

  @ObservedObject private var authHolder = TPPUserAccountAuthentication.shared
  
  @State private var logoutText = ""
  @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
  @State private var selectedView: Int? = 0
  @State private var syncEnabled = true
  @State private var toggleLogoutWarning = false
  @State private var toggleSyncBookmarks = AccountsManager.shared.accounts().first?.details?.syncPermissionGranted ?? false
  
  var body: some View {
    settingsListView
      .navigationBarItems(leading: leadingBarButton)
      .navigationBarTitle(Strings.Settings.settings)
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        self.orientation = UIDevice.current.orientation
      }
  }
  
  @ViewBuilder private var settingsListView: some View {
    List {}
      .listStyle(GroupedListStyle())
  }

  @ViewBuilder private var listView: some View {
    List {
      Section {} header: {
        HStack {
          Spacer()
          Image("LaunchImageLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200)
          Spacer()
        }
      }
      if AccountsManager.shared.accounts().count == 1 {
        if authHolder.isAuthenticated {
          logoutSection
        } else {
          loginSection
        }
        
      } else {
        librariesSection
      }
      syncBookmarksSection
      infoSection
      // This shows the Finnish/Swedish version of the logo if that is the
      // current locale and the English version otherwise
      if ["fi", "sv"].contains(Locale.current.languageCode) {
        natLibFiLogoFiSv
      } else {
        natLibFiLogoEn
      }
    }
  }
  
  @ViewBuilder private var librariesSection: some View {
    let viewController = TPPSettingsAccountsTableViewController(accounts: TPPSettings.shared.settingsAccountsList)
    let navButton = Button(Strings.Settings.addLibrary) {
      viewController.addAccount()
    }

    let wrapper = UIViewControllerWrapper(viewController) { _ in }
      .navigationBarTitle(Text(Strings.Settings.libraries))
      .navigationBarItems(trailing: navButton)

    Section {
      row(title: Strings.Settings.libraries, index: 1, selection: self.$selectedView, destination: wrapper.anyView())
    }
  }

  @ViewBuilder private var syncBookmarksSection: some View {
    Section(footer: Text(NSLocalizedString("Save your reading position and bookmarks to all your other devices.", comment: "Explain to the user they can save their bookmarks in the cloud across all their devices."))) {
      Toggle(isOn: $toggleSyncBookmarks) {
        Text(Strings.Settings.syncBookmarks)
          .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      }.disabled(!syncEnabled)
        .onChange(of: toggleSyncBookmarks) { value in
          
          TPPSignInBusinessLogic.getShared { logic in
            logic?.changeSyncPermission(to: value, postServerSyncCompletion: { value in
              toggleSyncBookmarks = value
            })
          }
          
        }.onAppear {
          TPPSignInBusinessLogic.getShared { logic in
            logic?.checkSyncPermission(preWork: {
              syncEnabled = false
            }, postWork: { enableSync in
              syncEnabled = true
              toggleSyncBookmarks = enableSync
            })
          }
        }
    }
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
  }
  
  @ViewBuilder private var leadingBarButton: some View {
    Button {
      TPPRootTabBarController.shared().showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
    }
  }
  
  @ViewBuilder private var logoutSection: some View {
    Section {
      Button {
        TPPSignInBusinessLogic.getShared { logic in
          if let _logic = logic {
            if _logic.shouldShowSyncButton() && !self.toggleSyncBookmarks {
              self.logoutText = NSLocalizedString("If you sign out without enabling Sync, your books and any saved bookmarks will be removed.", comment: "")
            } else {
              self.logoutText = NSLocalizedString("If you sign out, your books and any saved bookmarks will be removed.", comment: "")
            }
          }
         
          toggleLogoutWarning = true
        }
       
      } label: {
        HStack {
          Text(Strings.Settings.signOut)
            .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }.alert(Strings.TPPSigninBusinessLogic.signout, isPresented: $toggleLogoutWarning) {
        Button(Strings.Settings.signOut, role: .destructive) {
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
     
      Button {
        let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
 
        passkey.register("", TPPUserAccount.sharedAccount().authToken!) { registerToken in
          if let token = registerToken, !token.isEmpty {
            TPPNetworkExecutor.shared.authenticateWithToken(token) { _ in
            }
          }
        }
      } label: {
        HStack {
          Text(Strings.Settings.registerPasskey)
            .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
     
      NavigationLink(
        destination:
        DependentsView())
      {
        Text(Strings.Settings.dependentsButton)
      }
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
    }
  }
  
  @ViewBuilder private var loginSection: some View {
    Section {
      row(title: Strings.Settings.loginSuomiFi, destination: SuomiIdentificationWebView(authenticationDocument: AccountsManager.shared.currentAccount!.authenticationDocument).anyView())
      Button {
        let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
        passkey.login { loginToken in
          if let token = loginToken, !token.isEmpty {
            TPPNetworkExecutor.shared.authenticateWithToken(token) { _ in
            }
          }
        }
      } label: {
        HStack {
          Text(Strings.Settings.loginPasskey)
            .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
        }
      }
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
    }
  }

  @ViewBuilder private var infoSection: some View {
    let view: AnyView = showDeveloperSettings ? EmptyView().anyView() : versionInfo.anyView()
    Section(footer: view) {
      feedbackRow
      accessibilityRow
      privacyRow
      softwareLicenseRow
      userAgreementRow
      faqRow
    }
  }
  
  @ViewBuilder private var feedbackRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPFeedbackURLString)!,
      title: Strings.Settings.feedback,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.feedback))

    row(title: Strings.Settings.feedback, index: 1, selection: $selectedView, destination: wrapper.anyView())
  }
  
  @ViewBuilder private var accessibilityRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPAccessibilityURLString)!,
      title: Strings.Settings.accessibility,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.accessibility))

    row(title: Strings.Settings.accessibility, index: 2, selection: $selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var privacyRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPPrivacyPolicyURLString)!,
      title: Strings.Settings.privacyPolicy,
      failureMessage: Strings.Error.loadFailedError
    )

    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.privacyPolicy))

    row(title: Strings.Settings.privacyPolicy, index: 3, selection: $selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var softwareLicenseRow: some View {
    let viewController = BundledHTMLViewController(
      fileURL: Bundle.main.url(forResource: "software-licenses", withExtension: "html")!,
      title: Strings.Settings.softwareLicenses
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.softwareLicenses))

    row(title: Strings.Settings.softwareLicenses, index: 4, selection: $selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var userAgreementRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPUserAgreementURLString)!,
      title: Strings.Settings.eula,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.eula))

    row(title: Strings.Settings.eula, index: 5, selection: $selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var faqRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPFAQURLString)!,
      title: Strings.Settings.faq,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(Strings.Settings.faq))

    row(title: Strings.Settings.faq, index: 6, selection: $selectedView, destination: wrapper.anyView())
  
    // button to open preferences view
    NavigationLink(
      destination:
      PreferencesView())
    {
      Text(Strings.Preferences.preferencesButton)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
    }
  }
  
  @ViewBuilder private var versionInfo: some View {
    let productName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    
    Text("\(productName) version \(version) (\(build))")
      .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
      .frame(height: 40)
      .horizontallyCentered()
  }

  /*
   This returns the Finnish/Swedish version of the logo

   Note the unfortunate duplication with natLibFiLogoEn,
   because apparently passing parameters isn't exactly possible here
   */
  @ViewBuilder private var natLibFiLogoFiSv: some View {
    HStack {
      Spacer()
      Image("NatLibFiLogoFiSv")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200)
      Spacer()
    }
  }

  /*
   This returns the English version of the logo

   Note the unfortunate duplication with natLibFiLogoFiSv,
   because apparently passing parameters isn't exactly possible here
   */
  @ViewBuilder private var natLibFiLogoEn: some View {
    HStack {
      Spacer()
      Image("NatLibFiLogoEn")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200)
      Spacer()
    }
  }

  private func row(title: String, destination: AnyView) -> some View {
    NavigationLink(
      destination: destination,
      label: { Text(title) }
    )
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
  }
  
  private func row(title: String, index: Int, selection: Binding<Int?>, destination: AnyView) -> some View {
    NavigationLink(
      destination: destination,
      tag: index,
      selection: selection,
      label: { Text(title) }
    )
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
  }
}
