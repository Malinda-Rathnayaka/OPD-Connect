import 'package:flutter/material.dart';

import 'staff_models.dart';

class StaffCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  const StaffCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StaffStyle.line),
    ),
    child: child,
  );
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill(this.label, {super.key, this.color = StaffStyle.green});
  factory StatusPill.account(StaffAccount account) => StatusPill(
    account.reviewNote.startsWith('Invitation')
        ? 'Invitation prepared'
        : switch (account.status) {
            AccountStatus.active => 'Active',
            AccountStatus.pending => 'Needs review',
            AccountStatus.rejected => 'Rejected',
            AccountStatus.inactive => 'Inactive',
          },
    color: switch (account.status) {
      AccountStatus.active => StaffStyle.green,
      AccountStatus.pending => StaffStyle.amber,
      AccountStatus.rejected => StaffStyle.red,
      AccountStatus.inactive => StaffStyle.muted,
    },
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class AccountAvatar extends StatelessWidget {
  final StaffAccount account;
  final double size;
  const AccountAvatar(this.account, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) {
    final color = account.role == 'doctor'
        ? const Color(0xFF4A73B0)
        : account.role == 'admin'
        ? StaffStyle.green
        : const Color(0xFF8C69AD);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        account.initials,
        style: TextStyle(
          color: color,
          fontSize: size / 3.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const SectionHeading(
    this.title, {
    super.key,
    this.subtitle = '',
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, detail;
  final Widget? action;
  const EmptyState({
    super.key,
    this.icon = Icons.search_rounded,
    required this.title,
    required this.detail,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 16),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: StaffStyle.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: StaffStyle.green, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class InfoBanner extends StatelessWidget {
  final String text;
  final bool warning;
  final Widget? action;
  const InfoBanner(this.text, {super.key, this.warning = false, this.action});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF5E6) : StaffStyle.mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline_rounded : Icons.verified_user_outlined,
          size: 19,
          color: warning ? StaffStyle.amber : StaffStyle.green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: warning ? StaffStyle.amber : StaffStyle.green,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

String relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

String readableDate(DateTime? date) {
  if (date == null) return 'Not recorded';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
