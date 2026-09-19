import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../widgets/filter_pill.dart';
import '../widgets/omw_card.dart';
import '../widgets/svg_icon.dart';

/// "Account" tab for both roles. Not drawn in Figma; composed from the
/// Figma card, pill and typography tokens. Hosts the sender/courier switch.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accepted = state.accepted;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      children: [
        OmwCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.stroke,
                  ),
                ),
                child: const SvgIcon(AppIcons.userRound, size: 28),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signed in as', style: AppText.routeLabel),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      state.email ?? '',
                      style: AppText.routeValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OmwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardEyebrow(label: 'I AM USING OMW TO'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterPill(
                    label: 'Send parcels',
                    selected: state.role == AppRole.sender,
                    onTap: () => state.setRole(AppRole.sender),
                  ),
                  FilterPill(
                    label: 'Deliver parcels',
                    selected: state.role == AppRole.courier,
                    onTap: () => state.setRole(AppRole.courier),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.role == AppRole.courier) ...[
          const SizedBox(height: AppSpacing.lg),
          OmwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardEyebrow(label: 'ACCEPTED JOBS (${accepted.length})'),
                if (accepted.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Requests you accept from the feed show up here.',
                    style: AppText.caption.copyWith(
                      color: AppColors.inkAt(0.6),
                    ),
                  ),
                ],
                for (final job in accepted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SvgIcon(job.parcel.icon, size: 20),
                    minLeadingWidth: 20,
                    title: Text(job.destination, style: AppText.routeValue),
                    subtitle: Text(
                      'From ${job.pickup}',
                      style: AppText.caption.copyWith(
                        color: AppColors.inkAt(0.6),
                      ),
                    ),
                    trailing: Text('₹${job.fare}', style: AppText.inputValue),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: state.signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(
                color: AppColors.ink,
                width: AppRadii.stroke,
              ),
              shape: const StadiumBorder(),
            ),
            child: Text('Sign out', style: AppText.button),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Demo build: sign-in, payments and courier matching are simulated '
          'on this device.',
          textAlign: TextAlign.center,
          style: AppText.legal,
        ),
      ],
    );
  }
}
