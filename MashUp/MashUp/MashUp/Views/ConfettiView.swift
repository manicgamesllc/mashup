import SwiftUI

struct ConfettiView: View {
    @Binding var isShowing: Bool
    let duration: Double = 3.0  // Changed duration to 5 seconds
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<100) { _ in
                    ConfettiPiece(
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        startY: -20,
                        screenHeight: geometry.size.height
                    )
                    .opacity(isShowing ? 1 : 0)
                }
            }
        }
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

private struct ConfettiPiece: View {
    let startX: CGFloat
    let startY: CGFloat
    let screenHeight: CGFloat
    
    @State private var rotation = Double.random(in: 0...360)
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    
    private let color: Color
    private let size: CGFloat
    private let fallDuration: Double
    private let swayDistance: CGFloat
    
    init(startX: CGFloat, startY: CGFloat, screenHeight: CGFloat) {
        self.startX = startX
        self.startY = startY
        self.screenHeight = screenHeight
        
        let colors: [Color] = [.red, .blue, .yellow, .green, .purple, .orange, .pink]
        self.color = colors.randomElement() ?? .blue
        self.size = CGFloat.random(in: 5...8)
        self.fallDuration = Double.random(in: 2.0...3.0)
        self.swayDistance = CGFloat.random(in: -30...30)
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                x = startX
                y = startY
                
                withAnimation(
                    .linear(duration: fallDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = Double.random(in: -360...360)
                    x = startX + swayDistance
                    y = screenHeight + 50
                }
            }
    }
}
