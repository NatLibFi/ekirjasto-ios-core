//
//  TransifexManager.swift
//  Palace
//
//  Created by Maurice Carriers on 9/6/22.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Transifex

class CustomLocaleProvider : TXCurrentLocaleProvider {
    func currentLocale() -> String {
      return Bundle.main.preferredLocalizations[0]
    }
}

@objc class TransifexManager: NSObject {
  @objc static func setup() {
    let locales = TXLocaleState(sourceLocale: "en",
                                appLocales: ["en", "fi", "sv"],
                                currentLocaleProvider: CustomLocaleProvider())

    TXNative.initialize(
      locales: locales,
      token: ""
    )

    TXNative.fetchTranslations()
  }
}
