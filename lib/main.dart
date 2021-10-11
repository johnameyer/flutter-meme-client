import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Browser',
      home: Scaffold(
        appBar: AppBar(title: const Text('Meme Browser')),
        body: MemeListView(),
      ),
    );
  }
}

class RedditData {
  String after;
  List<dynamic> children;

  RedditData({required this.after, required this.children});
}

Future<RedditData> getMemes(String? token) async {
  final url = 'https://www.reddit.com/r/dankmemes/top.json' +
      (token != null ? '?after=' + token : '');
  var jsonString = await http.read(Uri.parse(url));
  var payload = jsonDecode(jsonString)['data'];
  return RedditData(
      after: payload['after'],
      children: payload['children']
          .where((i) =>
              i['data']['url'] != null && !i['data']['url'].contains('.gif'))
          .toList());
}

class MemeListView extends StatefulWidget {
  @override
  _MemeListViewState createState() => _MemeListViewState();
}

class _MemeListViewState extends State<MemeListView> {
  final _biggerFont = const TextStyle(fontSize: 18.0);

  final PagingController<String?, dynamic> _pagingController =
      PagingController(firstPageKey: null);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(String? pageKey) async {
    try {
      final data = await getMemes(pageKey);
      final newItems = data.children;
      _pagingController.appendPage(newItems, data.after);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) => PagedListView<String?, dynamic>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<dynamic>(
        itemBuilder: (context, item, index) =>
            _buildRow(item as Map<String, dynamic>),
      ));

  Widget _buildRow(Map<String, dynamic> o) {
    return GestureDetector(
      child: Wrap(
        children: [
          Card(
            child: Container(
              child: Image.network(o['data']['url'], fit: BoxFit.contain),
              constraints: BoxConstraints.loose(Size(
                MediaQuery.of(context).size.width,
                2 * MediaQuery.of(context).size.height / 3,
              )),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),
        ],
        alignment: WrapAlignment.center,
      ),
      onLongPress: () async {
        var shared = false;
        if(Platform.isAndroid || Platform.isIOS) {
          try {
            var response = await http.get(Uri.parse(o['data']['url']));
            final directory = (await getTemporaryDirectory()).path;
            final path = '$directory/cache.png';
            File imgFile = File(path);
            imgFile.writeAsBytesSync(response.bodyBytes);
            await Share.shareFiles([path]);
            shared = true;
          } catch (e, t) {
            print(e);
            print(t);
          }
        }
        if(!shared) {
          print(o['data']['url']);
          await Share.share(o['data']['url']);
        }
      },
    );
    //   ListTile(
    // title: Text(
    //   o['data']['title'],
    //   style: _biggerFont,
    // ),
    // );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
