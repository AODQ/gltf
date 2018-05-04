module gltf2.gltfenum;
import std.string, std.conv, std.algorithm, std.range;
void Enforce_glTF ( string err ) {
  throw new Exception(err);
}
void Enforce_glTF ( bool cond, string err ) {
  if ( !cond ) throw new Exception(err);
}
void Enforce_glTF(T)(T* ptr, string err) {
  if ( ptr is null ) throw new Exception(err);
}

// ----- enum ------------------------------------------------------------------
T To_glTFEnum(T)(ulong mem) {
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

enum glTFInterpolation {
  Linear, Step, CubicSpline
}
glTFInterpolation String_To_glTFInterpolation ( string t ) {
  switch ( t ) {
    default: assert(false, t ~ " not valid glTFInterpolation");
    case "LINEAR":      return glTFInterpolation.Linear;
    case "STEP":        return glTFInterpolation.Step;
    case "CUBICSPLINE": return glTFInterpolation.CubicSpline;
  }
}
enum glTFCameraType { Perspective, Orthographic };
auto String_To_glTFCameraType ( string str ) {
  switch ( str ) {
    default: assert(false, "Invalid glTFCameraType " ~ str );
    case "": goto case "perspective"; // explicit fallthrough
    case "perspective":  return glTFCameraType.Perspective;
    case "orthographic": return glTFCameraType.Orthographic;
  }
}

enum glTFBufferViewTarget {
  NonGPU = 0,
  Array = 34962,
  ElementArray = 34963
};
alias Scalar_To_glTFBufferViewTarget = To_glTFEnum!(glTFBufferViewTarget);
