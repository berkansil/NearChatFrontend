import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nearchat/models/channel_model.dart';
import 'package:nearchat/models/message_model.dart';
import 'package:nearchat/models/user_model.dart';
import 'package:web_socket_channel/io.dart';
import 'token_storage.dart';

//https://nearchat.duckdns.org

///An exception indicating that the current token is no longer valid and the user should be taken back to the login page
class AuthenticationException implements Exception {}

//An exception indicating a generic API error which can't be handled but should be displayed
class APIException implements Exception {
  String errorMessage;
  APIException(this.errorMessage);
}

class ApiService {
  final String apiUrl = "https://nearchat.duckdns.org";
  final TokenStorage _tokenStorage = TokenStorage();

  Future<IOWebSocketChannel> subscribe(int channelId) async {
    final String? token = await _tokenStorage.getToken(); //get the token

    if (token == null) {
      throw AuthenticationException();
    }

    final uri = Uri.parse(
        "wss://nearchat.duckdns.org/subscribe?channelId=$channelId"); //Get a special websocket secure (wss) uri

    //Connect to the websocket with the token and return the websocket
    return IOWebSocketChannel.connect(
      uri,
      headers: {'Authorization': token},
    );
  }

  Future<String> _request(String endpoint,
      {String method = "GET", Map<String, dynamic>? body}) async {
    final url = Uri.parse("$apiUrl/$endpoint");
    final token = await _tokenStorage.getToken();

    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": token,
    };

    late http.Response response;
    if (method == "POST") {
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    } else {
      response = await http.get(url, headers: headers);
    }

    //Special exception that will tell the requesting page to go back to the login screen
    if (response.statusCode == 401) {
      _tokenStorage.removeToken();
      throw AuthenticationException();
    }

    //Handle all other API failures by throwing an API exception that should be displayed to the user
    if (response.statusCode != 200) {
      final Map<String, dynamic> errorDetails = jsonDecode(response.body);
      throw APIException(
          errorDetails['message'] ?? errorDetails['error'] ?? "Unknown error");
    }

    return response.body;
  }

  Future<void> sendMessage(int channelId, String message) async {
    print("send message called");
    await _request("sendMessage",
        method: "POST", body: {"content": message, "channelId": channelId});
  }

  Future<List<Message>> getMessages(int channelId, int? lastMessageId) async {
    final response = await _request("getMessages",
        method: "POST",
        body: {"channelId": channelId, "lastMessageId": lastMessageId});

    List out = jsonDecode(response);

    return out.map((data) => Message.fromJson(data)).toList();

//    List<Message> out = response.map((i) => Message.fromJson(i)).toList();
//    return out;
  }

  ///Update GPS coordinates and get channels. Should be run when the home page is first opened.
  Future<List<Channel>> updateGPS(double lat, double lon) async {
    final response = await _request("updateGPS",
        method: "POST", body: {"lat": lat, "lon": lon}) as List;

    List<Channel> out = response.map((i) => Channel.fromJson(i)).toList();
    return out;
  }

  ///Get channels without updating GPS.
  Future<List<Channel>> getChannels() async {
    List response = jsonDecode(await _request("getChannels", method: "GET"));

    return response.map((data) => Channel.fromJson(data)).toList();
    //List<Channel> out = response.map((i) => Channel.fromJson(i)).toList();
    //return out;
  }

  Future<User> getUserDetails(int? userId) async {
    print("Getting details for $userId");
    final response =
        await _request("queryUser", method: "POST", body: {"userId": userId});

    print("Returning data for $userId");
    return User.fromJson(jsonDecode(response));
  }

  Future<String> login(String username, String password) async {
    final response = jsonDecode(await _request("login",
        method: "POST", body: {"username": username, "password": password}));

    await _tokenStorage.saveToken(response["token"]);
    return response["token"];
  }

  Future<String> register(String username, String password) async {
    final response = jsonDecode(await _request("register",
        method: "POST", body: {"username": username, "password": password}));

    if (response.containsKey("token")) {
      await _tokenStorage.saveToken(response["token"]);
      return response["token"];
    } else {
      throw Exception("Registration failed");
    }
  }

  Future<void> logout() async {
    await _request("logout", method: "POST");
    await _tokenStorage.removeToken();
  }
}
