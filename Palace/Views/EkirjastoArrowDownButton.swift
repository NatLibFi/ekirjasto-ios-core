//
//  EkirjastoArrowDownButton.swift
//  Ekirjasto
//
//  Created by Nianzu on 20.6.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import UIKit

private let ButtonPadding: CGFloat = 6.0

@objc enum ArrowDownButtonType: Int {
  case normal
  case clock
}

@objc class ArrowDownButton: UIButton {
  // Properties
  private var type: ArrowDownButtonType {
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
  
  // UI Components
  private let label: UILabel = UILabel()
  private let iconView: UIImageView = UIImageView()
  
  // Initializer
  init(type: ArrowDownButtonType, endDate: Date?, isFromDetailView: Bool) {
    self.type = type
    self.endDate = endDate
    self.isFromDetailView = isFromDetailView
    
    super.init(frame: CGRect.zero)
    
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setter
  @objc func setType(_ type: ArrowDownButtonType) {
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
    label.textColor = self.tintColor
    label.font = UIFont.palaceFont(ofSize: 9)
    
    addSubview(label)
    addSubview(iconView)
  }
  
  private func updateViews() {
    let padX = ButtonPadding + 2
    let padY = ButtonPadding
  
    self.iconView.image = UIImage.init(named: "ArrowDownEkirjasto")?.withRenderingMode(.alwaysTemplate)
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
  
  private func updateColors() {
    let color: UIColor = self.isEnabled ? UIColor(named: "ColorEkirjastoGreen")! : UIColor.gray
    self.layer.borderColor = color.cgColor
    self.label.textColor = color
    self.iconView.tintColor = color
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
    s.width += ButtonPadding * 2
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

extension ArrowDownButton {
  @objc (initWithType:isFromDetailView:)
  convenience init(type: ArrowDownButtonType, isFromDetailView: Bool) {
    self.init(type: type, endDate: nil, isFromDetailView: isFromDetailView)
  }
}
