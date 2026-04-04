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

    var body: some View {
        VStack(spacing: 20) {
            canvas
            controls
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 860)
        .background(background.ignoresSafeArea())
    }

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            meshDisplay
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

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
                    }
                }
                .frame(maxWidth: 340)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 460)
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
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MeshKit Sample")
                        .font(.title.weight(.semibold))
                    Text(demoMode.detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    actionButton(title: "Random Palette", accent: false, action: randomizePaletteAndMesh)
                    actionButton(title: "Regenerate Mesh", accent: true, action: regenerateMesh)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Mode")
                Picker("Mode", selection: $demoMode) {
                    ForEach(DemoMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Seed Mesh")

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Palette")
                            .font(.headline)
                        Picker("Palette", selection: $palette) {
                            ForEach(Hue.allCases, id: \.self) { hue in
                                Text(hue.displayTitle).tag(hue)
                            }
                        }
                        #if os(macOS)
                        .pickerStyle(MenuPickerStyle())
                        #else
                        .pickerStyle(MenuPickerStyle())
                        #endif
                    }

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
                }

                Toggle("Randomize control point locations when regenerating", isOn: $randomizeLocations)
            }

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

            if demoMode == .animated {
                animatedControls
            }

            Text(statusSummary)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
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

    private func featureChip(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(panelFillColor))
            .overlay(Capsule().stroke(panelStrokeColor, lineWidth: 1))
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

    private func actionButton(title: String, accent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(PlainButtonStyle())
    }

    private func regenerateMesh() {
        selectedPoint = nil
        colors = Self.makeMesh(
            palette: palette,
            size: meshDensity.size,
            randomizeLocations: randomizeLocations
        )
    }

    private func randomizePaletteAndMesh() {
        palette = Hue.randomPalette(includesMonochrome: false)
        regenerateMesh()
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
