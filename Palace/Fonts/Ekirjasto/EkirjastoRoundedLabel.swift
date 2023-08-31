//
//  EkirjastoRoundedLabel.swift
//  Ekirjasto
//
//  Created by Nianzu on 21.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import UIKit

class EkirjastoRoundedLabel: UILabel {
  var edgeInset: UIEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

  override func drawText(in rect: CGRect) {
    self.layer.borderColor = TPPConfiguration.iconColor().cgColor
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 13;
    let insets = UIEdgeInsets.init(top: edgeInset.top, left: edgeInset.left, bottom: edgeInset.bottom, right: edgeInset.right)
    super.drawText(in: rect.inset(by: insets))
  }

  override var intrinsicContentSize: CGSize {
      let size = super.intrinsicContentSize
      return CGSize(width: size.width + edgeInset.left + edgeInset.right, height: size.height + edgeInset.top + edgeInset.bottom)
  }
}
