//
//  ChartView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 17/12/2023.
//

import SwiftUI
import Charts

struct INRChartView: View {
    var data: [INR]
    
    @AppStorage("INRLowerLimit") var lowerLimit: Double?
    @AppStorage("INRUpperLimit") var upperLimit: Double?
    
    var body: some View {
        Chart{
            ForEach(data){pomiar in
                BarMark(
                    x: .value("Data", pomiar.date, unit: .weekOfYear),
                    y: .value("Wartosc", pomiar.value)
                )
                .annotation{
                    Text(verbatim: pomiar.value.formatted()).font(.caption).dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .foregroundStyle(barColorINR(value: pomiar.value))
            }
        }
    }
    
    func barColorINR(value: Double) -> Color{
        let ll = lowerLimit ?? 2
        let ul = upperLimit ?? 3
        
        switch(value){
        case ll..<ul:
            return .green
        case (ll-ll/4)..<ll:
            return .yellow
        case ul..<(ul+ul/4):
            return .yellow
        default:
            return .red
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        INRChartView(data: [INR(value: 4, date: Date()), INR(value: 3, date: Date())])
    }
}
