import 'package:flutter/material.dart';
import 'package:nearchat/data/notifiers.dart';
import 'package:nearchat/models/channel_model.dart';
import 'package:nearchat/server/api_service.dart';

class ChannelSelector extends StatefulWidget {
  const ChannelSelector({super.key});

  @override
  State<ChannelSelector> createState() => _ChannelSelectorState();
}

class _ChannelSelectorState extends State<ChannelSelector> {
  bool _isLoading = false;
  late List<Channel> channels;

  String?
      _errored; //Track any error that the api might have returned to show the user.

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchChannels();
  }

  Future<void> fetchChannels() async {
    //Don't start fetching channels while a fetch is already in progress
    if (_isLoading) {
      return;
    }

    //Clear any error messages, and display to the user that it's loading while also ensuring the method isn't called again.
    setState(() {
      _isLoading = true;
      _errored = null;
    });

    //Get the channels from the API, load them into the class.
    try {
      channels = await _apiService.getChannels();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errored = e.toString(); //Display an error messages
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errored != null
              ? Center(child: Text(_errored!))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    return FilledButton(
                      child: Text(channels[index].name),
                      onPressed: () {
                        channelNotifier.value = channels[
                            index]; //Inform all other pages what channel was selected
                        Navigator.pop(context); //Remove the channel selector
                      },
                    );
                  }),
    );
  }
}
