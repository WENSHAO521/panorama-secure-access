import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/traffic_quota_input.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'form_row.dart';

/// The custom traffic row of the profile editor and the link import: an
/// amount and its unit, where [QuotaUnit.none] keeps the subscription's own
/// total. Typing an amount without a unit picks GB; picking none clears it.
class TrafficQuotaField extends StatelessWidget {
  const TrafficQuotaField({
    super.key,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    this.invalid = false,
    this.onChanged,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final QuotaUnit unit;
  final ValueChanged<QuotaUnit> onUnitChanged;
  final bool invalid;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  void _handleChanged(String value) {
    if (unit == QuotaUnit.none && value.trim().isNotEmpty) {
      onUnitChanged(QuotaUnit.gb);
    }
    onChanged?.call(value);
  }

  void _handleUnitChanged(QuotaUnit value) {
    if (value == QuotaUnit.none && controller.text.isNotEmpty) {
      controller.clear();
      onChanged?.call('');
    }
    onUnitChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return FormRow(
      title: appLocalizations.customTraffic,
      invalid: invalid,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Flexible(
            child: FormRowTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: appLocalizations.none,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: textInputAction,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(TextInputLimits.number),
              ],
              onChanged: _handleChanged,
              onFieldSubmitted: onFieldSubmitted,
            ),
          ),
          Flexible(
            flex: 2,
            child: SegmentedControl<QuotaUnit>(
              segments: [
                for (final value in QuotaUnit.values)
                  (
                    value,
                    value == QuotaUnit.none
                        ? appLocalizations.none
                        : value.symbol,
                  ),
              ],
              value: unit,
              onChanged: _handleUnitChanged,
            ),
          ),
        ],
      ),
    );
  }
}

extension TrafficQuotaInputErrorLabel on TrafficQuotaInputError {
  String label(BuildContext context) => switch (this) {
    TrafficQuotaInputError.invalid =>
      context.appLocalizations.customTrafficInvalidDesc,
    TrafficQuotaInputError.tooLarge =>
      context.appLocalizations.customTrafficTooLargeDesc,
  };
}
