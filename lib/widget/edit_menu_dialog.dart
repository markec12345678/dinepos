import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/MenuProvider.dart'; // Import MenuProvider
import '../utils/image_storage.dart';

class EditMenuItemDialog extends StatefulWidget {
  final int id; // The Hive index of the menu item
  final String name;
  final double price;
  final double? offerPrice;
  final int stock;
  final String category;
  final String? subCategory;
  final String? unitType;
  final String? imageUrl; // Added image URL as a parameter
  final String? description; // Added description as a parameter
  const EditMenuItemDialog({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.stock,
    required this.category,
    this.subCategory,
    required this.unitType,
    this.imageUrl, // Add image URL as parameter
    this.description, // Add description parameter
  });

  @override
  _EditMenuItemDialogState createState() => _EditMenuItemDialogState();
}

class _EditMenuItemDialogState extends State<EditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late double price;
  late double? offerPrice;
  late int stock;
  late String category;
  String? subCategory;
  late String unitType;
  File? _imageFile;
  late String description;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    price = widget.price;
    offerPrice = widget.offerPrice;
    stock = widget.stock;
    category = widget.category;
    subCategory = widget.subCategory;
    unitType = widget.unitType ?? 'Full';
    description = widget.description ?? ''; // Initialize description
    final url = widget.imageUrl ?? '';
    _imageFile = url.startsWith('http') ? null : (url.isNotEmpty ? File(url) : null);
  }

  // Method to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        String? filePath = result.files.single.path;

        if (filePath != null) {
          final originalFile = File(filePath);

          if (await originalFile.exists()) {
            final fileName = result.files.single.name;
            final targetFilePath = await ImageStorage.copyPickedImage(filePath, fileName);

            setState(() {
              _imageFile = targetFilePath != null ? File(targetFilePath) : null;
            });
            debugPrint('File copied to: $targetFilePath');
          } else {
            throw Exception('File not found at path: $filePath');
          }
        } else {
          throw Exception('Selected file path is null.');
        }
      } else {
        debugPrint('No file selected.');
      }
    } catch (e) {
      debugPrint('An error occurred while picking the file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image pick failed: $e')),
        );
      }
    }
  }

  // Function to update the menu item via MenuProvider
  void _updateMenuItem(MenuItemsProvider menuProvider) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      menuProvider.updateMenuItem(
        widget.id,
        name,
        price,
        offerPrice,
        stock,
        category,
        subCategory,
        _imageFile?.path,
        description,
        unitType: unitType,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      content: SingleChildScrollView(

        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Menu Item",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Name is required' : null,
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: price.toString(),
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || double.tryParse(value) == null
                      ? 'Enter a valid price'
                      : null,
                  onSaved: (value) => price = double.parse(value!),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: offerPrice?.toString(),
                  decoration: InputDecoration(labelText: 'Offer Price (Optional)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => offerPrice = value?.isEmpty ?? true
                      ? null
                      : double.parse(value!),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: stock.toString(),
                  decoration: InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || int.tryParse(value) == null
                      ? 'Enter a valid stock quantity'
                      : null,
                  onSaved: (value) => stock = int.parse(value!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: ['Vegetable', 'Non-Vegetable']
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
                const SizedBox(height: 10),
                if (category == 'Non-Vegetable')
                  DropdownButtonFormField<String>(
                    value: subCategory,
                    decoration: InputDecoration(labelText: 'Subcategory'),
                    items: ['Beef', 'Chicken', 'Fish']
                        .map((sub) => DropdownMenuItem(
                      value: sub,
                      child: Text(sub),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => subCategory = value),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Description is required' : null,
                  onSaved: (value) => description = value!,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: unitType,
                  decoration: const InputDecoration(labelText: 'Unit Type'),
                  items: const ['Full', 'Half', 'Kg', 'Piece']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) => setState(() => unitType = value ?? 'Full'),
                ),
                const SizedBox(height: 20),

                // Image Picker Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _widgetImage(_imageFile, widget.imageUrl),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Access MenuProvider using context and update the item
                        final menuProvider =
                        Provider.of<MenuItemsProvider>(context, listen: false);
                        _updateMenuItem(menuProvider);
                      },
                      child: Text("Update"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
Widget _widgetImage(File? imageFile, String? imageUrl) {
  // Check if imageFile is null or empty path
  if (imageFile == null || imageFile.path.isEmpty) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      return const Center(child: Text("Tap to update an image"));
    }
  } else {
    return Image.file(imageFile, fit: BoxFit.cover);
  }
}
