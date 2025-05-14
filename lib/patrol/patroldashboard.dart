import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/models/checklist.dart';
import 'package:patroltracking/navigationbar.dart';
import 'package:patroltracking/patrol/patrolEvent.dart';
import 'package:patroltracking/services/api_service.dart';

class PatrolDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userdata;
  final String token;

  const PatrolDashboardScreen({
    super.key,
    required this.userdata,
    required this.token,
  });

  @override
  State<PatrolDashboardScreen> createState() => _PatrolDashboardScreenState();
}

class _PatrolDashboardScreenState extends State<PatrolDashboardScreen> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  final Location _location = Location();
  bool _isTracking = false;
  Timer? _locationTimer;

  List<EventChecklistGroup> _eventGroups = [];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    List<EventChecklistGroup> events = await ApiService.fetchGroupedChecklists(
      widget.userdata['id'],
      widget.token,
    );

    // Sort: Inprogress → Pending → Completed
    events.sort((a, b) {
      const priority = {'inprogress': 0, 'pending': 1, 'completed': 2};
      final aPriority = priority[a.status.toLowerCase()] ?? 3;
      final bPriority = priority[b.status.toLowerCase()] ?? 3;
      return aPriority.compareTo(bPriority);
    });

    setState(() => _eventGroups = events);
    await _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude ?? 0.0,
          locationData.longitude ?? 0.0,
        );
      });
    } catch (e) {
      print("Location error: $e");
    }
  }

  void _startTracking() {
    setState(() => _isTracking = true);
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final locationData = await _location.getLocation();
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude ?? 0.0,
          locationData.longitude ?? 0.0,
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    });
  }

  void _showStartPatrolPopup({required EventChecklistGroup event}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Start Patrol"),
        content:
            Text("Do you want to start the workflow: ${event.workflowId}?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ApiService.startWorkflow(
                event.workflowId,
                widget.token,
              );
              if (success) {
                _startTracking();
                _navigateToPatrolEventCheckScreen(event);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to start workflow")),
                );
              }
            },
            child: const Text("Start"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _navigateToPatrolEventCheckScreen(EventChecklistGroup event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatrolEventCheckScreen(
          token: widget.token,
          userdata: widget.userdata,
          eventId: event.workflowId,
          eventtitle: event.workflowTitle,
        ),
      ),
    );
  }

  void _showCompletedWorkflowAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Workflow Completed"),
        content: const Text("This workflow has already been completed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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
        title: Text('Patrol Dashboard', style: AppConstants.headingStyle),
      ),
      drawer: CustomDrawer(userdata: widget.userdata, token: widget.token),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 16.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("currentLocation"),
                        position: _currentPosition!,
                        infoWindow: const InfoWindow(title: "Your Location"),
                      ),
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    mapType: MapType.terrain,
                  ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Workflow',
                    style: AppConstants.headingStyle.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _eventGroups.isEmpty
                        ? const Center(
                            child: Text(
                              "No workflow assigned",
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eventGroups.length,
                            itemBuilder: (context, index) {
                              final event = _eventGroups[index];
                              final status = event.status.toLowerCase();
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: ListTile(
                                  title: Text(
                                    event.workflowTitle,
                                    style: AppConstants.boldPurpleFontStyle,
                                  ),
                                  subtitle: Text(
                                    "Status: ${event.status}",
                                    style: AppConstants.normalPurpleFontStyle,
                                  ),
                                  onTap: () {
                                    if (status == "pending") {
                                      _showStartPatrolPopup(event: event);
                                    } else if (status == "inprogress") {
                                      _navigateToPatrolEventCheckScreen(event);
                                    } else if (status == "completed") {
                                      _showCompletedWorkflowAlert();
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Unknown workflow status")),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
