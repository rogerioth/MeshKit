//
//  MeshSize.swift
//  
//
//  Created by Roger Hirooka on 11/16/23.
//

import Foundation

public struct MeshSize: Codable, Hashable {
    public init(width: Int = 3, height: Int = 3) {
        self.width = width
        self.height = height
    }

    public var width: Int
    public var height: Int

    public static var standard: MeshSize {
        return .init()
    }

    public static var zero: MeshSize {
        return .init(width: 0, height: 0)
    }
}
