//
//  TPPSignInBusinessLogic+Extensions.swift
//  Palace
//
//  Created by Joni Salmela on 22.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation


extension TPPSignInBusinessLogic {
  
  private static var shared : TPPSignInBusinessLogic? = nil
  
  public static func getShared(completion: @escaping (TPPSignInBusinessLogic?)->()){
    
    if let _shared = shared {
      completion(_shared)
      return
    }
    
    AccountsManager.shared.onAccountsHaveLoaded {
      let account = AccountsManager.shared.accounts().first!

      shared = TPPSignInBusinessLogic(libraryAccountID: account.uuid, libraryAccountsProvider: AccountsManager.shared, urlSettingsProvider: TPPSettings.shared, bookRegistry: TPPBookRegistry.shared as TPPBookRegistrySyncing, bookDownloadsCenter: MyBooksDownloadCenter.shared, userAccountProvider: TPPUserAccount.self, uiDelegate: nil, drmAuthorizer: nil)
      completion(shared)
    }
    

  }
  
  public func notifySignIn(){
    if libraryAccountID == libraryAccountsProvider.currentAccountId {
      bookRegistry.sync()
    }

    NotificationCenter.default.post(name: .TPPIsSigningIn, object: false)
  }
  
}
