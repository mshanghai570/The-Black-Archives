import SwiftUI

struct ProgressBar: View {
    let value: Double // Range 0.0 - 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(height: 6)
                
                // Progress
                Rectangle()
                    .fill(ArchiveColors.bronze)
                    .frame(width: geo.size.width * CGFloat(value), height: 6)
            }
            .border(ArchiveColors.border, width: 1)
        }
        .frame(height: 6)
    }
}
