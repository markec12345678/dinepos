import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menuItem.dart';
import '../provider/MenuProvider.dart';

import '../utils/const.dart';
import '../utils/image_storage.dart';

class AddMenuItem extends StatefulWidget {
  @override
  _AddMenuItemState createState() => _AddMenuItemState();
}

class _AddMenuItemState extends State<AddMenuItem> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  // Image picker related variables
  File? _imageFile;

  String category = 'Vegetable'; // Default category
  String? subCategory; // Subcategory for non-vegetable items
  String unitType = 'Full'; // Default unit type (Full)

  // Method to clear all fields
  void clearFields() {

    setState(() {
      _nameController.clear();
      _priceController.clear();
      _offerPriceController.clear();
      _stockController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      category = 'Vegetable';
      subCategory = null;
      unitType = 'Full'; // Reset unit type to default
       // Reset image selection
    });
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _nameController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  Future<Directory> getWritableDirectory() async {
    return ImageStorage.getWritableDirectory();
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



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: secondaryColor,
        shadowColor: bgColor,

      title: Text('Add Items/Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField('Item Name',Icons.barcode_reader, _nameController),
              Row(
                children: [
                  Expanded(child: _buildNumberFormField('Price',Icons.price_change_outlined, _priceController)),

                  Expanded(child: _buildNumberFormField('Offer',Icons.local_offer, _offerPriceController)),
                ],
              ),
              _buildNumberFormField('Stock',Icons.remove_shopping_cart, _stockController),
              _builddescriptionFormField('Description', _descriptionController),

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
                  child: _imageFile == null
                      ? Center(child: Text("Tap to select an image"))
                      : Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Category: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              // Category Dropdown

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Vegetable Option (Green when selected)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            category = 'Vegetable';  // Set to Vegetable when tapped
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: category == 'Vegetable' ? Colors.green : Colors.red, // Green if selected, Red if not
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,  // Icon for Vegetable
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Vegetable",  // Text for Vegetable
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),
                    // Non-Vegetable Option (Green when selected)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            category = 'Non-Vegetable';  // Set to Non-Vegetable when tapped
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: category == 'Non-Vegetable' ? Colors.green : Colors.red, // Green if selected, Red if not
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_dining,  // Icon for Non-Vegetable
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Non-Veg",  // Text for Non-Vegetable
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (category == 'Non-Vegetable') ...[Text(
                'Sub Category: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
],
              if (category == 'Non-Vegetable') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Radio button for 'Beef'
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Beef',
                          groupValue: subCategory,
                          onChanged: (value) {
                            setState(() {
                              subCategory = value!;
                            });
                          },
                        ),
                        Text('Beef'),
                      ],
                    ),

                    // Radio button for 'Chicken'
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Chicken',
                          groupValue: subCategory,
                          onChanged: (value) {
                            setState(() {
                              subCategory = value!;
                            });
                          },
                        ),
                        Text('Chicken'),
                      ],
                    ),

                    // Radio button for 'Fish'
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Fish',
                          groupValue: subCategory,
                          onChanged: (value) {
                            setState(() {
                              subCategory = value!;
                            });
                          },
                        ),
                        Text('Fish'),
                      ],
                    ),
                  ],
                ),
              ],

              Text(
                'Unit Type: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              // Unit Type Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Radio<String>(
                        value: 'Full',
                        groupValue: unitType,
                        onChanged: (value) {
                          setState(() {
                            unitType = value!;
                          });
                        },
                      ),
                      Text('Full'),
                    ],
                  ),

                  // Radio button for 'Half'
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Half',
                        groupValue: unitType,
                        onChanged: (value) {
                          setState(() {
                            unitType = value!;
                          });
                        },
                      ),
                      Text('Half'),
                    ],
                  ),

                  // Radio button for 'Kg'
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Kg',
                        groupValue: unitType,
                        onChanged: (value) {
                          setState(() {
                            unitType = value!;
                          });
                        },
                      ),
                      Text('Kg'),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Piece',
                        groupValue: unitType,
                        onChanged: (value) {
                          setState(() {
                            unitType = value!;
                          });
                        },
                      ),
                      Text('Piece'),
                    ],
                  ),
                ],
              ),



            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // id=0 lets the provider assign a stable auto-increment id
              // (replaces the previous Random().nextInt(100000) collision risk).
              final newMenuItem = MenuItem(
                id: 0,
                itemName: _nameController.text,
                price: double.tryParse(_priceController.text) ?? 0.0,
                offerPrice: double.tryParse(_offerPriceController.text) ?? 0.0,
                stock: int.tryParse(_stockController.text) ?? 0,
                category: category,
                subCategory: subCategory,
                unitType: unitType,
                description: _descriptionController.text,
                imageUrl: _imageFile?.path ?? "", // Save the image path
              );

              final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
              menuProvider.addMenuItem(newMenuItem);
              clearFields(); // Clear fields without closing the dialog
            }
          },
          child: Text('Add Item'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  // Helper functions to build form fields
  Widget _buildTextFormField(String label,IconData? icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon, // Icon to indicate input field purpose
            color: primaryColor,
          ),
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey[600], // Subtle color for the label
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto, // Animates label
          filled: true,
          fillColor: secondary2Color, // Light background color
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // Rounded edges
            borderSide: BorderSide.none, // Remove border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: primaryColor, // Focused border color
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.red, // Error border color
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.red, // Focused error border color
              width: 2,
            ),
          ),
        ),

        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
  Widget _builddescriptionFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        maxLines: null, // Makes the text field grow as the user types
        minLines: 1, // Minimum number of lines
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          hintText: "Enter description...",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // Rounded edges
            borderSide: BorderSide.none, // Remove border
          ), // Removes default border
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey[600], // Subtle color for the label
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto, // Animates label
          filled: true,
          fillColor: secondary2Color, // Light background color


          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: primaryColor, // Focused border color
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.red, // Error border color
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.red, // Focused error border color
              width: 2,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildNumberFormField(String label,IconData? icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 250, // Set the width here
        child: TextFormField(
          keyboardType: TextInputType.number,
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 16,
              color: Colors.grey[600], // Subtle color for the label
              fontWeight: FontWeight.w500,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto, // Animates label
            filled: true,
            fillColor: secondary2Color, // Light background color
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // Rounded edges
              borderSide: BorderSide.none, // Remove border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: primaryColor, // Focused border color
                width: 2,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.red, // Error border color
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.red, // Focused error border color
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              icon, // Icon to indicate input field purpose
              color: primaryColor,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (!RegExp(r'^\d+$').hasMatch(value)) {
              return 'Please enter only numbers';
            }
            return null;
          },
        ),
      ),
    );
  }
}
