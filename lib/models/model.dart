abstract class Model {
  Map<String, dynamic> toMap();
  static Model fromMap(Map<String, dynamic> data) {
    // TODO: implement fromMap
    throw UnimplementedError();
  }
  static Model fromJson(Map<String, dynamic> data){
    // TODO: implement fromJson
    throw UnimplementedError();
  }
  Future<Model> save() async {
    // TODO: implement save
    throw UnimplementedError();
  }
  static Future<int> saveMany(List<Model> modelList) async {
    // TODO: implement saveMany
    throw UnimplementedError();
  }
}