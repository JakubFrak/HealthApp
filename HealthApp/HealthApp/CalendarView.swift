//
//  CalendarView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 20/12/2023.
//

import SwiftUI

struct CalendarView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, data: _data, range: interval)
    }
    
    let interval: DateInterval
    //@ObservedObject var viewmodel: LekiViewModel
    @Binding var data: [MedTakenDate]
    
    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        return view
    }
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        
    }
    class Coordinator: NSObject, UICalendarViewDelegate{
        var parent: CalendarView
        @Binding var data: [MedTakenDate]
        var range: DateInterval
        init(parent: CalendarView, data: Binding<[MedTakenDate]>, range: DateInterval) {
            self.parent = parent
            self._data = data
            self.range = range
        }
        var calendar: Calendar{
            Calendar(identifier: .gregorian)
        }
        
        @MainActor
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = calendar.date(from: dateComponents) else{
                return nil
            }
            if(data.contains(where: {calendar.isDate($0.date, inSameDayAs: date)})){
                if(data[data.firstIndex(where: {calendar.isDate($0.date, inSameDayAs: date)})!].isTaken){
                    return .default(color: .green, size: .large)
                }
            }
            if(date > Date()){return .none}
            if(date < data.compactMap{$0.date}.min() ?? range.start){return .none}
            return .default(color: .red, size: .large)
        }
    }
}
