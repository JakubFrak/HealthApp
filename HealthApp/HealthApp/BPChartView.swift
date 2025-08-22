//
//  BPChartView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 19/12/2023.
//

import SwiftUI
import Charts

struct BPChartView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    var data: [Tetno]
    
    var body: some View {
        ScrollView{
            Text("Puls").font(.title2)
            Chart{
                ForEach(data){pomiar in
                    LineMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.pulse)
                    ).symbol{
                        Circle().fill(.blue).frame(width: 5)
                    }
                    PointMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.pulse))
                    .annotation{
                        if(dynamicTypeSize < DynamicTypeSize.accessibility1){
                            Text("\(pomiar.pulse, specifier: "%.0f")").font(.caption)//.dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                    }
                }
            }.chartYScale(domain: [40, 120]).frame(width: 300, height: self.dynamicTypeSize.isAccessibilitySize ? 600 : 300)
            Text("Ciśnienie rozkurczowe").font(.title2)
            Chart{
                ForEach(data){pomiar in
                    LineMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.diastolic_pressure)
                    ).symbol{
                        Circle().fill(.blue).frame(width: 5)
                    }.foregroundStyle(.green)
                    PointMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.diastolic_pressure))
                    .annotation{
                        if(dynamicTypeSize < DynamicTypeSize.accessibility1){
                            Text("\(pomiar.diastolic_pressure, specifier: "%.0f")").font(.caption)//.dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                    }.foregroundStyle(.green)
                }
            }.chartYScale(domain: [40, 120]).frame(width: 300, height: self.dynamicTypeSize.isAccessibilitySize ? 600 : 300)
            Text("Ciśnienie skurczowe").font(.title2)
            Chart{
                ForEach(data){pomiar in
                    LineMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.systolic_pressure)
                    ).symbol{
                        Circle().fill(.blue).frame(width: 5)
                    }.foregroundStyle(.orange)
                    PointMark(
                        x: .value("Data", pomiar.time),
                        y: .value("Wartosc", pomiar.systolic_pressure))
                    .annotation{
                        if(dynamicTypeSize < DynamicTypeSize.accessibility1){
                            Text("\(pomiar.systolic_pressure, specifier: "%.0f")").font(.caption)//.dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        }
                    }.foregroundStyle(.orange)
                }
            }.chartYScale(domain: [90, 160]).frame(width: 300, height: self.dynamicTypeSize.isAccessibilitySize ? 600 : 300)
            
        }
    }
}

struct BPChartView_Previews: PreviewProvider {
    static var previews: some View {
        BPChartView(data: [Tetno(diastolic_pressure: 100, pulse: 100, systolic_pressure: 100, time: Date())])
    }
}
