import UIKit

final class TPPContentBadgeImageView: UIImageView {

  @objc enum TPPBadgeImage: Int {
    case audiobook
    case ebook

    func assetName() -> String {
      switch self {
      case .audiobook:
        return "AudiobookBadge"
      case .ebook:
        fatalError("No asset yet")
      }
    }
  }

  @objc required init(badgeImage: TPPBadgeImage) {
    super.init(image: UIImage(named: badgeImage.assetName()))
    backgroundColor = UIColor(named: "ColorEkirjastoGreen") //edited by Ellibs
    tintColor = UIColor(named: "ColorEkirjastoBlack") //Added by Ellibs
    layer.borderWidth = 1.5 //Added by Ellibs
    layer.borderColor = UIColor.white.cgColor //Added by Ellibs
    contentMode = .scaleAspectFit
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc class func pin(badge: UIImageView, toView view: UIView, isLane: Bool) {
    if (badge.superview == nil) {
      view.addSubview(badge)
    }
    badge.autoSetDimensions(to: CGSize(width: 30, height: 30))
    if(!isLane) {
      badge.autoPinEdge(.trailing, to: .trailing, of: view, withOffset: 6)
      badge.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -6)
    } else {
      badge.autoPinEdge(.trailing, to: .trailing, of: view, withOffset: -6)
      badge.autoPinEdge(.bottom, to: .bottom, of: view)
    }
  }
}
