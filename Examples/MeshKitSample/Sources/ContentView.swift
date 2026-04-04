import MeshKit
import SwiftUI

private enum DemoMode: String, CaseIterable, Hashable {
    case preview = "Preview"
    case editor = "Edit"
    case animated = "Animate"

    var title: String {
        rawValue
    }

    var detail: String {
        switch self {
        case .preview:
            return "Pure Mesh rendering with the current control points."
        case .editor:
            return "Drag the interior points to reshape the gradient live."
        case .animated:
            return "MeshAnimator drives a continuous morph based on the current mesh."
        }
    }
}

private enum MeshDensity: Int, CaseIterable, Hashable {
    case compact = 3
    case standard = 4
    case detailed = 5

    var title: String {
        "\(rawValue)x\(rawValue)"
    }

    var size: MeshSize {
        MeshSize(width: rawValue, height: rawValue)
    }
}

struct ContentView: View {
    private let compactLayoutBreakpoint: CGFloat = 700

    @Environment(\.colorScheme) private var colorScheme

    @State private var demoMode: DemoMode = .editor
    @State private var palette: Hue = .purple
    @State private var randomizeLocations = true
    @State private var meshDensity: MeshDensity = .standard
    @State private var colors = ContentView.makeMesh(
        palette: .purple,
        size: .init(width: 4, height: 4),
        randomizeLocations: true
    )
    @State private var selectedPoint: MeshColor?
    @State private var subdivisions = Double(MeshDefaults.subdivisions)
    @State private var grainAlpha = Double(MeshDefaults.grainAlpha)
    @State private var animationFramesPerSecond = 36.0
    @State private var animationDuration = 2.8
    @State private var motionAmount = 0.18
    @State private var turbulenceAmount = 0.14
    @State private var colorDrift = true
    @State private var isShowingFullscreenMesh = false
    @State private var animatedMeshSeed = UUID()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let isCompact = geometry.size.width < compactLayoutBreakpoint

                ScrollView(scrollAxes(isCompact: isCompact), showsIndicators: false) {
                    if isCompact {
                        content(isCompact: true)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .top)
                    } else {
                        content(isCompact: false)
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .frame(minWidth: 760, minHeight: 860, alignment: .top)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(background.ignoresSafeArea())

                if isShowingFullscreenMesh {
                    fullscreenMeshView
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isShowingFullscreenMesh)
        }
    }

    private func scrollAxes(isCompact: Bool) -> Axis.Set {
        isCompact ? .vertical : [.horizontal, .vertical]
    }

    private func content(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 16 : 20) {
            canvas(isCompact: isCompact)
            controls(isCompact: isCompact)
        }
    }

    private func canvas(isCompact: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            meshDisplay
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(panelStrokeColor, lineWidth: 1)
                )

            meshCanvasOverlay(
                isCompact: isCompact,
                isFullscreen: false,
                action: { isShowingFullscreenMesh = true }
            )
        }
        .frame(maxWidth: .infinity, minHeight: isCompact ? 340 : 460)
    }

    private var fullscreenMeshView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                background.ignoresSafeArea()

                meshDisplay
                    .ignoresSafeArea()

                meshCanvasOverlay(
                    isCompact: geometry.size.width < compactLayoutBreakpoint,
                    isFullscreen: true,
                    action: { isShowingFullscreenMesh = false }
                )
                .padding(.top, geometry.safeAreaInsets.top + 16)
                .padding(.horizontal, 16)

                VStack {
                    Spacer()

                    panelCard(spacing: 8) {
                        Text("Fullscreen Mesh")
                            .font(.headline.weight(.semibold))
                        Text(fullscreenSummary)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
        }
    }

    @ViewBuilder
    private var meshDisplay: some View {
        switch demoMode {
        case .preview:
            Mesh(
                colors: colors,
                grainAlpha: Float(grainAlpha),
                subdivisions: Int(subdivisions)
            )
        case .editor:
            MeshEditor(
                colors: $colors,
                selectedPoint: $selectedPoint,
                grainAlpha: Float(grainAlpha),
                subdivisions: Float(subdivisions)
            )
        case .animated:
            Mesh(
                colors: colors,
                animatorConfiguration: animatorConfiguration,
                grainAlpha: Float(grainAlpha),
                subdivisions: Int(subdivisions)
            )
            .id(animatedMeshSeed)
        }
    }

    @ViewBuilder
    private func controls(isCompact: Bool) -> some View {
        if isCompact {
            compactControls
        } else {
            regularControls
        }
    }

    private var regularControls: some View {
        panelCard(spacing: 18) {
            controlsHeader(isCompact: false)
            modeSection
            seedMeshSection(isCompact: false)
            renderSection

            if demoMode == .animated {
                animatedControls
            }

            statusText
        }
    }

    private var compactControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            panelCard {
                controlsHeader(isCompact: true)
            }

            panelCard(spacing: 10) {
                modeSection
            }

            panelCard {
                seedMeshSection(isCompact: true)
            }

            panelCard {
                renderSection
            }

            if demoMode == .animated {
                panelCard {
                    animatedControls
                }
            }

            panelCard(spacing: 8) {
                statusText
            }
        }
    }

    private func panelCard<Content: View>(
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(panelFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(panelStrokeColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func controlsHeader(isCompact: Bool) -> some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 14) {
                titleBlock(compact: true)

                VStack(spacing: 10) {
                    actionButton(title: "Regenerate Mesh", accent: true, fillWidth: true, action: regenerateMesh)
                    actionButton(title: "Random Palette", accent: false, fillWidth: true, action: randomizePaletteAndMesh)
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                titleBlock(compact: false)

                Spacer()

                HStack(spacing: 10) {
                    actionButton(title: "Random Palette", accent: false, action: randomizePaletteAndMesh)
                    actionButton(title: "Regenerate Mesh", accent: true, action: regenerateMesh)
                }
            }
        }
    }

    private func titleBlock(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MeshKit Sample")
                .font((compact ? Font.title2 : Font.title).weight(.semibold))
            Text(demoMode.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Mode")
            Picker("Mode", selection: $demoMode) {
                ForEach(DemoMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private func seedMeshSection(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Seed Mesh")

            if isCompact {
                VStack(alignment: .leading, spacing: 14) {
                    palettePicker
                    gridPicker
                }
            } else {
                HStack(spacing: 16) {
                    palettePicker
                    gridPicker
                }
            }

            Toggle("Randomize control point locations when regenerating", isOn: $randomizeLocations)
        }
    }

    private var palettePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Palette")
                .font(.headline)
            Picker("Palette", selection: $palette) {
                ForEach(Hue.allCases, id: \.self) { hue in
                    Text(hue.displayTitle).tag(hue)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gridPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grid")
                .font(.headline)
            Picker("Grid", selection: $meshDensity) {
                ForEach(MeshDensity.allCases, id: \.self) { density in
                    Text(density.title).tag(density)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var renderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Render")

            sliderRow(
                title: "Subdivisions",
                value: Int(subdivisions).description,
                slider: Slider(value: $subdivisions, in: 8...36, step: 1)
            )

            sliderRow(
                title: "Grain Alpha",
                value: String(format: "%.2f", grainAlpha),
                slider: Slider(value: $grainAlpha, in: 0...0.12, step: 0.01)
            )
        }
    }

    private var statusText: some View {
        Text(statusSummary)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func meshCanvasOverlay(
        isCompact: Bool,
        isFullscreen: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(demoMode.title)
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(badgeFillColor))
                    .overlay(Capsule().stroke(panelStrokeColor, lineWidth: 1))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        featureChip(demoMode.title)
                        featureChip(palette.displayTitle)
                        featureChip(meshDensity.title)
                        if demoMode == .animated {
                            featureChip("\(Int(animationFramesPerSecond)) FPS")
                            if colorDrift {
                                featureChip("Color Drift")
                            }
                        }
                        if isFullscreen {
                            featureChip("Expanded")
                        }
                    }
                }
                .frame(maxWidth: isCompact ? .infinity : 340, alignment: .leading)
            }

            Spacer(minLength: 0)

            iconActionButton(
                systemImage: isFullscreen ? "xmark" : "arrow.up.left.and.arrow.down.right",
                title: isFullscreen ? "Close" : (isCompact ? "Fullscreen" : nil),
                action: action
            )
        }
        .padding(16)
    }

    private var animatedControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Animated Mesh")

            Toggle("Shuffle mesh colors while animating", isOn: $colorDrift)

            sliderRow(
                title: "Frame Rate",
                value: "\(Int(animationFramesPerSecond)) FPS",
                slider: Slider(value: $animationFramesPerSecond, in: 24...60, step: 6)
            )

            sliderRow(
                title: "Morph Duration",
                value: String(format: "%.1fs", animationDuration),
                slider: Slider(value: $animationDuration, in: 1.4...5.0, step: 0.2)
            )

            sliderRow(
                title: "Position Drift",
                value: String(format: "%.2f", motionAmount),
                slider: Slider(value: $motionAmount, in: 0.02...0.30, step: 0.01)
            )

            sliderRow(
                title: "Turbulence",
                value: String(format: "%.2f", turbulenceAmount),
                slider: Slider(value: $turbulenceAmount, in: 0.02...0.30, step: 0.01)
            )
        }
    }

    private var animatorConfiguration: MeshAnimator.Configuration {
        MeshAnimator.Configuration(
            framesPerSecond: Int(animationFramesPerSecond),
            animationSpeedRange: animationDuration...(animationDuration + 1.8),
            meshRandomizer: animationRandomizer
        )
    }

    private var animationRandomizer: MeshRandomizer {
        let availableColors = colors.elements.map { $0.asSimd() }

        return MeshRandomizer(
            locationRandomizer: MeshRandomizer.randomizeLocationExceptEdges(
                range: -Float(motionAmount)...Float(motionAmount)
            ),
            turbulencyRandomizer: MeshRandomizer.randomizeTurbulencyExceptEdges(
                range: -Float(turbulenceAmount)...Float(turbulenceAmount)
            ),
            colorRandomizer: colorDrift
                ? MeshRandomizer.arrayBasedColorRandomizer(availableColors: availableColors)
                : { color, initialColor, _, _, _, _ in
                    color = initialColor
                }
        )
    }

    private var background: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.10, blue: 0.14),
                Color(red: 0.13, green: 0.17, blue: 0.23)
            ]
        }

        return [
            Color(red: 0.98, green: 0.96, blue: 0.92),
            Color(red: 0.91, green: 0.95, blue: 0.99)
        ]
    }

    private var panelFillColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.13, green: 0.15, blue: 0.19).opacity(0.92)
        }

        return Color.white.opacity(0.8)
    }

    private var badgeFillColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.96)
        }

        return Color.white.opacity(0.88)
    }

    private var panelStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.10)
        }

        return Color.black.opacity(0.06)
    }

    private var buttonFillColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.20, green: 0.22, blue: 0.27)
        }

        return Color.white.opacity(0.7)
    }

    private var buttonStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.10)
        }

        return Color.black.opacity(0.08)
    }

    private var primaryButtonFillColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.30 : 0.14)
    }

    private var primaryButtonStrokeColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.48 : 0.22)
    }

    private var statusSummary: String {
        switch demoMode {
        case .preview:
            return "Preview mode renders the current mesh without grabbers or animation."
        case .editor:
            if let selectedPoint {
                return String(
                    format: "Selected point at x: %.2f, y: %.2f. Regenerate applies the current palette and grid settings.",
                    selectedPoint.location.x,
                    selectedPoint.location.y
                )
            }

            return "Edit mode exposes the live control points. Regenerate applies the current palette and grid settings."
        case .animated:
            return "Animate mode uses the current mesh as its seed. Position drift, turbulence, color drift, and morph duration all feed MeshAnimator.Configuration."
        }
    }

    private var fullscreenSummary: String {
        switch demoMode {
        case .preview:
            return "Preview mode scales the current mesh to the full screen."
        case .editor:
            return "Editor mode stays live in fullscreen, so you can drag control points with more room."
        case .animated:
            return "Animate mode keeps the active MeshAnimator configuration while the mesh fills the screen."
        }
    }

    private func featureChip(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(panelFillColor))
            .overlay(Capsule().stroke(panelStrokeColor, lineWidth: 1))
    }

    private func iconActionButton(
        systemImage: String,
        title: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))

                if let title {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundColor(.primary)
            .padding(.horizontal, title == nil ? 12 : 14)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(badgeFillColor)
            )
            .overlay(
                Capsule()
                    .stroke(panelStrokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title ?? "Toggle fullscreen mesh")
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
    }

    private func sliderRow<SliderView: View>(title: String, value: String, slider: SliderView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            slider
        }
    }

    private func actionButton(
        title: String,
        accent: Bool,
        fillWidth: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            buttonLabel(title: title, accent: accent, fillWidth: fillWidth)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func buttonLabel(title: String, accent: Bool, fillWidth: Bool) -> some View {
        if fillWidth {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent ? primaryButtonFillColor : buttonFillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent ? primaryButtonStrokeColor : buttonStrokeColor, lineWidth: 1)
                )
        } else {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent ? primaryButtonFillColor : buttonFillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent ? primaryButtonStrokeColor : buttonStrokeColor, lineWidth: 1)
                )
        }
    }

    private func regenerateMesh() {
        selectedPoint = nil
        colors = Self.makeMesh(
            palette: palette,
            size: meshDensity.size,
            randomizeLocations: randomizeLocations
        )
        restartAnimatedMesh()
    }

    private func randomizePaletteAndMesh() {
        palette = Hue.randomPalette(includesMonochrome: false)
        regenerateMesh()
    }

    private func restartAnimatedMesh() {
        animatedMeshSeed = UUID()
    }

    private static func makeMesh(
        palette: Hue,
        size: MeshSize,
        randomizeLocations: Bool
    ) -> MeshColorGrid {
        MeshKit.generate(
            palette: palette,
            luminosity: .bright,
            size: size,
            withRandomizedLocations: randomizeLocations
        )
    }
}
