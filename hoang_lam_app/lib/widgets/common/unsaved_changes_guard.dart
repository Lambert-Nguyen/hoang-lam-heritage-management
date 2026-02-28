import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A widget that wraps a form and warns the user about unsaved changes
/// when they try to navigate away.
///
/// Usage:
/// ```dart
/// UnsavedChangesGuard(
///   hasUnsavedChanges: _isDirty,
///   child: Form(...),
/// )
/// ```
class UnsavedChangesGuard extends StatelessWidget {
  final bool hasUnsavedChanges;
  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final l10n = AppLocalizations.of(context)!;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.unsavedChangesTitle),
            content: Text(l10n.unsavedChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.keepEditing),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.discardChanges),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
