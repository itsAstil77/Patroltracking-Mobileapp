// Checklist model
class ChecklistItem {
  final String checklistId;
  final String title;
  final String status;
  final String? locationCode; // Made nullable to avoid exception
  final bool isActive;

  ChecklistItem({
    required this.checklistId,
    required this.title,
    required this.status,
    this.locationCode,
    required this.isActive,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      checklistId: json['checklistId'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      locationCode: json['locationCode'], // Can be null
      isActive: json['isActive'] ?? false,
    );
  }
}

class EventChecklistGroup {
  final String workflowId;
  final String workflowTitle;
  final bool isActive;
  final String status;
  final DateTime? assignedStart;
  final DateTime? assignedEnd;
  final List<ChecklistItem> checklists;

  EventChecklistGroup({
    required this.workflowId,
    required this.workflowTitle,
    required this.isActive,
    required this.status,
    required this.assignedStart,
    required this.assignedEnd,
    required this.checklists,
  });

  factory EventChecklistGroup.fromJson(Map<String, dynamic> json) {
    return EventChecklistGroup(
      workflowId: json['workflowId'] ?? '',
      workflowTitle: json['workflowTitle'] ?? '',
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? '',
      assignedStart: json['AssignedStart'] != null
          ? DateTime.tryParse(json['AssignedStart'])
          : null,
      assignedEnd: json['AssignedEnd'] != null
          ? DateTime.tryParse(json['AssignedEnd'])
          : null,
      checklists: (json['checklists'] as List<dynamic>)
          .map((item) => ChecklistItem.fromJson(item))
          .toList(),
    );
  }
}

// class EventChecklistGroup {
//   final String eventId;
//   final String eventTitle;
//   final bool isActive;
//   final String status;
//   final String? endDateTime;
//   final List<Checklist> checklists;

//   EventChecklistGroup({
//     required this.eventId,
//     required this.eventTitle,
//     required this.isActive,
//     required this.status,
//     this.endDateTime,
//     required this.checklists,
//   });

//   factory EventChecklistGroup.fromJson(Map<String, dynamic> json) {
//     return EventChecklistGroup(
//       eventId: json['workflowId'] ?? '',
//       eventTitle: (json['workflowTitle'] ?? '').toString().trim(),
//       isActive: json['isActive'] ?? false,
//       status: json['status'] ?? '',
//       endDateTime: json['endDateTime'], // Can be null
//       checklists: (json['checklists'] as List<dynamic>)
//           .map((e) => Checklist.fromJson(e))
//           .toList(),
//     );
//   }
// }
// class EventChecklistGroup {
//   final String workflowId;
//   final String workflowTitle;
//   final bool isActive;
//   final String status;
//   final DateTime assignedStart;
//   final DateTime assignedEnd;
//   final List<ChecklistItem> checklists;

//   EventChecklistGroup({
//     required this.workflowId,
//     required this.workflowTitle,
//     required this.isActive,
//     required this.status,
//     required this.assignedStart,
//     required this.assignedEnd,
//     required this.checklists,
//   });

//   factory EventChecklistGroup.fromJson(Map<String, dynamic> json) {
//     return EventChecklistGroup(
//       workflowId: json['workflowId'],
//       workflowTitle: json['workflowTitle'],
//       isActive: json['isActive'],
//       status: json['status'],
//       assignedStart: DateTime.parse(json['AssignedStart']),
//       assignedEnd: DateTime.parse(json['AssignedEnd']),
//       checklists: (json['checklists'] as List)
//           .map((item) => ChecklistItem.fromJson(item))
//           .toList(),
//     );
//   }
// }

// class Checklist {
//   final String id;
//   final String checklistId;
//   final String eventId;
//   final String locationCode;
//   final String title;
//   final String remarks;
//   final String status;
//   final String assignedTo;
//   final String assignedBy;
//   final DateTime startDateTime;
//   final DateTime endDateTime;

//   Checklist({
//     required this.id,
//     required this.checklistId,
//     required this.eventId,
//     required this.locationCode,
//     required this.title,
//     required this.remarks,
//     required this.status,
//     required this.assignedTo,
//     required this.assignedBy,
//     required this.startDateTime,
//     required this.endDateTime,
//   });

//   factory Checklist.fromJson(Map<String, dynamic> json) {
//     return Checklist(
//       id: json['_id'],
//       checklistId: json['checklistId'],
//       eventId: json['eventId'],
//       locationCode: json['locationCode'],
//       title: json['title'],
//       remarks: json['remarks'],
//       status: json['status'],
//       assignedTo: json['assignedTo'],
//       assignedBy: json['assignedBy'],
//       startDateTime: DateTime.parse(json['startDateTime']),
//       endDateTime: DateTime.parse(json['endDateTime']),
//     );
//   }
// }
// class Checklist {
//   final String checklistId;
//   final String title;
//   final String status;
//   final String locationCode;
//   final String startDateTime;
//   final String endDateTime;
//   final bool isActive;

//   Checklist({
//     required this.checklistId,
//     required this.title,
//     required this.status,
//     required this.locationCode,
//     required this.startDateTime,
//     required this.endDateTime,
//     required this.isActive,
//   });

//   factory Checklist.fromJson(Map<String, dynamic> json) {
//     return Checklist(
//       checklistId: json['checklistId'],
//       title: json['title'],
//       status: json['status'],
//       locationCode: json['locationCode'],
//       startDateTime: json['startDateTime'],
//       endDateTime: json['endDateTime'],
//       isActive: json['isActive'],
//     );
//   }
// }
