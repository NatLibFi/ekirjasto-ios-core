//
//  UIFont+Ekirjasto.swift
//  Ekirjasto
//
//  Created by Nianzu on 19.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

extension UIFont {
  @objc class func palaceFont(ofSize fontSize: CGFloat) -> UIFont {
    UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize)!
  }
  
  @objc class func semiBoldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
    UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize)!
  }
  
  @objc class func boldPalaceFont(ofSize fontSize: CGFloat) -> UIFont {
    UIFont(name: TPPConfiguration.ekirjastoFontName(), size: fontSize)!
  }
}
