module gltf2.jsonloader;
import gltf2.jsonx;
public import gltf2.jsonx : JsonValue;
import std.array, std.string, std.file : exists;
import std.traits;
import std.variant;

private template JSON_glTFTemplate ( bool Has_name = true ) {
  static if ( Has_name ) string name;
  JsonValue extensions, extras;
  private alias Type = typeof(this);

  void Check_Required ( ) {}
}

// ----- glTF (root object) ----------------------------------------------------
class JSON_glTFConstruct {
  mixin JSON_glTFTemplate!false;
  string[] extensionsUsed, extensionsRequired;
  uint scene;
  JSON_glTFAssetInfo asset;
  JSON_glTFAccessorInfo   []   accessors;
  JSON_glTFAnimationInfo  []  animations;
  JSON_glTFBufferInfo     []     buffers;
  JSON_glTFBufferViewInfo [] bufferViews;
  JSON_glTFCameraInfo     []     cameras;
  JSON_glTFImageInfo      []      images;
  JSON_glTFMaterialInfo   []   materials;
  JSON_glTFMeshInfo       []      meshes;
  JSON_glTFNodeInfo       []       nodes;
  JSON_glTFSamplerInfo    []    samplers;
  JSON_glTFSceneInfo      []      scenes;
  JSON_glTFSkinInfo       []       skins;
  JSON_glTFTextureInfo    []    textures;

  auto RPointer(T:JSON_glTFAccessorInfo  )(uint i){return &accessors[i];}
  auto RPointer(T:JSON_glTFAnimationInfo )(uint i){return &animations[i];}
  auto RPointer(T:JSON_glTFBufferInfo    )(uint i){return &buffers[i];}
  auto RPointer(T:JSON_glTFBufferViewInfo)(uint i){return &bufferViews[i];}
  auto RPointer(T:JSON_glTFCameraInfo    )(uint i){return &cameras[i];}
  auto RPointer(T:JSON_glTFImageInfo     )(uint i){return &images[i];}
  auto RPointer(T:JSON_glTFMaterialInfo  )(uint i){return &materials[i];}
  auto RPointer(T:JSON_glTFMeshInfo      )(uint i){return &meshes[i];}
  auto RPointer(T:JSON_glTFNodeInfo      )(uint i){return &nodes[i];}
  auto RPointer(T:JSON_glTFSamplerInfo   )(uint i){return &samplers[i];}
  auto RPointer(T:JSON_glTFSceneInfo     )(uint i){return &scenes[i];}
  auto RPointer(T:JSON_glTFSkinInfo      )(uint i){return &skins[i];}
  auto RPointer(T:JSON_glTFTextureInfo   )(uint i){return &textures[i];}

  static enum HasBufferType(T) = __traits(compiles, RPointer!T(0));

  static JSON_glTFConstruct Construct ( string filename ) {
    import std.string, std.conv, std.file;
    return jsonDecode!JSON_glTFConstruct(filename.read.to!string.strip);
  }
};

// ----- accessor --------------------------------------------------------------
struct JSON_glTFSparseAccessorIndexInfo {
  mixin JSON_glTFTemplate!false;
  uint bufferView = -1;
  uint byteOffset = 0, componentType = -1;
}
struct JSON_glTFSparseAccessorValueInfo {
  mixin JSON_glTFTemplate!false;
  uint bufferView = -1;
  uint byteOffset = 0;
}
struct JSON_glTFSparseAccessorInfo {
  mixin JSON_glTFTemplate!false;
  uint count = -1;
  JSON_glTFSparseAccessorIndexInfo indices;
  JSON_glTFSparseAccessorValueInfo values;
}
struct JSON_glTFAccessorInfo {
  mixin JSON_glTFTemplate;
  uint count = -1, componentType = -1;
  string type = "";
  uint bufferView, byteOffset = 0;
  bool normalized = false;
  Variant[] max, min;
  JSON_glTFSparseAccessorInfo sparse;
}

// ----- animation -------------------------------------------------------------
struct JSON_glTFAnimationChannelTargetInfo {
  mixin JSON_glTFTemplate!false;
  uint node;
  string path = "";
}
struct JSON_glTFAnimationChannelInfo {
  mixin JSON_glTFTemplate!false;
  JSON_glTFAnimationChannelTargetInfo target;
  uint sampler = -1;
}
struct JSON_glTFAnimationSamplerInfo {
  mixin JSON_glTFTemplate!false;
  uint input = -1, output = -1;
  string interpolation = "LINEAR";
}
struct JSON_glTFAnimationInfo {
  mixin JSON_glTFTemplate;
  JSON_glTFAnimationChannelInfo[] channels;
  JSON_glTFAnimationSamplerInfo[] samplers;
}

// ----- asset -----------------------------------------------------------------
struct JSON_glTFAssetInfo {
  mixin JSON_glTFTemplate!false;
  string _version = "",
         minVersion,
         generator,
         copyright;
}

// ----- buffer ----------------------------------------------------------------
struct JSON_glTFBufferInfo {
  mixin JSON_glTFTemplate;
  string uri;
  uint byteLength = -1;
}
struct JSON_glTFBufferViewInfo {
  mixin JSON_glTFTemplate;
  uint buffer = -1,
       byteLength = -1,
       byteOffset = 0,
       byteStride,
       target = 34962;
}

// ----- camera ----------------------------------------------------------------
struct JSON_glTFCameraProjectionPerspectiveInfo {
  mixin JSON_glTFTemplate!false;
  float aspectRatio = 1.0f, yfov    = float.nan,
        zfar        = 100.0f, znear = float.nan;
}
struct JSON_glTFCameraProjectionOrthographicInfo {
  mixin JSON_glTFTemplate!false;
  float xmag = float.nan, ymag  = float.nan,
        zfar = float.nan, znear = float.nan;
}
struct JSON_glTFCameraInfo {
  mixin JSON_glTFTemplate;
  JSON_glTFCameraProjectionPerspectiveInfo perspective;
  JSON_glTFCameraProjectionOrthographicInfo orthographic;
  string type = "";
}

// ----- image -----------------------------------------------------------------
struct JSON_glTFImageInfo {
  mixin JSON_glTFTemplate;
  string uri, mimeType;
  uint bufferView;
}

// ----- material --------------------------------------------------------------
struct JSON_glTFMaterialTextureInfo {
  mixin JSON_glTFTemplate!false;
  uint index = -1, texCoord = 0;

  bool Exists ( ) { return index != -1; }
}
struct JSON_glTFMaterialPBRMetallicRoughnessInfo {
  mixin JSON_glTFTemplate!false;
  float[] baseColorFactor = []; // TODO; better check if this exists
  JSON_glTFMaterialTextureInfo baseColorTexture;
  JSON_glTFMaterialTextureInfo metallicRoughnessTexture;
  float metallicFactor = 1.0f, roughnessFactor = 1.0f;

  bool Exists ( ) {
    return baseColorFactor.length != 0 ||
           baseColorTexture.Exists;
  }

  bool Has_Base_Colour_Texture ( ) { return baseColorTexture.index != -1; }
}
struct JSON_glTFMaterialNormalTextureInfo {
  mixin JSON_glTFTemplate!false;
  uint index = -1, texCoord = 0;
  float scale = 1.0f;
}
struct JSON_glTFMaterialOcclusionTextureInfo {
  mixin JSON_glTFTemplate!false;
  uint index = -1, texCoord = 0;
  float strength = 1.0f;
}
struct JSON_glTFMaterialEmissiveTextureInfo {
  mixin JSON_glTFTemplate!false;
  uint index = -1, texCoord = 0;
  float intensity = 1.0f;
}
struct JSON_glTFMaterialInfo {
  mixin JSON_glTFTemplate;
  JSON_glTFMaterialPBRMetallicRoughnessInfo pbrMetallicRoughness;
  JSON_glTFMaterialTextureInfo normalTexture, occlusionTexture, emissiveTexure;
  float[] emissiveFactor = [0.0f, 0.0f, 0.0f];
  string alphaMode = "OPAQUE";
  float alphaCutoff = 0.5f;
  bool doubleSided = false;
}

// ----- mesh ------------------------------------------------------------------
struct JSON_glTFMeshPrimitiveTypeInfo {
  uint POSITION = -1, NORMAL = -1, TANGENT = -1;
  uint TEXCOORD_0 = -1, TEXCOORD_1 = -1;
  uint COLOR_0    = -1, COLOR_1    = -1;
  uint JOINTS_0   = -1, JOINTS_1   = -1;
  uint WEIGHTS_0  = -1, WEIGHTS_1  = -1;
}
struct JSON_glTFMeshPrimitiveInfo {
  mixin JSON_glTFTemplate!false;
  @("required") JSON_glTFMeshPrimitiveTypeInfo attributes;
  JSON_glTFMeshPrimitiveTypeInfo[] targets;
  uint mode = 4;
  uint indices = -1, material = -1;
  bool Has_Material ( ) { return material != -1; }
}
struct JSON_glTFMeshInfo {
  mixin JSON_glTFTemplate;
  @("required") JSON_glTFMeshPrimitiveInfo[] primitives;
  float[] weights = [];
}

// ----- node ------------------------------------------------------------------
struct JSON_glTFNodeInfo {
  mixin JSON_glTFTemplate;
  uint[] children;
  uint skin = -1, mesh = -1, camera = -1;
  float[] rotation    = [0f, 0f, 0f, 1f],
          scale       = [1f, 1f, 1f],
          translation = [0f, 0f, 0f];
  float[] matrix = []; // non-standard hack for now
  uint[] weights;
}

// ----- sampler ---------------------------------------------------------------
struct JSON_glTFSamplerInfo {
  mixin JSON_glTFTemplate;
  uint magFilter = 9729,  minFilter = 9729,
       wrapS     = 10497, wrapT     = 10497;
}

// ----- scene -----------------------------------------------------------------
struct JSON_glTFSceneInfo {
  mixin JSON_glTFTemplate;
  uint[] nodes;
}

// ----- skin ------------------------------------------------------------------
struct JSON_glTFSkinInfo {
  mixin JSON_glTFTemplate;
  uint[] joints;
  uint inverseBindMatrices, skeleton;
}

// ----- texture ---------------------------------------------------------------
struct JSON_glTFTextureInfo {
  mixin JSON_glTFTemplate;
  uint sampler = -1, source;
  bool Has_Sampler ( ) { return sampler != -1; }
}
