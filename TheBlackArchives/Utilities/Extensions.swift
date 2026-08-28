import SwiftUI

extension View {
    func border(width: CGFloat, edge: Edge, color: Color) -> some View {
        modifier(EdgeBorder(width: width, edge: edge, color: color))
    }
}

struct EdgeBorder: ViewModifier {
    var width: CGFloat
    var edge: Edge
    var color: Color
    
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                self.makeBorder(size: geo.size)
            }
        )
    }
    
    private func makeBorder(size: CGSize) -> some View {
        let x: CGFloat = 0
        let y: CGFloat = 0
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        
        return Rectangle()
            .fill(color)
            .frame(
                width: (edge == .leading || edge == .trailing) ? width : w,
                height: (edge == .top || edge == .bottom) ? width : h
            )
            .offset(x: edge == .trailing ? w - width : x, y: edge == .bottom ? h - width : y)
    }
}
