import SwiftUI

struct BlobOutlineView: View {
    
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @Binding var activeBlobID: UUID?
    
    // Hover state for heading rows
    @State private var hoveredRowID: UUID? = nil
    
    static let rowHeight: CGFloat = 26
    
    // MARK: - Body
    
    var body: some View {
        
    }
    
    @ViewBuilder
    private func blobOutline(_ blob: Blob) -> some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("OUTLINE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(AppColors.shared.contentSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
            }
        }
    }
}
