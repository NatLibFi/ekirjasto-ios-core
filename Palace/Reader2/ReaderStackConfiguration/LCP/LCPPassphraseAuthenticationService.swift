//
//  LCPPassphraseAuthenticationService.swift
//  The Palace Project
//
//  Created by Ernest Fan on 2021-02-08.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

#if LCP

import Foundation
import ReadiumLCP

/**
 For Passphrase in License Document, see https://readium.org/lcp-specs/releases/lcp/latest#41-introduction
 */
class LCPPassphraseAuthenticationService: LCPAuthenticating {

  @MainActor
  func retrievePassphrase(
    for license: LCPAuthenticatedLicense,
    reason: LCPAuthenticationReason,
    allowUserInteraction: Bool,
    sender: Any?
  ) async -> String? {
    if TPPSettings.shared.enterLCPPassphraseManually {
      return await requestPassphrase(for: license, reason: reason, allowUserInteraction: allowUserInteraction, sender: sender)
    } else {
      return await retrievePassphraseFromLoan(for: license, reason: reason, allowUserInteraction: allowUserInteraction, sender: sender)
    }
  }

  /// Retrieves LCP passphrase from loans
  private func retrievePassphraseFromLoan(
    for license: LCPAuthenticatedLicense,
    reason: LCPAuthenticationReason,
    allowUserInteraction: Bool,
    sender: Any?
  ) async -> String? {
    let licenseId = license.document.id
    let registry = TPPBookRegistry.shared
    guard let loansUrl = AccountsManager.shared.currentAccount?.loansUrl else {
      return nil
    }
    let logError = makeLogger(code: .lcpPassphraseRetrievalFail, urlKey: "loansUrl", urlValue: loansUrl)
    guard let books = registry.loans as? [TPPBook],
          let book = books.filter({ registry.fulfillmentId(forIdentifier: $0.identifier) == licenseId }).first else {
      logError("LCP passphrase retrieval error: no book with fulfillment id found", "licenseId", licenseId)
      return nil
    }

    return await withCheckedContinuation { continuation in
      TPPNetworkExecutor.shared.GET(loansUrl) { result in
        switch result {
        case .success(let data, _):
          let responseBody = String(data: data, encoding: .utf8)
          guard let xml = TPPXML(data: data),
                let entries = xml.children(withName: "entry") as? [TPPXML]
          else {
            logError("LCP passphrase retrieval error: loans XML parsing failed", "responseBody", responseBody ?? "N/A")
            continuation.resume(returning: nil)
            return
          }
          for entry in entries {
            if let entryId = entry.firstChild(withName: "id")?.value, entryId == book.identifier {
              guard let links = (entry.children as? [TPPXML])?.filter({ $0.name == "link" }) else {
                continue
              }
              for link in links {
                if let passphrase = link.firstChild(withName: "hashed_passphrase")?.value {
                  continuation.resume(returning: passphrase)
                  return
                }
              }
            }
          }
          logError("LCP passphrase retrieval error: passphrase not found for \(book.identifier)", "responseBody", responseBody ?? "N/A")
          continuation.resume(returning: nil)
        case .failure(let error, _):
          logError("LCP passphrase retrieval error", NSUnderlyingErrorKey, error)
          continuation.resume(returning: nil)
        }
      }
    }
  }

  /// Enter LCP passphrase manually
  @MainActor
  private func requestPassphrase(
    for license: LCPAuthenticatedLicense,
    reason: LCPAuthenticationReason,
    allowUserInteraction: Bool,
    sender: Any?
  ) async -> String? {
    return await withCheckedContinuation { continuation in
      var passphraseField: UITextField?
      let ac = UIAlertController(title: "Enter LCP Passphrase", message: license.hint, preferredStyle: .alert)
      let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
        continuation.resume(returning: passphraseField?.text)
      }
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        continuation.resume(returning: nil)
      }
      ac.addAction(doneAction)
      ac.addAction(cancelAction)
      ac.addTextField { textField in
        textField.placeholder = "Passphrase"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.keyboardType = .default
        textField.returnKeyType = .done
        textField.isSecureTextEntry = true
        passphraseField = textField
      }
      TPPAlertUtils.presentFromViewControllerOrNil(alertController: ac, viewController: nil, animated: true, completion: nil)
    }
  }

  private func makeLogger(code: TPPErrorCode, urlKey: String, urlValue: URL) -> (_ summary: String, _ errorKey: String, _ errorValue: Any) -> Void {
    func logError(summary: String, errorKey: String, errorValue: Any) -> Void {
      TPPErrorLogger.logError(
        withCode: code,
        summary: summary,
        metadata: [
          urlKey: urlValue,
          errorKey: errorValue
        ]
      )
    }
    return logError
  }
}

#endif
