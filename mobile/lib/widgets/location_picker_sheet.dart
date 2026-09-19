import 'package:flutter/material.dart';

import '../models/omw_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

/// Bottom sheet listing the campus landmarks served by the backend
/// (GET /api/map/locations). Resolves to the chosen location id.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.locations,
    this.selectedId,
  });

  final String title;
  final List<CampusLocation> locations;
  final String? selectedId;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<CampusLocation> locations,
    String? selectedId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LocationPickerSheet(
        title: title,
        locations: locations,
        selectedId: selectedId,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final items = widget.locations
        .where(
          (l) =>
              q.isEmpty ||
              l.name.toLowerCase().contains(q) ||
              l.categoryLabel.toLowerCase().contains(q),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.authGutter,
            0,
            AppSpacing.authGutter,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: AppText.sectionTitle),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _query,
                style: AppText.fieldText,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search campus landmarks',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'No landmark matches “${_query.text}”.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyMuted,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final l = items[i];
                          final selected = l.id == widget.selectedId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const SvgIcon(Lucide.mapPin, size: 20),
                            minLeadingWidth: 20,
                            selected: selected,
                            selectedColor: AppColors.ink,
                            title: Text(
                              l.name,
                              style: AppText.routeValue.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              l.categoryLabel,
                              style: AppText.labelSmall,
                            ),
                            trailing: selected
                                ? const SvgIcon(Lucide.check, size: 20)
                                : null,
                            onTap: () => Navigator.of(context).pop(l.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
