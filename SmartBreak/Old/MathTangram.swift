////
////  ContentView.swift
////  SmartBreak
////
////  Created by Hugo Peyron on 07/05/2025.
////
//
//import SwiftUI
//
//// MARK: - Models
//
//struct Cell: Identifiable, Equatable {
//  let id = UUID()
//  var value: Int?
//  var isFixed: Bool = false
//  var isHighlighted: Bool = false
//  var notes: Set<Int> = []
//}
//
//struct GameRules {
//  let size: Int
//  let rowSums: [Int]
//  let colSums: [Int]
//
//  init(size: Int = 5) {
//    self.size = size
//    self.rowSums = (0..<size).map { _ in Int.random(in: 5...15) }
//    self.colSums = (0..<size).map { _ in Int.random(in: 5...15) }
//  }
//}
//
//// MARK: - View Model
//
//class TangoViewModel: ObservableObject {
//  @Published var grid: [[Cell]]
//  @Published var rules: GameRules
//  @Published var selectedCell: (row: Int, col: Int)?
//  @Published var errorMessage: String?
//  @Published var isGameComplete = false
//  @Published var inputMode: InputMode = .value
//
//  enum InputMode {
//    case value
//    case notes
//  }
//
//  init(size: Int = 5) {
//    self.rules = GameRules(size: size)
//    self.grid = Array(repeating: Array(repeating: Cell(), count: size), count: size)
//    setupGame()
//  }
//
//  private func setupGame() {
//    for _ in 0..<15 {
//      let row = Int.random(in: 0..<rules.size)
//      let col = Int.random(in: 0..<rules.size)
//      let value = Int.random(in: 1...5)
//      grid[row][col].value = value
//      grid[row][col].isFixed = true
//    }
//  }
//
//  func selectCell(row: Int, col: Int) {
//    if selectedCell?.row == row && selectedCell?.col == col {
//      selectedCell = nil
//    } else {
//      selectedCell = (row, col)
//    }
//  }
//
//  func inputValue(_ value: Int?) {
//    guard let selectedCell = selectedCell else { return }
//    guard !grid[selectedCell.row][selectedCell.col].isFixed else { return }
//
//    if inputMode == .value {
//      // If the same value is tapped again, remove it (toggle behavior)
//      if grid[selectedCell.row][selectedCell.col].value == value {
//        grid[selectedCell.row][selectedCell.col].value = nil
//      } else {
//        grid[selectedCell.row][selectedCell.col].value = value
//      }
//    } else {
//      // Notes mode
//      if let value = value {
//        if grid[selectedCell.row][selectedCell.col].notes.contains(value) {
//          grid[selectedCell.row][selectedCell.col].notes.remove(value)
//        } else {
//          grid[selectedCell.row][selectedCell.col].notes.insert(value)
//        }
//      }
//    }
//
//    checkCompletion()
//  }
//
//  func toggleInputMode() {
//    inputMode = inputMode == .value ? .notes : .value
//  }
//
//  func clearCell() {
//    guard let selectedCell = selectedCell else { return }
//    guard !grid[selectedCell.row][selectedCell.col].isFixed else { return }
//
//    grid[selectedCell.row][selectedCell.col].value = nil
//    grid[selectedCell.row][selectedCell.col].notes = []
//  }
//
//  func calculateRowSum(_ row: Int) -> Int {
//    return grid[row].compactMap { $0.value }.reduce(0, +)
//  }
//
//  func calculateColSum(_ col: Int) -> Int {
//    return (0..<rules.size).compactMap { grid[$0][col].value }.reduce(0, +)
//  }
//
//  func isRowComplete(_ row: Int) -> Bool {
//    return calculateRowSum(row) == rules.rowSums[row]
//  }
//
//  func isColComplete(_ col: Int) -> Bool {
//    return calculateColSum(col) == rules.colSums[col]
//  }
//
//  func checkCompletion() {
//    // Check if all rows and columns are complete
//    let allRowsComplete = (0..<rules.size).allSatisfy { isRowComplete($0) }
//    let allColsComplete = (0..<rules.size).allSatisfy { isColComplete($0) }
//
//    isGameComplete = allRowsComplete && allColsComplete
//  }
//
//  func newGame() {
//    rules = GameRules(size: rules.size)
//    grid = Array(repeating: Array(repeating: Cell(), count: rules.size), count: rules.size)
//    selectedCell = nil
//    isGameComplete = false
//    setupGame()
//  }
//}
//
//// MARK: - Views
//
//struct CellView: View {
//  let value: Int?
//  let isFixed: Bool
//  let isSelected: Bool
//  let isHighlighted: Bool
//  let notes: Set<Int>
//  let size: CGFloat
//
//  var body: some View {
//    ZStack {
//      Rectangle()
//        .fill(backgroundColor)
//        .border(Color.black, width: 1)
//
//      if let value = value {
//        Text("\(value)")
//          .font(.system(size: size * 0.5))
//          .fontWeight(isFixed ? .bold : .regular)
//      } else if !notes.isEmpty {
//        // Display notes
//        VStack(spacing: 2) {
//          ForEach(0..<3) { row in
//            HStack(spacing: 2) {
//              ForEach(1...3, id: \.self) { col in
//                let num = row * 3 + col
//                if num <= 9 && notes.contains(num) {
//                  Text("\(num)")
//                    .font(.system(size: size * 0.15))
//                    .frame(width: size / 3.5, height: size / 3.5)
//                } else {
//                  Text("")
//                    .frame(width: size / 3.5, height: size / 3.5)
//                }
//              }
//            }
//          }
//        }
//        .frame(width: size, height: size)
//      }
//    }
//    .frame(width: size, height: size)
//  }
//
//  var backgroundColor: Color {
//    if isSelected {
//      return Color.gray.opacity(0.3)
//    } else if isHighlighted {
//      return Color.gray.opacity(0.1)
//    } else {
//      return Color.white
//    }
//  }
//}
//
//struct GridView: View {
//  @ObservedObject var viewModel: TangoViewModel
//  let gridSize: CGFloat
//
//  var cellSize: CGFloat {
//    gridSize / CGFloat(viewModel.rules.size)
//  }
//
//  var body: some View {
//    VStack(spacing: 0) {
//      // Column sum headers
//      HStack(spacing: 0) {
//        // Empty top-left corner
//        Text("")
//          .frame(width: cellSize, height: cellSize / 2)
//
//        // Column sums
//        ForEach(0..<viewModel.rules.size, id: \.self) { col in
//          VStack {
//            Text("\(viewModel.rules.colSums[col])")
//              .font(.caption)
//              .fontWeight(.bold)
//
//            Image(systemName: viewModel.isColComplete(col) ? "checkmark.circle.fill" : "circle")
//              .font(.caption)
//              .foregroundColor(viewModel.isColComplete(col) ? .black : .gray)
//          }
//          .frame(width: cellSize, height: cellSize / 2)
//        }
//      }
//
//      // Grid rows with row sums
//      ForEach(0..<viewModel.rules.size, id: \.self) { row in
//        HStack(spacing: 0) {
//          // Row sum
//          VStack {
//            Text("\(viewModel.rules.rowSums[row])")
//              .font(.caption)
//              .fontWeight(.bold)
//
//            Image(systemName: viewModel.isRowComplete(row) ? "checkmark.circle.fill" : "circle")
//              .font(.caption)
//              .foregroundColor(viewModel.isRowComplete(row) ? .black : .gray)
//          }
//          .frame(width: cellSize / 2, height: cellSize)
//
//          // Cells in this row
//          ForEach(0..<viewModel.rules.size, id: \.self) { col in
//            CellView(
//              value: viewModel.grid[row][col].value,
//              isFixed: viewModel.grid[row][col].isFixed,
//              isSelected: viewModel.selectedCell?.row == row && viewModel.selectedCell?.col == col,
//              isHighlighted: viewModel.selectedCell?.row == row || viewModel.selectedCell?.col == col,
//              notes: viewModel.grid[row][col].notes,
//              size: cellSize
//            )
//            .onTapGesture {
//              viewModel.selectCell(row: row, col: col)
//            }
//          }
//        }
//      }
//    }
//    .background(Color.black.opacity(0.1))
//    .overlay(
//      Rectangle()
//        .stroke(Color.black, lineWidth: 2)
//    )
//  }
//}
//
//struct NumberPadView: View {
//  let onInput: (Int) -> Void
//  let onClear: () -> Void
//  let onToggleMode: () -> Void
//  let inputMode: TangoViewModel.InputMode
//
//  var body: some View {
//    VStack(spacing: 10) {
//      HStack {
//        Text(inputMode == .value ? "Input Mode" : "Notes Mode")
//          .font(.headline)
//          .foregroundColor(.black)
//
//        Spacer()
//
//        Button(action: onToggleMode) {
//          Image(systemName: inputMode == .value ? "pencil.tip" : "pencil.tip.crop.circle.badge.minus")
//            .font(.title2)
//            .foregroundColor(.black)
//        }
//      }
//      .padding(.horizontal)
//
//      // Number grid (1-9)
//      VStack(spacing: 8) {
//        ForEach(0..<3) { row in
//          HStack(spacing: 8) {
//            ForEach(1...3, id: \.self) { col in
//              let number = row * 3 + col
//              Button(action: {
//                onInput(number)
//              }) {
//                Text("\(number)")
//                  .font(.title)
//                  .frame(minWidth: 50, minHeight: 50)
//                  .background(Circle().fill(Color.white))
//                  .overlay(Circle().stroke(Color.black, lineWidth: 1))
//              }
//              .foregroundColor(.black)
//            }
//          }
//        }
//
//        // Clear button
//        Button(action: onClear) {
//          Label("Clear", systemImage: "xmark.circle")
//            .font(.headline)
//            .padding(.vertical, 10)
//            .padding(.horizontal, 25)
//            .background(Capsule().fill(Color.white))
//            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
//        }
//        .foregroundColor(.black)
//        .padding(.top, 5)
//      }
//    }
//    .padding()
//    .background(Color.gray.opacity(0.1))
//    .cornerRadius(12)
//  }
//}
//
//struct TangoGameView: View {
//  @StateObject private var viewModel = TangoViewModel()
//  @State private var showingCompletionAlert = false
//
//  var body: some View {
//    VStack(spacing: 20) {
//      Text("Tango")
//        .font(.largeTitle)
//        .fontWeight(.bold)
//
//      if let errorMessage = viewModel.errorMessage {
//        Text(errorMessage)
//          .foregroundColor(.red)
//          .padding()
//      }
//
//      GridView(viewModel: viewModel, gridSize: min(UIScreen.main.bounds.width - 40, 350))
//        .padding(.horizontal)
//
//      NumberPadView(
//        onInput: { viewModel.inputValue($0) },
//        onClear: { viewModel.clearCell() },
//        onToggleMode: { viewModel.toggleInputMode() },
//        inputMode: viewModel.inputMode
//      )
//      .padding(.horizontal)
//
//      Button(action: { viewModel.newGame() }) {
//        Label("New Game", systemImage: "arrow.counterclockwise")
//          .font(.headline)
//          .padding(.vertical, 10)
//          .padding(.horizontal, 25)
//          .background(Capsule().fill(Color.white))
//          .overlay(Capsule().stroke(Color.black, lineWidth: 1))
//      }
//      .foregroundColor(.black)
//      .padding(.top, 5)
//    }
//    .padding()
//    .background(Color.white)
//    .alert(isPresented: $showingCompletionAlert) {
//      Alert(
//        title: Text("Congratulations!"),
//        message: Text("You've completed the puzzle!"),
//        dismissButton: .default(Text("New Game"), action: {
//          viewModel.newGame()
//        })
//      )
//    }
//    .onChange(of: viewModel.isGameComplete) { complete, _ in
//      if complete {
//        showingCompletionAlert = true
//      }
//    }
//  }
//}
//
//// MARK: - Preview
//
//struct ContentView_Previews: PreviewProvider {
//  static var previews: some View {
//    TangoGameView()
//  }
//}
