//
// TPPSettingsView.swift
// E-kirjasto app view for Settings tab
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
    List {
      //logo at the top of the view
      eLibraryLogoSection
      //Login, logout, dependents buttons
      accountSection
      //Info buttons and footer with NatLibFi logo and version
      infoSection
    }
    .listStyle(GroupedListStyle())
  }
  
  @ViewBuilder private var eLibraryLogoSection: some View {
    Section {}
      header: {
        HStack {
          Spacer()
          Image("LaunchImageLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200)
          Spacer()
        }
      }
  }

  @ViewBuilder private var accountSection: some View {
    if AccountsManager.shared.accounts().count == 1 {
      if authHolder.isAuthenticated {
        Section {
          logoutRow
          registerPasskeyRow
          dependentsRow
        }
      } else {
        Section(
          footer: Text(Strings.Settings.loginFooterUserAgreementText)
            .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
        ) {
          loginWithSuomiFiRow
          loginWithPasskeyRow
        }
      }
    }
  }
  
  @ViewBuilder private var infoSection: some View {
    Section(
      footer: footer
    ) {
      feedbackRow
      accessibilityRow
      privacyRow
      softwareLicensesRow
      userAgreementRow
      instructionsRow
      preferencesRow
    }
  }
  
  @ViewBuilder private var leadingBarButton: some View {
    Button {
      TPPRootTabBarController.shared().showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
    }
  }
  
  @ViewBuilder private var logoutRow: some View {
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
      buttonLabelHStackRow(
        title: Strings.Settings.signOut
      )
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
  }
  
  @ViewBuilder private var registerPasskeyRow: some View {
    Button {
      let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
      
      passkey.register("", TPPUserAccount.sharedAccount().authToken!) { registerToken in
        if let token = registerToken, !token.isEmpty {
          TPPNetworkExecutor.shared.authenticateWithToken(token) { _ in
          }
        }
      }
    } label: {
      buttonLabelHStackRow(
        title: Strings.Settings.registerPasskey
      )
    }
  }
  
  @ViewBuilder private var dependentsRow: some View {
    navigationLinkRow(
      title: Strings.Settings.dependentsButton,
      destination: DependentsView().anyView()
    )
  }
  
  @ViewBuilder private var loginWithSuomiFiRow: some View {
    let authenticationDocument = AccountsManager.shared.currentAccount!.authenticationDocument
    
    navigationLinkRow(
      title: Strings.Settings.loginSuomiFi,
      destination: SuomiIdentificationWebView(authenticationDocument: authenticationDocument).anyView()
    )
  }
  
  @ViewBuilder private var loginWithPasskeyRow: some View {
    Button {
      let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
      
      passkey.login { loginToken in
        if let token = loginToken, !token.isEmpty {
          TPPNetworkExecutor.shared.authenticateWithToken(token) { _ in
          }
        }
      }
    } label: {
      buttonLabelHStackRow(
        title: Strings.Settings.loginPasskey
      )
    }
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
  }
  
  @ViewBuilder private var footer: some View {
  //Footer with the NatLibFi logo and version info
    VStack{
      Spacer(minLength: 10)
      natLibFiLogoSection
      versionInfo
    }
  }
  
  @ViewBuilder private var natLibFiLogoSection: some View {
    let natLibFiLogo = ["fi", "sv"].contains(Locale.current.languageCode)
      ? "NatLibFiLogoFiSv"
      : "NatLibFiLogoEn"
    
    HStack {
      Image(natLibFiLogo)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200)
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
  
  @ViewBuilder private var feedbackRow: some View {
    navigationLinkRow(
      title: Strings.Settings.feedback,
      index: 1,
      selection: $selectedView,
      destination: remoteHTMLView(
        url: TPPSettings.TPPFeedbackURLString,
        title: Strings.Settings.feedback
      ).anyView()
    )
  }
  
  @ViewBuilder private var accessibilityRow: some View {
    navigationLinkRow(
      title: Strings.Settings.accessibility,
      index: 2,
      selection: $selectedView,
      destination: remoteHTMLView(
        url: TPPSettings.TPPAccessibilityURLString,
        title: Strings.Settings.accessibility
      ).anyView()
    )
  }
  
  @ViewBuilder private var privacyRow: some View {
    navigationLinkRow(
      title: Strings.Settings.privacyPolicy,
      index: 3,
      selection: $selectedView,
      destination: remoteHTMLView(
        url: TPPSettings.TPPPrivacyPolicyURLString,
        title: Strings.Settings.privacyPolicy
      ).anyView()
    )
  }
  
  @ViewBuilder private var softwareLicensesRow: some View {
    navigationLinkRow(
      title: Strings.Settings.softwareLicenses,
      index: 4,
      selection: $selectedView,
      destination: bundledHTMLView(
        resource: "software-licenses",
        title: Strings.Settings.privacyPolicy
      ).anyView()
    )
  }
  
  @ViewBuilder private var userAgreementRow: some View {
    navigationLinkRow(
      title: Strings.Settings.eula,
      index: 5,
      selection: $selectedView,
      destination: remoteHTMLView(
        url: TPPSettings.TPPUserAgreementURLString,
        title: Strings.Settings.eula
      ).anyView()
    )
  }
  
  @ViewBuilder private var instructionsRow: some View {
    navigationLinkRow(
      title: Strings.Settings.instructions,
      index: 6,
      selection: $selectedView,
      destination: remoteHTMLView(
        url: TPPSettings.TPPInstructionsURLString,
        title: Strings.Settings.instructions
      ).anyView()
    )
  }

  @ViewBuilder private var preferencesRow: some View {
    navigationLinkRow(
      title: Strings.Preferences.preferencesButton,
      destination: PreferencesView().anyView()
    )
  }

  private func navigationLinkRow(title: String, destination: AnyView) -> some View {
    NavigationLink(
      destination: destination,
      label: { Text(title) }
    )
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
  }
  
  private func navigationLinkRow(title: String, index: Int, selection: Binding<Int?>, destination: AnyView) -> some View {
    NavigationLink(
      destination: destination,
      tag: index,
      selection: selection,
      label: { Text(title) }
    )
    .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
  }
  
  private func buttonLabelHStackRow(title: String) -> some View {
    HStack {
      Text(title)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      Spacer()
      Image("ArrowRight")
        .padding(.leading, 10)
        .foregroundColor(Color(uiColor: .lightGray))
    }
  }
  
  @ViewBuilder private func remoteHTMLView(url: String, title: String) -> some View {
    let controller = RemoteHTMLViewController(
      URL: URL(string: url)!,
      title: title,
      failureMessage: Strings.Error.loadFailedError
    )
    
    UIViewControllerWrapper(controller, updater: { _ in })
      .navigationBarTitle(Text(title))
  }
  
  @ViewBuilder private func bundledHTMLView(resource: String, title: String) -> some View {
    let controller = BundledHTMLViewController(
      fileURL: Bundle.main.url(forResource: resource, withExtension: "html")!,
      title: title
    )
    
    UIViewControllerWrapper(controller, updater: { _ in })
      .navigationBarTitle(Text(title))
  }
}
