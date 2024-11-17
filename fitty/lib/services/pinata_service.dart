// services/pinata_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PinataService {
  final String? pinataJwt = dotenv.env['PINATA_JWT'];
  final String baseUrl = 'https://api.pinata.cloud';
  final String uploadUrl = 'https://api.pinata.cloud/pinning';

  PinataService() {
    if (pinataJwt == null) {
      throw Exception('PINATA_JWT is not set in environment variables.');
    }
  }

  Future<String?> uploadFile(File file,
      {String? name, Map<String, String>? keyValues}) async {
    final url = Uri.parse('$uploadUrl/pinFileToIPFS');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $pinataJwt',
      });
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      Map<String, dynamic> pinataMetadata = {};
      if (name != null || keyValues != null) {
        if (name != null) pinataMetadata['name'] = name;
        if (keyValues != null) pinataMetadata['keyvalues'] = keyValues;
        request.fields['pinataMetadata'] = jsonEncode(pinataMetadata);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var body = await response.stream.bytesToString();
        var jsonResponse = json.decode(body);
        return jsonResponse['IpfsHash']; // CID of the uploaded file
      } else {
        var body = await response.stream.bytesToString();
        print('Failed to upload file: ${response.statusCode}');
        print('Response body: $body');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<String?> uploadJson(Map<String, dynamic> jsonContent,
      {String? name, Map<String, String>? keyValues}) async {
    final url = Uri.parse('$uploadUrl/pinJSONToIPFS');

    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $pinataJwt',
      };

      Map<String, dynamic> body = {
        'pinataContent': jsonContent,
      };
      if (name != null || keyValues != null) {
        Map<String, dynamic> pinataMetadata = {};
        if (name != null) pinataMetadata['name'] = name;
        if (keyValues != null) pinataMetadata['keyvalues'] = keyValues;
        body['pinataMetadata'] = pinataMetadata;
      }

      var response =
          await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['IpfsHash']; // CID of the uploaded JSON
      } else {
        print('Failed to upload JSON: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading JSON: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getJson(String cid) async {
    final url = Uri.parse('https://gateway.pinata.cloud/ipfs/$cid');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData;
      } else {
        print('Failed to fetch JSON: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching JSON: $e');
      return null;
    }
  }

  Future<void> deleteFile(String cid) async {
    final url = Uri.parse('$baseUrl/pinning/unpin/$cid');

    try {
      var headers = {
        'Authorization': 'Bearer $pinataJwt',
      };

      var response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        print('Successfully unpinned $cid');
      } else {
        print('Failed to unpin $cid: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
