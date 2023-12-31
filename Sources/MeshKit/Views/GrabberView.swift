//
//  SwiftUIView.swift
//
//
//  Created by Ethan Lipnik on 8/28/22.
//

import SwiftUI

struct GrabberView: View {
  @Binding var grid: MeshColorGrid
  @Binding var selectedPoint: MeshColor?

  var didMovePoint: (_ x: Int, _ y: Int, _ translation: CGSize, _ meshPoint: MeshPoint) -> Void

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        ForEach(0..<grid.width, id: \.self) { x in
          GridView(
            x: x, grid: $grid, selectedPoint: $selectedPoint, proxy: proxy,
            didMovePoint: didMovePoint)
        }
      }
    }
  }
}

struct GridView: View {
  let x: Int
  @Binding var grid: MeshColorGrid
  @Binding var selectedPoint: MeshColor?
  let proxy: GeometryProxy
  var didMovePoint: (_ x: Int, _ y: Int, _ translation: CGSize, _ meshPoint: MeshPoint) -> Void

  var body: some View {
    ForEach(0..<grid.height, id: \.self) { y in
      let offset = (grid.height - 1)
      let isEdge = grid.isEdge(x: x, y: y)

      let xOffset = CGFloat(Int(proxy.size.width) * x) / CGFloat(grid.width - 1)
      let yOffset = CGFloat(Int(proxy.size.height) * y) / CGFloat(grid.height - 1)

      PointView(
        point: $grid[x, offset - y], grid: $grid, selectedPoint: $selectedPoint, proxy: proxy,
        isEdge: isEdge
      ) { translation, meshPoint in
        didMovePoint(x, offset - y, translation, meshPoint)
      }
      .offset(
        x: xOffset - (x + 1 == grid.width ? 60 : 0) + (x == 0 ? 30 : -30),
        y: yOffset - (y + 1 == grid.height ? 60 : 0) + (y == 0 ? 30 : -30)
      )
    }
  }
}

struct PointView: View {
  @Binding var point: MeshColor
  @Binding var grid: MeshColorGrid
  @Binding var selectedPoint: MeshColor?
  let proxy: GeometryProxy
  let isEdge: Bool
  var didMove: (_ translation: CGSize, _ point: MeshPoint) -> Void

  @State private var offset: CGSize = .zero

  var body: some View {
    Circle()
      .fill(selectedPoint == point ? Color.white : Color.black.opacity(0.2))
      .scaleEffect(selectedPoint == point ? 1.1 : 1)
      .scaleEffect(isEdge ? 0.5 : 1)
      .shadow(color: .black.opacity(0.2), radius: 8, y: 8)
      .offset(offset)
      .animation(.interactiveSpring(), value: offset)
      .animation(.easeInOut, value: selectedPoint)
      .frame(maxWidth: 35, maxHeight: 35)
      .onTapGesture {
        selectedPoint = point
      }
      .gesture(
        DragGesture()
          .onChanged({ value in
            selectedPoint = point

            guard !isEdge else { return }

            let location = value.location
            var width = location.x / (proxy.size.width / 2)
            var height = location.y / (proxy.size.height / 2)

            width = min(0.3, max(-0.3, width))
            height = min(0.3, max(-0.3, height))

            let meshPoint = MeshPoint(
              x: Float(width) + point.startLocation.x, y: -Float(height) + point.startLocation.y)
            point.location = meshPoint

            let offsetWidth = -proxy.size.width / CGFloat(grid.width)
            let offsetX = min(abs(offsetWidth) - 45, max(offsetWidth + 45, location.x))

            let offsetHeight = -proxy.size.height / CGFloat(grid.height)
            let offsetY = min(abs(offsetHeight) - 45, max(offsetHeight + 45, location.y))
            offset = CGSize(width: offsetX, height: offsetY)

            didMove(CGSize(width: width, height: 1 - height), meshPoint)
          })
      )
  }
}
