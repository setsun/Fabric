import Fabric
import Metal
import Satin
import Testing

private final class PluginGeometryNode: BaseGeometryNode
{
    override class var name: String { "Plugin Geometry" }
    override class var nodeTimeMode: Node.TimeMode { .TimeBase }

    override class func registerPorts(context: Context) -> [(name: String, port: Fabric.Port)]
    {
        [
            (
                "inputSize",
                ParameterPort(
                    parameter: FloatParameter(
                        "Size",
                        1,
                        .inputfield,
                        "Geometry size"
                    )
                )
            ),
        ] + super.registerPorts(context: context)
    }

    override var geometry: Geometry { triangleGeometry }

    private lazy var triangleGeometry = TriangleGeometry(context: context)
    private(set) var updateInvocationCount = 0

    override func updateGeometry(
        renderer: GraphRenderer,
        executionInfo: GraphExecutionInfo,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer
    ) throws -> Bool
    {
        updateInvocationCount += 1
        return try super.updateGeometry(
            renderer: renderer,
            executionInfo: executionInfo,
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )
    }
}

@Suite("Base Geometry Node Plugin API")
struct BaseGeometryNodePluginAPITests
{
    @Test("An external-style subclass inherits ports and participates in execution")
    func externalSubclassUsesBaseGeometryLifecycle() throws
    {
        guard let harness = GraphExecutionTestHarness() else { return }
        guard let commandBuffer = harness.renderer.commandQueue.makeCommandBuffer() else
        {
            return
        }

        let node = PluginGeometryNode(context: harness.context)
        let renderPassDescriptor = MTLRenderPassDescriptor()

        try node.execute(
            renderer: harness.renderer,
            executionInfo: harness.makeExecutionInfo(),
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )

        #expect(node.findPort(named: "inputSize", as: ParameterPort<Float>.self) != nil)
        #expect(node.inputPrimitiveType.value == "Triangle")
        #expect(node.primitiveType() == .triangle)
        #expect(node.outputGeometry.value === node.geometry)
        #expect(node.updateInvocationCount == 1)
    }
}
