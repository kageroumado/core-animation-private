import QuartzCore

public extension CALayerHost {
    /// Creates a layer that hosts content rendered in a remote `CAContext`.
    ///
    /// The remote process renders into a `CAContext`, shares its
    /// ``CARenderContextID``, and this host composites that content into the
    /// local layer tree via the WindowServer. This is the mechanism WebKit uses
    /// to display GPU-process-rendered web content in the UI process.
    ///
    /// - Parameters:
    ///   - contextID: The remote context's identifier. The remote context must be
    ///     configured to permit hosting.
    ///   - preservesFlip: Preserve the remote content's flip state. Default
    ///     `true`, which is correct for hosting flipped content (e.g. WebKit) so
    ///     it renders right-side up.
    /// - Returns: A configured `CALayerHost`.
    static func hosting(contextID: CARenderContextID,
                        preservesFlip: Bool = true) -> CALayerHost {
        let host = CALayerHost()
        host.contextId = contextID
        host.preservesFlip = preservesFlip
        return host
    }
}
