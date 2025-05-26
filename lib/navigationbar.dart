import 'package:flutter/material.dart';
import 'package:patroltracking/Login/login.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/patrol/PatrolIncident.dart';
import 'package:patroltracking/patrol/completedWorkflow.dart';
import 'package:patroltracking/patrol/patrolMultimediaScreen.dart';
import 'package:patroltracking/patrol/patroldashboard.dart';
//import 'package:patroltracking/patrol/patrolEvent.dart';
import 'package:patroltracking/profile.dart';
import 'package:patroltracking/settings.dart';

class CustomDrawer extends StatelessWidget {
  final Map<String, dynamic> userdata;
  final String token;

  const CustomDrawer({required this.token, super.key, required this.userdata});

  @override
  Widget build(BuildContext context) {
    print("Token in CustomDrawer: $token");
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: userdata['imageUrl'].isNotEmpty
                      ? NetworkImage(userdata['imageUrl'])
                      : null,
                  child: userdata['imageUrl'] == null ||
                          userdata['imageUrl'].isEmpty
                      ? Icon(Icons.person,
                          size: 30, color: AppConstants.primaryColor)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${userdata['patrolGuardName']}',
                  style: AppConstants.drawerMiniHeaderStyle,
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', () {
            _navigateToScreen(
                context,
                PatrolDashboardScreen(
                  userdata: userdata,
                  token: token,
                ));
          }),
          _buildDrawerItem(context, Icons.perm_media, 'Multimedia', () {
            _navigateToScreen(
                context,
                PatrolMultimediaScreen(
                  checklistId: '',
                  token: token,
                  user: userdata,
                  mode: 'bymenu',
                ));
          }),
          _buildDrawerItem(context, Icons.person_2, 'Profile', () {
            _navigateToScreen(
                context,
                ProfileScreen(
                  user: userdata,
                  mode: '',
                  token: token,
                ));
          }),
          _buildDrawerItem(context, Icons.event_available, 'Workflows', () {
            _navigateToScreen(
                context,
                WorkflowScreen(
                  userdata: userdata,
                  token: token,
                ));
          }),
          _buildDrawerItem(context, Icons.settings, 'Settings', () {
            _navigateToScreen(
                context,
                SettingsScreen(
                  userdata: userdata,
                  token: token,
                ));
          }),
          _buildDrawerItem(context, Icons.power_settings_new_outlined, 'Logout',
              () {
            _showLogoutConfirmationDialog(context);
          }),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor),
      title: Text(title, style: AppConstants.normalFontStyle),
      onTap: onTap,
    );
  }
}
