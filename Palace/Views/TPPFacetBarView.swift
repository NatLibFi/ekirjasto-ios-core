import Foundation

@objc protocol TPPFacetBarViewDelegate {
  func present(_ viewController: UIViewController)
}

@objcMembers class TPPFacetBarView : UIView {
  var entryPointView: TPPEntryPointView = TPPEntryPointView()
 
  private let accountSiteButton = UIButton()
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
  
  private lazy var logoView: UIView = {
    let logoView = UIView()
    logoView.backgroundColor = TPPConfiguration.readerBackgroundColor()
    
    let imageHolder = UIView()
    imageHolder.autoSetDimension(.height, toSize: 40.0)
    imageHolder.autoSetDimension(.width, toSize: 40.0)
    imageHolder.addSubview(imageView)
    
    imageView.autoPinEdgesToSuperviewEdges()
    
    let container = UIView()
    logoView.addSubview(container)
    container.addSubview(imageHolder)
        
    container.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0))
    imageHolder.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 10.0, left: 0.0, bottom: 0.0, right: 0.0), excludingEdge: .trailing)

    return logoView
  }()
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.lineBreakMode = .byWordWrapping
    label.numberOfLines = 0
    label.textAlignment = .center
    label.text = AccountsManager.shared.currentAccount?.name
    label.textColor = .gray
    label.font = UIFont.boldSystemFont(ofSize: 18.0)
    return label
  }()
  
  private lazy var imageView: UIImageView = {
    let view = UIImageView(image: UIImage(named: "LaunchImageLogo"))
    view.contentMode = .scaleAspectFill
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
    addSubview(logoView)
    addSubview(entryPointView)

    setupConstraints()
  }
  
  private func setupConstraints() {
    entryPointView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
    facetView.autoPinEdge(toSuperviewEdge: .leading)
    facetView.autoPinEdge(toSuperviewEdge: .trailing)
    
    entryPointView.autoPinEdge(.bottom, to: .top, of: facetView)
    logoView.autoPinEdge(.top, to: .bottom, of: facetView, withOffset: 10.0)
    logoView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10.0)
    logoView.autoAlignAxis(.vertical, toSameAxisOf: self, withOffset: -15)
    logoView.autoConstrainAttribute(.width, to: .width, of: self, withMultiplier: 0.8, relation: .lessThanOrEqual)
  }
  
  @objc func removeLogo() {
    self.logoView.removeFromSuperview()
    facetView.autoPinEdge(.top, to: .bottom, of: facetView, withOffset: 10.0)   //Added by Ellibs
    facetView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10.0)          
  }
  
  @objc private func showAccountPage() {
    guard let homePageUrl = AccountsManager.shared.currentAccount?.homePageUrl, let url = URL(string: homePageUrl) else { return }
    let webController = BundledHTMLViewController(fileURL: url, title: AccountsManager.shared.currentAccount?.name.capitalized ?? "")
    webController.hidesBottomBarWhenPushed = true
    delegate?.present(webController)
  }
}
