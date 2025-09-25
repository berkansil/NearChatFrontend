import 'dart:convert';

class Channel {
  final int channelId;
  final String name;
  final String channelType;

  Channel({required this.channelId, required this.name, required this.channelType});

  factory Channel.fromJson(Map<String, dynamic> json) { 
    return Channel(channelId: json["ChannelId"], name: json["Name"], channelType: json["ChannelType"]);
  }

  static Channel fromRawJson(String str) => Channel.fromJson(jsonDecode(str));
}
