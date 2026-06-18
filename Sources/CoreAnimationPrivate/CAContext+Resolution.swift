import QuartzCore

public extension CALayer {
    /// The Core Animation render context this layer's tree belongs to.
    ///
    /// Thin Swift accessor over the private `-[CALayer context]` method. Returns
    /// `nil` when the layer is not attached to a context (e.g. detached from any
    /// window).
    var renderContext: CAContext? {
        context()
    }

    /// Resolves the WindowServer render-context ID for this layer's tree.
    ///
    /// A `CAPortalLayer` only mirrors content within the *same* `CAContext` when
    /// you set ``CAPortalLayer/sourceLayer`` alone. To mirror a layer that lives
    /// in another window (a different context), the portal also needs
    /// ``CAPortalLayer/sourceContextId``. This method finds that ID.
    ///
    /// The immediate layer sometimes has no context during window transitions, so
    /// this walks up the superlayer chain until it finds a valid (non-zero)
    /// context ID.
    ///
    /// - Returns: A non-zero ``CARenderContextID``, or `nil` if no context is
    ///   currently associated with this layer's tree.
    func resolvedRenderContextID() -> CARenderContextID? {
        if let id = context()?.contextId, id != 0 {
            return id
        }
        var ancestor = superlayer
        while let layer = ancestor {
            if let id = layer.context()?.contextId, id != 0 {
                return id
            }
            ancestor = layer.superlayer
        }
        return nil
    }
}
