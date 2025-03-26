import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:church_app/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadService {
  final String uploadUrl = '${ApiConstants.usersUrl}/uploadimage';

  Future<String> uploadImage(Uint8List fileBytes, String fileName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final UserId = prefs.getString('user_id');
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.usersUrl}/$UserId/uploadimage'));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return responseData; // Assuming API returns the image URL
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }
}
