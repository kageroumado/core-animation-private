import Foundation
import QuartzCore

public extension CABackdropLayer {
    /// Sets a Gaussian blur as this backdrop's filter.
    ///
    /// Builds a private `CAFilter` of type `gaussianBlur` and assigns it as the
    /// layer's sole filter. `normalizeEdges` prevents the darkening artifact at
    /// the edges of the blurred region.
    ///
    /// - Parameters:
    ///   - radius: Blur radius in points.
    ///   - normalizeEdges: Avoid edge darkening. Default `true`.
    func setBlurRadius(_ radius: Double, normalizeEdges: Bool = true) {
        guard let filter = CAFilter(name: "gaussianBlur") else { return }
        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(normalizeEdges, forKey: "inputNormalizeEdges")
        filters = [filter]
    }

    /// Creates a backdrop layer configured with a Gaussian blur.
    ///
    /// - Parameters:
    ///   - radius: Blur radius in points.
    ///   - normalizeEdges: Avoid edge darkening. Default `true`.
    ///   - windowServerAware: When `true`, the backdrop samples content from
    ///     other windows and the desktop, not just sibling layers — enabling
    ///     "blur the desktop behind a translucent window" effects.
    ///
    ///     - Important: This has privacy implications, as it lets the layer
    ///       sample content belonging to other applications. Default `false`.
    /// - Returns: A configured `CABackdropLayer`.
    static func blur(radius: Double,
                     normalizeEdges: Bool = true,
                     windowServerAware: Bool = false) -> CABackdropLayer {
        let layer = CABackdropLayer()
        layer.windowServerAware = windowServerAware
        layer.setBlurRadius(radius, normalizeEdges: normalizeEdges)
        return layer
    }
}
