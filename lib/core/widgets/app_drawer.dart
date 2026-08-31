import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';

enum DrawerMenuItem {
  dashboard,
  myServiceRequests,
  allWorkOrders,
  awaitingPauseApproval,
  awaitingClosureApproval,
  inventoryRequestAwaitingClientApproval,
  feedback,
  profile,
  about,
}

/// The three sub-items under the "Work Order" expandable menu — kept as
/// its own small list so the drawer knows which item to auto-expand for
/// and which rows to render inside it.
const _workOrderMenuItems = [
  DrawerMenuItem.allWorkOrders,
  DrawerMenuItem.awaitingPauseApproval,
  DrawerMenuItem.awaitingClosureApproval,
];

/// The sub-item(s) under the "Inventory Request" expandable menu — kept
/// as its own small list, same pattern as [_workOrderMenuItems], so more
/// items can be added later without touching the expansion widget.
const _inventoryRequestMenuItems = [
  DrawerMenuItem.inventoryRequestAwaitingClientApproval,
];

extension _DrawerMenuItemX on DrawerMenuItem {
  IconData get icon {
    switch (this) {
      case DrawerMenuItem.dashboard:
        return Icons.home_outlined;
      case DrawerMenuItem.myServiceRequests:
        return Icons.assignment_turned_in_outlined;
      case DrawerMenuItem.allWorkOrders:
      case DrawerMenuItem.awaitingPauseApproval:
      case DrawerMenuItem.awaitingClosureApproval:
        return Icons.playlist_add_check_outlined;
      case DrawerMenuItem.inventoryRequestAwaitingClientApproval:
        return Icons.inventory_2_outlined;
      case DrawerMenuItem.feedback:
        return Icons.edit_outlined;
      case DrawerMenuItem.profile:
        return Icons.person_outline;
      case DrawerMenuItem.about:
        return Icons.info_outline;
    }
  }

  String get labelKey {
    switch (this) {
      case DrawerMenuItem.dashboard:
        return 'dashboard';
      case DrawerMenuItem.myServiceRequests:
        return 'my_service_requests';
      case DrawerMenuItem.allWorkOrders:
        return 'all_work_orders';
      case DrawerMenuItem.awaitingPauseApproval:
        return 'awaiting_pause_approval';
      case DrawerMenuItem.awaitingClosureApproval:
        return 'awaiting_approval_closure';
      case DrawerMenuItem.inventoryRequestAwaitingClientApproval:
        return 'awaiting_client_approval';
      case DrawerMenuItem.feedback:
        return 'feedback';
      case DrawerMenuItem.profile:
        return 'profile';
      case DrawerMenuItem.about:
        return 'about';
    }
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selected});

  final DrawerMenuItem selected;

  static const _itemsAbove = [
    DrawerMenuItem.dashboard,
    DrawerMenuItem.myServiceRequests,
  ];

  static const _itemsBelow = [
    DrawerMenuItem.profile,
    // DrawerMenuItem.feedback,
    // DrawerMenuItem.about,
  ];

  void _handleTap(BuildContext context, DrawerMenuItem item) {
    Navigator.of(context).pop();
    if (item == selected) return;

    if (item == DrawerMenuItem.dashboard) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else if (item == DrawerMenuItem.myServiceRequests) {
      Get.offAllNamed(AppRoutes.serviceRequestList);
    } else if (item == DrawerMenuItem.allWorkOrders) {
      Get.offAllNamed(AppRoutes.workOrderList);
    } else if (item == DrawerMenuItem.awaitingPauseApproval) {
      Get.offAllNamed(AppRoutes.workOrderPauseApprovalList);
    } else if (item == DrawerMenuItem.awaitingClosureApproval) {
      Get.offAllNamed(AppRoutes.workOrderClosureApprovalList);
    } else if (item == DrawerMenuItem.inventoryRequestAwaitingClientApproval) {
      Get.offAllNamed(AppRoutes.inventoryRequestAwaitingClientApproval);
    } else if (item == DrawerMenuItem.profile) {
      Get.toNamed(AppRoutes.profile);
    } else {}
  }

  void _signOut(BuildContext context) async {
    Navigator.of(context).pop();
    await Get.find<SessionService>().clear();
    AppSnackbar.showSuccess('logged_out_success'.tr);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    // Responsive width: matches the reference proportion (~84% of the
    // screen) on phones, but caps out on tablets/large screens instead
    // of growing unbounded.
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.84).clamp(280.0, 360.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.scaffoldWhite,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/png/ic_logo.png',
                    width: 84,
                    height: 84 * 0.75,
                    fit: BoxFit.cover,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.drawerCollapseButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primary,
              child: Obx(() {
                final name = session.userName.value ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                return Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Text(
                  session.userName.value ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Text(
                  session.userEmail.value ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: AppColors.divider, height: 1, thickness: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _itemsAbove)
                    _DrawerRow(
                      icon: item.icon,
                      label: item.labelKey.tr,
                      isSelected: item == selected,
                      onTap: () => _handleTap(context, item),
                    ),
                  _WorkOrderExpansionMenu(
                    selected: selected,
                    onItemTap: (item) => _handleTap(context, item),
                  ),
                  _InventoryRequestExpansionMenu(
                    selected: selected,
                    onItemTap: (item) => _handleTap(context, item),
                  ),
                  for (final item in _itemsBelow)
                    _DrawerRow(
                      icon: item.icon,
                      label: item.labelKey.tr,
                      isSelected: item == selected,
                      onTap: () => _handleTap(context, item),
                    ),
                ],
              ),
            ),
            _DrawerRow(
              icon: Icons.logout,
              label: 'sign_out'.tr,
              isSelected: false,
              onTap: () => _signOut(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// The "Work Order" expandable menu — a parent row (matches the other
/// drawer rows in icon/label styling) that opens to reveal "All Work
/// Orders" / "Awaiting for Pause Approval" / "Awaiting Approval for
/// Closure". Auto-expanded whenever the current screen is one of the
/// three, so navigating in never hides the highlighted sub-item.
class _WorkOrderExpansionMenu extends StatelessWidget {
  const _WorkOrderExpansionMenu({
    required this.selected,
    required this.onItemTap,
  });

  final DrawerMenuItem selected;
  final ValueChanged<DrawerMenuItem> onItemTap;

  bool get _isChildSelected => _workOrderMenuItems.contains(selected);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(_isChildSelected),
        initiallyExpanded: _isChildSelected,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        childrenPadding: EdgeInsets.zero,
        iconColor: AppColors.headingBlueGrey,
        collapsedIconColor: AppColors.headingBlueGrey,
        leading: Icon(
          Icons.playlist_add_check_outlined,
          size: 26,
          color: AppColors.headingBlueGrey,
        ),
        title: Text(
          'work_order'.tr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.headingBlueGrey,
          ),
        ),
        children: [
          for (final item in _workOrderMenuItems)
            _DrawerRow(
              icon: item.icon,
              label: item.labelKey.tr,
              isSelected: item == selected,
              onTap: () => onItemTap(item),
              indent: true,
            ),
        ],
      ),
    );
  }
}

/// The "Inventory Request" expandable menu — a parent row (matches the
/// other drawer rows in icon/label styling) that opens to reveal
/// "Awaiting Client Approval". Auto-expanded whenever the current screen
/// is one of its children, same pattern as [_WorkOrderExpansionMenu].
class _InventoryRequestExpansionMenu extends StatelessWidget {
  const _InventoryRequestExpansionMenu({
    required this.selected,
    required this.onItemTap,
  });

  final DrawerMenuItem selected;
  final ValueChanged<DrawerMenuItem> onItemTap;

  bool get _isChildSelected => _inventoryRequestMenuItems.contains(selected);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(_isChildSelected),
        initiallyExpanded: _isChildSelected,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        childrenPadding: EdgeInsets.zero,
        iconColor: AppColors.headingBlueGrey,
        collapsedIconColor: AppColors.headingBlueGrey,
        leading: Icon(
          Icons.inventory_2_outlined,
          size: 26,
          color: AppColors.headingBlueGrey,
        ),
        title: Text(
          'inventory_request'.tr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.headingBlueGrey,
          ),
        ),
        children: [
          for (final item in _inventoryRequestMenuItems)
            _DrawerRow(
              icon: item.icon,
              label: item.labelKey.tr,
              isSelected: item == selected,
              onTap: () => onItemTap(item),
              indent: true,
            ),
        ],
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.indent = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// True for sub-items nested inside the "Work Order" expansion menu —
  /// adds extra leading space so they read as children of that row.
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.headingBlueGrey;

    return Material(
      color: isSelected
          ? AppColors.drawerSelectedBackground
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent ? 48 : 24, 20, 24, 20),
          child: Row(
            children: [
              Icon(icon, size: indent ? 20 : 26, color: color),
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}