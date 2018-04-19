module gltf2.gltfbase;
import gltf2.jsonloader;
import std.array;
import std.algorithm;
import std.exception;
import std.algorithm, std.range;
import std.file : exists;
import std.stdio;
import std.variant;
import std.string;
import std.traits;
import std.conv;

private alias JSONFile = JSON_glTFFileInfo;

// ----- enum ------------------------------------------------------------------
private T To_glTFEnum(T)(ulong mem) {
  import std.traits;
  Enforce_glTF(EnumMembers!T.only.canFind(mem),
         "Value '%s' not a valid %s".format(mem, T.stringof));
  return cast(T)mem;
}
enum glTFAssetType { Scene, Library };
enum glTFAttribute { Index, Normal, Position, TexCoord0 = 10, Colour0 = 20 };
enum glTFMode { Points = 0, Lines = 1, LineLoop = 2, LineStrip = 3,
                Triangles = 4, TriangleStrip = 5, TriangleFan = 6 };
auto glTFMode_Info ( glTFMode mode ) {
  struct Info { string name; }
  return Info(mode.to!string);
}
enum glTFType { Scalar, Vec2, Vec3, Vec4, Mat2, Mat3, Mat4 };
auto glTFType_Info ( glTFType type ) {
  immutable int[glTFType] To_Info = [
    glTFType.Scalar: 1, glTFType.Vec2: 2, glTFType.Vec3: 3, glTFType.Vec4: 4,
    glTFType.Mat2:   4, glTFType.Mat3: 9, glTFType.Mat4: 16
  ];
  struct Info { string label; uint count; }
  return Info(type.to!string, To_Info[type]);
}
glTFType To_glTFType ( string u ) {
  switch ( u ) with ( glTFType ) {
    default: assert(false, "String '%s' not a valid type".format(u));
    case "SCALAR": return Scalar; case "VEC2": return Vec2;
    case "VEC3": return Vec3; case "VEC4": return Vec4;
    case "MAT2": return Mat2; case "MAT3": return Mat3;
    case "MAT4": return Mat4;
  }
}

enum glTFFilterType {
  Nearest = 9728, Linear = 9729,
  NearestMipmapNearest = 9984,
  LinearMipmapNearest = 9985,
  NearestMipmapLinear = 9986,
  LinearMipmapLinear = 9987
}
enum glTFWrapType {
  ClampToEdge = 33071,
  MirroredRepeat = 33648,
  Repeat = 10497
}
enum glTFComponentType {
  Byte=5120, Ubyte=5121, Short=5122, Ushort=5123, Int=5124, Uint=5125,
  Float=5126
};
alias Scalar_To_glTFComponentType = To_glTFEnum!(glTFComponentType);
auto glTFComponentType_Info ( glTFComponentType type ) {
  struct Info { string name; uint label; uint size; }
  final switch ( type ) with ( glTFComponentType ) {
    case Byte:   return Info("Byte",   5120, 1);
    case Ubyte:  return Info("Ubyte",  5121, 1);
    case Short:  return Info("Short",  5122, 2);
    case Ushort: return Info("Ushort", 5123, 2);
    case Int:    return Info("Int",    5124, 4);
    case Uint:   return Info("Uint",   5125, 4);
    case Float:  return Info("Float",  5126, 4);
  }
}

enum glTFBufferViewTarget {
  NonGPU = 0,
  Array = 34962,
  ElementArray = 34963
};
alias Scalar_To_glTFBufferViewTarget = To_glTFEnum!(glTFBufferViewTarget);

// ----- templates -------------------------------------------------------------
private template glTFTemplate ( JSON_Base ) {
  static immutable bool Has_name = __traits(hasMember, JSON_Base, "name");
  static if ( Has_name ) string name;
  JsonValue extensions, extras;
  JSON_Base json_info;
  uint buffer_index;
  private alias Type = typeof(this);

  void Template_Construct ( uint _buffer_index, ref JSON_Base t ) {
    json_info = t;
    buffer_index = _buffer_index;
    static if ( Has_name ) name = t.name;
    extensions = t.extensions;
    extras = t.extras;
  }
}


// ----- glTF (root object) ----------------------------------------------------
class glTFObject {
  // no json info
  string repository;
  string[] extensions_used, extensions_required;
  uint scene;

  glTFAsset                asset;
  glTFAccessor   []    accessors;
  glTFAnimation  []   animations;
  glTFBuffer     []      buffers;
  glTFBufferView [] buffer_views;
  glTFImage      []       images;
  glTFMaterial   []    materials;
  glTFMesh       []       meshes;
  glTFNode       []        nodes;
  glTFSampler    []     samplers;
  glTFScene      []       scenes;
  glTFSkin       []        skins;
  glTFTexture    []     textures;

  private void Fill_Buff(T, U)(ref T[] buff, ref U[] js) {
    iota(0, js.length).each!((i) { buff[i] = T(cast(uint)i, this, js[i]); });
  }

  this ( string _repository, JSON_glTFFileInfo info ) {
    // load asset/misc info
    repository = _repository;
    extensions_used = info.extensionsUsed;
    extensions_required = info.extensionsRequired;
    asset = glTFAsset(this, info.asset);

    // set buffer lengths
    accessors.length    = info.accessors.length;
    animations.length   = info.animations.length;
    buffers.length      = info.buffers.length;
    buffer_views.length = info.bufferViews.length;
    images.length       = info.images.length;
    materials.length    = info.materials.length;
    meshes.length       = info.meshes.length;
    nodes.length        = info.nodes.length;
    samplers.length     = info.samplers.length;
    scenes.length       = info.scenes.length;
    skins.length        = info.skins.length;
    textures.length     = info.textures.length;

    // create glTF buffers from JSON data
    Fill_Buff(accessors,    info.accessors);
    Fill_Buff(animations,   info.animations);
    Fill_Buff(buffers,      info.buffers);
    Fill_Buff(buffer_views, info.bufferViews);
    Fill_Buff(images,       info.images);
    Fill_Buff(materials,    info.materials);
    Fill_Buff(meshes,       info.meshes);
    Fill_Buff(nodes,        info.nodes);
    Fill_Buff(samplers,     info.samplers);
    Fill_Buff(scenes,       info.scenes);
    Fill_Buff(skins,        info.skins);
    Fill_Buff(textures,     info.textures);
  }
}

// ----- accessor --------------------------------------------------------------
struct glTFAccessor {
  mixin glTFTemplate!JSON_glTFAccessorInfo;
  glTFBufferView* buffer_view;
  uint count, offset;
  glTFType type;
  glTFComponentType component_type;
  JsonValue max, min;

  this ( uint idx, glTFObject data, ref JSON_glTFAccessorInfo acc_info ) {
    Template_Construct(idx, acc_info);
    count = acc_info.count;
    offset = acc_info.byteOffset;
    type = To_glTFType(acc_info.type);
    component_type = Scalar_To_glTFComponentType(acc_info.componentType);
    buffer_view = &data.buffer_views[acc_info.bufferView];
    max = acc_info.max;
    min = acc_info.min;
  }
}

// ----- animation -------------------------------------------------------------
struct glTFAnimation {
  mixin glTFTemplate!JSON_glTFAnimationInfo;
  this ( uint idx, glTFObject data, ref JSON_glTFAnimationInfo ani_info ) {
    Template_Construct(idx, ani_info);
  }
}

// ----- asset -----------------------------------------------------------------
struct glTFAsset {
  mixin glTFTemplate!JSON_glTFAssetInfo;
  this ( glTFObject data, ref JSON_glTFAssetInfo ass_info ) {
    Template_Construct(0, ass_info);
  }
}

// ----- buffer ----------------------------------------------------------------
struct glTFBuffer {
  mixin glTFTemplate!JSON_glTFBufferInfo;
  uint length;
  ubyte[] raw_data;

  this ( uint idx, glTFObject obj, ref JSON_glTFBufferInfo buf_info ) {
    Template_Construct(idx, buf_info);
    import std.file : read;
    length = buf_info.byteLength;
    // TODO: variant for when uri is not a file
    raw_data = cast(ubyte[])read(obj.repository ~ buf_info.uri);
    Enforce_glTF(raw_data.length == length, "Buffer length mismatch");
  }
}
struct glTFBufferView {
  mixin glTFTemplate!JSON_glTFBufferViewInfo;
  glTFBuffer* buffer;
  glTFBufferViewTarget target;
  uint offset, length, stride;

  this ( uint idx, glTFObject data, ref JSON_glTFBufferViewInfo buf_info ) {
    Template_Construct(idx, buf_info);
    buffer = &data.buffers[buf_info.buffer];
    offset = buf_info.byteOffset;
    length = buf_info.byteLength;
    stride = buf_info.byteStride;
    target = Scalar_To_glTFBufferViewTarget(buf_info.target);
  }
}

// ----- camera ----------------------------------------------------------------
struct glTFCamera {
  mixin glTFTemplate!JSON_glTFCameraInfo;

  this ( uint idx, glTFObject data, ref JSON_glTFCameraInfo cam_info ) {
    Template_Construct(idx, cam_info);
  }
}

// ----- image -----------------------------------------------------------------
struct glTFImage {
  mixin glTFTemplate!JSON_glTFImageInfo;
  ubyte[] raw_data; // RGBA
  uint width, height;

  int NPOT ( uint w ) {
    -- w;
    w |= w >> 1;
    w |= w >> 2;
    w |= w >> 4;
    w |= w >> 8;
    w |= w >> 16;
    return w + 1;
  }

  this ( uint idx, glTFObject data, ref JSON_glTFImageInfo info ) {
    Template_Construct(idx, info);
    import imageformats;
    auto img = read_image(data.repository ~ info.uri);
    raw_data = img.pixels;
    width = img.w; height = img.h;

    // check if have to scale to power of 2
    uint nwidth = width, nheight = height;
    if ( (nwidth&(nwidth-1)) != 0 ) nwidth = NPOT(nwidth);
    if ( (nheight&(nheight-1)) != 0 ) nheight = NPOT(nheight);
    if ( nwidth == width && nheight == height ) return; // not necessary
    ubyte[] ndata;
    ndata.length = nwidth*nheight*4;

    bool has_alpha = img.c == ColFmt.RGBA;
    uint offset = has_alpha ? 4 : 3;

    // copy data over using lerp
    foreach ( i; 0 .. nwidth )
    foreach ( j; 0 .. nheight ) {
      float wlerp = i/cast(float)nwidth,
            hlerp = j/cast(float)nheight;
      int W = cast(int)(wlerp*width), H = cast(int)(hlerp*height);
      uint nidx = (i+j*nwidth)*4, ridx = (W+H*width)*offset;
      ndata[nidx .. nidx+3] = raw_data[ridx .. ridx+3];
      if ( has_alpha ) ndata[nidx+3] = raw_data[ridx+3];
      else             ndata[nidx+3] = 255;
    }


    width = nwidth; height = nheight;
    raw_data = ndata;
  }
}

// ----- material --------------------------------------------------------------
struct glTFMaterialTexture {
  mixin glTFTemplate!JSON_glTFMaterialTextureInfo;
  glTFTexture* texture;

  this ( glTFObject obj, ref JSON_glTFMaterialTextureInfo mat_info ) {
    Template_Construct(0, mat_info);
    texture = &obj.textures[mat_info.index];
  }

  bool Exists ( ) { return texture !is null; }
}
struct glTFMaterialPBRMetallicRoughness {
  float[] colour_factor;
  float metallic_factor, roughness_factor;
  glTFMaterialTexture base_colour_texture;

  bool Has_Base_Colour_Texture ( ) {
    return base_colour_texture.Exists;
  }

  this ( glTFObject obj, JSON_glTFMaterialPBRMetallicRoughnessInfo info ) {
    writeln(info.baseColorFactor);
    colour_factor = info.baseColorFactor;
    metallic_factor = info.metallicFactor;
    roughness_factor = info.roughnessFactor;
    if ( info.baseColorTexture.Exists )
      base_colour_texture = glTFMaterialTexture(obj, info.baseColorTexture);
  }
}
struct glTFMaterialNil { }
struct glTFMaterial {
  mixin glTFTemplate!JSON_glTFMaterialInfo;
  Algebraic!(glTFMaterialPBRMetallicRoughness, glTFMaterialNil) material;

  this ( uint idx, glTFObject obj, ref JSON_glTFMaterialInfo info ) {
    Template_Construct(idx, info);
    material = glTFMaterialNil();
    if ( info.pbrMetallicRoughness.Exists ) {
      material = glTFMaterialPBRMetallicRoughness(obj,
                             info.pbrMetallicRoughness);
    }
  }
}

// ----- mesh ------------------------------------------------------------------
struct glTFPrimitive {
  mixin glTFTemplate!JSON_glTFMeshPrimitiveInfo;
  private glTFAccessor*[glTFAttribute] accessors;
  glTFMaterial* material;
  glTFMode mode;

  private void Set_Accessor(glTFObject data, glTFAttribute atr, int idx) {
    accessors[atr] = idx != -1 ? &data.accessors[idx] : null;
  }

  bool Has_Index ( ) {
    return accessors[glTFAttribute.Index] !is null;
  }
  glTFAccessor* RAccessor ( glTFAttribute atr ) {
    return accessors[atr];
  }

  this ( uint idx, glTFObject data, JSON_glTFMeshPrimitiveInfo pri_info ) {
    Template_Construct(idx, pri_info);
    auto atr = &pri_info.attributes;
    Set_Accessor(data, glTFAttribute.Index, pri_info.indices);
    Set_Accessor(data, glTFAttribute.Position, atr.POSITION);
    Set_Accessor(data, glTFAttribute.Normal, atr.NORMAL);
    Set_Accessor(data, glTFAttribute.TexCoord0, atr.TEXCOORD_0);
    Set_Accessor(data, glTFAttribute.Colour0, atr.COLOR_0);
    mode = cast(glTFMode)pri_info.mode;
    if ( pri_info.Has_Material ) material = &data.materials[pri_info.material];
  }
}
struct glTFMesh {
  mixin glTFTemplate!JSON_glTFMeshInfo;
  glTFPrimitive[] primitives;
  float[] weights;

  this ( uint idx, glTFObject obj, ref JSON_glTFMeshInfo msh_info ) {
    Template_Construct(idx, msh_info);
    name = msh_info.name;
    weights = msh_info.weights;
    // fill primitives
    foreach ( iter, p; msh_info.primitives )
      primitives ~= glTFPrimitive(cast(uint)iter, obj, p);
  }
}

// ----- node ------------------------------------------------------------------
struct glTFNode {
  mixin glTFTemplate!JSON_glTFNodeInfo;
  glTFNode*[] children;
  glTFMesh* mesh;
  float[] matrix;

  bool Has_Transformation_Matrix() { return !matrix.empty(); }
  bool Has_Mesh() { return mesh !is null; }
  glTFMesh* RMesh() { return mesh; }

  void Enforce(bool cond, string err) {
    if ( !cond ) throw new Exception("Node '%s' %s".format(name, err));
  }

  this ( uint idx, glTFObject obj, ref JSON_glTFNodeInfo node_info ) {
    Template_Construct(idx, node_info);
    name = node_info.name;
    children = node_info.children.map!(i => &obj.nodes[i]).array;
    if ( node_info.mesh != -1 ) mesh = &obj.meshes[node_info.mesh];
    // -- set matrix --
    if ( node_info.matrix.length == 16 ) {
      matrix = node_info.matrix;
    } else if ( node_info.matrix.length == 9 ) {
      matrix = [
        node_info.matrix[0], node_info.matrix[1], node_info.matrix[2], 0.0f,
        node_info.matrix[3], node_info.matrix[4], node_info.matrix[5], 0.0f,
        node_info.matrix[6], node_info.matrix[7], node_info.matrix[8], 0.0f,
        0.0f,                0.0f,                0.0f,                1.0f,
      ];
    } else if ( node_info.matrix.length == 0 ) {
      // no translation/rotation/scale
      Enforce(node_info.translation.length == 0 && node_info.scale.length == 0
           && node_info.rotation.length == 0, "TRS vectors not yet supported");
      matrix = [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
    } else {
      throw new Exception("Unsupported node-transformation matrix length of %s"
                           .format(node_info.matrix.length));
    }
  }
}

// ----- sampler ---------------------------------------------------------------
struct glTFSampler {
  mixin glTFTemplate!JSON_glTFSamplerInfo;
  glTFFilterType min_filter, mag_filter;
  glTFWrapType wrap_s, wrap_t;

  this ( uint idx, glTFObject obj, ref JSON_glTFSamplerInfo info ) {
    Template_Construct(idx, info);
    min_filter = cast(glTFFilterType)info.minFilter;
    mag_filter = cast(glTFFilterType)info.magFilter;
    wrap_s = cast(glTFWrapType)info.wrapS;
    wrap_t = cast(glTFWrapType)info.wrapT;
  }
}

// ----- scene -----------------------------------------------------------------
struct glTFScene {
  mixin glTFTemplate!JSON_glTFSceneInfo;
  glTFNode*[] nodes;

  this ( uint idx, glTFObject obj, ref JSON_glTFSceneInfo scn_info ) {
    Template_Construct(idx, scn_info);
    nodes = scn_info.nodes.map!(i => &obj.nodes[i]).array;
  }

  string RName ( ) { return name; }
}

// ----- skin ------------------------------------------------------------------
struct glTFSkin {
  mixin glTFTemplate!JSON_glTFSkinInfo;

  this ( uint idx, glTFObject obj, ref JSON_glTFSkinInfo skn_info ) {
    Template_Construct(idx, skn_info);
  }
}

// ----- texture ---------------------------------------------------------------
struct glTFTexture {
  mixin glTFTemplate!JSON_glTFTextureInfo;
  glTFImage* image;
  glTFSampler* sampler;

  this ( uint idx, glTFObject obj, ref JSON_glTFTextureInfo tex_info ) {
    Template_Construct(idx, tex_info);
    image = &obj.images[tex_info.source];
    if ( tex_info.Has_Sampler )
      sampler = &obj.samplers[tex_info.sampler];
  }
}


// ----- misc functions --------------------------------------------------------
private void Enforce_glTF ( string err ) {
  throw new Exception(err);
}
private void Enforce_glTF ( bool cond, string err ) {
  if ( !cond ) throw new Exception(err);
}
private void Enforce_glTF(T)(T* ptr, string err) {
  if ( ptr is null ) throw new Exception(err);
}

void Emit_Warning ( string warning ) {
  writeln("Warning: ", warning);
}

bool Supported_Extension ( string extension ) {
  switch ( extension ) {
    default: return false;
    case "AODQ_lights": return true;
  }
}

void Enforce_File_Asset_Data(JSONFile json_asset) {
  // -- check version --
  string ver = json_asset.asset._version;
  if ( json_asset.asset.minVersion != "" ) ver = json_asset.asset.minVersion;
  switch ( ver ) {
    default: throw new Exception("Unsupported glTF Version " ~ ver);
    case "2.0": break;
    case "1.0":
      throw new Exception("glTF2 not backwards-compatible with version 1.0");
  }
  // -- check extensions required --
  foreach ( ext; json_asset.extensionsRequired ) {
    if ( !Supported_Extension(ext) )
      throw new Exception("Required extension '%s' not supported".format(ext));
  }
  // -- check extensions used --
  foreach ( ext; json_asset.extensionsUsed ) {
    if ( !Supported_Extension(ext) )
      Emit_Warning("extension '%s' used but not supported".format(ext));
  }
}

auto glTF_Load_JSON_File(string filename) {
  enforce(exists(filename), "Could not load file " ~ filename);
  return Load_JSON_glTFFileInfo(filename);
}
glTFObject glTF_Load_File(string filename) {
  import std.path;
  string path = filename.dirName ~ "/";
  auto json_asset = glTF_Load_JSON_File(filename);
  glTFObject obj = new glTFObject(path, json_asset);
  return obj;
}
