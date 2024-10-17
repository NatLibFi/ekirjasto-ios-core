import Foundation

@objc protocol TPPFacetBarViewDelegate {
  func present(_ viewController: UIViewController)
}

@objcMembers class TPPFacetBarView : UIView {
  var entryPointView: TPPEntryPointView = TPPEntryPointView()
 
  private let borderHeight = 1.0 / UIScreen.main.scale;
  private let toolbarHeight = CGFloat(40.0);

  weak var delegate: TPPFacetBarViewDelegate?
  
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
    topBorderView.autoSetDimension(.height, toSize:borderHeight)
    return view
  }()
  
  @available(*, unavailable)
  private override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(origin: CGPoint, width: CGFloat) {
    
    super.init(frame: CGRect(x: origin.x, y: origin.y, width: width, height: borderHeight + toolbarHeight + 52.0))
    
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
    entryPointView.isHidden = false;
    facetView.isHidden = true;

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
