module gltf2.gltfbase;
import gltf2.gltfenum;
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


// ----- templates -------------------------------------------------------------
private template glTFTemplate ( JSON_Base ) {
  static immutable bool Has_name = __traits(hasMember, JSON_Base, "name");
  static immutable bool Has_buffer = JSON_glTFConstruct.HasBufferType!JSON_Base;
  static if ( Has_name ) string name;
  JsonValue extensions, extras;
  uint buffer_index;
  private alias Type = typeof(this);

  void Template_Construct(uint _buffer_index, ref JSON_Base obj) {
    buffer_index = _buffer_index;
    static if ( Has_name ) name = obj.name;
    extensions = obj.extensions;
    extras = obj.extras;
  }

  static if ( Has_buffer )
  JSON_Base* Template_Construct(uint _buffer_index, JSON_glTFConstruct t){
    buffer_index = _buffer_index;
    JSON_Base* ptr = t.RPointer!JSON_Base(buffer_index);
    Template_Construct(buffer_index, *ptr);
    return ptr;
  }
}

// ----- accessor --------------------------------------------------------------
struct glTFAccessor {
  mixin glTFTemplate!JSON_glTFAccessorInfo;
  uint buffer_view;
  uint count, offset;
  glTFType type;
  glTFComponentType component_type;
  JsonValue max, min;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    buffer_view = jdata.bufferView;
    count = jdata.count;
    offset = jdata.byteOffset;
    type = To_glTFType(jdata.type);
    component_type = Scalar_To_glTFComponentType(jdata.componentType);
    max = jdata.max;
    min = jdata.min;
  }
}

// ----- animation -------------------------------------------------------------
struct glTFAnimation {
  mixin glTFTemplate!JSON_glTFAnimationInfo;
  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    Template_Construct(idx, sobj);
  }
}

// ----- asset -----------------------------------------------------------------
struct glTFAsset {
  mixin glTFTemplate!JSON_glTFAssetInfo;
  this(RObj)(RObj obj, JSON_glTFConstruct sobj) {
    Template_Construct(0, sobj.asset);
  }
}

// ----- buffer ----------------------------------------------------------------
struct glTFBuffer {
  mixin glTFTemplate!JSON_glTFBufferInfo;
  uint length;
  ubyte[] raw_data;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    import std.file : read;
    length = jdata.byteLength;
    // TODO: variant for when uri is not a file
    raw_data = cast(ubyte[])read(obj.base_path ~ jdata.uri);
    Enforce_glTF(raw_data.length == length, "Buffer length mismatch");
  }
}
struct glTFBufferView {
  mixin glTFTemplate!JSON_glTFBufferViewInfo;
  glTFBuffer* buffer;
  glTFBufferViewTarget target;
  uint offset, length, stride;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    buffer = &obj.buffers[jdata.buffer].gltf;
    offset = jdata.byteOffset;
    length = jdata.byteLength;
    stride = jdata.byteStride;
    target = Scalar_To_glTFBufferViewTarget(jdata.target);
  }
}

// ----- camera ----------------------------------------------------------------
struct glTFCamera {
  mixin glTFTemplate!JSON_glTFCameraInfo;

  this(RObj)(uint idx, ref JSON_glTFNodeInfo node) {
    // Template_Construct(idx, sobj);
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

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    import imageformats;
    auto img = read_image(obj.base_path ~ jdata.uri);
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
  uint texture = -1;

  this(RObj)(RObj obj, JSON_glTFMaterialTextureInfo jdata) {
    Template_Construct(0, jdata);
    writeln("IDX: ", jdata.index);
    texture = jdata.index;
  }

  bool Exists ( ) { return texture !is -1; }
}
struct glTFMaterialPBRMetallicRoughness {
  float[] colour_factor;
  float metallic_factor, roughness_factor;
  glTFMaterialTexture base_colour_texture;

  bool Has_Base_Colour_Texture ( ) {
    return base_colour_texture.Exists;
  }

  this(RObj)(RObj obj, JSON_glTFMaterialPBRMetallicRoughnessInfo jdata) {
    colour_factor = jdata.baseColorFactor;
    metallic_factor = jdata.metallicFactor;
    roughness_factor = jdata.roughnessFactor;
    if ( jdata.baseColorTexture.Exists )
      base_colour_texture = glTFMaterialTexture(obj, jdata.baseColorTexture);
  }
}
struct glTFMaterialNil { }
struct glTFMaterial {
  mixin glTFTemplate!JSON_glTFMaterialInfo;
  Algebraic!(glTFMaterialPBRMetallicRoughness, glTFMaterialNil) material;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    material = glTFMaterialNil();
    if ( jdata.pbrMetallicRoughness.Exists ) {
      material = glTFMaterialPBRMetallicRoughness(obj,
                             jdata.pbrMetallicRoughness);
    }
  }
}

// ----- mesh ------------------------------------------------------------------
struct glTFPrimitive {
  mixin glTFTemplate!JSON_glTFMeshPrimitiveInfo;
  private glTFAccessor*[glTFAttribute] accessors;
  uint material = -1;
  glTFMode mode;

  private void Set_Accessor(RObj)(RObj data, glTFAttribute atr, int idx) {
    accessors[atr] = idx != -1 ? &data.accessors[idx].gltf : null;
  }

  bool Has_Material ( ) { return material != -1; }
  bool Has_Index ( ) {
    return accessors[glTFAttribute.Index] !is null;
  }
  glTFAccessor* RAccessor ( glTFAttribute atr ) {
    return accessors[atr];
  }

  this(RObj)(uint idx, RObj obj, ref JSON_glTFMeshPrimitiveInfo jdata) {
    Template_Construct(idx, jdata);
    auto atr = &jdata.attributes;
    Set_Accessor(obj, glTFAttribute.Index,     jdata.indices);
    Set_Accessor(obj, glTFAttribute.Position,  atr.POSITION);
    Set_Accessor(obj, glTFAttribute.Normal,    atr.NORMAL);
    Set_Accessor(obj, glTFAttribute.TexCoord0, atr.TEXCOORD_0);
    Set_Accessor(obj, glTFAttribute.Colour0,   atr.COLOR_0);
    mode = cast(glTFMode)jdata.mode;
    material = jdata.material;
  }
}
struct glTFMesh {
  mixin glTFTemplate!JSON_glTFMeshInfo;
  glTFPrimitive[] primitives;
  float[] weights;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    name = jdata.name;
    weights = jdata.weights;
    // fill primitives
    foreach ( iter, ref p; jdata.primitives )
      primitives ~= glTFPrimitive(cast(uint)iter, obj, p);
  }
}

// ----- node ------------------------------------------------------------------
struct glTFNode {
  mixin glTFTemplate!JSON_glTFNodeInfo;
  uint[] children;
  uint mesh;
  float[] matrix;

  bool Has_Transformation_Matrix() { return !matrix.empty(); }
  bool Has_Mesh() { return mesh !is -1; }
  uint RMesh() { return mesh; }

  void Enforce(bool cond, string err) {
    if ( !cond ) throw new Exception("Node '%s' %s".format(name, err));
  }

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    children = jdata.children.map!(i => cast(uint)i).array;
    mesh = jdata.mesh;
    // -- set matrix --
    if ( jdata.matrix.length == 16 ) {
      matrix = jdata.matrix;
    } else if ( jdata.matrix.length == 9 ) {
      matrix = [
        jdata.matrix[0], jdata.matrix[1], jdata.matrix[2], 0.0f,
        jdata.matrix[3], jdata.matrix[4], jdata.matrix[5], 0.0f,
        jdata.matrix[6], jdata.matrix[7], jdata.matrix[8], 0.0f,
        0.0f,                0.0f,                0.0f,                1.0f,
      ];
    } else if ( jdata.matrix.length == 0 ) {
      // no translation/rotation/scale
      Enforce(jdata.translation.length == 0 && jdata.scale.length == 0
           && jdata.rotation.length == 0, "TRS vectors not yet supported");
      matrix = [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
    } else {
      throw new Exception("Unsupported node-transformation matrix length of %s"
                           .format(jdata.matrix.length));
    }
  }
}

// ----- sampler ---------------------------------------------------------------
struct glTFSampler {
  mixin glTFTemplate!JSON_glTFSamplerInfo;
  glTFFilterType min_filter, mag_filter;
  glTFWrapType wrap_s, wrap_t;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    min_filter = cast(glTFFilterType)jdata.minFilter;
    mag_filter = cast(glTFFilterType)jdata.magFilter;
    wrap_s = cast(glTFWrapType)jdata.wrapS;
    wrap_t = cast(glTFWrapType)jdata.wrapT;
  }
}

// ----- scene -----------------------------------------------------------------
struct glTFScene {
  mixin glTFTemplate!JSON_glTFSceneInfo;
  uint[] nodes;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    nodes = jdata.nodes.map!(i => cast(uint)i).array;
  }

  string RName ( ) { return name; }
}

// ----- skin ------------------------------------------------------------------
struct glTFSkin {
  mixin glTFTemplate!JSON_glTFSkinInfo;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
  }
}

// ----- texture ---------------------------------------------------------------
struct glTFTexture {
  mixin glTFTemplate!JSON_glTFTextureInfo;
  glTFImage* image;
  glTFSampler* sampler;

  this(RObj)(uint idx, RObj obj, JSON_glTFConstruct sobj) {
    auto jdata = Template_Construct(idx, sobj);
    image = &obj.images[jdata.source].gltf;
    if ( jdata.Has_Sampler )
      sampler = &obj.samplers[jdata.sampler].gltf;
  }
}


// ----- misc functions --------------------------------------------------------

void Emit_Warning ( string warning ) {
  writeln("Warning: ", warning);
}

bool Supported_Extension ( string extension ) {
  switch ( extension ) {
    default: return false;
    case "AODQ_lights": return true;
  }
}

// void Enforce_File_Asset_Data(JSON_glTFAssetInfo json_asset) {
//   // -- check version --
//   string ver = json_asset._version;
//   if ( json_asset.minVersion != "" ) ver = json_asset.minVersion;
//   switch ( ver ) {
//     default: throw new Exception("Unsupported glTF Version " ~ ver);
//     case "2.0": break;
//     case "1.0":
//       throw new Exception("glTF2 not backwards-compatible with version 1.0");
//   }
//   // -- check extensions required --
//   foreach ( ext; json_asset.extensionsRequired ) {
//     if ( !Supported_Extension(ext) )
//       throw new Exception("Required extension '%s' not supported".format(ext));
//   }
//   // -- check extensions used --
//   foreach ( ext; json_asset.extensionsUsed ) {
//     if ( !Supported_Extension(ext) )
//       Emit_Warning("extension '%s' used but not supported".format(ext));
//   }
// }
