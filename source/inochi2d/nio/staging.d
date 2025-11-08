module inochi2d.nio.staging;
import nulib.collections;
import niobium;
import numem;

/**
    A managed staging buffer.
*/
class NioStagingBuffer : NuRefCounted {
private:
@nogc:
    NioDevice                   device_;
    NioBuffer                   buffer_;
    size_t                      alignment_;

    /// Creates initial 32 mb buffer.
    void createBuffer() {
        buffer_ = device_.createBuffer(NioBufferDescriptor(
            storage: NioStorageMode.sharedStorage,
            usage: NioBufferUsage.transfer,
            size: 33_554_432
        ));
    }

public:

    /**
        The underlying staging buffer.
    */
    @property NioBuffer buffer() => buffer_;

    /**
        Alignment of allocations in the buffer.
    */
    @property size_t alignment() => alignment_;

    /**
        Size of the buffer.
    */
    @property size_t size() => buffer_.size();

    // Destructor
    ~this() {
        buffer_.release();
    }

    /**
        Creates a new managed staging buffer.

        Params:
            device =    The device that owns the staging buffer.
            alignment = The increments that the staging buffer will grow.
    */
    this(NioDevice device, size_t alignment = 33_554_432) {
        this.device_ = device;
        this.alignment_ = alignment;
        this.createBuffer();
    }


    /**
        Resizes the buffer.

        Params:
            newSize =   The new size to request from the memory pool.

        Notes:
            The size will be aligned to $(D alignment).
    */
    void resize(size_t newSize) {
        if (newSize > buffer_.size) {
            buffer_ = device_.createBuffer(NioBufferDescriptor(
                storage: NioStorageMode.sharedStorage,
                usage: NioBufferUsage.transfer,
                size: cast(uint)nu_alignup(newSize, alignment_)
            ));
        }
    }

    /**
        Uploads data to the buffer at the given offset.

        Params:
            offset =    Offset into the staging buffer to upload to.
            data =      The data to upload.
        
        Returns:
            The ending offset of the upload.
    */
    ptrdiff_t upload(size_t offset, void[] data) {
        if (offset+data.length > this.size)
            return -1;

        if (auto mapped = buffer_.map()) {
            mapped[offset..offset+data.length] = data[0..$];
            buffer_.unmap();
        }
        return offset+data.length;
    }
}