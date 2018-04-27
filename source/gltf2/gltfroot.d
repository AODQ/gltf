module gltf2.gltfroot;
import gltf2.gltfbase, gltf2.jsonloader, gltf2.gltfroot;
import std.string;
import std.traits;

struct glTFSubrootObj(string api, glTFType, API_glTFType) {
  glTFType gltf;
  mixin(q{API_glTFType %s;}.format(api));
  mixin(q{private alias api_data = %s;}.format(api));
}

private immutable string[] glTF_Subroot_obj_list = [
  "Accessor", "Animation", "Buffer", "BufferView", "Image",
  "Material", "Mesh", "Node", "Sampler", "Scene", "Skin", "Texture"
];

private template glTFSubrootAliasesConstructor(string api, APIType) {
  static foreach ( mem; glTF_Subroot_obj_list )
    mixin(q{ static alias Subroot%s = glTFSubrootObj!(api, glTF%s, APIType.%s);}
          .format(mem, mem, mem));
}

class glTFRootObj(string api, APIType) {

  // construct subroot gltf aliases
  mixin glTFSubrootAliasesConstructor!(api, APIType);

  SubrootAccessor   [] accessors;
  SubrootAnimation  [] animations;
  SubrootBuffer     [] buffers;
  SubrootBufferView [] buffer_views;
  SubrootImage      [] images;
  SubrootMaterial   [] materials;
  SubrootMesh       [] meshes;
  SubrootNode       [] nodes;
  SubrootSampler    [] samplers;
  SubrootScene      [] scenes;
  SubrootSkin       [] skins;
  SubrootTexture    [] textures;

  string base_path;

  this ( string filename ) {
    import std.path : dirName;
    // -- load file
    base_path = filename.dirName ~ "/";
    JSON_glTFConstruct json_asset = JSON_glTFConstruct.Construct(filename);

    // -- set buffers
    accessors.length    = json_asset.accessors.length;
    animations.length   = json_asset.animations.length;
    buffers.length      = json_asset.buffers.length;
    buffer_views.length = json_asset.bufferViews.length;
    images.length       = json_asset.images.length;
    materials.length    = json_asset.materials.length;
    meshes.length       = json_asset.meshes.length;
    nodes.length        = json_asset.nodes.length;
    samplers.length     = json_asset.samplers.length;
    scenes.length       = json_asset.scenes.length;
    skins.length        = json_asset.skins.length;
    textures.length     = json_asset.textures.length;
    import std.stdio;
    writeln("TEXTURES: ", textures);

    // -- fill buffer with glTF data
    void Fill_glTFSubbuffers(T...)(ref T tuple) {
      static foreach ( buff; tuple ) {
        foreach ( it, ref mem; buff )
          mem.gltf = typeof(mem.gltf)(cast(uint)it, this, json_asset);
      }
    }

    Fill_glTFSubbuffers(accessors, animations, buffers, buffer_views, images,
                        materials, meshes, nodes, samplers, scenes, skins,
                        textures);
    json_asset.destroy();

    // // -- fill buffer with API data (order matters)
    void Fill_APISubbuffers(T...)(ref T tuple) {
      import std.stdio;
      static foreach ( buff; tuple ) {
        writeln("Fill subbuffer: ", typeof(buff[0].api_data).stringof);
        foreach ( it, ref mem; buff )
          mem.api_data = typeof(mem.api_data)(cast(uint)it, this);
      }
    }
    Fill_APISubbuffers(textures, materials, buffers, buffer_views, accessors,
                       animations, images, meshes, nodes, samplers, scenes,
                       skins);
    // --
  }
}

unittest {
  import std.stdio;
  struct API {
    alias ROBJ = glTFRootObj!("vk", API);
    struct Accessor   { this(uint it, ROBJ obj) {} }
    struct Animation  { this(uint it, ROBJ obj) {} }
    struct Buffer     { this(uint it, ROBJ obj) {} }
    struct BufferView { this(uint it, ROBJ obj) {} }
    struct Image      { this(uint it, ROBJ obj) {} }
    struct Material   { this(uint it, ROBJ obj) {} }
    struct Mesh       { this(uint it, ROBJ obj) {} }
    struct Node       { this(uint it, ROBJ obj) {} }
    struct Sampler    { this(uint it, ROBJ obj) {} }
    struct Scene      { this(uint it, ROBJ obj) {} }
    struct Skin       { this(uint it, ROBJ obj) {} }
    struct Texture    { this(uint it, ROBJ obj) {} }
  }
  API.ROBJ base;
}
