import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    printLongString("Request [${options.method}] => PATH: ${options.path}");
    printLongString("Headers: ${options.headers}");
    if (options.queryParameters.isNotEmpty) {
      printLongString("Query Parameters: ${options.queryParameters}");
    }
    if (options.data != null) {
      printLongString("Request Body: ${options.data}");
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    printLongString("Response [${response.statusCode}] => PATH: ${response.requestOptions.path}");
    printLongString("Response: $response");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    printLongString("Error [${err.response?.statusCode}] => PATH: ${err.requestOptions.path}");
    printLongString("Error Response: ${err.response}");
    super.onError(err, handler);
  }
}

void printLongString(String text) {
  const int chunkSize = 1000;
  for (int i = 0; i < text.length; i += chunkSize) {
    int endIndex = i + chunkSize;
    if (endIndex > text.length) endIndex = text.length;
    //print(text.substring(i, endIndex));
  }
}
