/// Thrown by [ServiceRequestRemoteDataSource] when the "My Service
/// Requests" list API call fails (network error, non-2xx response, or an
/// unexpected/unparseable body).
class ServiceRequestException implements Exception {
  const ServiceRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
