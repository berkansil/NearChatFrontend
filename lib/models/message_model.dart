import 'dart:convert';

class Message {
  final int messageId;
  final String content;
  final DateTime sendDate;
  final int authorId;
  final int? replyingMessageId;
  final int channelId;


  Message({required this.messageId, required this.content, required this.sendDate, required this.authorId, required this.channelId, this.replyingMessageId});

  factory Message.fromJson(Map<String, dynamic> json) { 
    return Message(messageId: json["MessageId"], content: json["Content"], sendDate: DateTime.parse(json["SendDate"]), authorId: json["AuthorId"], channelId: json["ChannelId"], replyingMessageId: json["ReplyingMessageId"]);
  }

  static Message fromRawJson(String str) => Message.fromJson(jsonDecode(str));
}
