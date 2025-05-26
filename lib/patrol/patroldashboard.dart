import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geo;
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
      widget.userdata['userId'],
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

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
  }

  void _showStartPatrolPopup({required EventChecklistGroup event}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Start Patrol"),
        content:
            Text("Do you want to start the assignment: ${event.workflowId}?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final position = await _getCurrentLocation();

                final success = await ApiService.startWorkflow(
                  event.workflowId,
                  widget.token,
                  latitude: position.latitude,
                  longitude: position.longitude,
                );

                if (success) {
                  _startTracking();
                  _navigateToPatrolEventCheckScreen(event);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to start assignment")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Location error: ${e.toString()}")),
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
        content: const Text("This assignment has already been completed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSOSPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation Box!"),
        content: Text("Are you sure to submit SOS?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              _sendSOSAlert();
            },
            child: const Text("Yes"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOSAlert() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      final response = await ApiService.sendSOSAlert(
        token: widget.token,
        userid: widget.userdata['userId'],
        latitude: position.latitude,
        longitude: position.longitude,
        remarks: "Emergency! Immediate help needed!",
      );

      // Check status inside response map
      if (response['message'] == 'SOS alert saved successfully.') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚨 SOS Alert Sent")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("🚨 Failed to send SOS: ${response['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 SOS Error: $e")),
      );
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            // label: const Text("Send SOS"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _showSOSPopup,
          )
        ],
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
                    'Assigned assignment',
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
                              "No assignment assigned",
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
                                                "Unknown assignment status")),
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
