import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/navigationbar.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController mobileController;
  late TextEditingController locationController;
  String profileImage = '';

  @override
  void initState() {
    super.initState();

    // Initialize with real user data from the widget.user map
    nameController =
        TextEditingController(text: widget.user['patrolGuardName'] ?? '');
    emailController = TextEditingController(text: widget.user['email'] ?? '');
    mobileController =
        TextEditingController(text: widget.user['mobileNumber'] ?? '');
    locationController =
        TextEditingController(text: widget.user['companyCode'] ?? '');
    profileImage = widget.user['imageUrl'] ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = pickedFile.path;
      });
    }
  }

  // void _saveProfile() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Profile updated (not saved)")),
  //   );
  // }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppConstants.primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Profile", style: AppConstants.headingStyle),
      ),
      drawer: CustomDrawer(
        token: '', // You can pass token if needed
        userdata: widget.user,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                backgroundImage: profileImage.isNotEmpty
                    ? (profileImage.startsWith('http')
                        ? NetworkImage(profileImage) as ImageProvider
                        : FileImage(File(profileImage)))
                    : null,
                child: profileImage.isEmpty
                    ? Icon(Icons.person,
                        size: 50, color: AppConstants.primaryColor)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            // Text("Tap to change profile picture",
            //     style: TextStyle(fontSize: 12, color: AppConstants.tabHeader)),
            const SizedBox(height: 20),
            _buildTextField(label: "Name", controller: nameController),
            const SizedBox(height: 10),
            _buildTextField(
                label: "Email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _buildTextField(
                label: "Mobile Number",
                controller: mobileController,
                keyboardType: TextInputType.phone,
                readOnly: true),
            const SizedBox(height: 10),
            _buildTextField(
                label: "Location",
                controller: locationController,
                readOnly: true),
            const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: _saveProfile,
            //   child: Text("Save Changes",
            //       style: AppConstants.selectedButtonFontStyle),
            //   style: ElevatedButton.styleFrom(
            //       minimumSize: const Size(double.infinity, 50)),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        labelStyle: AppConstants.boldPurpleFontStyle,
      ),
      readOnly: readOnly,
      style: AppConstants.normalPurpleFontStyle,
      keyboardType: keyboardType,
    );
  }
}
