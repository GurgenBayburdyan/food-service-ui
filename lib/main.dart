import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(FoodServiceApp());
}

class FoodServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal.shade600,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
        cardColor: Colors.white,
      ),
      home: FoodHomePage(),
    );
  }
}

class FoodHomePage extends StatefulWidget {
  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  List categories = [];
  List dishes = [];
  final categoryUrl = 'http://localhost:8080/categories';
  final dishUrl = 'http://localhost:8080/dishes';
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final imgController = TextEditingController();
  final categoryController = TextEditingController();
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final categoriesResponse = await http.get(Uri.parse(categoryUrl));
    final dishesResponse = await http.get(Uri.parse(dishUrl));

    setState(() {
      categories = json.decode(categoriesResponse.body);
      dishes = json.decode(dishesResponse.body);
    });
  }

  Future<void> addCategory(String name) async {
    await http.post(
      Uri.parse(categoryUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );

    fetchData();
  }

  Future<void> addDish(String name, int price, String description,
      String imageUrl, int categoryId) async {
    await http.post(
      Uri.parse(dishUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'categoryId': categoryId
      }),
    );

    fetchData();
  }

  void showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              )),
          ElevatedButton(
            onPressed: () {
              addCategory(categoryController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void showAddDishDialog() {
    int selectedCategory = categories.isNotEmpty ? categories[0]['id'] : 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Dish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextField(
                  controller: imgController,
                  decoration: const InputDecoration(labelText: 'Image URL')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (val) =>
                    setState(() => selectedCategory = val ?? selectedCategory),
                items: categories.map<DropdownMenuItem<int>>((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              )),
          ElevatedButton(
            onPressed: () {
              addDish(
                nameController.text,
                int.tryParse(priceController.text) ?? 0,
                descriptionController.text,
                imgController.text,
                selectedCategory,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDishCard(
      {required String title,
      required int price,
      required String image,
      required String description}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(
              image,
              fit: BoxFit.cover,
              height: 150,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('\$$price',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDishes = selectedCategoryId == null
        ? dishes
        : dishes
            .where((dish) => dish['categoryId'] == selectedCategoryId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Service'),
        actions: [
          IconButton(
              onPressed: showAddCategoryDialog, icon: Icon(Icons.category)),
          IconButton(onPressed: showAddDishDialog, icon: Icon(Icons.fastfood)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            const Text('Dishes',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map<Widget>((cat) {
                  final isSelected = selectedCategoryId == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat['name']),
                      selected: isSelected,
                      selectedColor: Colors.teal.shade600,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCategoryId = isSelected ? null : cat['id'];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: filteredDishes
                  .map((dish) => buildDishCard(
                        title: dish['name'],
                        price: dish['price'],
                        image: dish['imageUrl'],
                        description: dish['description'],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
