# GL Transmission Format (glTF2) for D

glTF2 is a specification by Khronos for transmitting and loading 3D scenes and
models for applications. Read more: https://github.com/KhronosGroup/glTF

This is planned to be a complete implementation of the glTF2 specification,
with support for all future Khronos extensions. This repository is the core
glTF2 implementation, which includes features such as:
  * Validation
  * Loading multiple formats (standard, binary, embedded)
  * A simple layer on top of JSON structs

The idea is to give a core glTF2 implemention in which graphics APIs may be
built on top of. There are plans for loaders and viewers for both OpenGL
and Vulkan, along with possibly an experimental Global Illumination viewer.

 * [Base glTF2](https://github.com/AODQ/gltf)
 * [OpenGL Loader](https://github.com/AODQ/gltf-opengl)
 * [OpenGL Viewer](https://github.com/AODQ/gltf-opengl-viewer)
 * Vulkan Loader: WIP
 * Vulkan Viewer: WIP

![](https://github.com/AODQ/gltf/blob/master/media/glTF2-api-spec-0.png?raw=true)

The goal right now is to load & view all glTF2 sample models in OpenGL from
  https://github.com/KhronosGroup/glTF-Sample-Models/tree/master/2.0/

The following is a list of working models with an implementation quality from *
  to *** when compared to their reference screenshot:

    "Triangle Without Indices" ........... **
    "Triangle" ........................... **
    "Box" ................................ **
    "BoxInterleaved" ..................... **
    "Suzanne" ............................ *
    "SciFiHelmet" ........................ *

![](https://github.com/AODQ/gltf/blob/master/media/suzeanneworking.gif)
