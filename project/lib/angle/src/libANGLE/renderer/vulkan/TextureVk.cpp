//
// Copyright 2016 The ANGLE Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// TextureVk.cpp:
//    Implements the class methods for TextureVk.
//

#include "libANGLE/renderer/vulkan/TextureVk.h"

#include "common/debug.h"

namespace rx
{

TextureVk::TextureVk(const gl::TextureState &state) : TextureImpl(state)
{
}

TextureVk::~TextureVk()
{
}

gl::Error TextureVk::setImage(ContextImpl *contextImpl,
                              GLenum target,
                              size_t level,
                              GLenum internalFormat,
                              const gl::Extents &size,
                              GLenum format,
                              GLenum type,
                              const gl::PixelUnpackState &unpack,
                              const uint8_t *pixels)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setSubImage(ContextImpl *contextImpl,
                                 GLenum target,
                                 size_t level,
                                 const gl::Box &area,
                                 GLenum format,
                                 GLenum type,
                                 const gl::PixelUnpackState &unpack,
                                 const uint8_t *pixels)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setCompressedImage(ContextImpl *contextImpl,
                                        GLenum target,
                                        size_t level,
                                        GLenum internalFormat,
                                        const gl::Extents &size,
                                        const gl::PixelUnpackState &unpack,
                                        size_t imageSize,
                                        const uint8_t *pixels)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setCompressedSubImage(ContextImpl *contextImpl,
                                           GLenum target,
                                           size_t level,
                                           const gl::Box &area,
                                           GLenum format,
                                           const gl::PixelUnpackState &unpack,
                                           size_t imageSize,
                                           const uint8_t *pixels)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::copyImage(ContextImpl *contextImpl,
                               GLenum target,
                               size_t level,
                               const gl::Rectangle &sourceArea,
                               GLenum internalFormat,
                               const gl::Framebuffer *source)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::copySubImage(ContextImpl *contextImpl,
                                  GLenum target,
                                  size_t level,
                                  const gl::Offset &destOffset,
                                  const gl::Rectangle &sourceArea,
                                  const gl::Framebuffer *source)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setStorage(ContextImpl *contextImpl,
                                GLenum target,
                                size_t levels,
                                GLenum internalFormat,
                                const gl::Extents &size)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setEGLImageTarget(GLenum target, egl::Image *image)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::setImageExternal(GLenum target,
                                      egl::Stream *stream,
                                      const egl::Stream::GLTextureDescription &desc)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

gl::Error TextureVk::generateMipmap(ContextImpl *contextImpl)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

void TextureVk::setBaseLevel(GLuint baseLevel)
{
    UNIMPLEMENTED();
}

void TextureVk::bindTexImage(egl::Surface *surface)
{
    UNIMPLEMENTED();
}

void TextureVk::releaseTexImage()
{
    UNIMPLEMENTED();
}

gl::Error TextureVk::getAttachmentRenderTarget(const gl::FramebufferAttachment::Target &target,
                                               FramebufferAttachmentRenderTarget **rtOut)
{
    UNIMPLEMENTED();
    return gl::Error(GL_INVALID_OPERATION);
}

void TextureVk::syncState(const gl::Texture::DirtyBits &dirtyBits)
{
    UNIMPLEMENTED();
}

gl::Error TextureVk::setStorageMultisample(ContextImpl *contextImpl,
                                           GLenum target,
                                           GLsizei samples,
                                           GLint internalformat,
                                           const gl::Extents &size,
                                           GLboolean fixedSampleLocations)
{
    UNIMPLEMENTED();
    return gl::InternalError() << "setStorageMultisample is unimplemented.";
}

}  // namespace rx
