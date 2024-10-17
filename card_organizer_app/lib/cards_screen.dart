import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;
  final Function onUpdate;

  CardsScreen({required this.folderId, required this.onUpdate});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isAddingCards = false;
  List<bool> _selectedCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final db = DatabaseHelper();
    final database = await db.database;

    List<Map<String, dynamic>> cards = await database.query(
      'Cards',
      where: 'folder_id = ?',
      whereArgs: [widget.folderId],
    );
    setState(() {
      _cards = cards;
      _selectedCards = List<bool>.filled(cards.length, false);
    });
  }

  String _getCardDisplay(String? name) {
    if (name == null) {
      return 'Unknown';
    }

    switch (name) {
      case 'Ace':
        return 'A';
      case 'King':
        return 'K';
      case 'Queen':
        return 'Q';
      case 'Jack':
        return 'J';
      default:
        return name;
    }
  }

  Future<void> _deleteCard(int cardId) async {
    final db = DatabaseHelper();
    final database = await db.database;

    await database.delete('Cards', where: 'id = ?', whereArgs: [cardId]);
    _loadCards();
    widget.onUpdate();
  }

  Future<void> _editCard(int cardId, String currentName) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Card'),
          content: TextField(
            controller: controller,
            decoration:
                InputDecoration(hintText: 'Enter a value (1-99 or A-Z)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String newValue = controller.text.trim();
                if (_isValidCardValue(newValue)) {
                  _updateCard(cardId, newValue);
                  Navigator.of(context).pop();
                } else {
                  _showMessage(
                      'Invalid input. Please enter a value from 1-99 or A-Z.');
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

  bool _isValidCardValue(String value) {
    final isDigit = int.tryParse(value);
    final isLetter = value.length == 1 && RegExp(r'^[A-Z]$').hasMatch(value);
    return (isDigit != null && isDigit >= 1 && isDigit <= 99) || isLetter;
  }

  Future<void> _updateCard(int cardId, String newValue) async {
    final db = DatabaseHelper();
    final database = await db.database;

    await database.update(
        'Cards',
        {
          'name': newValue,
        },
        where: 'id = ?',
        whereArgs: [cardId]);

    _loadCards();
    widget.onUpdate();
    _showMessage('Card updated successfully.');
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

  @override
  Widget build(BuildContext context) {
    String emoji;
    switch (widget.folderId) {
      case 1:
        emoji = '❤️';
        break;
      case 2:
        emoji = '♠️';
        break;
      case 3:
        emoji = '♦️';
        break;
      case 4:
        emoji = '♣️';
        break;
      default:
        emoji = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cards'),
        actions: [
          _isAddingCards
              ? TextButton(
                  onPressed: () => _toggleAddingCards(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _toggleAddingCards,
                ),
        ],
      ),
      body: _cards.isEmpty
          ? Center(child: Text('No cards in this folder.'))
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getCardDisplay(card['name']),
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () =>
                                            _editCard(card['id'], card['name']),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () =>
                                            _deleteCard(card['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                left: 16,
                                child: Text(
                                  emoji,
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              if (_isAddingCards)
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: Checkbox(
                                    value: _selectedCards[index],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _selectedCards[index] = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isAddingCards && _isAnyCardSelected()
          ? FloatingActionButton(
              onPressed: _addToFolder,
              child: Text(
                'Add',
                style: TextStyle(fontSize: 16),
              ),
            )
          : null,
    );
  }

  void _toggleAddingCards() {
    setState(() {
      _isAddingCards = !_isAddingCards;
      if (!_isAddingCards) {
        _selectedCards = List<bool>.filled(_cards.length, false);
      }
    });
  }

  bool _isAnyCardSelected() {
    return _selectedCards.any((selected) => selected);
  }

  void _addToFolder() {
    final selectedCount = _selectedCards.where((selected) => selected).length;

    if (selectedCount < 3) {
      _showMessage('You need at least 3 cards to add to this folder.');
    } else if (selectedCount > 6) {
      _showMessage('This folder can only hold 6 cards.');
    } else {
      _showFolderNameDialog();
    }
  }

  void _showFolderNameDialog() {
    final TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Folder Name'),
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

  Future<void> _createFolder(String folderName) async {
    final db = DatabaseHelper();
    final database = await db.database;

    int folderId =
        await database.insert('Folders', {'folder_name': folderName});

    for (int i = 0; i < _selectedCards.length; i++) {
      if (_selectedCards[i]) {
        await database.update(
            'Cards',
            {
              'folder_id': folderId,
            },
            where: 'id = ?',
            whereArgs: [_cards[i]['id']]);
      }
    }

    setState(() {
      _selectedCards = List<bool>.filled(_cards.length, false);
    });
    _loadCards();
    widget.onUpdate();
    _showMessage('Folder created and cards added successfully.');
  }
}
