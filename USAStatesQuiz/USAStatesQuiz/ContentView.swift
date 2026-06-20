import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var game = StateQuizViewModel()

    var body: some View {
        ZStack {
            AppBackground()

            if game.selectedMode == nil {
                QuizModeMenuView { mode in
                    game.start(mode: mode)
                }
            } else {
                QuizGameView(game: game)
            }
        }
    }
}

struct QuizGameView: View {
    @ObservedObject var game: StateQuizViewModel

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let width = proxy.size.width
            let height = proxy.size.height
            let mapHeight = min(360, max(250, height * 0.36))

            ZStack {
                VStack(spacing: 14) {
                    TopBarView(
                        title: game.modeTitle,
                        roundText: game.roundText,
                        score: game.score,
                        mistakes: game.mistakes,
                        progress: game.progress,
                        onRestart: game.restart,
                        onMenu: game.returnToMenu
                    )

                    ZoomableStateMapView(
                        states: game.mapStates,
                        highlightedState: game.currentState?.name,
                        usesUSAInsets: game.usesUSAInsets
                    )
                        .frame(height: mapHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.16), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 16, y: 10)

                    VStack(spacing: 12) {
                        Text(game.isComplete ? "Round complete" : game.prompt)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))

                        AnswerSlotsView(
                            answer: game.currentState?.name ?? "",
                            typedLetters: game.typedLetters,
                            wrongSlotIndex: game.wrongSlotIndex
                        )
                    }
                    .padding(.top, 4)

                    LetterKeyboardView(
                        letters: game.keyboardLetters,
                        usedIndices: game.usedKeyboardIndices,
                        wrongIndex: game.wrongKeyboardIndex,
                        isDisabled: game.isComplete
                    ) { index in
                        game.pickLetter(at: index)
                    }
                    .frame(height: 136)
                    .padding(.top, 2)

                    HStack(spacing: 12) {
                        ActionButton(title: "Hint", systemImage: "lightbulb.fill") {
                            game.revealHint()
                        }
                        .disabled(game.isComplete)

                        ActionButton(title: "Delete", systemImage: "delete.left.fill") {
                            game.removeLastLetter()
                        }
                        .disabled(game.typedLetters.isEmpty || game.isComplete)
                    }
                    .padding(.top, 2)

                    if game.isComplete {
                        CompletionView(total: game.totalRounds, score: game.score, mistakes: game.mistakes, onRestart: game.restart)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, max(10, safeTop * 0.25))
                .padding(.bottom, max(12, safeBottom * 0.35))
                .frame(width: width, height: height, alignment: .top)
            }
        }
    }
}

struct QuizModeMenuView: View {
    let onSelect: (QuizMode) -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Map Quiz")
                            .font(.system(size: 44, weight: .black))
                            .foregroundStyle(.white)
                        Text("Choose a region, find the highlighted shape, and spell the answer one letter at a time.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, max(24, proxy.safeAreaInsets.top + 12))

                    VStack(spacing: 12) {
                        ForEach(QuizMode.allCases) { mode in
                            Button {
                                onSelect(mode)
                            } label: {
                                QuizModeCard(mode: mode)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Pinch and drag the map during the quiz to inspect small states and countries.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 16))
                }
                .padding(.horizontal, 18)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
    }
}

struct QuizModeCard: View {
    let mode: QuizMode

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: mode.systemImage)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(mode.accentColor)
                .frame(width: 52, height: 52)
                .background(mode.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.white)
                Text(mode.subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(mode.roundCount)")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                Text("rounds")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(14)
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.13), lineWidth: 1))
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.10),
                Color(red: 0.01, green: 0.02, blue: 0.04),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct TopBarView: View {
    let title: String
    let roundText: String
    let score: Int
    let mistakes: Int
    let progress: Double
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onMenu) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 42)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(roundText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.cyan.opacity(0.9))
                    Text(title)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                StatPill(value: "\(score)", label: "Score", color: .green)
                StatPill(value: "\(mistakes)", label: "Miss", color: .red)

                Button(action: onRestart) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.12), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: progress)
                .tint(.green)
                .background(.white.opacity(0.16), in: Capsule())
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 18, weight: .black))
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .foregroundStyle(.white)
        .frame(width: 50, height: 42)
        .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.32), lineWidth: 1))
    }
}

struct AnswerSlotsView: View {
    let answer: String
    let typedLetters: [String]
    let wrongSlotIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            let letters = answerLetters
            let slotCount = letters.count
            let rowCount = slotCount > 14 ? 2 : 1
            let columnCount = Int(ceil(Double(slotCount) / Double(rowCount)))
            let spacing: CGFloat = 6
            let available = proxy.size.width - CGFloat(max(columnCount - 1, 0)) * spacing
            let slotWidth = min(42, max(20, available / CGFloat(max(columnCount, 1))))
            let slotHeight = max(40, slotWidth * 1.18)
            let columns = Array(repeating: GridItem(.fixed(slotWidth), spacing: spacing), count: max(columnCount, 1))

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(letters.indices, id: \.self) { index in
                    Text(letterForSlot(at: index))
                        .font(.system(size: min(27, slotWidth * 0.64), weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: slotWidth, height: slotHeight)
                        .background(slotFill(for: index), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(slotStroke(for: index), lineWidth: wrongSlotIndex == index ? 2 : 1)
                        )
                        .scaleEffect(wrongSlotIndex == index ? 1.06 : 1)
                        .animation(.spring(response: 0.18, dampingFraction: 0.45), value: wrongSlotIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: answerLetters.count > 14 ? 94 : 48)
    }

    private var answerLetters: [String] {
        answer
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .uppercased()
            .filter { $0.isLetter }
            .map(String.init)
    }

    private func letterForSlot(at index: Int) -> String {
        guard typedLetters.indices.contains(index) else { return "" }
        return typedLetters[index]
    }

    private func slotFill(for index: Int) -> LinearGradient {
        if wrongSlotIndex == index {
            return LinearGradient(colors: [Color.red.opacity(0.95), Color.red.opacity(0.55)], startPoint: .top, endPoint: .bottom)
        }

        if typedLetters.indices.contains(index) {
            return LinearGradient(colors: [Color.green.opacity(0.92), Color.green.opacity(0.48)], startPoint: .top, endPoint: .bottom)
        }

        return LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
    }

    private func slotStroke(for index: Int) -> Color {
        if wrongSlotIndex == index { return .red.opacity(0.95) }
        if typedLetters.indices.contains(index) { return .green.opacity(0.5) }
        return .white.opacity(0.22)
    }
}

struct LetterKeyboardView: View {
    let letters: [String]
    let usedIndices: Set<Int>
    let wrongIndex: Int?
    let isDisabled: Bool
    let onPick: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 8
            let keyWidth = (proxy.size.width - spacing * 6) / 7
            let keyHeight = min(60, max(46, keyWidth * 0.92))
            let columns = Array(repeating: GridItem(.fixed(keyWidth), spacing: spacing), count: 7)

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(letters.indices, id: \.self) { index in
                    Button {
                        onPick(index)
                    } label: {
                        Text(letters[index])
                            .font(.system(size: min(30, keyWidth * 0.58), weight: .black))
                            .foregroundStyle(usedIndices.contains(index) ? .white.opacity(0.22) : .white)
                            .frame(width: keyWidth, height: keyHeight)
                            .background(keyFill(for: index), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(keyStroke(for: index), lineWidth: wrongIndex == index ? 2 : 1)
                            )
                            .scaleEffect(wrongIndex == index ? 0.94 : 1)
                    }
                    .disabled(usedIndices.contains(index) || isDisabled)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func keyFill(for index: Int) -> LinearGradient {
        if wrongIndex == index {
            return LinearGradient(colors: [Color.red.opacity(0.95), Color.red.opacity(0.52)], startPoint: .top, endPoint: .bottom)
        }

        if usedIndices.contains(index) {
            return LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        }

        return LinearGradient(colors: [Color(red: 0.20, green: 0.36, blue: 0.54), Color(red: 0.13, green: 0.20, blue: 0.30)], startPoint: .top, endPoint: .bottom)
    }

    private func keyStroke(for index: Int) -> Color {
        if wrongIndex == index { return .red.opacity(0.95) }
        return .white.opacity(0.14)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct CompletionView: View {
    let total: Int
    let score: Int
    let mistakes: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Final score \(score)/\(total)")
                .font(.system(size: 22, weight: .black))
            Text("\(mistakes) wrong taps")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.68))
            Button("Play Again", action: onRestart)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(.green, in: Capsule())
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
    }
}

struct ZoomableStateMapView: View {
    let states: [USStateShape]
    let highlightedState: String?
    let usesUSAInsets: Bool

    @State private var scale: CGFloat = 1
    @State private var steadyScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var steadyOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                StateMapView(states: states, highlightedState: highlightedState, usesUSAInsets: usesUSAInsets)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .gesture(mapGestures(in: proxy.size))
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            resetZoom()
                        }
                    }
                    .onChange(of: highlightedState) { _ in
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            resetZoom()
                        }
                    }

                MapZoomControls(
                    scale: scale,
                    onZoomIn: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                            setScale(min(maxScale, scale + 0.75), in: proxy.size)
                        }
                    },
                    onZoomOut: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                            setScale(max(minScale, scale - 0.75), in: proxy.size)
                        }
                    },
                    onReset: {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.84)) {
                            resetZoom()
                        }
                    }
                )
                .padding(10)
            }
            .clipped()
        }
        .accessibilityLabel("Zoomable quiz map")
    }

    private func mapGestures(in size: CGSize) -> some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = min(maxScale, max(minScale, steadyScale * value))
                    offset = clampedOffset(steadyOffset, scale: scale, size: size)
                }
                .onEnded { _ in
                    scale = min(maxScale, max(minScale, scale))
                    offset = clampedOffset(offset, scale: scale, size: size)
                    steadyScale = scale
                    steadyOffset = offset
                },
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard scale > minScale else { return }
                    let proposed = CGSize(
                        width: steadyOffset.width + value.translation.width,
                        height: steadyOffset.height + value.translation.height
                    )
                    offset = clampedOffset(proposed, scale: scale, size: size)
                }
                .onEnded { _ in
                    offset = clampedOffset(offset, scale: scale, size: size)
                    steadyOffset = offset
                }
        )
    }

    private func setScale(_ newScale: CGFloat, in size: CGSize) {
        scale = newScale
        steadyScale = newScale
        offset = clampedOffset(offset, scale: newScale, size: size)
        steadyOffset = offset

        if newScale == minScale {
            resetZoom()
        }
    }

    private func resetZoom() {
        scale = minScale
        steadyScale = minScale
        offset = .zero
        steadyOffset = .zero
    }

    private func clampedOffset(_ proposed: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        guard scale > minScale else { return .zero }

        let horizontalLimit = max(0, (size.width * (scale - 1)) / 2)
        let verticalLimit = max(0, (size.height * (scale - 1)) / 2)

        return CGSize(
            width: min(horizontalLimit, max(-horizontalLimit, proposed.width)),
            height: min(verticalLimit, max(-verticalLimit, proposed.height))
        )
    }
}

struct MapZoomControls: View {
    let scale: CGFloat
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            mapButton(systemImage: "minus.magnifyingglass", action: onZoomOut)
            mapButton(systemImage: "plus.magnifyingglass", action: onZoomIn)
            mapButton(systemImage: "arrow.counterclockwise", action: onReset)
        }
        .padding(6)
        .background(.black.opacity(0.42), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }

    private func mapButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct StateMapView: View {
    let states: [USStateShape]
    let highlightedState: String?
    let usesUSAInsets: Bool

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.61, green: 0.83, blue: 0.88)))

                if usesUSAInsets {
                    drawMainland(in: &context, size: size)
                    drawInset(named: "Alaska", label: "AK", in: &context, size: size, rect: alaskaRect(size))
                    drawInset(named: "Hawaii", label: "HI", in: &context, size: size, rect: hawaiiRect(size))
                } else {
                    drawAll(in: &context, size: size)
                }
            }
        }
    }

    private var mainlandStates: [USStateShape] {
        states.filter { $0.name != "Alaska" && $0.name != "Hawaii" }
    }

    private func drawMainland(in context: inout GraphicsContext, size: CGSize) {
        let projection = GeoProjection(bounds: GeoProjection.bounds(for: mainlandStates), canvasSize: size, padding: 14)
        draw(states: mainlandStates, projection: projection, in: &context)
    }

    private func drawAll(in context: inout GraphicsContext, size: CGSize) {
        let projection = GeoProjection(bounds: GeoProjection.bounds(for: states), canvasSize: size, padding: 18)
        draw(states: states, projection: projection, in: &context)
    }

    private func drawInset(named name: String, label: String, in context: inout GraphicsContext, size: CGSize, rect: CGRect) {
        guard let state = states.first(where: { $0.name == name }) else { return }
        let projection = GeoProjection(bounds: GeoProjection.bounds(for: [state]), canvasSize: rect.size, padding: 8, origin: rect.origin)
        draw(states: [state], projection: projection, in: &context)

        let text = Text(label)
            .font(.system(size: 11, weight: .black))
            .foregroundColor(.black.opacity(0.58))
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.maxY + 8), anchor: .center)
    }

    private func draw(states: [USStateShape], projection: GeoProjection, in context: inout GraphicsContext) {
        for state in states {
            for polygon in state.polygons {
                var path = Path()
                for ring in polygon {
                    guard let first = ring.first else { continue }
                    path.move(to: projection.point(for: first))
                    for coordinate in ring.dropFirst() {
                        path.addLine(to: projection.point(for: coordinate))
                    }
                    path.closeSubpath()
                }

                let isHighlighted = state.name == highlightedState
                if isHighlighted {
                    context.fill(path, with: .color(Color(red: 1, green: 0.12, blue: 0.18)))
                    context.stroke(path, with: .color(.white.opacity(0.98)), lineWidth: 2.4)
                    drawSmallHighlightTarget(for: path, in: &context)
                } else {
                    context.fill(path, with: .color(.white))
                    context.stroke(path, with: .color(Color(white: 0.72)), lineWidth: 0.9)
                }
            }
        }
    }

    private func drawSmallHighlightTarget(for path: Path, in context: inout GraphicsContext) {
        let rect = path.boundingRect
        guard rect.width < 18 || rect.height < 18 else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(8, min(15, max(rect.width, rect.height) + 5))
        let outer = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        let inner = Path(ellipseIn: CGRect(
            x: center.x - 2.5,
            y: center.y - 2.5,
            width: 5,
            height: 5
        ))

        context.stroke(outer, with: .color(.white.opacity(0.95)), lineWidth: 3)
        context.stroke(outer, with: .color(Color(red: 1, green: 0.12, blue: 0.18)), lineWidth: 1.5)
        context.fill(inner, with: .color(Color(red: 1, green: 0.12, blue: 0.18)))
    }

    private func alaskaRect(_ size: CGSize) -> CGRect {
        CGRect(x: size.width * 0.055, y: size.height * 0.70, width: size.width * 0.23, height: size.height * 0.21)
    }

    private func hawaiiRect(_ size: CGSize) -> CGRect {
        CGRect(x: size.width * 0.31, y: size.height * 0.78, width: size.width * 0.15, height: size.height * 0.12)
    }
}

enum QuizMode: String, CaseIterable, Identifiable {
    case usaStates
    case brazilStates
    case southAmericaCountries
    case centralAmericaCountries
    case europeCountries

    var id: String { rawValue }

    var title: String {
        switch self {
        case .usaStates: return "USA States"
        case .brazilStates: return "Brazil States"
        case .southAmericaCountries: return "South America"
        case .centralAmericaCountries: return "Central America"
        case .europeCountries: return "Europe"
        }
    }

    var subtitle: String {
        switch self {
        case .usaStates: return "All 50 United States"
        case .brazilStates: return "Brazil's 26 states and Federal District"
        case .southAmericaCountries: return "Sovereign countries in South America"
        case .centralAmericaCountries: return "Countries from Belize to Panama"
        case .europeCountries: return "European countries on the map"
        }
    }

    var prompt: String {
        switch self {
        case .usaStates, .brazilStates: return "Name the highlighted state"
        case .southAmericaCountries, .centralAmericaCountries, .europeCountries: return "Name the highlighted country"
        }
    }

    var resourceName: String {
        switch self {
        case .usaStates: return "us-states"
        case .brazilStates: return "brazil-states"
        case .southAmericaCountries: return "south-america-countries"
        case .centralAmericaCountries: return "central-america-countries"
        case .europeCountries: return "europe-countries"
        }
    }

    var roundCount: Int {
        switch self {
        case .usaStates: return 50
        case .brazilStates: return 27
        case .southAmericaCountries: return 12
        case .centralAmericaCountries: return 7
        case .europeCountries: return 44
        }
    }

    var usesUSAInsets: Bool {
        self == .usaStates
    }

    var systemImage: String {
        switch self {
        case .usaStates: return "flag.fill"
        case .brazilStates: return "diamond.fill"
        case .southAmericaCountries: return "globe.americas.fill"
        case .centralAmericaCountries: return "map.fill"
        case .europeCountries: return "globe.europe.africa.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .usaStates: return .cyan
        case .brazilStates: return .green
        case .southAmericaCountries: return .orange
        case .centralAmericaCountries: return .mint
        case .europeCountries: return .purple
        }
    }
}

@MainActor
final class StateQuizViewModel: ObservableObject {
    @Published var selectedMode: QuizMode?
    @Published var mapStates: [USStateShape] = []
    @Published var questions: [USStateShape] = []
    @Published var currentIndex = 0
    @Published var typedLetters: [String] = []
    @Published var keyboardLetters: [String] = []
    @Published var usedKeyboardIndices: Set<Int> = []
    @Published var wrongSlotIndex: Int?
    @Published var wrongKeyboardIndex: Int?
    @Published var score = 0
    @Published var mistakes = 0
    @Published var isComplete = false

    private let usaExcludedShapes = Set(["Puerto Rico", "District of Columbia"])
    private let fillerLetters = Array("ETAOINSHRDLUCMFGYPWBVKXJQZ").map(String.init)

    var modeTitle: String {
        selectedMode?.title ?? "Map Quiz"
    }

    var prompt: String {
        selectedMode?.prompt ?? "Name the highlighted place"
    }

    var usesUSAInsets: Bool {
        selectedMode?.usesUSAInsets ?? false
    }

    var totalRounds: Int {
        questions.count
    }

    var currentState: USStateShape? {
        guard !isComplete, questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return min(Double(currentIndex) / Double(questions.count), 1)
    }

    var roundText: String {
        guard !questions.isEmpty else { return "Loading" }
        if isComplete { return "Round \(questions.count) of \(questions.count)" }
        return "Round \(currentIndex + 1) of \(questions.count)"
    }

    func start(mode: QuizMode) {
        selectedMode = mode
        let decoded = USStateShape.loadBundledShapes(resourceName: mode.resourceName)
            .filter { mode == .usaStates ? !usaExcludedShapes.contains($0.name) : true }
            .sorted { $0.name < $1.name }
        mapStates = decoded
        questions = decoded.shuffled()
        score = 0
        mistakes = 0
        currentIndex = 0
        isComplete = false
        prepareQuestion()
    }

    func returnToMenu() {
        selectedMode = nil
        mapStates.removeAll()
        questions.removeAll()
        typedLetters.removeAll()
        keyboardLetters.removeAll()
        usedKeyboardIndices.removeAll()
        wrongSlotIndex = nil
        wrongKeyboardIndex = nil
        isComplete = false
    }

    func pickLetter(at index: Int) {
        guard keyboardLetters.indices.contains(index),
              !usedKeyboardIndices.contains(index),
              !isComplete else { return }

        let expected = expectedLetter
        guard !expected.isEmpty else { return }

        if keyboardLetters[index] == expected {
            typedLetters.append(expected)
            usedKeyboardIndices.insert(index)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            if typedLetters.count == normalizedAnswer.count {
                completeCurrentState()
            }
        } else {
            mistakes += 1
            wrongSlotIndex = typedLetters.count
            wrongKeyboardIndex = index
            UINotificationFeedbackGenerator().notificationOccurred(.error)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                self.wrongSlotIndex = nil
                self.wrongKeyboardIndex = nil
            }
        }
    }

    func removeLastLetter() {
        guard let removed = typedLetters.popLast() else { return }
        if let index = usedKeyboardIndices.sorted().reversed().first(where: { keyboardLetters[$0] == removed }) {
            usedKeyboardIndices.remove(index)
        }
    }

    func revealHint() {
        guard !isComplete, !expectedLetter.isEmpty else { return }
        if let index = keyboardLetters.indices.first(where: { keyboardLetters[$0] == expectedLetter && !usedKeyboardIndices.contains($0) }) {
            pickLetter(at: index)
        }
    }

    func restart() {
        guard selectedMode != nil else { return }
        score = 0
        mistakes = 0
        currentIndex = 0
        isComplete = false
        questions.shuffle()
        prepareQuestion()
    }

    private var normalizedAnswer: String {
        normalizedLetters(from: currentState?.name ?? "")
    }

    private var expectedLetter: String {
        let answer = normalizedAnswer
        guard typedLetters.count < answer.count else { return "" }
        return String(answer[answer.index(answer.startIndex, offsetBy: typedLetters.count)])
    }

    private func completeCurrentState() {
        score += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if self.currentIndex + 1 >= self.questions.count {
                self.currentIndex = self.questions.count
                self.isComplete = true
                self.typedLetters.removeAll()
                self.usedKeyboardIndices.removeAll()
                self.keyboardLetters.removeAll()
            } else {
                self.currentIndex += 1
                self.prepareQuestion()
            }
        }
    }

    private func prepareQuestion() {
        wrongSlotIndex = nil
        wrongKeyboardIndex = nil
        typedLetters.removeAll()
        usedKeyboardIndices.removeAll()

        var letters = normalizedAnswer.map(String.init)
        while letters.count < 14 {
            if let filler = fillerLetters.randomElement() {
                letters.append(filler)
            }
        }
        keyboardLetters = letters.shuffled()
    }

    private func normalizedLetters(from text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .uppercased()
            .filter { $0.isLetter }
            .map(String.init)
            .joined()
    }
}

struct GeoProjection {
    let minLongitude: Double
    let maxLongitude: Double
    let minLatitude: Double
    let maxLatitude: Double
    let canvasSize: CGSize
    let padding: CGFloat
    let origin: CGPoint

    init(bounds: GeoBounds, canvasSize: CGSize, padding: CGFloat = 0, origin: CGPoint = .zero) {
        minLongitude = bounds.minLongitude
        maxLongitude = bounds.maxLongitude
        minLatitude = bounds.minLatitude
        maxLatitude = bounds.maxLatitude
        self.canvasSize = canvasSize
        self.padding = padding
        self.origin = origin
    }

    func point(for coordinate: GeoCoordinate) -> CGPoint {
        let longitudeRange = max(maxLongitude - minLongitude, 0.001)
        let latitudeRange = max(maxLatitude - minLatitude, 0.001)
        let drawableWidth = max(canvasSize.width - padding * 2, 1)
        let drawableHeight = max(canvasSize.height - padding * 2, 1)
        let mapAspect = longitudeRange / latitudeRange
        let canvasAspect = drawableWidth / drawableHeight
        let scale: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        if mapAspect > Double(canvasAspect) {
            scale = drawableWidth / CGFloat(longitudeRange)
            xOffset = padding
            yOffset = padding + (drawableHeight - CGFloat(latitudeRange) * scale) / 2
        } else {
            scale = drawableHeight / CGFloat(latitudeRange)
            xOffset = padding + (drawableWidth - CGFloat(longitudeRange) * scale) / 2
            yOffset = padding
        }

        let x = origin.x + (coordinate.longitude - minLongitude) * Double(scale) + Double(xOffset)
        let y = origin.y + (maxLatitude - coordinate.latitude) * Double(scale) + Double(yOffset)
        return CGPoint(x: x, y: y)
    }

    static func bounds(for states: [USStateShape]) -> GeoBounds {
        var bounds = GeoBounds()
        for state in states {
            for polygon in state.polygons {
                for ring in polygon {
                    for coordinate in ring {
                        bounds.include(coordinate)
                    }
                }
            }
        }
        return bounds
    }
}

struct GeoBounds {
    var minLongitude = Double.greatestFiniteMagnitude
    var maxLongitude = -Double.greatestFiniteMagnitude
    var minLatitude = Double.greatestFiniteMagnitude
    var maxLatitude = -Double.greatestFiniteMagnitude

    mutating func include(_ coordinate: GeoCoordinate) {
        minLongitude = min(minLongitude, coordinate.longitude)
        maxLongitude = max(maxLongitude, coordinate.longitude)
        minLatitude = min(minLatitude, coordinate.latitude)
        maxLatitude = max(maxLatitude, coordinate.latitude)
    }
}

struct GeoCoordinate {
    let longitude: Double
    let latitude: Double
}

struct USStateShape: Identifiable {
    let id: String
    let name: String
    let polygons: [[[GeoCoordinate]]]

    static func loadBundledShapes(resourceName: String) -> [USStateShape] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let featureCollection = try? JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data) else {
            return []
        }

        return featureCollection.features.map { feature in
            USStateShape(
                id: feature.properties.name,
                name: feature.properties.name,
                polygons: feature.geometry.polygons
            )
        }
    }
}

struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

struct GeoJSONFeature: Decodable {
    let properties: GeoJSONProperties
    let geometry: GeoJSONGeometry
}

struct GeoJSONProperties: Decodable {
    let name: String
}

struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: GeoJSONCoordinates

    var polygons: [[[GeoCoordinate]]] {
        switch coordinates {
        case .polygon(let rings):
            return [rings.map { ring in ring.map { GeoCoordinate(longitude: $0[0], latitude: $0[1]) } }]
        case .multiPolygon(let polygons):
            return polygons.map { polygon in
                polygon.map { ring in
                    ring.map { GeoCoordinate(longitude: $0[0], latitude: $0[1]) }
                }
            }
        }
    }
}

enum GeoJSONCoordinates: Decodable {
    case polygon([[[Double]]])
    case multiPolygon([[[[Double]]]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let multiPolygon = try? container.decode([[[[Double]]]].self) {
            self = .multiPolygon(multiPolygon)
        } else {
            self = .polygon(try container.decode([[[Double]]].self))
        }
    }
}
