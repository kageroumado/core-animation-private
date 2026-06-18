import QuartzCore

public extension CAPortalLayer {
    /// Applies the property recipe for faithful visual mirroring.
    ///
    /// This is the combination that reliably reproduces a source layer's
    /// appearance, including AppKit's flipped backing layers:
    ///
    /// - `matchesTransform = true` — **critical**. The portal inherits the
    ///   source's transform chain. For an `NSView` backing layer (which has
    ///   `isGeometryFlipped == true`) this is what makes scroll direction and
    ///   content position match the original instead of rendering upside-down.
    /// - `matchesOpacity = true` — preserves the source's transparency.
    /// - `allowsBackdropGroups = true` — lets backdrop blur/vibrancy from the
    ///   source composite correctly through the portal.
    /// - `crossDisplay` — allow mirroring content that lives on another display.
    /// - `hidesSourceLayer = false` — keep the original visible (the portal is an
    ///   *additional* view of it, not a relocation).
    ///
    /// - Parameters:
    ///   - crossDisplay: Whether the portal may mirror across displays. Default `true`.
    ///   - matchesPosition: Whether the portal tracks the source's position in its
    ///     parent. Leave `false` (the default) when you position the portal
    ///     yourself via `frame`; set `true` for thumbnails that should follow the
    ///     source.
    func applyMirroringDefaults(crossDisplay: Bool = true, matchesPosition: Bool = false) {
        matchesTransform = true
        matchesOpacity = true
        self.matchesPosition = matchesPosition
        allowsBackdropGroups = true
        self.crossDisplay = crossDisplay
        if #available(macOS 13.0, *) {
            hidesSourceLayer = false
        }
    }

    /// Points this portal at `sourceLayer`, resolving the cross-window context ID.
    ///
    /// Wraps the assignment in a non-animating transaction so the portal swaps
    /// instantly (no implicit fade), then calls ``refreshConnection()`` to work
    /// around a first-attach rendering quirk.
    ///
    /// - Parameters:
    ///   - sourceLayer: The layer to mirror.
    ///   - crossWindow: When `true` (default) the source's
    ///     ``CARenderContextID`` is resolved and assigned to
    ///     ``sourceContextId`` so mirroring works across windows. Pass `false`
    ///     to skip this when the source is known to share the portal's context.
    func mirror(_ sourceLayer: CALayer, crossWindow: Bool = true) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.sourceLayer = sourceLayer
        if crossWindow, let id = sourceLayer.resolvedRenderContextID() {
            sourceContextId = id
        }
        CATransaction.commit()

        refreshConnection()
    }

    /// Re-establishes the portal's connection to its source.
    ///
    /// `CAPortalLayer` has a quirk: when first added to a tree — especially right
    /// after a mouse-click window activation, or on the first cross-window move —
    /// it can render blank because the compositing connection isn't fully
    /// established yet. Setting ``sourceLayer`` to `nil` and back forces an
    /// internal update that re-evaluates the connection.
    ///
    /// Call this after the source has produced its first frame (or whenever you
    /// observe a blank portal). The operation is wrapped in a non-animating
    /// transaction.
    func refreshConnection() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let savedSource = sourceLayer
        let savedContextID = sourceContextId
        sourceLayer = nil
        sourceLayer = savedSource
        sourceContextId = savedContextID
        CATransaction.commit()
    }

    /// Creates a fully-configured portal that mirrors `sourceLayer`.
    ///
    /// Equivalent to allocating a `CAPortalLayer`, calling
    /// ``applyMirroringDefaults(crossDisplay:matchesPosition:)`` and then
    /// ``mirror(_:crossWindow:)``.
    ///
    /// - Parameters:
    ///   - sourceLayer: The layer to mirror.
    ///   - frame: The portal's frame. Defaults to `.zero`; set it (or an
    ///     autoresizing mask) before display.
    ///   - crossWindow: Resolve and assign the source context ID. Default `true`.
    ///   - crossDisplay: Allow mirroring across displays. Default `true`.
    ///   - matchesPosition: Track the source's position. Default `false`.
    /// - Returns: A configured portal ready to be added as a sublayer.
    static func mirroring(_ sourceLayer: CALayer,
                          frame: CGRect = .zero,
                          crossWindow: Bool = true,
                          crossDisplay: Bool = true,
                          matchesPosition: Bool = false) -> CAPortalLayer {
        let portal = CAPortalLayer()
        portal.frame = frame
        portal.applyMirroringDefaults(crossDisplay: crossDisplay, matchesPosition: matchesPosition)
        portal.mirror(sourceLayer, crossWindow: crossWindow)
        return portal
    }
}
