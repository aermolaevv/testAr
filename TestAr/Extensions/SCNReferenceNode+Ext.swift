//
//  SCNReferenceNode+Ext.swift
//  TestAr
//
//  Created by Alexey on 5/18/20.
//  Copyright © 2020 Alexey. All rights reserved.
//

import ARKit
import SceneKit

extension SCNReferenceNode {
    convenience init(named resourceName: String, loadImmediately: Bool = true) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "scn", subdirectory: "Models.scnassets")!
        self.init(url: url)!
        if loadImmediately {
            self.load()
        }
    }
}
