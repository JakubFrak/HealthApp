//
//  IntakeAmountView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 22/12/2023.
//

import SwiftUI

struct IntakeAmountView: View {
    @Binding var intake: Intake
    
    var body: some View {
        switch intake.name{
        case "Nicotine":
            //Rectangle().frame(height: 200).cornerRadius(10).foregroundColor(.cyan)
            VStack{
                Text(convertIntakeRawValue(intake: intake.name)).foregroundColor(.white).font(.title2).multilineTextAlignment(.center)
                HStack{
                    Text("Spożyta ilość: ").foregroundColor(.white)
                    Picker("", selection: $intake.amount){
                        ForEach(Array(stride(from: 0, to: 210, by: 10)), id: \.self){index in
                            Text("\(index)").tag(index)
                        }
                    }.pickerStyle(.wheel).clipped().frame(height: 80)
                    Text("mg").foregroundColor(.white)
                }.padding([.leading, .trailing])
                Text("To w przybliżeniu \(Double(intake.amount)/13.0, specifier: "%.1f") papierosy").foregroundColor(.white).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity, minHeight: 200).background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case "Caffeine":
            //Rectangle().frame(height: 200).cornerRadius(10).foregroundColor(.cyan)
            VStack{
                Text(convertIntakeRawValue(intake: intake.name)).foregroundColor(.white).font(.title2).multilineTextAlignment(.center)
                HStack{
                    Text("Spożyta ilość: ").foregroundColor(.white)
                    Picker("", selection: $intake.amount){
                        ForEach(Array(stride(from: 0, to: 1000, by: 10)), id: \.self){index in
                            Text("\(index)").tag(index)
                        }
                    }.pickerStyle(.wheel).clipped().frame(height: 80)
                    Text("mg").foregroundColor(.white)
                }.padding([.leading, .trailing])
                Text("To w przybliżeniu \(Double(intake.amount)*2.5, specifier: "%.0f")ml kawy, \(Double(intake.amount)/2, specifier: "%.0f")ml espresso lub \(Double(intake.amount)*3.3, specifier: "%.0f")ml napoju energetycznego").foregroundColor(.white).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity, minHeight: 200).background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case "Alcohol":
            VStack{
                Text(convertIntakeRawValue(intake: intake.name)).foregroundColor(.white).font(.title2).multilineTextAlignment(.center)
                HStack{
                    Text("Spożyta ilość: ").foregroundColor(.white)
                    Picker("", selection: $intake.amount){
                        ForEach(Array(stride(from: 0, to: 1000, by: 10)), id: \.self){index in
                            Text("\(index)").tag(index)
                        }
                    }.pickerStyle(.wheel).clipped().frame(height: 80)
                    Text("mg").foregroundColor(.white)
                }.padding([.leading, .trailing])
                Text("To w przybliżeniu \(intake.amount*20)ml piwa, \(Double(intake.amount)*8.3, specifier: "%.0f")ml wina lub \(Double(intake.amount)*2.5, specifier: "%.0f")ml wódki ").foregroundColor(.white).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity, minHeight: 200).background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case "Green_vegetables":
            VStack{
                Text(convertIntakeRawValue(intake: intake.name)).foregroundColor(.white).font(.title2).multilineTextAlignment(.center)
                HStack{
                    Text("Spożyta ilość: ").foregroundColor(.white)
                    Picker("", selection: $intake.amount){
                        ForEach(Array(stride(from: 0, to: 2000, by: 100)), id: \.self){index in
                            Text("\(index)").tag(index)
                        }
                    }.pickerStyle(.wheel).clipped().frame(height: 80)
                    Text("µg witaminy K").foregroundColor(.white).multilineTextAlignment(.center)
                }.padding([.leading, .trailing])
                Text("To w przybliżeniu \(Double(intake.amount)/5, specifier: "%.0f")g szpinaku, \(Double(intake.amount)/2, specifier: "%.0f")g brokuł lub \(intake.amount)g sałaty").foregroundColor(.white).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity, minHeight: 200).background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        default:
            Text(convertIntakeRawValue(intake: intake.name)).foregroundColor(.white).font(.title2).frame(maxWidth: .infinity, minHeight: 90).background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        
    }
    
    func convertIntakeRawValue(intake: String) -> String{
        switch intake{
        case "Green_vegetables":
            return "Warzywa Zielone"
        case "Caffeine":
            return "Kofeina"
        case "Nicotine":
            return "Nikotyna"
        case "Alcohol":
            return "Alkohol"
        case "Other":
            return "Inne"
        default:
            return intake
        }
    }
}

struct IntakeAmountView_Previews: PreviewProvider {
    static var previews: some View {
        IntakeAmountView(intake: .constant(Intake(name: "Green_vegetables", amount: 700)))
    }
}
