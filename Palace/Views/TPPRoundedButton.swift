//
//  TPPRoundedButton.swift
//  The Palace Project
//
//  Created by Ernest Fan on 2021-03-31.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import UIKit

private let TPPRoundedButtonPadding: CGFloat = 10.0 //Edited by Ellibs

@objc enum TPPRoundedButtonType: Int {
  case normal
  case clock
}

@objc class TPPRoundedButton: UIButton {
  // Properties
  private var type: TPPRoundedButtonType {
    didSet {
      updateViews()
    }
  }
  private var endDate: Date? {
    didSet {
      updateViews()
    }
  }
  private var isFromDetailView: Bool
  private var isReturnButton: Bool? = false
  
  // UI Components
  private let label: UILabel = UILabel()
  private let iconView: UIImageView = UIImageView()
  
  // Initializer
  init(type: TPPRoundedButtonType, endDate: Date?, isFromDetailView: Bool, isReturnButton: Bool?) {
    self.type = type
    self.endDate = endDate
    self.isFromDetailView = isFromDetailView
    self.isReturnButton = isReturnButton
    
    super.init(frame: CGRect.zero)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setter
  @objc func setType(_ type: TPPRoundedButtonType) {
    self.type = type
  }
  
  @objc func setEndDate(_ date: NSDate?) {
    guard let convertedDate = date as Date? else {
      return
    }
    endDate = convertedDate
  }
  
  @objc func setFromDetailView(_ isFromDetailView: Bool) {
    self.isFromDetailView = isFromDetailView
  }
  
  // MARK: - UI
  private func setupUI() {
    titleLabel?.font = UIFont.palaceFont(ofSize: 14)
    layer.borderColor = UIColor(named: "ColorEkirjastoGreen")?.cgColor
    layer.borderWidth = 1
    layer.cornerRadius = 3
    layer.backgroundColor = UIColor(named: "ColorEkirjastoLightestGreen")?.cgColor //Added by Ellibs
    
    label.textColor = self.tintColor
    label.font = UIFont.palaceFont(ofSize: 9)
    
    addSubview(label)
    addSubview(iconView)
  }
  
  private func updateViews() {
    let padX = TPPRoundedButtonPadding + 2
    let padY = TPPRoundedButtonPadding
    
    if (self.type == .normal || self.isFromDetailView) {
      if isFromDetailView {
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
      } else {
        self.contentEdgeInsets = UIEdgeInsets(top: padY, left: padX, bottom: padY, right: padX)
      }
      self.iconView.isHidden = true
      self.label.isHidden = true
    } else {
      self.iconView.image = UIImage.init(named: "Clock")?.withRenderingMode(.alwaysTemplate)
      self.iconView.isHidden = false
      self.label.isHidden = false
      self.label.text = self.endDate?.timeUntilString(suffixType: .short) ?? ""
      self.label.sizeToFit()
      
      self.iconView.frame = CGRect(x: padX, y: padY/2, width: 14, height: 14)
      var frame = self.label.frame
      frame.origin = CGPoint(x: self.iconView.center.x - frame.size.width/2, y: self.iconView.frame.maxY)
      self.label.frame = frame
      self.contentEdgeInsets = UIEdgeInsets(top: padY, left: self.iconView.frame.maxX + padX, bottom: padY, right: padX)
    }
  }
  
  private func updateColors() {
    var color: UIColor = self.isEnabled ? self.tintColor : UIColor.gray
    self.layer.cornerRadius = 2
    if(self.isReturnButton == true) {
      self.layer.borderWidth = 0.8
      self.layer.borderColor = UIColor(named: "ColorEkirjastoGreen")?.cgColor
      self.backgroundColor = UIColor.clear
    } else {
      self.layer.borderColor = UIColor(named: "ColorEkirjastoGreen")?.cgColor
      color = UIColor(named: "ColorEkirjastoButtonTextWithBackground")!
      self.iconView.tintColor = color
      self.label.textColor = color
    }
    setTitleColor(color, for: .normal)
  }
  
  // Override UIView functions
  override var isEnabled: Bool {
    didSet {
      updateColors()
    }
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if (!self.isEnabled
      && self.point(inside: self.convert(point, to: self), with: event)) {
      return self
    }
    return super.hitTest(point, with: event)
  }
  
  override func sizeThatFits(_ size: CGSize) -> CGSize {
    var s = super.sizeThatFits(size)
    s.width += TPPRoundedButtonPadding * 2
    return s
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateColors()
  }
  
  override var accessibilityLabel: String? {
    get {
      guard !self.iconView.isHidden,
        let title = self.titleLabel?.text,
        let timeUntilString = self.endDate?.timeUntilString(suffixType: .long) else {
          return self.titleLabel?.text
      }
      return "\(title).\(timeUntilString) remaining."
    }
    set {}
  }
}

extension TPPRoundedButton {
  @objc (initWithType:isFromDetailView:isReturnButton:)
  convenience init(type: TPPRoundedButtonType, isFromDetailView: Bool, isReturnButton: Bool) {
    self.init(type: type, endDate: nil, isFromDetailView: isFromDetailView, isReturnButton: isReturnButton)
  }
}
