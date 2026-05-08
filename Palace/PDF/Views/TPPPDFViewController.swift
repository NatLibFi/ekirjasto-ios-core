//
//  TPPPDFViewController.swift
//  Palace
//
//  Created by Vladimir Fedorov on 31.05.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI

/// Maximum file size the app can decrypt without crashing
fileprivate let supportedEncryptedDataSize = 200 * 1024 * 1024

class TPPPDFViewController: NSObject {

  @objc static func create(document: TPPPDFDocument, metadata: TPPPDFDocumentMetadata) -> UIViewController {
    // Resolve the effective document (decrypt if needed) before constructing the host.
    let readerDocument: TPPPDFDocument
    if document.isEncrypted && document.data.count < supportedEncryptedDataSize {
      let data = document.decrypt(data: document.data, start: 0, end: UInt(document.data.count))
      readerDocument = TPPPDFDocument(data: data)
    } else {
      readerDocument = document
    }

    // Create the host first with a placeholder rootView so we can capture it
    // weakly in the dismiss closure. `@Environment(\.dismiss)` does not bridge
    // across the UIKit modal presentation used on iPad, so we dismiss/pop
    // explicitly based on where the host ended up in the VC hierarchy.
    let controller = UIHostingController(rootView: AnyView(EmptyView()))
    controller.title = metadata.title ?? ""
    controller.hidesBottomBarWhenPushed = true

    let onDismiss: () -> Void = { [weak controller] in
      guard let controller = controller else { return }
      if let nav = controller.navigationController,
         nav.viewControllers.first !== controller {
        // Pushed onto an existing nav stack (iPhone path)
        nav.popViewController(animated: true)
      } else if let nav = controller.navigationController {
        // Root of a modally-presented nav controller (iPad path)
        nav.dismiss(animated: true)
      } else {
        controller.dismiss(animated: true)
      }
    }

    controller.rootView = AnyView(
      TPPPDFReaderView(document: readerDocument, onDismiss: onDismiss)
        .environmentObject(metadata)
    )
    return controller
  }

}
