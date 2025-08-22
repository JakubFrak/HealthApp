//
//  RangedSliderView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 24/12/2023.
//

import SwiftUI

struct RangedSliderView: View {
    let currentValue: Binding<ClosedRange<Float>>
    let sliderBounds: ClosedRange<Int>
    
    public init(value: Binding<ClosedRange<Float>>, bounds: ClosedRange<Int>) {
        self.currentValue = value
        self.sliderBounds = bounds
    }
    
    var body: some View {
        GeometryReader { geomentry in
            sliderView(sliderSize: geomentry.size)
        }
    }
    
        
    @ViewBuilder private func sliderView(sliderSize: CGSize) -> some View {
        let sliderViewYCenter = sliderSize.height / 2
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red)
                .frame(height: 4)
            ZStack {
                let sliderBoundDifference = sliderBounds.count - 1
                let stepWidthInPixel = CGFloat(sliderSize.width) / CGFloat(sliderBoundDifference)
                
                // Calculate Left Thumb initial position
                let leftThumbLocation: CGFloat = currentValue.wrappedValue.lowerBound == Float(sliderBounds.lowerBound)
                    ? 0
                    : CGFloat(currentValue.wrappedValue.lowerBound - Float(sliderBounds.lowerBound)) * stepWidthInPixel
                
                // Calculate right thumb initial position
                let rightThumbLocation = CGFloat(currentValue.wrappedValue.upperBound) * stepWidthInPixel
                
                if((rightThumbLocation+rightThumbLocation/4)>(CGFloat(sliderBounds.upperBound) * stepWidthInPixel)){
                    yellowLine(from: .init(x: (leftThumbLocation-leftThumbLocation/4), y: sliderViewYCenter), to: .init(x: (CGFloat(sliderBounds.upperBound) * stepWidthInPixel), y: sliderViewYCenter))
                }else{
                    yellowLine(from: .init(x: (leftThumbLocation-leftThumbLocation/4), y: sliderViewYCenter), to: .init(x: (rightThumbLocation+rightThumbLocation/4), y: sliderViewYCenter))
                }
                
                // Path between both handles
                lineBetweenThumbs(from: .init(x: leftThumbLocation, y: sliderViewYCenter), to: .init(x: rightThumbLocation, y: sliderViewYCenter))
                
                // Left Thumb Handle
                let leftThumbPoint = CGPoint(x: leftThumbLocation, y: sliderViewYCenter)
                thumbView(position: leftThumbPoint, value: Float(currentValue.wrappedValue.lowerBound))
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(0, dragLocation.x), sliderSize.width)
                        
                        let newValue = round((Float(sliderBounds.lowerBound) + Float(xThumbOffset / stepWidthInPixel))*20)/20
                        
                        // Stop the range thumbs from colliding each other
                        if newValue < currentValue.wrappedValue.upperBound {
                            currentValue.wrappedValue = newValue...currentValue.wrappedValue.upperBound
                        }
                    })
                
                // Right Thumb Handle
                thumbView(position: CGPoint(x: rightThumbLocation, y: sliderViewYCenter), value: currentValue.wrappedValue.upperBound)
                    .highPriorityGesture(DragGesture().onChanged { dragValue in
                        let dragLocation = dragValue.location
                        let xThumbOffset = min(max(CGFloat(leftThumbLocation), dragLocation.x), sliderSize.width)
                        
                        var newValue = Float(xThumbOffset / stepWidthInPixel) // convert back the value bound
                        newValue = round((min(newValue, Float(sliderBounds.upperBound)))*20)/20
                        
                        // Stop the range thumbs from colliding each other
                        if newValue > currentValue.wrappedValue.lowerBound {
                            currentValue.wrappedValue = currentValue.wrappedValue.lowerBound...newValue
                        }
                    })
            }
        }
    }
    
    @ViewBuilder func lineBetweenThumbs(from: CGPoint, to: CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Color.green, lineWidth: 4)
    }
    
    @ViewBuilder func yellowLine(from: CGPoint, to: CGPoint) -> some View{
        Path {path in
            path.move(to: from)
            path.addLine(to: to)
        }.stroke(Color.yellow, lineWidth: 4)
    }
    
    @ViewBuilder func thumbView(position: CGPoint, value: Float) -> some View {
        ZStack {
            Text(String(value))
                .offset(y: -20)
            Circle()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
                .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 2)
                .contentShape(Rectangle())
        }
        .position(x: position.x, y: position.y)
    }
}
