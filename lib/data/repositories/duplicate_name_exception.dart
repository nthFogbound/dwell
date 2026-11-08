/// Thrown when a name is already used (e.g. two courses with the same name).
class DuplicateNameException implements Exception {
  const DuplicateNameException(this.message);

  final String message;

  @override
  String toString() => message;
}