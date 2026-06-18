import Foundation

// Re-export the raw private interfaces so a single `import CoreAnimationPrivate`
// exposes both the underlying types (CAPortalLayer, CALayerHost, CABackdropLayer,
// CAContext, CAFilter, …) and the Swift conveniences in this module.
@_exported import CoreAnimationPrivateObjC

/// A WindowServer-assigned identifier for a Core Animation render context.
///
/// Produced by ``CAContext/contextId`` and consumed by
/// ``CAPortalLayer/sourceContextId`` and ``CALayerHost/contextId``. A value of
/// `0` denotes an invalid/uninitialized context, so the helpers in this package
/// treat `0` as "no context".
public typealias CARenderContextID = UInt32

/// Runtime availability checks for the private classes this package vends.
///
/// These classes are part of QuartzCore but undocumented. They have existed for
/// many macOS releases, but because they are private there is no compile-time
/// guarantee they exist on a given system. Check before instantiating if you
/// want to fail gracefully rather than trap.
public enum CoreAnimationPrivate {
    /// Whether `CAPortalLayer` exists in the running QuartzCore.
    public static var isPortalLayerAvailable: Bool {
        NSClassFromString("CAPortalLayer") != nil
    }

    /// Whether `CALayerHost` exists in the running QuartzCore.
    public static var isLayerHostAvailable: Bool {
        NSClassFromString("CALayerHost") != nil
    }

    /// Whether `CABackdropLayer` exists in the running QuartzCore.
    public static var isBackdropLayerAvailable: Bool {
        NSClassFromString("CABackdropLayer") != nil
    }
}
