//
//  TPPEncryptedPDFPageViewController.swift
//  Palace
//
//  Created by Vladimir Fedorov on 01.06.2022.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI

/// Single page view controller
class TPPEncryptedPDFPageViewController: UIViewController {
  
  private let contentInset: CGFloat = 5
  
  var document: TPPEncryptedPDFDocument
  var pageNumber: Int

  private var timer: Timer?
  private var imageView: UIImageView?
  private var scrollView: UIScrollView?
  private var didZoom = false
  private var image: UIImage? {
    didSet {
      imageView?.image = image
    }
  }
  private var doubleTap = UITapGestureRecognizer()
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(encryptedPdf: TPPEncryptedPDFDocument, pageNumber: Int) {
    self.document = encryptedPdf
    self.pageNumber = pageNumber
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    doubleTap.numberOfTapsRequired = 2
    doubleTap.addTarget(self, action: #selector(tappedToZoom))
    
    scrollView = UIScrollView(frame: view.bounds)
    scrollView!.minimumZoomScale = 1
    scrollView!.maximumZoomScale = 4
    scrollView!.delegate = self
    scrollView!.backgroundColor = .secondarySystemBackground
    view.addSubview(scrollView!)
    scrollView!.autoPinEdgesToSuperviewEdges()
    
    imageView = UIImageView(frame: view.bounds.insetBy(dx: contentInset * 2, dy: contentInset * 2))
    imageView!.contentMode = .scaleAspectFit
    imageView!.clipsToBounds = false
    imageView!.layer.shadowOffset = .zero
    imageView!.layer.shadowRadius = contentInset
    imageView!.layer.shadowOpacity = 0.2
    scrollView!.addSubview(imageView!)
    scrollView!.addGestureRecognizer(doubleTap)

    // Blank page
    if let pageSize = document.page(at: pageNumber)?.getBoxRect(.mediaBox).size {
      imageView!.image = UIImage(color: .white, size: pageSize)
    }
    
    // The page is rendered after a short delay to avoid rendering when the user quickly scrolls through pages
    timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { _ in
      self.renderPageImage()
    })
  }
  
  @objc func tappedToZoom(_ sender: UITapGestureRecognizer) {
    guard let scrollView = scrollView else {
      return
    }
    renderZoomedPageImage()
    if scrollView.zoomScale == 1.0 {
      let point = sender.location(in: scrollView)
      scrollView.zoom(to: CGRect(origin: point, size: .zero), animated: true)
    } else {
      scrollView.setZoomScale(1.0, animated: true)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    /// We need this code because UIPageViewController needs to re-render previous/next page
    /// after scrolling through the pages stops
    /// - UIPageViewController expects them to be correctly rendered in this case.
    if image == nil {
      renderPageImage()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    /// Cancel timer if the user quickly scrolls through the pages
    /// otherwise the queue will be filled with page rendering tasks
    timer?.invalidate()
    timer = nil
  }
  
  /// Render page for the view size
  private func renderPageImage() {
    let viewSize = self.view.bounds.size
    DispatchQueue.pdfImageRenderingQueue.async {
      if let pageImage = self.document.image(for: self.pageNumber, size: viewSize) {
        DispatchQueue.main.async {
          self.image = pageImage
        }
      }
    }
  }
  
  /// Render zoomed page for maximum scrollView zoom scale.
  ///
  /// Performs this rendering only once, and replaces current page image after that.
  private func renderZoomedPageImage() {
    if didZoom {
      return
    }
    didZoom = true
    guard let maxScale = self.scrollView?.maximumZoomScale, maxScale > 1.0 else {
      return
    }
    let viewSize = self.view.bounds.size
    let imageSize = CGSize(width: viewSize.width * maxScale, height: viewSize.height * maxScale)
    DispatchQueue.pdfImageRenderingQueue.async {
      if let pageImage = self.document.image(for: self.pageNumber, size: imageSize) {
        DispatchQueue.main.async {
          self.image = pageImage
        }
      }
    }
  }

}

extension TPPEncryptedPDFPageViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    renderZoomedPageImage()
  }
}
