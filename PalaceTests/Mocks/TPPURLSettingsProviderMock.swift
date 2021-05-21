//
//  TPPURLSettingsProviderMock.swift
//  The Palace Project
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class TPPURLSettingsProviderMock: NSObject, NYPLUniversalLinksSettings, NYPLFeedURLProvider {
  var accountMainFeedURL: URL?

  var universalLinksURL: URL {
    return URL(string: "https://example.com/univeral-link-redirect")!
  }
}

