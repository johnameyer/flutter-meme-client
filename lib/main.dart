import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      home: Scaffold(body: MemeListView()),
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
  Widget build(BuildContext context) =>
      PagedListView<String?, dynamic>.separated(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<dynamic>(
          itemBuilder: (context, item, index) =>
              _buildRow(item as Map<String, dynamic>),
        ),
        separatorBuilder: (context, index) => const Divider(),
      );

  Widget _buildRow(Map<String, dynamic> o) {
    return Image.network(o['data']['url']);
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
