import 'package:flutter/material.dart';
import 'package:nearchat/data/notifiers.dart';
import 'package:nearchat/models/channel_model.dart';
import 'package:nearchat/server/api_service.dart';

class MessageBoxWidget extends StatefulWidget {
  MessageBoxWidget({super.key});

  @override
  State<MessageBoxWidget> createState() => _MessageBoxWidgetState();
}

class _MessageBoxWidgetState extends State<MessageBoxWidget> {
  final TextEditingController messageController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool sendInProgress = false;
  DateTime? lastMessageTime;

  void _sendPressed(Channel toChannel) async {
    // Debounce to prevent rapid consecutive messages
    if (lastMessageTime != null &&
        DateTime.now().difference(lastMessageTime!) < Duration(seconds: 1)) {
      print("Rate limit.");
      return;
    }
    lastMessageTime = DateTime.now();

    setState(() {
      sendInProgress = true;
    });

    try{
      await _apiService.sendMessage(toChannel.channelId, messageController.text);

      // Clear the input field after sending
      messageController.clear();
    } catch(e){
      print(e.toString());
    }

    if (mounted) {
      setState(() {
        sendInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: channelNotifier,
        builder: (context, newChannel, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                      labelText: newChannel != null
                          ? "Send message to ${newChannel.name}"
                          : "Select channel",
                      enabled: newChannel != null),
                ),
              ),
              IconButton(
                icon: sendInProgress
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                onPressed: newChannel != null && !sendInProgress
                    ? () => _sendPressed(newChannel)
                    : null,
              )
            ],
          );
        });
  }
}
