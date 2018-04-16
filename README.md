# GL Transmission Format (glTF2) for D

glTF2 is a specification by Khronos for transmitting and loading 3D scenes and
models for applications. Read more: https://github.com/KhronosGroup/glTF

The major benefit is that it allows for scenes and models to be used seamlessly
throughout multiple applications, mitigating the use for what was once a task
for in-house libraries.

This is planned to be a complete implementation of the glTF2 specification,
with support for all future Khronos extensions. This repository is the core
glTF2 implementation, which includes features such as:
  glTF2 validation
  Loading of glTF, binary and embedded formats
  A simple layer on top of JSON, replacing array indices with pointers

The idea is to give a core glTF2 implemention in which graphics APIs may be
built on top of. Right now, the OpenGL glTF2 (gltf2opengl) loader is in
development, loading all the glTF2 data using OpenGL3.3. There is also the
OpenGL glTF2 Viewer (gltf2openglviewer) which can be used to view glTF2 models
and scenes with a GUI using GLFW/OpenGL. There is also planned the Vulkan glTF2
(gltf2vulkan) loader and viewer (gltf2vulkanviewer), along with an experimental
global illumination viewer (gltf2giviewer).


                                      -> OpenGL (GL_glTF2)--> OpenGL Apps (OpenGLViewer)
                                     /
(json file) -> (JSON_glTF) -> (glTF2) -> Vulkan (VK_glTF2)--> Vulkan Apps (VulkanViewer)
                                     \
                                      -> etc (API_glTF2)----> other API apps

The goal right now is to load & view all glTF2 sample models in OpenGL from
  https://github.com/KhronosGroup/glTF-Sample-Models/tree/master/2.0/

The following is a list of working models with an implementation quality from *
  to *** when compared to their reference screenshot:


  "Triangle Without Indices" ........... **
  "Triangle" ........................... **
  "Box" ................................ *
  "Suzanne" ............................ *
  "SciFiHelmet" ........................ *