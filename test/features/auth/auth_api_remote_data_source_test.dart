import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/features/auth/data/datasources/auth_api_remote_data_source.dart';
import 'package:iungo/features/auth/data/datasources/auth_exceptions.dart';

/// Minimal fake network layer: no real HTTP, no extra dependencies.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _success({
  Object? email = 'returned@example.com',
  Object? password = 'returned-pass',
}) =>
    {
      'code': 200,
      'data': {
        'user_id': 'abc',
        'username': 'mareeswari',
        'password': password,
        'email': email,
        'user_type': 'employee',
        'login_record_id': 3784,
        'redirection_page': 'home.php',
      },
      'message': 'Login Successfully',
    };

AuthApiRemoteDataSourceImpl _dataSource(
  ResponseBody Function(RequestOptions options) handler, {
  _FakeAdapter? adapter,
}) {
  final dio = Dio()..httpClientAdapter = adapter ?? _FakeAdapter(handler);
  return AuthApiRemoteDataSourceImpl(dio);
}

Future<void> _expectFailure(
  Future<Object?> future,
  AuthApiFailureType type,
) {
  return expectLater(
    future,
    throwsA(
      isA<AuthApiException>().having((e) => e.type, 'type', type),
    ),
  );
}

void main() {
  group('AuthApiRemoteDataSourceImpl.authenticate', () {
    test('Scenario 1: success returns the credentials from the response, '
        'sent as GET with the typed username/password', () async {
      final adapter = _FakeAdapter((_) => _json(_success()));
      final ds = _dataSource((_) => _json(_success()), adapter: adapter);

      final creds = await ds.authenticate(
        username: 'typed@example.com',
        password: 'typed-pass',
      );

      expect(creds.email, 'returned@example.com');
      expect(creds.password, 'returned-pass');
      expect(creds.userId, 'abc');
      expect(creds.username, 'mareeswari');
      expect(creds.userType, 'employee');
      expect(creds.loginRecordId, 3784);
      expect(creds.redirectionPage, 'home.php');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(),
          'https://iungo.citgroupltd.com/api/auth.php');
      expect(request.data, {
        'username': 'typed@example.com',
        'password': 'typed-pass',
      });
    });

    test('email is trimmed, password is passed through untouched', () async {
      final ds = _dataSource(
        (_) => _json(_success(email: '  a@b.com ', password: ' p ')),
      );
      final creds = await ds.authenticate(username: 'u', password: 'p');
      expect(creds.email, 'a@b.com');
      expect(creds.password, ' p ');
    });

    test('Scenario 2: body code 401 (HTTP 200) -> unauthorized + API message',
        () async {
      final ds = _dataSource(
        (_) => _json({'code': 401, 'message': 'Invalid credentials'}),
      );
      await expectLater(
        ds.authenticate(username: 'u', password: 'p'),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.type, 'type', AuthApiFailureType.unauthorized)
              .having((e) => e.message, 'message', 'Invalid credentials'),
        ),
      );
    });

    test('Scenario 2: HTTP 401 with JSON body -> unauthorized + API message',
        () async {
      final ds = _dataSource(
        (_) => _json({'code': 401, 'message': 'Bad login'}, status: 401),
      );
      await expectLater(
        ds.authenticate(username: 'u', password: 'p'),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.type, 'type', AuthApiFailureType.unauthorized)
              .having((e) => e.message, 'message', 'Bad login'),
        ),
      );
    });

    test('unknown non-success body code -> rejected', () async {
      final ds = _dataSource((_) => _json({'code': 422, 'message': 'Nope'}));
      await _expectFailure(
        ds.authenticate(username: 'u', password: 'p'),
        AuthApiFailureType.rejected,
      );
    });

    final statusCases = <int, AuthApiFailureType>{
      400: AuthApiFailureType.badRequest,
      401: AuthApiFailureType.unauthorized,
      403: AuthApiFailureType.forbidden,
      404: AuthApiFailureType.notFound,
      500: AuthApiFailureType.serverError,
      502: AuthApiFailureType.serverError,
      503: AuthApiFailureType.serverError,
      418: AuthApiFailureType.unknown,
    };
    statusCases.forEach((status, type) {
      test('HTTP $status -> ${type.name}', () async {
        final ds = _dataSource(
          (_) => ResponseBody.fromString('', status),
        );
        await _expectFailure(
          ds.authenticate(username: 'u', password: 'p'),
          type,
        );
      });
    });

    group('invalid responses never yield credentials', () {
      final cases = <String, Object>{
        'Scenario 3: email missing': _success()
          ..['data'] = {'password': 'p'},
        'Scenario 3: email empty': _success(email: ''),
        'Scenario 3: email blank': _success(email: '   '),
        'Scenario 3: email null': _success(email: null),
        'Scenario 4: password missing': _success()
          ..['data'] = {'email': 'a@b.com'},
        'Scenario 4: password empty': _success(password: ''),
        'Scenario 4: password null': _success(password: null),
        'data missing': {'code': 200, 'message': 'ok'},
        'data is an empty list (PHP empty array)': {
          'code': 200,
          'data': [],
        },
        'code missing': {
          'data': {'email': 'a@b.com', 'password': 'p'},
        },
        'code is not a number': {
          'code': 'abc',
          'data': {'email': 'a@b.com', 'password': 'p'},
        },
        'body is a JSON array': ['nope'],
      };
      cases.forEach((name, body) {
        test(name, () async {
          final ds = _dataSource((_) => _json(body));
          await _expectFailure(
            ds.authenticate(username: 'u', password: 'p'),
            AuthApiFailureType.invalidResponse,
          );
        });
      });

      test('non-JSON body', () async {
        final ds = _dataSource(
          (_) => ResponseBody.fromString(
            '<html>oops</html>',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/html'],
            },
          ),
        );
        await _expectFailure(
          ds.authenticate(username: 'u', password: 'p'),
          AuthApiFailureType.invalidResponse,
        );
      });

      test('string code "200" is accepted', () async {
        final body = _success()..['code'] = '200';
        final ds = _dataSource((_) => _json(body));
        final creds = await ds.authenticate(username: 'u', password: 'p');
        expect(creds.email, 'returned@example.com');
      });
    });

    test('Scenario 6: no connection -> noInternet', () async {
      final ds = _dataSource(
        (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      await _expectFailure(
        ds.authenticate(username: 'u', password: 'p'),
        AuthApiFailureType.noInternet,
      );
    });

    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('Scenario 7: ${t.name} -> timeout', () async {
        final ds = _dataSource(
          (o) => throw DioException(requestOptions: o, type: t),
        );
        await _expectFailure(
          ds.authenticate(username: 'u', password: 'p'),
          AuthApiFailureType.timeout,
        );
      });
    }

    test('unexpected error -> unknown', () async {
      final ds = _dataSource((_) => throw StateError('boom'));
      await _expectFailure(
        ds.authenticate(username: 'u', password: 'p'),
        AuthApiFailureType.unknown,
      );
    });
  });
}
