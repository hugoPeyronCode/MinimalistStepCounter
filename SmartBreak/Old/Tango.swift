import SwiftUI

// MARK: - Models

enum CellState: Int, CaseIterable {
    case empty = 0
    case sun = 1
    case moon = 2

    var symbol: String {
        switch self {
        case .empty: return ""
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        }
    }

    mutating func toggle() {
        self = CellState(rawValue: (self.rawValue + 1) % 3) ?? .empty
    }
}

enum JunctionType: String {
    case equal = "="
    case cross = "×"
    case none = ""
}

struct Cell: Identifiable, Equatable {
    let id = UUID()
    var state: CellState = .empty
    var hasError: Bool = false
}

struct Position: Hashable {
    let row: Int
    let col: Int
}

enum JunctionSymbol: String {
    case equal = "="
    case cross = "×"
    case none = ""
}

struct Junction: Identifiable, Equatable {
    let id = UUID()
    let position: Position
    let isHorizontal: Bool
    let type: JunctionType
}

// MARK: - View Model

class TangoViewModel: ObservableObject {
    @Published var grid: [[Cell]]
    @Published var junctions: [Junction]
    @Published var selectedPosition: Position?
    @Published var gameWon: Bool = false
    @Published var moveHistory: [[[Cell]]] = []
    @Published var showClearAlert: Bool = false

    let size: Int
    let symbolsPerRow: Int

    init(size: Int = 6) {
        self.size = size
        // For a 6x6 grid, there should be 3 suns and 3 moons per row/column
        self.symbolsPerRow = size / 2

        // Initialize empty grid
        self.grid = Array(repeating: Array(repeating: Cell(), count: size), count: size)

        // Initialize junctions (in a real game, these would be predefined)
        self.junctions = []

        // Add some sample junctions as shown in the image
        setupSampleJunctions()
    }

    private func setupSampleJunctions() {
        // Create horizontal junctions between cells at row 5-6 (as shown in the screenshot)
        let horizontalJunctions: [(row: Int, col: Int, type: JunctionType)] = [
            (4, 0, .equal),    // Column 1, between rows 5-6
            (4, 1, .cross),    // Column 2, between rows 5-6
            (4, 2, .equal),    // Column 3, between rows 5-6
            (4, 3, .cross),    // Column 4, between rows 5-6
            (4, 4, .equal),    // Column 5, between rows 5-6
            (4, 5, .equal)     // Column 6, between rows 5-6
        ]

        // Add horizontal junctions
        for j in horizontalJunctions {
            junctions.append(Junction(
                position: Position(row: j.row, col: j.col),
                isHorizontal: true,
                type: j.type
            ))
        }
    }

    func toggleCell(at position: Position) {
        // Save current state for undo
        moveHistory.append(copyGrid())

        grid[position.row][position.col].state.toggle()
        validateBoard()
        checkWinCondition()
    }

    func undo() {
        if let lastGrid = moveHistory.popLast() {
            grid = lastGrid
            validateBoard()
        }
    }

    func clearGame() {
        resetGame()
    }

    private func copyGrid() -> [[Cell]] {
        return grid.map { $0.map { $0 } }
    }

    func validateBoard() {
        // Reset all error states
        for row in 0..<size {
            for col in 0..<size {
                grid[row][col].hasError = false
            }
        }

        // Check for three consecutive same symbols horizontally
        for row in 0..<size {
            for col in 0..<(size-2) {
                let cell1 = grid[row][col].state
                let cell2 = grid[row][col+1].state
                let cell3 = grid[row][col+2].state

                if cell1 != .empty && cell1 == cell2 && cell2 == cell3 {
                    grid[row][col].hasError = true
                    grid[row][col+1].hasError = true
                    grid[row][col+2].hasError = true
                }
            }
        }

        // Check for three consecutive same symbols vertically
        for col in 0..<size {
            for row in 0..<(size-2) {
                let cell1 = grid[row][col].state
                let cell2 = grid[row+1][col].state
                let cell3 = grid[row+2][col].state

                if cell1 != .empty && cell1 == cell2 && cell2 == cell3 {
                    grid[row][col].hasError = true
                    grid[row+1][col].hasError = true
                    grid[row+2][col].hasError = true
                }
            }
        }

        // Check completed rows for equal sun/moon count
        for row in 0..<size {
            let cells = grid[row]
            let allFilled = cells.allSatisfy { $0.state != .empty }

            if allFilled {
                let sunCount = cells.filter { $0.state == .sun }.count
                let moonCount = cells.filter { $0.state == .moon }.count

                if sunCount != symbolsPerRow || moonCount != symbolsPerRow {
                    for col in 0..<size {
                        grid[row][col].hasError = true
                    }
                }
            }
        }

        // Check completed columns for equal sun/moon count
        for col in 0..<size {
            let cells = (0..<size).map { grid[$0][col] }
            let allFilled = cells.allSatisfy { $0.state != .empty }

            if allFilled {
                let sunCount = cells.filter { $0.state == .sun }.count
                let moonCount = cells.filter { $0.state == .moon }.count

                if sunCount != symbolsPerRow || moonCount != symbolsPerRow {
                    for row in 0..<size {
                        grid[row][col].hasError = true
                    }
                }
            }
        }

        // Check junction constraints
        for junction in junctions {
            let pos = junction.position

            if junction.isHorizontal {
                // Horizontal junction between (row, col) and (row, col+1)
                if pos.col < size - 1 {
                    let cell1 = grid[pos.row][pos.col].state
                    let cell2 = grid[pos.row][pos.col + 1].state

                    // Only validate if both cells are filled
                    if cell1 != .empty && cell2 != .empty {
                        let sameSymbols = cell1 == cell2

                        switch junction.type {
                        case .equal:
                            if !sameSymbols {
                                grid[pos.row][pos.col].hasError = true
                                grid[pos.row][pos.col + 1].hasError = true
                            }
                        case .cross:
                            if sameSymbols {
                                grid[pos.row][pos.col].hasError = true
                                grid[pos.row][pos.col + 1].hasError = true
                            }
                        case .none:
                            break
                        }
                    }
                }
            } else {
                // Vertical junction between (row, col) and (row+1, col)
                if pos.row < size - 1 {
                    let cell1 = grid[pos.row][pos.col].state
                    let cell2 = grid[pos.row + 1][pos.col].state

                    // Only validate if both cells are filled
                    if cell1 != .empty && cell2 != .empty {
                        let sameSymbols = cell1 == cell2

                        switch junction.type {
                        case .equal:
                            if !sameSymbols {
                                grid[pos.row][pos.col].hasError = true
                                grid[pos.row + 1][pos.col].hasError = true
                            }
                        case .cross:
                            if sameSymbols {
                                grid[pos.row][pos.col].hasError = true
                                grid[pos.row + 1][pos.col].hasError = true
                            }
                        case .none:
                            break
                        }
                    }
                }
            }
        }
    }

    func checkWinCondition() {
        // Check if all cells are filled
        let allFilled = grid.flatMap { $0 }.allSatisfy { $0.state != .empty }

        // Check if there are no errors
        let noErrors = grid.flatMap { $0 }.allSatisfy { !$0.hasError }

        gameWon = allFilled && noErrors
    }

    func resetGame() {
        grid = Array(repeating: Array(repeating: Cell(), count: size), count: size)
        moveHistory = []
        gameWon = false
        validateBoard()
    }

    func countSymbolsInRow(_ row: Int) -> (sun: Int, moon: Int) {
        let sunCount = grid[row].filter { $0.state == .sun }.count
        let moonCount = grid[row].filter { $0.state == .moon }.count
        return (sunCount, moonCount)
    }

    func countSymbolsInColumn(_ col: Int) -> (sun: Int, moon: Int) {
        let sunCount = (0..<size).map { grid[$0][col] }.filter { $0.state == .sun }.count
        let moonCount = (0..<size).map { grid[$0][col] }.filter { $0.state == .moon }.count
        return (sunCount, moonCount)
    }

    func isRowComplete(_ row: Int) -> Bool {
        let allFilled = grid[row].allSatisfy { $0.state != .empty }
        let (sun, moon) = countSymbolsInRow(row)
        return allFilled && sun == symbolsPerRow && moon == symbolsPerRow
    }

    func isColComplete(_ col: Int) -> Bool {
        let allFilled = (0..<size).map { grid[$0][col] }.allSatisfy { $0.state != .empty }
        let (sun, moon) = countSymbolsInColumn(col)
        return allFilled && sun == symbolsPerRow && moon == symbolsPerRow
    }
}

// MARK: - Views

struct CellView: View {
    let state: CellState
    let hasError: Bool
    let isSelected: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )

            if state != .empty {
                Image(systemName: state.symbol)
                    .font(.system(size: 24))
                    .foregroundColor(state == .sun ? .black : .black)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var backgroundColor: Color {
        if state == .empty {
            return Color.white
        } else {
            return Color(UIColor(white: 0.94, alpha: 1.0)) // Light beige/cream color
        }
    }

    private var borderColor: Color {
        if hasError {
            return Color.red
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var borderWidth: CGFloat {
        if hasError {
            return 2
        } else {
            return 0.5
        }
    }
}

struct JunctionView: View {
    let type: JunctionType
    let isHorizontal: Bool

    var body: some View {
        if type != .none {
            Text(type.rawValue)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(UIColor.darkGray))
                .frame(width: 20, height: 20)
                .rotationEffect(isHorizontal ? .zero : .degrees(90))
        } else {
            Color.clear
                .frame(width: 20, height: 20)
        }
    }
}

struct GridView: View {
    @ObservedObject var viewModel: TangoViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Grid cells and junctions
            mainGridView
        }
        .padding(2)
        .background(Color.white)
        .cornerRadius(4)
    }

    private var mainGridView: some View {
        ZStack {
            // Cell grid
            VStack(spacing: 0) {
                ForEach(0..<viewModel.size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<viewModel.size, id: \.self) { col in
                            cellView(row: row, col: col)
                        }
                    }
                }
            }

            // Horizontal junctions
            ForEach(viewModel.junctions.filter { $0.isHorizontal }, id: \.id) { junction in
                junctionView(junction: junction)
            }

            // Vertical junctions
            ForEach(viewModel.junctions.filter { !$0.isHorizontal }, id: \.id) { junction in
                junctionView(junction: junction)
            }
        }
    }

    private func cellView(row: Int, col: Int) -> some View {
        let cell = viewModel.grid[row][col]
        let position = Position(row: row, col: col)
        let isSelected = viewModel.selectedPosition == position

        return CellView(
            state: cell.state,
            hasError: cell.hasError,
            isSelected: isSelected
        )
        .frame(width: 50, height: 50)
        .onTapGesture {
            viewModel.selectedPosition = position
            viewModel.toggleCell(at: position)
        }
    }

    private func junctionView(junction: Junction) -> some View {
        let pos = junction.position
        let cellSize: CGFloat = 50

        // Calculate x and y positions for junction symbols
        // For horizontal junctions: centered horizontally between cells, aligned with cell bottom
        // For vertical junctions: centered vertically between cells, aligned with cell right
        let x: CGFloat
        let y: CGFloat

        if junction.isHorizontal {
            // Place horizontal junctions between rows
            x = CGFloat(pos.col) * cellSize + cellSize/2
            y = CGFloat(pos.row) * cellSize + cellSize
        } else {
            // Place vertical junctions between columns
            x = CGFloat(pos.col) * cellSize + cellSize
            y = CGFloat(pos.row) * cellSize + cellSize/2
        }

        return JunctionView(type: junction.type, isHorizontal: junction.isHorizontal)
            .position(x: x, y: y)
    }
}

struct TangoGameView: View {
    @StateObject private var viewModel = TangoViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Tango")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            GridView(viewModel: viewModel)
                .padding(.horizontal)

            // Bottom buttons
            HStack(spacing: 20) {
                Button(action: { viewModel.undo() }) {
                    Text("Undo")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(minWidth: 120, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.gray, lineWidth: 1)
                                .background(Color.white)
                        )
                }

                Button(action: { viewModel.showClearAlert = true }) {
                    Text("Clear")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(minWidth: 120, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.gray, lineWidth: 1)
                                .background(Color.white)
                        )
                }
            }
        }
        .padding(.vertical)
        .background(Color.white)
        .alert(isPresented: $viewModel.gameWon) {
            Alert(
                title: Text("Congratulations!"),
                message: Text("You've completed the puzzle!"),
                dismissButton: .default(Text("New Game"), action: {
                    viewModel.resetGame()
                })
            )
        }
        .alert("Clear Game", isPresented: $viewModel.showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearGame()
            }
        } message: {
            Text("Are you sure you want to clear the game? This action cannot be undone.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TangoGameView()
    }
}
