import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authServices.dart';

class TokenInterceptor implements InterceptorContract {
  final AuthService authService;

  TokenInterceptor({required this.authService});

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('auth_token');
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async {
    if (response.statusCode == 401) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        try {
          final newTokens = await authService.refreshToken(refreshToken);
          final newAccessToken = newTokens['session']['access_token'];
          final newRefreshToken = newTokens['session']['refresh_token'];

          await prefs.setString('auth_token', newAccessToken);
          await prefs.setString('refresh_token', newRefreshToken);

          // Retry the original request with the new access token
          final retryRequest = response.request;
          retryRequest!.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await http.Response.fromStream(await retryRequest.send());
          return retryResponse;
        } catch (e) {
          // Handle token refresh failure
        }
      }
    }
    return response;
  }

  @override
  FutureOr<bool> shouldInterceptRequest() {
    return true;
  }

  @override
  FutureOr<bool> shouldInterceptResponse() {
    return true;
  }
}