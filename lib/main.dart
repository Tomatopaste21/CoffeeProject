import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(CoffeeRankerApp());
}

class CoffeeRankerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Ranker',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Color(0xFFF3E5AB),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.brown[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.brown[600],
        ),
      ),
      home: CoffeeShopListScreen(),
    );
  }
}

class CoffeeShop {
  String name;
  double price;
  double rating;
  String notes;

  CoffeeShop({
    required this.name,
    required this.price,
    required this.rating,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'rating': rating,
        'notes': notes,
      };

  factory CoffeeShop.fromJson(Map<String, dynamic> json) => CoffeeShop(
        name: json['name'],
        price: json['price'],
        rating: json['rating'],
        notes: json['notes'],
      );
}

class CoffeeShopListScreen extends StatefulWidget {
  @override
  _CoffeeShopListScreenState createState() => _CoffeeShopListScreenState();
}

class _CoffeeShopListScreenState extends State<CoffeeShopListScreen> with SingleTickerProviderStateMixin {
  List<CoffeeShop> coffeeShops = [];
  String sortBy = 'Name';

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoffeeShops();
    });
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addCoffeeShop(CoffeeShop coffeeShop) {
    setState(() {
      coffeeShops.add(coffeeShop);
      _saveCoffeeShops();
    });
  }

  void _editCoffeeShop(int index, CoffeeShop coffeeShop) {
    setState(() {
      coffeeShops[index] = coffeeShop;
      _saveCoffeeShops();
    });
  }

  void _deleteCoffeeShop(int index) {
    setState(() {
      coffeeShops.removeAt(index);
      _saveCoffeeShops();
    });
  }

  void _saveCoffeeShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = coffeeShops.map((shop) => json.encode(shop.toJson())).toList();
      await prefs.setStringList('coffeeShops', data);
    } catch (e) {
      print('Failed to save coffee shops: $e');
    }
  }

  void _loadCoffeeShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('coffeeShops') ?? [];
      setState(() {
        coffeeShops = data.map((item) => CoffeeShop.fromJson(json.decode(item))).toList();
      });
    } catch (e) {
      print('Failed to load coffee shops: $e');
    }
  }

  void _sortCoffeeShops() {
    setState(() {
      if (sortBy == 'Name') {
        coffeeShops.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else if (sortBy == 'Price') {
        coffeeShops.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortBy == 'Rating') {
        coffeeShops.sort((b, a) => a.rating.compareTo(b.rating)); // High to low
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _sortCoffeeShops();

    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Ranker'),
        actions: [
          DropdownButton<String>(
            value: sortBy,
            dropdownColor: Colors.brown[300],
            iconEnabledColor: Colors.white,
            underline: SizedBox(),
            items: ['Name', 'Price', 'Rating'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  'Sort by $value',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                sortBy = newValue!;
              });
            },
          ),
        ],
      ),
      body: coffeeShops.isEmpty
          ? Center(
              child: Text(
                'No coffee shops added yet!',
                style: TextStyle(fontSize: 18, color: Colors.brown[900]),
              ),
            )
          : ListView.builder(
              itemCount: coffeeShops.length,
              itemBuilder: (context, index) {
                final shop = coffeeShops[index];
                return Dismissible(
                  key: Key(shop.name + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteCoffeeShop(index);
                  },
                  child: ScaleTransition(
                    scale: Tween(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
                    ),
                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        title: Text(
                          shop.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('Price: \$${shop.price.toStringAsFixed(2)}'),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: shop.rating,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.brown,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                                SizedBox(width: 8),
                                Text('${shop.rating.toStringAsFixed(1)}/5'),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('Notes: ${shop.notes}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteCoffeeShop(index);
                          },
                        ),
                        onTap: () async {
                          final editedShop = await Navigator.push<CoffeeShop>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddCoffeeShopScreen(coffeeShop: shop),
                            ),
                          );
                          if (editedShop != null) {
                            _editCoffeeShop(index, editedShop);
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _controller.forward(from: 0);
          final newShop = await Navigator.push<CoffeeShop>(
            context,
            MaterialPageRoute(builder: (context) => AddCoffeeShopScreen()),
          );
          if (newShop != null) {
            _addCoffeeShop(newShop);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddCoffeeShopScreen extends StatefulWidget {
  final CoffeeShop? coffeeShop;

  AddCoffeeShopScreen({this.coffeeShop});

  @override
  _AddCoffeeShopScreenState createState() => _AddCoffeeShopScreenState();
}

class _AddCoffeeShopScreenState extends State<AddCoffeeShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String notes;
  late double price;
  late double rating;

  @override
  void initState() {
    super.initState();
    name = widget.coffeeShop?.name ?? '';
    notes = widget.coffeeShop?.notes ?? '';
    price = widget.coffeeShop?.price ?? 0.0;
    rating = widget.coffeeShop?.rating ?? 3.0;
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.coffeeShop != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Coffee Shop' : 'Add Coffee Shop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Coffee Shop Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: price == 0.0 ? '' : price.toString(),
                decoration: InputDecoration(
                  labelText: 'Coffee Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter price';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
                onSaved: (value) => price = double.parse(value!),
              ),
              SizedBox(height: 16),
              Text(
                'Rating',
                style: TextStyle(fontSize: 16),
              ),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.brown,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: notes,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onSaved: (value) => notes = value ?? '',
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final newShop = CoffeeShop(
                      name: name,
                      price: price,
                      rating: rating,
                      notes: notes,
                    );
                    Navigator.pop(context, newShop);
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Coffee Shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
