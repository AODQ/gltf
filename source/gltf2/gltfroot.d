module gltf2.gltfroot;
import gltf2.gltfbase, gltf2.jsonloader, gltf2.gltfroot;
import std.string;
import std.traits;

struct glTFSubrootObj(string mem, string api, RootObj, glTFType, API_glTFType) {
  glTFType gltf;
  mixin(q{API_glTFType %s;}.format(api));
  mixin(q{private alias api_data = %s;}.format(api));
  RootObj root;

  static if ( mem == "Scene" )
  RootObj.SubrootNode* RCamera_Node ( ) {
    foreach ( node; gltf.nodes ) {
      auto ncam = root.nodes[node].RCamera_Node;
      if ( ncam !is null ) return ncam;
    }
    return null;
  }

  static if ( mem == "Node" )
  RootObj.SubrootNode* RCamera_Node ( ) {
    if ( gltf.Has_Camera ) return &this;
    foreach ( ch; gltf.children ) {
      auto ncam = root.nodes[ch].RCamera_Node;
      if ( ncam !is null ) return ncam;
    }
    return null;
  }

  static if ( mem == "Node" ) {
    uint node_parent = -1;
    bool Has_Node_Parent ( ) { return node_parent != -1; }
  }

  auto opDispatch(string func, T...)(T params) {
    static if ( hasMember!(API_glTFType, func) )
      mixin(q{ return api_data.%s(root, params); }.format(func));
  }

  static if ( mem == "Node" )
  RootObj.SubrootCamera* RCamera ( ) {
    if ( !gltf.Has_Camera ) return null;
    return &root.cameras[gltf.camera];
  }
}

private immutable string[] glTF_Subroot_obj_list = [
  "Accessor", "Animation", "Buffer", "BufferView", "Camera", "Image",
  "Material", "Mesh", "Node", "Sampler", "Scene", "Skin", "Texture"
];

private template glTFSubrootAliasesConstructor(string api, Root, APIT) {
  static foreach ( mem; glTF_Subroot_obj_list )
    mixin(q{
      static alias Subroot%s = glTFSubrootObj!(mem, api, Root, glTF%s, APIT.%s);
    }.format(mem, mem, mem));
}

class glTFRootObj(string api, APIType) {

  // construct subroot gltf aliases
  mixin glTFSubrootAliasesConstructor!(api, typeof(this), APIType);

  SubrootAccessor   [] accessors;
  SubrootAnimation  [] animations;
  SubrootBuffer     [] buffers;
  SubrootBufferView [] buffer_views;
  SubrootCamera     [] cameras;
  SubrootImage      [] images;
  SubrootMaterial   [] materials;
  SubrootMesh       [] meshes;
  SubrootNode       [] nodes;
  SubrootSampler    [] samplers;
  SubrootScene      [] scenes;
  SubrootSkin       [] skins;
  SubrootTexture    [] textures;

  immutable string base_path;

  private immutable uint Default_scene = -1;
  SubrootScene* RDefault_Scene ( ) {
    if ( Default_scene == -1 ) return null;
    return &scenes[Default_scene];
  }

  this ( string filename ) {
    import std.path : dirName;
    // -- load file
    base_path = filename.dirName ~ "/";
    JSON_glTFConstruct json_asset = JSON_glTFConstruct.Construct(filename);

    // -- set consts
    Default_scene = json_asset.scene;

    // -- set buffers
    accessors.length    = json_asset.accessors.length;
    animations.length   = json_asset.animations.length;
    buffers.length      = json_asset.buffers.length;
    buffer_views.length = json_asset.bufferViews.length;
    cameras.length      = json_asset.cameras.length;
    images.length       = json_asset.images.length;
    materials.length    = json_asset.materials.length;
    meshes.length       = json_asset.meshes.length;
    nodes.length        = json_asset.nodes.length;
    samplers.length     = json_asset.samplers.length;
    scenes.length       = json_asset.scenes.length;
    skins.length        = json_asset.skins.length;
    textures.length     = json_asset.textures.length;

    // -- fill buffer with glTF data & refs to me
    void Fill_glTFSubbuffers(T...)(ref T tuple) {
      static foreach ( buff; tuple ) {
        foreach ( it, ref mem; buff ) {
          mem.gltf = typeof(mem.gltf)(cast(uint)it, this, json_asset);
          mem.root = this;
        }
      }
    }

    Fill_glTFSubbuffers(accessors, animations, buffers, buffer_views, cameras,
                        images, materials, meshes, nodes, samplers, scenes,
                        skins, textures);
    json_asset.destroy();

    // -- apply parents (API might need this)
    foreach ( it, ref node; nodes ) {
      foreach ( ref ch; node.gltf.children ) {
        nodes[ch].node_parent = cast(uint)it;
      }
    }

    // -- fill buffer with API data (order matters)
    void Fill_APISubbuffers(T...)(ref T tuple) {
      import std.stdio;
      static foreach ( buff; tuple ) {
        foreach ( it, ref mem; buff )
          mem.api_data = typeof(mem.api_data)(cast(uint)it, this);
      }
    }
    Fill_APISubbuffers(textures, materials, buffers, buffer_views, accessors,
                       animations, images, meshes, nodes, samplers, scenes,
                       skins, cameras);
  }

  void Update_Animation ( float delta ) {
    foreach ( ani; animations ) ani.gltf.Update(this, delta);
    foreach ( node; nodes ) node.gltf.Update(this);
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
    struct Cameras    { this(uint it, ROBJ obj) {} }
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
