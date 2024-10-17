import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_screen.dart';
import 'package:sqflite/sqflite.dart';

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final db = DatabaseHelper();
    final database = await db.database;

    List<Map<String, dynamic>> folders = await database.query('Folders');
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _resetDatabase() async {
    final db = DatabaseHelper();
    await db.resetDatabase();
    await _loadFolders();
  }

  Future<Map<String, dynamic>?> _getFirstCard(int folderId) async {
    final db = DatabaseHelper();
    final database = await db.database;

    List<Map<String, dynamic>> cards = await database.query(
      'Cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      limit: 1,
    );
    if (cards.isNotEmpty) {
      return cards.first;
    }
    return null;
  }

  Future<int> _getCardCount(int folderId) async {
    final db = DatabaseHelper();
    final database = await db.database;

    final count = await database
        .rawQuery('SELECT COUNT(*) FROM Cards WHERE folder_id = ?', [folderId]);
    return Sqflite.firstIntValue(count) ?? 0;
  }

  Future<void> _createFolder(String folderName) async {
    final db = DatabaseHelper();
    final database = await db.database;

    await database.insert('Folders', {'folder_name': folderName});
    _loadFolders();
  }

  Future<void> _deleteFolder(int folderId) async {
    final db = DatabaseHelper();
    final database = await db.database;

    await database.delete('Folders', where: 'id = ?', whereArgs: [folderId]);

    await database
        .delete('Cards', where: 'folder_id = ?', whereArgs: [folderId]);

    _loadFolders();
  }

  void _showDeleteConfirmation(int folderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: Text('Are you sure you want to delete this folder?'),
          actions: [
            TextButton(
              onPressed: () {
                _deleteFolder(folderId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showNewFolderDialog() {
    final TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  _createFolder(folderName);
                  Navigator.of(context).pop();
                } else {
                  _showMessage('Folder name cannot be empty.');
                }
              },
              child: Text('Create'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showEditFolderDialog(int folderId, String currentFolderName) {
    final TextEditingController folderNameController =
        TextEditingController(text: currentFolderName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  _updateFolder(folderId, folderName);
                  Navigator.of(context).pop();
                } else {
                  _showMessage('Folder name cannot be empty.');
                }
              },
              child: Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateFolder(int folderId, String folderName) async {
    final db = DatabaseHelper();
    final database = await db.database;

    await database.update(
      'Folders',
      {'folder_name': folderName},
      where: 'id = ?',
      whereArgs: [folderId],
    );
    _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: _folders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardsScreen(
                          folderId: folder['id'],
                          onUpdate: () {
                            _loadFolders();
                          },
                        ),
                      ),
                    );

                    if (result == true) {
                      _loadFolders();
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    margin: EdgeInsets.all(10.0),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  folder['folder_name'] == 'Hearts'
                                      ? '❤️'
                                      : folder['folder_name'] == 'Spades'
                                          ? '♠️'
                                          : folder['folder_name'] == 'Diamonds'
                                              ? '♦️'
                                              : '♣️',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                folder['folder_name'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _getFirstCard(folder['id']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasData &&
                                    snapshot.data != null) {
                                  final card = snapshot.data!;
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 50,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${card['name'] == 'Ace' ? 'A' : card['name']}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return SizedBox(height: 70);
                                }
                              },
                            ),
                          ],
                        ),
                        FutureBuilder<int>(
                          future: _getCardCount(folder['id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox.shrink();
                            } else {
                              return Positioned(
                                top: 10,
                                right: 10,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    '${snapshot.data}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.black),
                            onPressed: () {
                              _showEditFolderDialog(
                                  folder['id'], folder['folder_name']);
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.black),
                            onPressed: () {
                              _showDeleteConfirmation(folder['id']);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewFolderDialog,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetDatabase,
              tooltip: 'Reset to Default',
            ),
          ],
        ),
      ),
    );
  }
}
