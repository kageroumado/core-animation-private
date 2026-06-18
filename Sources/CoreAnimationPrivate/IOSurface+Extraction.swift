import IOSurface
import QuartzCore

// `IOSurface` is thread-safe by design — it exists to share GPU buffers across
// processes and threads, and binding one as a Metal texture needs no locking.
// These extraction helpers are therefore `nonisolated`, so they can run on a
// render/background thread even though the rest of this module defaults to
// `MainActor`. (Reading `contents` is a CALayer property access, which Core
// Animation serializes internally.)
public extension CALayer {
    /// The `IOSurface` backing this layer's `contents`, if it is surface-backed.
    ///
    /// GPU-composited layers (video, WebKit tiles, Metal output) store their
    /// pixels in an `IOSurface`, exposed through `contents` as either a raw
    /// `IOSurfaceRef` or Core Animation's private `CAIOSurface` wrapper. This
    /// returns the underlying surface in both cases, ready to bind as a Metal
    /// texture for zero-copy GPU access.
    ///
    /// - Note: The returned surface is **not** retained beyond the lifetime of
    ///   the layer's `contents`. Retain it yourself if you need to outlive the
    ///   layer.
    nonisolated var contentsIOSurface: IOSurfaceRef? {
        CALayer.ioSurface(fromContents: contents)
    }

    /// Recursively searches this layer and its descendants for the first
    /// IOSurface-backed `contents`.
    ///
    /// Useful for layer trees (such as WebKit's tiled rendering) where the
    /// surface-backed layer is nested below the layer you hold.
    ///
    /// - Parameter maximumDepth: How many levels of sublayers to descend.
    ///   Default `8`.
    /// - Returns: The first `IOSurfaceRef` found in depth-first order, or `nil`.
    nonisolated func firstContentsIOSurface(maximumDepth: Int = 8) -> IOSurfaceRef? {
        if let surface = contentsIOSurface {
            return surface
        }
        guard maximumDepth > 0, let sublayers else {
            return nil
        }
        for sublayer in sublayers {
            if let surface = sublayer.firstContentsIOSurface(maximumDepth: maximumDepth - 1) {
                return surface
            }
        }
        return nil
    }

    /// Extracts an `IOSurfaceRef` from a value taken from `CALayer.contents`.
    ///
    /// Handles both a raw `IOSurfaceRef` and the private `CAIOSurface` wrapper.
    ///
    /// - Parameter contents: A `CALayer.contents` value.
    /// - Returns: The underlying surface, or `nil` if `contents` is not
    ///   surface-backed.
    nonisolated static func ioSurface(fromContents contents: Any?) -> IOSurfaceRef? {
        guard let contents else {
            return nil
        }
        let object = contents as AnyObject
        let typeID = CFGetTypeID(object)

        if typeID == IOSurfaceGetTypeID() {
            return unsafeDowncast(object, to: IOSurfaceRef.self)
        }

        if typeID == CAIOSurfaceGetTypeID() {
            let wrapper = unsafeBitCast(object, to: CAIOSurfaceRef.self)
            // CAIOSurfaceGetIOSurface follows the "Get" rule (the returned
            // surface is not retained), so take it unretained.
            return CAIOSurfaceGetIOSurface(wrapper)?.takeUnretainedValue()
        }

        return nil
    }
}
