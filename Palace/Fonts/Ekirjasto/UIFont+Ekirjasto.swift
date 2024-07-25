//
//  UIFont+Ekirjasto.swift
//  Ekirjasto
//
//  Created by Nianzu on 19.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

extension UIFont {

  @objc class func palaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
  }

  @objc class func palaceFont(ofSize fontSize: CGFloat) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
  }

  @objc class func semiBoldPalaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
  }

  @objc class func semiBoldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
  }

  @objc class func boldPalaceFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: UIFont.preferredFont(forTextStyle: textStyle).pointSize) ?? UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
      return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
  }

  @objc class func boldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
      let font = UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
      return UIFontMetrics.default.scaledFont(for: font)
  }

}
