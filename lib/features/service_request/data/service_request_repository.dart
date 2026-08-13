import 'package:get/get.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';

/// Single in-memory source of truth for "My Service Requests".
///
/// Registered as a permanent GetxService (not tied to a page's lifecycle)
/// so that submitting the "New Service Request" form and viewing the list
/// both read/write the same [tickets] list — a newly created request shows
/// up at the top of "My Service Requests" immediately, without a backend.
class ServiceRequestRepository extends GetxService {
  final RxList<ServiceRequest> tickets = <ServiceRequest>[].obs;

  int _nextId = 1130;

  @override
  void onInit() {
    super.onInit();
    tickets.addAll(_seedTickets);
  }

  void addFromSubmission({
    required String subject,
    required String description,
    required String site,
  }) {
    tickets.insert(
      0,
      ServiceRequest(
        id: _nextId++,
        title: subject,
        description: description,
        requester: 'You',
        site: site,
        priority: ServiceRequestPriority.noPriority,
        status: ServiceRequestStatus.open,
        type: ServiceRequestOption.serviceRequest,
        dueDate: DateTime.now(),
      ),
    );
  }

  static final List<ServiceRequest> _seedTickets = [
    ServiceRequest(
      id: 1129,
      title: 'صيانه المبني',
      description: 'توحيد لون الطين',
      requester: 'Abdelmoneim Abdelrhman',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 8, 5),
      isArabicTitle: true,
    ),
    ServiceRequest(
      id: 836,
      title:
          'The screen shows information about resetting a password and instructions',
      description:
          'The screen displays instructions for resetting a password and advises contacting the responsible team if issues persist.',
      requester: 'CIT Group',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.noPriority,
      status: ServiceRequestStatus.awaitingApproval,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 8, 6),
    ),
    ServiceRequest(
      id: 674,
      title: 'The Salwa entrance glass and frame need to be cleaned daily including',
      description:
          'The Salwa entrance glass and frame need to be cleaned daily including fixing the broken frame near the main door.',
      requester: 'CIT Group',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 30),
    ),
    ServiceRequest(
      id: 292,
      title: 'Stairs repainting',
      description: 'Stairs repainting at ZONE4-Roads & Open Area',
      requester: 'Syed Abdul Samad',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.closed,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 20),
    ),
    ServiceRequest(
      id: 290,
      title: 'Wall repainting',
      description: 'Wall repainting at Salwa Museum (Addiriya)',
      requester: 'Syed Abdul Samad',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 18),
    ),
    ServiceRequest(
      id: 289,
      title: 'Rooftop glass cleaning',
      description: 'Rooftop glass cleaning Salwa Museum (Addiriya)',
      requester: 'Syed Abdul Samad',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 15),
    ),
    ServiceRequest(
      id: 263,
      title: 'Litter picking',
      description: 'Litter picking',
      requester: 'Syed Abdul Samad',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 10),
    ),
    ServiceRequest(
      id: 262,
      title: 'Issue reported in male toilet at Salwa Palace, Ground floor',
      description:
          'Issue reported in male toilet at Salwa Palace, Ground floor. User MN reported this issue. Confirmed by site team.',
      requester: 'CIT Group',
      site: 'Diriyah At Turaif',
      priority: ServiceRequestPriority.routine,
      status: ServiceRequestStatus.convertedAsWorkorder,
      type: ServiceRequestOption.serviceRequest,
      dueDate: DateTime(2026, 7, 8),
    ),
  ];
}
