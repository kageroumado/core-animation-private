import IOSurface
import QuartzCore
import Testing

@testable import CoreAnimationPrivate

@Suite("CoreAnimationPrivate")
struct CoreAnimationPrivateTests {
    @Test("Private classes resolve at runtime")
    func privateClassesExist() {
        #expect(CoreAnimationPrivate.isPortalLayerAvailable)
        #expect(CoreAnimationPrivate.isLayerHostAvailable)
        #expect(CoreAnimationPrivate.isBackdropLayerAvailable)
    }

    @Test("applyMirroringDefaults sets the faithful-mirroring recipe")
    func mirroringDefaults() {
        let portal = CAPortalLayer()
        portal.applyMirroringDefaults()

        #expect(portal.matchesTransform)
        #expect(portal.matchesOpacity)
        #expect(!portal.matchesPosition)
        #expect(portal.allowsBackdropGroups)
        #expect(portal.crossDisplay)
    }

    @Test("mirror() assigns the source layer")
    func mirrorAssignsSource() {
        let source = CALayer()
        let portal = CAPortalLayer.mirroring(source, frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        #expect(portal.sourceLayer === source)
        #expect(portal.frame == CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    @Test("Detached layer has no render context ID")
    func detachedLayerHasNoContext() {
        // A layer not attached to any window/context resolves to nil.
        let layer = CALayer()
        #expect(layer.resolvedRenderContextID() == nil)
    }

    @Test("Backdrop blur installs a gaussianBlur filter")
    func backdropBlur() {
        let backdrop = CABackdropLayer.blur(radius: 20)
        #expect(backdrop.filters?.count == 1)
    }

    @Test("Layer host stores its context ID and flip preference")
    func layerHost() {
        let host = CALayerHost.hosting(contextID: 42, preservesFlip: true)
        #expect(host.contextId == 42)
        #expect(host.preservesFlip)
    }

    @Test("IOSurface round-trips through CALayer contents")
    func ioSurfaceExtraction() throws {
        let surface: IOSurface
        if let created = IOSurface(properties: [
            .width: 16,
            .height: 16,
            .bytesPerElement: 4,
            .pixelFormat: 0x42475241 // 'BGRA'
        ]) {
            surface = created
        } else {
            Issue.record("Failed to create backing IOSurface")
            return
        }

        // Raw IOSurfaceRef path.
        let layer = CALayer()
        layer.contents = surface
        let extracted = try #require(layer.contentsIOSurface)
        #expect(IOSurfaceGetWidth(extracted) == 16)

        // CAIOSurface wrapper path.
        let wrapped = try #require(CAIOSurfaceCreate(surface))
        let unwrapped = try #require(CAIOSurfaceGetIOSurface(wrapped)?.takeUnretainedValue())
        #expect(IOSurfaceGetWidth(unwrapped) == 16)
    }
}
