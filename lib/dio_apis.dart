import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class DioApis {
  DioApis._();
  final dio =
      Dio(BaseOptions(baseUrl: "https://0ad3-112-199-240-193.ngrok-free.app"))
        ..interceptors.add(
          LogInterceptor(
            responseBody: true,
            requestBody: true,
          ),
        );
  Future<Response> uploadVideo({
    required File file,
    required bool isAdvertiser, //isAdvertiser
    required ValueChanged<double> progress,
  }) async {
    try {
      final response = await dio.post(
        '/upload',
        data: FormData.fromMap(isAdvertiser == false
            ? {
                "left_file": await MultipartFile.fromFile(file.path),
              }
            : {"right_file": await MultipartFile.fromFile(file.path)}),
        options: Options(
          headers: {
            "Authorization": "please enter the token here",
          },
        ),
        onSendProgress: (int sent, int total) {
          progress(sent / total);
        },
      );
      return response;
    } catch (e) {
      log("Error in uploading Video $e");
      return Response(
        statusCode: 500,
        requestOptions: RequestOptions(
          path: '/upload',
        ),
      );
    }
  }
}
