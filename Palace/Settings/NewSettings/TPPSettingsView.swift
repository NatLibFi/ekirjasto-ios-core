//
//  TPPSettingsView.swift
//  Palace
//
//  Created by Maurice Carrier on 12/2/21.
//  Copyright © 2021 The Palace Project. All rights reserved.
//

import SwiftUI
import CloudKit

struct TPPSettingsView: View {
  typealias DisplayStrings = Strings.Settings

  @AppStorage(TPPSettings.showDeveloperSettingsKey) private var showDeveloperSettings: Bool = false
  @State private var selectedView: Int? = 0
  @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
  //@State private var authenticated: Bool = TPPUserAccount.sharedAccount().authToken != nil
  @ObservedObject private var authHolder = TPPUserAccountAuthentication.shared

  //private var signInBusinessLogic = TPPSignInBusinessLogic.shared

  private var sideBarEnabled: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
      &&  UIDevice.current.orientation != .portrait
      &&  UIDevice.current.orientation != .portraitUpsideDown
  }

  var body: some View {

    /*if sideBarEnabled {
      NavigationView {
        listView
      }.navigationViewStyle(.stack)
    } else {*/
      listView.navigationBarItems(leading: leadingBarButton)
    //}
  }

  @ViewBuilder private var listView: some View {
    List {
      Section {
        
      } header: {
        HStack{
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
        }else {
          loginSection
        }
        
      }else{
        librariesSection
      }
      syncBookmarksSection
      //reportIssueSection
      infoSection
      // This shows the Finnish/Swedish version of the logo if that is the
      // current locale and the English version otherwise
      if ["fi", "sv"].contains(Locale.current.languageCode) {
        natLibFiLogoFiSv
      } else {
        natLibFiLogoEn
      }
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

  @State private var toggleSyncBookmarks = AccountsManager.shared.accounts().first?.details?.syncPermissionGranted ?? false
  @State private var toggleLogoutWarning = false
  @State private var syncEnabled = true//AccountsManager.shared.accounts().first?.details?.syncPermissionGranted ?? false
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
                syncEnabled = false
            }, postWork: { enableSync in
              syncEnabled = true
              toggleSyncBookmarks = enableSync
            })
          }
          
        }
    }
  }
  
  @ViewBuilder private var leadingBarButton: some View {
    Button {
      TPPRootTabBarController.shared().showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
    }
  }
  
 @ViewBuilder private var logoutSection: some View {
   Section{
    
     Button{
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
       
       
     } label: {
       HStack{
         Text(DisplayStrings.signOut)
         Spacer()
         Image("ArrowRight")
           .padding(.leading, 10)
           .foregroundColor(Color(uiColor: .lightGray))
       }
     }.alert(Strings.TPPSigninBusinessLogic.signout, isPresented: $toggleLogoutWarning){
       Button(DisplayStrings.signOut, role: .destructive) {
         TPPSignInBusinessLogic.getShared { logic in
           if let _logic = logic {
             if let alert = _logic.logOutOrWarn(){
               TPPRootTabBarController.shared().settingsViewController.present(alert, animated: true)
             }
             
           }
         }
       }
       
     } message: {
       Text(self.logoutText)
     }
     
     Button{
       let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
       
       /*let status = CKContainer.default().requestApplicationPermission(.userDiscoverability) { (status, error) in
           CKContainer.default().fetchUserRecordID { (record, error) in
               CKContainer.default().discoverUserIdentity(withUserRecordID: record!, completionHandler: { (userID, error) in
                   print(userID?.hasiCloudAccount)
                   print(userID?.lookupInfo?.phoneNumber)
                   print(userID?.lookupInfo?.emailAddress)
                   print((userID?.nameComponents?.givenName)! + " " + (userID?.nameComponents?.familyName)!)
               })
           }
        }*/
       
       
       passkey.register("", TPPUserAccount.sharedAccount().authToken!) { registerToken in
         if let token = registerToken, !token.isEmpty{
           TPPNetworkExecutor.shared.authenticateWithToken(token) { status in

           }
           
         }
       }
     } label: {
       HStack{
         Text(DisplayStrings.registerPasskey)
         Spacer()
         Image("ArrowRight")
           .padding(.leading, 10)
           .foregroundColor(Color(uiColor: .lightGray))
       }

     }
   }
  }
  
  @ViewBuilder private var loginSection: some View {
    Section{
      row(title: DisplayStrings.loginSuomiFi,destination:SuomiIdentificationWebView(authenticationDocument: AccountsManager.shared.currentAccount!.authenticationDocument).anyView())
      Button{
        /*let status = CKContainer.default().requestApplicationPermission(.userDiscoverability) { (status, error) in
            CKContainer.default().fetchUserRecordID { (record, error) in
                CKContainer.default().discoverUserIdentity(withUserRecordID: record!, completionHandler: { (userID, error) in
                    print(userID?.hasiCloudAccount)
                    print(userID?.lookupInfo?.phoneNumber)
                    print(userID?.lookupInfo?.emailAddress)
                    print((userID?.nameComponents?.givenName)! + " " + (userID?.nameComponents?.familyName)!)
                })
            }
         }*/
        let passkey = PasskeyManager(AccountsManager.shared.currentAccount!.authenticationDocument!)
        passkey.login { loginToken in
          if let token = loginToken, !token.isEmpty{
            TPPNetworkExecutor.shared.authenticateWithToken(token) { status in

            }
            
          }
        }
      } label: {
        HStack{
          Text(DisplayStrings.loginPasskey)
          Spacer()
          Image("ArrowRight")
            .padding(.leading, 10)
            .foregroundColor(Color(uiColor: .lightGray))
          
          
        }

      }
    } footer: {
      let viewController = RemoteHTMLViewController(
        URL: URL(string:  TPPSettings.TPPUserAgreementURLString)!,
        title: DisplayStrings.loginFooterUserAgreementText,
        failureMessage: Strings.Error.loadFailedError
      )
      
      let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })

      NavigationLink(
        destination: wrapper.anyView(),
        label: {
          Text(DisplayStrings.loginFooterUserAgreementText)
            .underline()
            .dynamicTypeSize(.xSmall)
            .foregroundColor(Color.init(uiColor: UIColor.link))
        }
      )
        
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
      .navigationBarTitle(Text(DisplayStrings.feedback))

    row(title: DisplayStrings.feedback, index: 1, selection: self.$selectedView, destination: wrapper.anyView())
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

  @ViewBuilder private var softwareLicenseRow: some View {
    let viewController = BundledHTMLViewController(
      fileURL: Bundle.main.url(forResource: "software-licenses", withExtension: "html")!,
      title: Strings.Settings.softwareLicenses
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.softwareLicenses))

    row(title: DisplayStrings.softwareLicenses, index: 4, selection: self.$selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var userAgreementRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPUserAgreementURLString)!,
      title: Strings.Settings.eula,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.eula))

    row(title: DisplayStrings.eula, index: 5, selection: self.$selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var faqRow: some View {
    let viewController = RemoteHTMLViewController(
      URL: URL(string: TPPSettings.TPPFAQURLString)!,
      title: Strings.Settings.faq,
      failureMessage: Strings.Error.loadFailedError
    )
    
    let wrapper = UIViewControllerWrapper(viewController, updater: { _ in })
      .navigationBarTitle(Text(DisplayStrings.faq))

    row(title: DisplayStrings.faq, index: 6, selection: self.$selectedView, destination: wrapper.anyView())
  }

  @ViewBuilder private var versionInfo: some View {
    let productName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let build = Bundle.main.object(forInfoDictionaryKey: (kCFBundleVersionKey as String)) as! String
    
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
    HStack{
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
    HStack{
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
