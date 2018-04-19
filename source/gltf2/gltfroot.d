module gltf2.gltfroot;
import gltf2.jsonloader, gltf2.gltfroot;
import std.string;

class glTFRootObject(string api,
            API_glTFConstructor,
            API_glTFAccessor,
            API_glTFAnimation,
            API_glTFBuffer,
            API_glTFBufferView,
            API_glTFImage,
            API_glTFMaterial,
            API_glTFMesh,
            API_glTFNode,
            API_glTFSampler,
            API_glTFScene,
            API_glTFSkin,
            API_glTFTexture) {
  struct RootSubObj(string type) {
    mixin("glTF%s          gltf_data;".format(type));
    mixin("API_glTF%s      %s_data;"  .format(type, api));
  }
  RootSubObj!"Accessor"   [] accessors;
  RootSubObj!"Animation"  [] animations;
  RootSubObj!"Buffer"     [] buffers;
  RootSubObj!"BufferView" [] bufferViews;
  RootSubObj!"Image"      [] images;
  RootSubObj!"Material"   [] materials;
  RootSubObj!"Mesh"       [] meshs;
  RootSubObj!"Node"       [] nodes;
  RootSubObj!"Sampler"    [] samplers;
  RootSubObj!"Scene"      [] scenes;
  RootSubObj!"Skin"       [] skins;
  RootSubObj!"Texture"    [] textures;

  string base_path;


  private void Fill_Buffer(string mem, T, U)(ref T[] to, ref U[] from) {
    import std.range, std.algorithm;
    iota(0, from.length).each!((i) {
    });
  }

  private void Apply_Fill(string u, T)(ref T asset) {
    Fill_Buff!u(accessors,    json_asset.accessors);
    Fill_Buff!u(animations,   json_asset.animations);
    Fill_Buff!u(buffers,      json_asset.buffers);
    Fill_Buff!u(buffer_views, json_asset.bufferViews);
    Fill_Buff!u(images,       json_asset.images);
    Fill_Buff!u(materials,    json_asset.materials);
    Fill_Buff!u(meshes,       json_asset.meshes);
    Fill_Buff!u(nodes,        json_asset.nodes);
    Fill_Buff!u(samplers,     json_asset.samplers);
    Fill_Buff!u(scenes,       json_asset.scenes);
    Fill_Buff!u(skins,        json_asset.skins);
    Fill_Buff!u(textures,     json_asset.textures);
  }

  void Load_JSON_File ( string filename ) {
    import std.path : dirname;
    // -- load file
    path = filename.dirName ~ "/";
    JSON_glTFConstructor json_asset = glTF_Load_JSON_File(filename);

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

    // -- fill buffer with json, glTF and then API
    Apply_Fill!"json"(json_asset);
    Apply_Fill!"glTF"(glTFObject(this));
    Apply_Fill!api(API_glTFConstructor(this));
  }
}
