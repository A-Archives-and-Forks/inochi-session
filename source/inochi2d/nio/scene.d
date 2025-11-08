module inochi2d.nio.scene;
import inochi2d.nio.staging;
import inochi2d.nio.puppet;
import inochi2d;
import niobium;
import numem;
import nulib.collections;
import nulib.math : min, max;

/**
    An Inochi2D Scene hosted by Niobium.
*/
class NioScene {
private:
@nogc:
    NioDevice                   device_;
    NioCommandQueue             queue_;
    weak_vector!NioPuppet       puppets_;

    /// Render state
    NioStagingBuffer            staging_;
    NioTexture                  maskTarget_;
    NioTexture[16][]            renderTargets_;

    /// Updates the puppets and their vertex data.
    void updatePuppets(NioCommandBuffer cmdbuffer, float delta) {

        // 1. Update the staging buffer's size.
        size_t totalBufferSize = 0;
        foreach(ref NioPuppet puppet; puppets_[]) {
            puppet.update(delta);
            totalBufferSize += puppet.totalBufferSize;
        }
        
        if (totalBufferSize > staging_.size)
            staging_.resize(totalBufferSize);

        // Then fill the staging buffer and enqueue transfer commands.
        auto cmds = cmdbuffer.beginTransferPass();
            cmds.insertBarrier(NioPipelineStage.transfer, NioPipelineStage.all);
            
            size_t vtxStart = 0;
            foreach(i, ref NioPuppet puppet; puppets_[]) {
                size_t vtxEnd = staging_.upload(vtxStart, cast(void[])puppet.vertices);
                size_t idxEnd = staging_.upload(vtxEnd, cast(void[])puppet.indices);

                cmds.copy(
                    NioBufferSrcInfo(
                        buffer: staging_.buffer, 
                        offset: cast(uint)vtxStart,
                        length: cast(uint)(vtxEnd-vtxStart)
                    ), 
                    NioBufferDstInfo(
                        buffer: puppet.vertexBuffer,
                        offset: 0,
                    )
                );
                cmds.copy(
                    NioBufferSrcInfo(
                        buffer: staging_.buffer, 
                        offset: cast(uint)vtxEnd,
                        length: cast(uint)(idxEnd-vtxEnd)
                    ), 
                    NioBufferDstInfo(
                        buffer: puppet.indexBuffer,
                        offset: 0,
                    )
                );
                vtxStart = idxEnd;
            }
        cmds.endEncoding();
    }

    /// Function which draws an individual puppet into the scene.
    void drawPuppet(NioPuppet puppet) {

    }
    
public:
    
    /**
        The Niobium device being used to render the scene.
    */
    @property NioDevice device() => device_;

    /// Destructor
    ~this() {
        queue_.release();
        staging_.release();
    }

    /// Constructor
    this(NioDevice device) {
        this.device_ = device;
        this.queue_ = device.createQueue(NioCommandQueueDescriptor(32));
        this.staging_ = nogc_new!NioStagingBuffer(device_);
    }

    /**
        Updates all of the puppets currently active in this scene,
        preparing all the puppets for rendering a frame.

        Params:
            delta = The time since the last frame.
    */
    void update(float delta) {
        NioCommandBuffer cmdbuffer = queue_.fetch();
            this.updatePuppets(cmdbuffer, delta);
            foreach(ref NioPuppet puppet; puppets_) {
                this.drawPuppet(puppet);
            }
        queue_.commit(cmdbuffer);
        cmdbuffer.await();
        cmdbuffer.release();
    }

    /**
        Blits the scene to the given target texture.

        Notes:
            This can be called multiple times with minimal overhead,
            as the internal drawing is done in $(D update).

        Params:
            target = The target to render the scene to.
    */
    void blit(NioTexture target) {

    }
}