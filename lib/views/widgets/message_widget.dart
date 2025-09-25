import 'package:flutter/material.dart';
import 'package:nearchat/models/user_model.dart';
import 'package:nearchat/server/api_service.dart';

class MessageWidget extends StatefulWidget {
  final int author;
  final String content;
  final DateTime sendDate;

  static const String defaultPfpUrl =
      "https://cdn.pixabay.com/photo/2023/02/18/11/00/icon-7797704_640.png"; //A placeholder if a user doesn't have a pfp

  const MessageWidget(
      {super.key,
      required this.author,
      required this.content,
      required this.sendDate});

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: FutureBuilder(
        future:
            _apiService.getUserDetails(widget.author), // Fetch dynamically
        builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
          if (snapshot.hasData) {
            print(snapshot.data!.username);
          }
          if (snapshot.hasError){
            print(snapshot.error.toString());
            print("errored");
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              snapshot.hasData
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(64),
                      child: Image.network(
                        snapshot.data!.profilePicture ??
                            MessageWidget.defaultPfpUrl,
                        height: 64,
                        width: 64,
                      ),
                    )
                  : const CircularProgressIndicator(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.hasData ? snapshot.data!.username : "Loading",
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(widget.content),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Text(widget.sendDate.toString())
            ],
          );
        },
      ),
    );
  }
}
