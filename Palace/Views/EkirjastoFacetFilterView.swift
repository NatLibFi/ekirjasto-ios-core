//
//  EkirjastoFacetFilterView.swift
//  Ekirjasto
//
//  Created by Nianzu on 11.7.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation

@objc class EkirjastoFacetFilterView: UIView {
  private let categorySegmentedControl = UISegmentedControl(items: ["Kaikki", "e-kirjat", "Äänikirjat"])
  
  override init(frame: CGRect) {
    super.init(frame: .zero)
    
    self.backgroundColor = TPPConfiguration.backgroundColor()
    
    setupView()
  }
  
  func setupView(){
    addSubview(categorySegmentedControl)
    
    categorySegmentedControl.selectedSegmentIndex = 0
    categorySegmentedControl.setWidth(100, forSegmentAt: 0)
    categorySegmentedControl.setWidth(100, forSegmentAt: 1)
    categorySegmentedControl.setWidth(100, forSegmentAt: 2)
    categorySegmentedControl.autoAlignAxis(toSuperviewMarginAxis: .vertical)
    self.heightAnchor.constraint(equalToConstant: self.categorySegmentedControl.bounds.height + 15).isActive = true
    categorySegmentedControl.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
