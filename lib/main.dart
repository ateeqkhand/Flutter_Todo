import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const url = 'http://192.168.100.23:3000/api/courses/';
Future<List<Album>> fetchAlbums() async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((json) => Album.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load albums');
  }
}

Future<Album> deleteAlbum(String id) async {
  final response = await http.delete(Uri.parse('$url$id'));
  if (response.statusCode == 200) {
    return Album.empty();
  } else {
    throw Exception('Failed to delete album.');
  }
}

Future<Album> createAlbum(String title) async {
  final response = await http.post(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'name': title}),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to create album.');
  }
}

Future<Album> updateAlbum(String title, String id) async {
  final response = await http.put(
    Uri.parse('$url$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'name': title}),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to update album.');
  }
}

class Album {
  final int id;
  final String name;

  const Album({required this.id, required this.name});
  Album.empty()
      : id = 0,
        name = '';

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  void refreshAlbums() {
    setState(() {
      futureAlbums = fetchAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomMaterialApp(
        futureAlbums: futureAlbums, onRefresh: refreshAlbums);
  }
}

class CustomMaterialApp extends StatefulWidget {
  const CustomMaterialApp({
    super.key,
    required this.futureAlbums,
    required this.onRefresh,
  });

  final Future<List<Album>> futureAlbums;
  final VoidCallback onRefresh;

  @override
  State<CustomMaterialApp> createState() => _CustomMaterialAppState();
}

class _CustomMaterialAppState extends State<CustomMaterialApp> {
  bool isUpdating = false;
  String? updatingAlbumId;
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      if (isUpdating && updatingAlbumId != null) {
        await updateAlbum(_controller.text, updatingAlbumId!);
        isUpdating = false;
        updatingAlbumId = null;
      } else {
        await createAlbum(_controller.text);
      }
      _controller.clear();
      setState(() {
        _isLoading = false;
      });
      widget.onRefresh();
    }
  }

  Future<void> _handleDelete(String id) async {
    setState(() {
      _isLoading = true;
    });
    await deleteAlbum(id);
    setState(() {
      _isLoading = false;
    });
    widget.onRefresh();
  }

  Future<void> _handleEdit(Album album) async {
    setState(() {
      _controller.text = album.name;
      isUpdating = true;
      updatingAlbumId = album.id.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        drawer: const Drawer(),
        appBar: AppBar(
          title: const Text('Todo App'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter a Todo',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: Text(isUpdating ? "Update" : "Submit"),
              ),
              Expanded(
                child: FutureBuilder<List<Album>>(
                  future: widget.futureAlbums,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    } else if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final album = snapshot.data![index];
                          return ListTile(
                            title: Center(
                              child: SingleChildScrollView(
                                child: Container(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width, 
                                  height:
                                      70, 
                                  margin: const EdgeInsets.symmetric(
                                      vertical:
                                          0,),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          10), // Padding inside the container
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, 
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        // manage text in left side and if more then one line put it to the next line.
                                        child: Text(
                                          "${index + 1}: ${album.name}",
                                          style:
                                              const TextStyle(fontSize: 16.0),
                                          overflow: TextOverflow
                                              .ellipsis,
                                          maxLines:
                                              5, 
                                        ),
                                      ),
                                      // both button right side 
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => _handleDelete(
                                                    album.id.toString()),
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                          ),
                                          IconButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => _handleEdit(album),
                                            icon: const Icon(
                                                Icons.drive_file_rename_outline,
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const Text('No data found.');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
