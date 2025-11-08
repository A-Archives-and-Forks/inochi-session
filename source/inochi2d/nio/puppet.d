module inochi2d.nio.puppet;
import inochi2d;
import niobium;
import numem;
import nulib.collections;
import nulib.math : min, max;

/**
    A niobium renderered puppet.
*/
class NioPuppet : NuRefCounted {
private:
@nogc:

    // Puppet info
    Puppet          puppet_;

    // Render handles
    NioDevice       device_;
    NioBuffer       vtx_;
    NioBuffer       idx_;
    NioTexture[]    tex_;

    // Creates the puppet and its associated buffers.
    void createPuppet(string file) {
        this.puppet_ = assumeNoThrowNoGC(&ins_puppet_load_pinned, file);
        this.tex_ = nu_malloca!NioTexture(puppet_.textureCache.cache.length);
        foreach(i, ref Texture texture; puppet_.textureCache.cache) {
            tex_[i] = device_.createTexture(NioTextureDescriptor(
                type: NioTextureType.type2D,
                format: NioPixelFormat.rgba8UnormSRGB, 
                storage: NioStorageMode.privateStorage,
                usage: NioTextureUsage.transfer | NioTextureUsage.sampled,
                width: texture.width,
                height: texture.height,
            )).upload(NioRegion3D(0, 0, 0, texture.width, texture.height, 1), 0, 0, texture.pixels, 0);
        }

        // NOTE:    We create the initial buffers here,
        //          the buffer sizes are not known until an update
        //          has occured, so we do a 0 ms update.
        assumeNoThrowNoGC(&ins_puppet_update_pinned, puppet_, 0);

        size_t vtxSize = puppet.drawList.vertices.length * VtxData.sizeof;
        size_t idxSize = puppet.drawList.indices.length * uint.sizeof;
        vtx_ = device_.createBuffer(NioBufferDescriptor(
            storage: NioStorageMode.privateStorage,
            usage: NioBufferUsage.transfer | NioBufferUsage.vertexBuffer,
            size: cast(uint)vtxSize
        ));
        idx_ = device_.createBuffer(NioBufferDescriptor(
            storage: NioStorageMode.privateStorage,
            usage: NioBufferUsage.transfer | NioBufferUsage.indexBuffer,
            size: cast(uint)idxSize
        ));
    }

    // Resizes the vertex and index buffers.
    void resizeBuffers() {
        size_t vtxSize = puppet.drawList.vertices.length * VtxData.sizeof;
        size_t idxSize = puppet.drawList.indices.length * uint.sizeof;

        if (vtxSize > vtx_.size) {
            vtx_.release();
            vtx_ = device_.createBuffer(NioBufferDescriptor(
                storage: NioStorageMode.privateStorage,
                usage: NioBufferUsage.transfer | NioBufferUsage.vertexBuffer,
                size: cast(uint)vtxSize
            ));
        }

        if (idxSize > idx_.size) {
            idx_.release();
            idx_ = device_.createBuffer(NioBufferDescriptor(
                storage: NioStorageMode.privateStorage,
                usage: NioBufferUsage.transfer | NioBufferUsage.indexBuffer,
                size: cast(uint)idxSize
            ));
        }
    }

public:
    
    /**
        The underlying Inochi2D Puppet
    */
    @property Puppet puppet() => puppet_;

    /**
        The loaded textures of the puppet.
    */
    @property NioTexture[] textures() => tex_;

    /**
        Vertex data of the puppet.
    */
    @property VtxData[] vertices() => puppet.drawList.vertices;

    /**
        The puppet's vertex buffer.
    */
    @property NioBuffer vertexBuffer() => vtx_;

    /**
        Vertex data of the puppet.
    */
    @property uint[] indices() => puppet.drawList.indices;

    /**
        The puppet's index buffer.
    */
    @property NioBuffer indexBuffer() => idx_;

    /**
        Total size of the puppet's buffers.
    */
    @property size_t totalBufferSize() => vtx_.size + idx_.size;


    // Destructor
    ~this() {
        assumeNoThrowNoGC(&ins_puppet_unload_pinned, puppet);
        if (vtx_) vtx_.release();
        if (idx_) idx_.release();
        foreach(ref NioTexture texture; tex_)
            texture.release();
        nu_freea(tex_);
    }

    /**
        Loads a puppet.
    */
    this(NioDevice device, string file) {
        this.device_ = device;
        this.createPuppet(file);
    }

    /**
        Updates the puppet and resizes vertex and index buffers if needed.

        Params:
            delta = Time since last frame.
    */
    void update(float delta) {
        assumeNoThrowNoGC(&ins_puppet_update_pinned, puppet_, delta);
        this.resizeBuffers();
    }
}

private:

extern(C) void ins_puppet_update_pinned(Puppet puppet, float delta) {
    puppet.update(delta);
    puppet.draw(delta);
}

extern(C) Puppet ins_puppet_load_pinned(string file) {
    import core.memory : GC;

    auto puppet_ = inLoadPuppet(file);
    GC.addRoot(cast(void*)puppet_);
    return puppet_;
}

extern(C) void ins_puppet_unload_pinned(Puppet puppet) {
    import core.memory : GC;

    GC.removeRoot(cast(void*)puppet);
}