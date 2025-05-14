import 'package:flutter/material.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/models/checklist.dart';
import 'package:patroltracking/patrol/patrolChecklistScan.dart';
import 'package:patroltracking/patrol/patrolMultimediaScreen.dart';
import 'package:patroltracking/patrol/patroldashboard.dart';
import 'package:patroltracking/services/api_service.dart';

class PatrolEventCheckScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> userdata;
  final String token;
  final String eventtitle;
  const PatrolEventCheckScreen({
    super.key,
    required this.userdata,
    required this.token,
    required this.eventId,
    required this.eventtitle,
  });

  @override
  _PatrolEventCheckScreenState createState() => _PatrolEventCheckScreenState();
}

class _PatrolEventCheckScreenState extends State<PatrolEventCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChecklists = [];
  List<Map<String, dynamic>> _filteredChecklists = [];
  final Map<String, bool> _selectedChecklists = {};
  bool _isLoading = true;
  //late Future<List<EventChecklistGroup>> _checklistsFuture;
  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  void _loadChecklists() async {
    try {
      final checklists = await ApiService.fetchWorkflowPatrolChecklists(
        workflowId: widget.eventId,
        patrolId: widget.userdata['id'],
        token: widget.token,
      );
      setState(() {
        _allChecklists = checklists;
        _filteredChecklists = List.from(checklists);
        for (var item in checklists) {
          final checklistId = item['checklistId'];
          _selectedChecklists[checklistId] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }
  }

  void _filterChecklists(String query) {
    setState(() {
      _filteredChecklists = _allChecklists
          .where((item) =>
              item['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sendChecklists() async {
    final selected = _selectedChecklists.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No checklist selected")),
      );
      return;
    }

    // Step 1: Complete selected checklists
    final message = await ApiService.completeChecklists(selected, widget.token);

    if (message != null) {
      // Step 2: Call completeWorkflow if checklists update successfully
      final workflowCompleted = await ApiService.completeWorkflow(
        widget.eventId,
        widget.token,
      );

      if (workflowCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Workflow completed successfully")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatrolDashboardScreen(
              userdata: widget.userdata,
              token: widget.token,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Checklists updated, but failed to complete workflow")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update checklists.")),
      );
    }
  }

  void _updateChecklist(String checklistId) async {
    try {
      final scanEndDate =
          await ApiService.updateScanEndTime(checklistId, widget.token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checklist-$checklistId submitted')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.eventtitle, style: AppConstants.headingStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.primaryColor),
          onPressed: () async {
            // Call your API before navigating back
            await ApiService.completeWorkflow(widget.eventId, widget.token);

            // Then navigate back
            //Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PatrolDashboardScreen(
                  userdata: widget.userdata,
                  token: widget.token,
                ),
              ),
            );
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelStyle: AppConstants.normalPurpleFontStyle,
                      labelText: "Search Checklist",
                      prefixIcon:
                          Icon(Icons.search, color: AppConstants.primaryColor),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterChecklists,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _filteredChecklists.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      "No checklist to display",
                                      style: AppConstants.normalPurpleFontStyle,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _filteredChecklists.length,
                                  itemBuilder: (context, index) {
                                    final checklist =
                                        _filteredChecklists[index];
                                    final checklistId =
                                        checklist['checklistId'] ?? '';
                                    final title = checklist['title'] ?? '';
                                    final isScanned =
                                        checklist['isScanned'] ?? false;
                                    final isCompleted =
                                        checklist['isCompleted'] ?? false;

                                    return Card(
                                      elevation: 2,
                                      margin: EdgeInsets.symmetric(vertical: 6),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0, vertical: 4),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedChecklists[
                                                      checklistId] ??
                                                  false,
                                              onChanged: null,
                                            ),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: AppConstants
                                                    .normalPurpleFontStyle,
                                              ),
                                            ),

                                            // QR SCANNER ICON
                                            IconButton(
                                              icon: Icon(
                                                Icons.qr_code_scanner,
                                                color: (!isCompleted)
                                                    ? AppConstants.primaryColor
                                                    : Colors.grey,
                                              ),
                                              onPressed: (!isCompleted)
                                                  ? () {
                                                      final locationCode =
                                                          checklist[
                                                                  'locationCode'] ??
                                                              '';

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PatrolChecklistScanScreen(
                                                            checklistId:
                                                                checklistId,
                                                            scannerlocation:
                                                                locationCode,
                                                            user:
                                                                widget.userdata,
                                                            token: widget.token,
                                                          ),
                                                        ),
                                                      );

                                                      setState(() {
                                                        checklist['isScanned'] =
                                                            true;
                                                      });
                                                    }
                                                  : null,
                                            ),

                                            // MEDIA ICON
                                            IconButton(
                                              icon: Icon(
                                                Icons.perm_media,
                                                color: (isScanned &&
                                                        !isCompleted)
                                                    ? AppConstants.primaryColor
                                                    : Colors.grey,
                                              ),
                                              onPressed: (isScanned &&
                                                      !isCompleted)
                                                  ? () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PatrolMultimediaScreen(
                                                            checklistId:
                                                                checklistId,
                                                            user:
                                                                widget.userdata,
                                                            token: widget.token,
                                                            mode: 'notbymenu',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                            ),

                                            // CHECK ICON
                                            IconButton(
                                              icon: Icon(
                                                Icons.check,
                                                color: (isScanned)
                                                    ? AppConstants.primaryColor
                                                    : Colors.grey,
                                              ),
                                              onPressed: (isScanned &&
                                                      !isCompleted)
                                                  ? () {
                                                      _updateChecklist(
                                                          checklistId);
                                                      setState(() {
                                                        checklist[
                                                                'isCompleted'] =
                                                            true;
                                                        _selectedChecklists[
                                                            checklistId] = true;
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.send,
                                color: AppConstants.primaryColor),
                            label: Text(
                              "Send",
                              style: AppConstants.selectedButtonFontStyle,
                            ),
                            onPressed: _sendChecklists,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
