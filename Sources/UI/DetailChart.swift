import SwiftUI

/// 迷你柱状图 — 用于 CPU 历史趋势展示
struct DetailChart: View {
    let dataPoints: [Double]
    let barColor: Color

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(dataPoints.indices, id: \.self) { index in
                    let value = dataPoints[index]
                    let maxValue = max(dataPoints.max() ?? 100, 1)
                    let height = max(CGFloat(value / maxValue) * geometry.size.height, 2)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor)
                        .frame(width: max((geometry.size.width - CGFloat(dataPoints.count - 1) * 2) / CGFloat(dataPoints.count), 1),
                               height: height)
                }
            }
        }
    }
}

#Preview {
    DetailChart(
        dataPoints: [12, 25, 18, 45, 32, 67, 54, 23, 41, 38],
        barColor: .blue
    )
    .frame(width: 150, height: 40)
    .padding()
}
