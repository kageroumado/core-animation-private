# CoreAnimationPrivate

Clean, **heavily documented** Swift access to the private QuartzCore / Core Animation
layer types that power live layer mirroring, cross-process layer hosting, and
real backdrop blur on macOS — with ergonomic Swift wrappers over the hard parts.

If you've ever wanted to **mirror one layer in another view/window without
re-rendering it** (`CAPortalLayer`), **host GPU-process content**
(`CALayerHost`), apply a **genuine `CABackdropLayer` blur**, read a layer's
**render-context ID** (`CAContext`), or pull the **`IOSurface`** backing a
layer's contents — but bounced off the fact that none of it is in the public
SDK and the type signatures are nowhere to be found — this package is for you.

The headers were reverse-engineered and annotated for the
[Refrax](https://github.com/kageroumado/refrax-browser) browser, then extracted
here so they're easy to find and reuse.

> [!WARNING]
> **These are private Apple APIs.** They are undocumented and may change or
> disappear in any macOS release. Using them will get an app **rejected from the
> Mac App Store**. They are perfectly fine for apps distributed outside the App
> Store, internal tools, prototypes, and research. The Swift layer guards
> instantiation behind runtime availability checks; the symbols themselves
> resolve from the system QuartzCore framework at runtime.

## What's inside

| Type | What it does |
|------|--------------|
| **`CAPortalLayer`** | Displays a live, read-only mirror of another layer's composited content — no extra backing store. Thumbnails, previews, picture-in-picture, the same content in multiple windows. |
| **`CALayerHost`** | Hosts content rendered in another process via a `CAContext` ID. This is how WebKit shows GPU-process web content in the UI process. |
| **`CABackdropLayer`** | The real frosted-glass primitive behind vibrancy. Gaussian blur, backdrop groups, optional window-server-wide sampling. |
| **`CAContext`** | A WindowServer compositing context. Its `contextId` is the key to cross-window portaling and remote hosting. |
| **`CAFilter`** | Private CA filters (`gaussianBlur`, `colorInvert`, `colorSaturate`, …) for `layer.filters`. |
| **`CAIOSurface`** | Extract the `IOSurface` backing a layer's `contents` for zero-copy Metal access. |
| Private `CALayer` properties | `_captureExcluded` (exclude from screen capture), `allowsGroupBlending`, `allowsEdgeAntialiasing`, and the `context` accessor. |

Every declaration carries DocC-style documentation explaining behavior,
defaults, availability, and gotchas. Reading the headers is half the value.

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/kageroumado/core-animation-private.git", from: "1.0.0")
```

```swift
.target(name: "MyApp", dependencies: ["CoreAnimationPrivate"])
```

A single `import CoreAnimationPrivate` re-exports both the raw types and the Swift
conveniences. macOS 13+.

## Usage

### Mirror a layer (CAPortalLayer)

The headline feature. `CAPortalLayer` shows a live copy of another layer's
content without duplicating its backing store.

```swift
import CoreAnimationPrivate

// One call: a fully-configured portal mirroring `sourceView.layer`.
let portal = CAPortalLayer.mirroring(sourceLayer, frame: containerView.bounds)
portal.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
containerView.layer?.addSublayer(portal)
```

`mirroring(_:)` applies the property recipe that actually works in practice
(learned the hard way):

- **`matchesTransform = true`** — the single most important setting. The portal
  inherits the source's transform chain. For an `NSView` backing layer (which is
  `isGeometryFlipped`), this is what keeps the mirror right-side-up with correct
  scroll direction instead of flipped.
- `matchesOpacity = true`, `allowsBackdropGroups = true`, `crossDisplay = true`,
  and the source stays visible (`hidesSourceLayer = false`).

Want to drive it yourself? The pieces are public:

```swift
let portal = CAPortalLayer()
portal.applyMirroringDefaults()        // the recipe above
portal.mirror(sourceLayer)             // sets sourceLayer + cross-window context ID
```

**Cross-window mirroring.** Setting `sourceLayer` alone only works within the
same window. To mirror a layer in *another* window you also need its
`CAContext` ID — `mirror(_:)` resolves and sets it for you via:

```swift
if let id = sourceLayer.resolvedRenderContextID() {
    portal.sourceContextId = id
}
```

**The blank-portal quirk.** When first attached — especially right after a
mouse-click window activation, or the first cross-window move — a portal can
render blank until its compositing connection settles. Nudge it:

```swift
portal.refreshConnection()   // toggles sourceLayer off/on inside a non-animating transaction
```

Call it after the source produces its first frame, or whenever you observe a
blank portal.

### Backdrop blur (CABackdropLayer)

```swift
let backdrop = CABackdropLayer.blur(radius: 20)
backdrop.frame = panel.bounds
panel.layer?.addSublayer(backdrop)

// Blur the desktop/other windows behind a translucent window
// (note the privacy implications):
let glass = CABackdropLayer.blur(radius: 30, windowServerAware: true)
```

### Host remote content (CALayerHost)

```swift
let host = CALayerHost.hosting(contextID: remoteContextID, preservesFlip: true)
host.frame = contentFrame
containerLayer.addSublayer(host)
```

### Read the IOSurface behind a layer

```swift
if let surface = layer.contentsIOSurface {
    // bind as a Metal texture, inspect pixels, etc.
}

// Search a nested tree (e.g. WebKit's tiled layers):
let surface = webView.layer?.firstContentsIOSurface()
```

### Render-context ID for any layer

```swift
let contextID = view.layer?.resolvedRenderContextID()   // walks up the tree if needed
```

### Fail gracefully if a class is gone

```swift
guard CoreAnimationPrivate.isPortalLayerAvailable else {
    // fall back to a snapshot image, etc.
    return
}
```

## Notes & caveats

- **Threading.** The portal, backdrop, layer-host, and context-resolution APIs
  are `@MainActor`-isolated. Core Animation property access is internally
  serialized, but these touch view-backed layers and rely on the main run loop
  committing the implicit `CATransaction` — committing off-main triggers
  main-thread-only `NSView` drawing and crashes. The IOSurface extraction
  helpers (`contentsIOSurface`, `firstContentsIOSurface()`,
  `ioSurface(fromContents:)`) are `nonisolated` and safe to call from a
  render/background thread, since `IOSurface` is designed for
  cross-thread/cross-process sharing.
- **Read-only.** A `CAPortalLayer` mirror does not forward input events to its
  source.
- **Same process.** `CAPortalLayer` mirrors layers in the same process;
  cross-*process* display is what `CALayerHost` + `CAContext` are for.
- **Performance.** Many portals of the same source, large blur radii, or
  frequently-changing backdrops all cost GPU time. Profile.
- **Verified on macOS 26.1** (the `CAIOSurface` symbols especially). Other
  versions are very likely fine but unverified.

## How it's built

- `CoreAnimationPrivateObjC` — a Clang target vending the annotated private
  headers as a module. The headers only *declare* the interfaces; the symbols
  come from the system QuartzCore framework at runtime.
- `CoreAnimationPrivate` — the Swift target with the ergonomic wrappers, which
  `@_exported import`s the headers so you get everything from one import.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

Header documentation cross-referenced against the open-source
[WebKit](https://github.com/WebKit/WebKit) `QuartzCoreSPI.h` and
`WebCoreCALayerExtras.mm`, and symbol exports from QuartzCore.
