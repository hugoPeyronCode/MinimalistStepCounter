//
//  CircularClockView.swift
//  SmartBreak
//
//  Created by Hugo Peyron on 14/05/2025.
//
import SwiftUI

// Vue avec un demi-cercle et 24 barres individuelles représentant chaque heure
struct Clock: View {
  @State private var currentHour = Calendar.current.component(.hour, from: Date())
  @State private var currentMinutes = Calendar.current.component(.minute, from: Date())
  @State private var timer: Timer?

  let radius: CGFloat = 130
  let barHeight: CGFloat = 20
  let barWidth: CGFloat = 2
  let numberOfHours = 24

  var body: some View {
    VStack() {
      ZStack {
        ForEach(0..<numberOfHours, id: \.self) { hour in
          hourBar(for: hour)
            .position(positionForHour(hour))
        }
      }
      .frame(width: (radius + barHeight) * 2, height: radius + 60)

//      Text("\(currentHour):\(currentMinutes)")
//        .font(.caption)
//        .foregroundStyle(.gray)

    }
    .onAppear {
      startTimer()
    }
    .onDisappear {
      timer?.invalidate()
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private func hourBar(for hour: Int) -> some View {
    let isPassed = hour < currentHour
    let rotationAngle = rotationAngleForHour(hour)

    Rectangle()
      .foregroundStyle(isPassed ? .primary : .tertiary)
      .frame(width: barWidth, height: barHeight)
      .clipShape(RoundedRectangle(cornerRadius: barWidth / 2))
      .rotationEffect(.radians(-rotationAngle))
      .animation(.spring(duration: 0.5, bounce: 0.1), value: isPassed)
  }

  private func rotationAngleForHour(_ hour: Int) -> CGFloat {
      // Angle de base pour chaque heure (demi-cercle de π radians)
      let baseAngle = CGFloat(Double.pi) - (CGFloat(hour) / CGFloat(numberOfHours - 1)) * CGFloat(Double.pi)

      // Ajouter π/2 pour que la barre soit perpendiculaire au rayon
      // À midi (heure 12), l'angle sera π/2 (vertical)
      // Aux extrémités (heures 0 et 23), l'angle sera 0 ou π (horizontal)
      return baseAngle - CGFloat(Double.pi / 2)
  }

  private func positionForHour(_ hour: Int) -> CGPoint {
      // Angle pour chaque heure (demi-cercle de π radians)
      let angle = CGFloat(Double.pi) - (CGFloat(hour) / CGFloat(numberOfHours - 1)) * CGFloat(Double.pi)

      // Position sur le cercle
      let centerX = (radius + barHeight)
      let centerY = radius + 30

      let x = centerX + (radius + barHeight/2) * cos(angle)
      let y = centerY - (radius + barHeight/2) * sin(angle)

      return CGPoint(x: x, y: y)
  }


  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
      currentHour = Calendar.current.component(.hour, from: Date())
    }
  }
}

#Preview {
  Clock()
    .padding()
}
