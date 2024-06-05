//
//  TransifexManager.swift
//  Palace
//
//  Created by Maurice Carriers on 9/6/22.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation
import Transifex

class CustomLocaleProvider : TXCurrentLocaleProvider {
    func currentLocale() -> String {
      return Bundle.main.preferredLocalizations[0]
    }
}

@objc class TransifexManager: NSObject {
  @objc static func setup() {
    let appLanguages = "en,fi,sv"
    let locales = TXLocaleState(sourceLocale: "en",
                                appLocales: appLanguages.components(separatedBy: ","),
                                currentLocaleProvider: CustomLocaleProvider())

    TXNative.initialize(
      locales: locales,
      // TODO:SAMI: Move the token to a config file
      token: ""
    )

    TXNative.fetchTranslations()
  }
}
