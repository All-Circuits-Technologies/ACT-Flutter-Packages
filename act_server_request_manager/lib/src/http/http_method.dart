// Copyright (c) 2020. BMS Circuits

/// Current http methods
enum HttpMethod { delete, get, head, patch, post, put }

/// Extension of the HttpMethod
extension HttpMethodExtension on HttpMethod {
  /// Getter allows to get a string representation of the enum
  ///
  /// Good to know : the toString() method of enum will display the enum class
  /// name like this: HttpMethod.delete
  String get str => this.toString().split('.').last;
}
