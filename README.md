# MeshKit

A powerful and easy to use live mesh gradient renderer for iOS, living branch of archived EthanLipnik's MeshKit


**This project wouldn't be possible without the awesome work from [Moving Parts](https://movingparts.io/gradient-meshes) and their [Swift Playground](https://github.com/movingparts-io/Gradient-Meshes-with-SceneKit)**

## What is MeshKit?

MeshKit is an easy to use live mesh gradient renderer for iOS. In just a few lines of code, you can create a mesh gradient.

<video width="640" height="480" controls>
    <source src="media/sample.mov" type="video/mp4">
Your browser does not support the video tag.
</video>

## Installation

### Swift Package Manager

Add the following line to your package dependencies in `Package.swift`:

```swift
.package(url: "https://github.com/rogerioth/meshkit.git", from: "1.0.0")
```

Or add it directly through Xcode:
1. File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/rogerioth/meshkit.git`
3. Select the version you want to use

## Usage

### Quickstart

```swift
    private let randomizer = MeshRandomizer(colorRandomizer: { _, _, _, _, _, _ in
        return
    })
    private let colors: MeshColorGrid = MeshKit.generate(palette: Hue.purple, size: MeshSize(width: 4, height: 4))

    public var grainAlpha: Float = MeshDefaults.grainAlpha
    public var subdivisions: Float = Float(MeshDefaults.subdivisions)
    public var colorSpace: CGColorSpace?

    public var body: some View {
        ZStack {
            Mesh(colors: colors,
                 animatorConfiguration: .init(meshRandomizer: randomizer),
                 grainAlpha: grainAlpha,
                 subdivisions: Int(subdivisions),
                 colorSpace: colorSpace)
            .edgesIgnoringSafeArea(.all)

            VStack {
            }
        }
    }
```

The snippet above will generate the effect seen in the video demo.

### Rendering with MeshView
MeshView is at the core of MeshKit, encapsulating an SCNView with enhanced capabilities to render mesh gradients efficiently. It's straightforward to use:

#### Creating a Mesh Gradient
To create a mesh gradient, first initialize a MeshView and add it to your view hierarchy. Then, call the create method with an array of MeshNode.Color:

```swift
let meshView = MeshView()
view.addSubview(meshView)

meshView.create([
    // Define your mesh points and colors here
])
```

You can invoke this method multiple times to update the gradient dynamically.

#### Understanding `MeshNode.Color`
Each mesh point is defined by the MeshNode.Color structure, comprising three components:

#### Point
Specifies the grid position for the color, such as 0, 0 for a corner. This parameter is critical for the gradient's structure and no two colors should have the same point.

#### Location
Represents the color's x and y coordinates for interpolation. Adjusting this will shift the color within the gradient. Avoid altering the location of edge points to maintain the gradient's shape.

#### Color
The UIColor for the point. Note that alpha values are not utilized and will be disregarded. Choose colors that blend well for a smoother gradient.

#### Configuring Mesh Dimensions
MeshView supports customization of mesh width and height, though it's recommended to keep them equal for simplicity. The default dimensions are 3x3. If you choose to alter this, remember to provide a corresponding number of colors. For instance, a 2x2 mesh requires 4 colors, while a 4x4 mesh needs 16.

#### Adjusting Subdivisions
You can modify the mesh's subdivisions to change its "resolution." The default setting is 18. Increasing this value can enhance detail but may affect performance.

## Development

The project includes several utility scripts in the `scripts` directory to help with development:

### Available Scripts

- `build.sh`: Builds the project
- `build-and-test.sh`: Builds the project and runs all tests
- `setup-environment.sh`: Sets up the development environment
- `publish.sh`: Helps publish new versions of the package

### Publishing New Versions

To publish a new version of MeshKit:

1. Ensure all your changes are committed
2. Make sure you're on the main branch
3. Run the publish script with the new version number:
   ```bash
   ./scripts/publish.sh X.Y.Z
   ```
   Replace X.Y.Z with your version number (e.g., 1.0.0)

The publish script will:
- Validate the version format
- Ensure you're on the main branch
- Check for uncommitted changes
- Run tests
- Create and push a git tag for the version

## Requirements

- iOS 14.0+
- macOS 11.0+
- Xcode 13.0+
- Swift 5.7+

## Acknowledgments
Special thanks to [Moving Parts](https://movingparts.io/gradient-meshes) for their foundational work in gradient meshes.

And to [EthanLipnik](https://github.com/EthanLipnik/) for creating the initial version.

## License

This project is licensed under the terms found in [LICENSE.txt](LICENSE.txt).