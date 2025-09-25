import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:nearchat/data/notifiers.dart";
import "package:nearchat/models/channel_model.dart";
import "package:nearchat/models/message_model.dart";
import "package:nearchat/server/api_service.dart";
import "package:nearchat/views/pages/settings_page.dart";
import "package:nearchat/views/widgets/channel_selector.dart";
import "package:nearchat/views/widgets/message_box.dart";
import "package:web_socket_channel/web_socket_channel.dart";
import "dart:convert";
import "../widgets/message_widget.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = []; //store the loaded messages
  int? _lastMessageId; //store the last message for loading older messages
  bool _hasMore =
      true; //track if there are more messages to be loaded so the progress indiactor isn't displayed
  bool _isLoading = false; //prevent repeat load attempts
  WebSocketChannel?
      _webSocketChannel; //store the current websocket so it can be closed
  int? _currentChannelId; // Track current channel ID

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
        _scrollListener); //track the position of the list view to decide if new messages need to be loaded
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoading || !_hasMore || channelNotifier.value == null) {
      return;
    } //don't repeat the request if it's already in progress

    setState(() => _isLoading =
        true); //ensure that the request isn't called again while it's still loading

    try {
      final newMessages = await _apiService.getMessages(
        channelNotifier.value!.channelId, //get the current channel id
        _lastMessageId, //and the last message
      );

      //in case the user has navigated away from this page while the messages were being loaded
      if (!mounted || _currentChannelId != channelNotifier.value!.channelId) {
        return;
      }

      setState(() {
        if (newMessages.isNotEmpty) { //if new messages were loaded
          _messages.addAll(newMessages);
          _lastMessageId = newMessages.last.messageId;
          _hasMore = true;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Future<void> _loadInitialMessages(Channel channel) async {
    //if the user has changed the page before this message is loaded
    if (!mounted || _currentChannelId == channel.channelId) return;

    _currentChannelId = channel.channelId; // Update current channel ID

    //Clear the home page
    setState(() {
      _messages = [];
      _lastMessageId = null;
      _hasMore = true;
    });

    try {
      final messages = await _apiService.getMessages(
          channel.channelId, null); //load the latest 20 messages

      // Check if still on the same channel after fetch
      if (!mounted || _currentChannelId != channel.channelId) return;

      setState(() {
        _messages = messages;
        if (messages.isNotEmpty) {
          _lastMessageId = messages.last.messageId;
        }

        _hasMore =
            messages.length >= 20; //if the page isn't full, the page is empty
      });
      _connectWebSocket(channel);
    } catch (e) {
      if (mounted) {
        //if the user has navigated away don't setState.
        setState(() => _hasMore = false);
      }
    }
  }

  void _connectWebSocket(Channel channel) async {
    // Close existing connection before opening a new connection
    if (_webSocketChannel != null) {
      await _webSocketChannel!.sink.close();
    }

    // Check again if the current channel is still the target channel
    if (_currentChannelId != channel.channelId) return;

    _webSocketChannel = await _apiService.subscribe(channel.channelId);

    _webSocketChannel!.stream.listen(
      (data) {
        //If this message is for a different channel (if the user has just changed page and it hasn't been closed yet)
        if (!mounted || _currentChannelId != channel.channelId) {
          return;
        }
        final message = Message.fromJson(jsonDecode(data));
        setState(() => _messages.insert(
            0, message)); //add the message to the start of the messages.
      },
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket connection closed'),
    );
  }

  @override
  void dispose() async {
    _webSocketChannel?.sink.close(); //ensure the websocket is closed
    _scrollController.dispose(); //clear the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, //move the page up if the keyboard is displayed
      bottomSheet: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child:
            MessageBoxWidget(), //put the messaging box on the bottom for the user to send messages
      ),
      appBar: AppBar(actions: [
        IconButton( //add a button to navigate to the settings page on the top of the app
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          ),
        ),
      ]),
      drawer: const SizedBox(width: 200, child: ChannelSelector()), //a drawer on the side so the user can select channels
      body: Padding(
        padding: const EdgeInsets.only(bottom: 90), //prevent the message widgets from touching the edge of the screen
        child: ValueListenableBuilder( //rebuild the current messages if the current channel changes
          valueListenable: channelNotifier,
          builder: (context, channel, _) {
            if (channel != null &&
                (_messages.isEmpty || _currentChannelId != channel.channelId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) { //call this after the page has been rendered (otherwise this will throw an exception)
                _loadInitialMessages(channel);
              });
            }

            return Column( //display the messages of this channel
              children: [
                if (_isLoading && _messages.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Expanded(
                  child: _messages.isEmpty //if there are no messages to display
                      ? Center(
                          child: _isLoading
                              ? const CircularProgressIndicator() //if there are messages being loaded, display a progress indicator
                              : const Text("No messages found"), //if there are no messages and nothing is being loaded
                        )
                      : ListView.builder(
                          reverse: true, //display bottom to top to align with how instant messaging channels generally are
                          controller: _scrollController,
                          itemCount: _messages.length + (_hasMore ? 1 : 0), //add an extra invisible item so the user can scroll above the last message.
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return _hasMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(), //if there is more, display a progress indicator as the extra item
                                      ),
                                    )
                                  : const SizedBox.shrink(); //display an invisible box if there are no messages to be loaded
                            }
                            final message = _messages[index]; //get the message the user has scrolled to
                            return MessageWidget( //load the message widget
                              author: message.authorId,
                              content: message.content,
                              sendDate: message.sendDate,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
