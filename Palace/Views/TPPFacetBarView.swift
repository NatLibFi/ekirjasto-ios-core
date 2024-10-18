//
//  TTPFacetBarView.swift
//
//  Last edited by E-KIRJASTO October 2024
//

import Foundation

@objc protocol TPPFacetBarViewDelegate {
  func present(_ viewController: UIViewController)
}

/*
 TPPFacetBarView is a UIView that has two subviews:
  - facetView
  - entryPointView

 In original Palace project the current library account's logo and name were displayed in a third subview called logoView
  - E-kirjasto app does not display the logo or name separately in app's basic views (Browse books, My books, Reservations) and the logoView subview was removed from TPPFacetBarView.
  - Also the functionality to show library details (the account page) when user taps said library logo or name, was removed from E-kirjasto app.
 */
@objcMembers class TPPFacetBarView: UIView {
  
  /*
   entryPointView
    - class TPPEntryPointView
    - is visible
    - contains the segmented buttons for filtering the books catalogue in app's Browse books view
    - see more details of this view in file TPPEntryPointView.swift
   */
  var entryPointView: TPPEntryPointView = .init()
  
  private let borderHeight = 1.0 / UIScreen.main.scale
  private let toolbarHeight = CGFloat(40.0)
  
  weak var delegate: TPPFacetBarViewDelegate?
  
  /*
  facetView
   - class TPPFacetView
   - hidden view
   - the bottom line of the facetView marks the point where the catalogue's book lane title "freezes" for a while, until it's replaced with another lane title
   - in other words, the facetView prevents the catalogue book lanes from visually sliding under the catalogue filter buttons when user scrolls the catalogue view up or down
   */
  lazy var facetView: TPPFacetView = {
    let view = TPPFacetView()
    
    let topBorderView = UIView()
    let bottomBorderView = UIView()
    
    topBorderView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)
    bottomBorderView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)
    
    view.addSubview(bottomBorderView)
    view.addSubview(topBorderView)
    
    bottomBorderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
    bottomBorderView.autoSetDimension(.height, toSize: borderHeight)
    topBorderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
    topBorderView.autoSetDimension(.height, toSize: borderHeight)
    
    return view
  }()
  
  @available(*, unavailable)
  override private init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(origin: CGPoint, width: CGFloat) {
    super.init(
      frame: CGRect(
        x: origin.x,
        y: origin.y,
        width: width,
        height: borderHeight + toolbarHeight + 52.0
      )
    )
    
    setupViews()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
  }
  
  private func setupViews() {
    backgroundColor = TPPConfiguration.backgroundColor()
    
    entryPointView.isHidden = false
    facetView.isHidden = true
    
    addSubview(facetView)
    addSubview(entryPointView)
    
    setupConstraints()
  }
  
  private func setupConstraints() {
    entryPointView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
    facetView.autoPinEdge(toSuperviewEdge: .leading)
    facetView.autoPinEdge(toSuperviewEdge: .trailing)
    facetView.autoPinEdge(.top, to: .bottom, of: facetView, withOffset: 10.0)
    facetView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10.0)
    entryPointView.autoPinEdge(.bottom, to: .top, of: facetView)
  }
  
}
