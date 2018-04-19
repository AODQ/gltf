module gltf2.gltfroot;
import gltf2.jsonloader, gltf2.gltfroot;
import std.string;

class glTFRootObject(string api) {
  struct RootSubObj(JSON_T, glTF_T, API_T) {
    JSON_T json_data; glTF_T gltf_data;
    mixin("API_T %s_data".format(api));
  }
  alias
}
