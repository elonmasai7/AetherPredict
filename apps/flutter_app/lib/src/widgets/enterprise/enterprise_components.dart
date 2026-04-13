import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class EnterprisePanel extends StatelessWidget {
  const EnterprisePanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AetherColors.bgElevated,
        borderRadius: BorderRadius.circular(AetherRadii.lg),
        border: Border.all(color: AetherColors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AetherColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? _toneFromLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AetherRadii.sm),
        border: Border.all(color: tone.withValues(alpha: 0.44)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Color _toneFromLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('critical') ||
        normalized.contains('failed') ||
        normalized.contains('down') ||
        normalized.contains('rejected') ||
        normalized.contains('blocked')) {
      return AetherColors.critical;
    }
    if (normalized.contains('warning') ||
        normalized.contains('pending') ||
        normalized.contains('review') ||
        normalized.contains('degraded')) {
      return AetherColors.warning;
    }
    if (normalized.contains('success') ||
        normalized.contains('healthy') ||
        normalized.contains('running') ||
        normalized.contains('active') ||
        normalized.contains('completed') ||
        normalized.contains('settled')) {
      return AetherColors.success;
    }
    return AetherColors.accent;
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EnterprisePanel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: AetherColors.muted),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AetherColors.muted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KpiStripItem {
  const KpiStripItem({
    required this.label,
    required this.value,
    this.delta,
    this.positiveDelta,
  });

  final String label;
  final String value;
  final String? delta;
  final bool? positiveDelta;
}

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.items});

  final List<KpiStripItem> items;

  @override
  Widget build(BuildContext context) {
    return EnterprisePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _KpiCell(item: items[index]),
              if (index != items.length - 1)
                const VerticalDivider(width: 1, color: AetherColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({required this.item});

  final KpiStripItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AetherColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              item.value,
              style: numericStyle(context, size: 20, weight: FontWeight.w600),
            ),
            if (item.delta != null) ...[
              const SizedBox(height: 2),
              Text(
                item.delta!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: item.positiveDelta == null
                          ? AetherColors.muted
                          : item.positiveDelta!
                              ? AetherColors.success
                              : AetherColors.critical,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum ActionButtonState {
  idle,
  loading,
  success,
  failure,
  disabled,
}

class ActionStateButton extends StatelessWidget {
  const ActionStateButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
    this.retryLabel,
  });

  final String label;
  final ActionButtonState state;
  final VoidCallback? onPressed;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = switch (state) {
      ActionButtonState.idle => label,
      ActionButtonState.loading => 'Processing...',
      ActionButtonState.success => 'Completed',
      ActionButtonState.failure => retryLabel ?? 'Retry',
      ActionButtonState.disabled => label,
    };

    final icon = switch (state) {
      ActionButtonState.idle => const Icon(Icons.play_arrow_rounded, size: 18),
      ActionButtonState.loading => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ActionButtonState.success =>
        const Icon(Icons.check_circle_outline, size: 18),
      ActionButtonState.failure => const Icon(Icons.refresh_rounded, size: 18),
      ActionButtonState.disabled => const Icon(Icons.block, size: 18),
    };

    final enabled = (state == ActionButtonState.idle ||
            state == ActionButtonState.failure) &&
        onPressed != null;

    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: switch (state) {
          ActionButtonState.success => AetherColors.success,
          ActionButtonState.failure => AetherColors.warning,
          ActionButtonState.disabled => AetherColors.bgPanel,
          _ => AetherColors.accent,
        },
      ),
      icon: icon,
      label: Text(effectiveLabel),
    );
  }
}

class EnterpriseTableColumn<T> {
  const EnterpriseTableColumn({
    required this.label,
    required this.cell,
    this.sortValue,
    this.width = 160,
    this.numeric = false,
  });

  final String label;
  final String Function(T row) cell;
  final Comparable<Object?> Function(T row)? sortValue;
  final double width;
  final bool numeric;
}

class EnterpriseTableFilter<T> {
  const EnterpriseTableFilter({required this.label, required this.predicate});

  final String label;
  final bool Function(T row) predicate;
}

class EnterpriseDataTable<T> extends StatefulWidget {
  const EnterpriseDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    required this.rowId,
    this.subtitle,
    this.filters = const [],
    this.searchHint = 'Search',
    this.searchText,
    this.actionsBuilder,
    this.expandedBuilder,
    this.emptyTitle = 'No records',
    this.emptyMessage = 'There are no records that match the selected filters.',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.rowsPerPageOptions = const [8, 12, 20],
  });

  final String title;
  final String? subtitle;
  final List<EnterpriseTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T row) rowId;
  final List<EnterpriseTableFilter<T>> filters;
  final String searchHint;
  final String Function(T row)? searchText;
  final List<Widget> Function(T row)? actionsBuilder;
  final Widget Function(T row)? expandedBuilder;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final List<int> rowsPerPageOptions;

  @override
  State<EnterpriseDataTable<T>> createState() => _EnterpriseDataTableState<T>();
}

class _EnterpriseDataTableState<T> extends State<EnterpriseDataTable<T>> {
  final _searchController = TextEditingController();
  int _filterIndex = 0;
  int _sortIndex = 0;
  bool _ascending = true;
  int _page = 0;
  int _rowsPerPage = 8;
  String? _expandedRowId;

  @override
  void initState() {
    super.initState();
    if (widget.rowsPerPageOptions.isNotEmpty) {
      _rowsPerPage = widget.rowsPerPageOptions.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRows = _processedRows();
    final totalPages = math.max(1, (filteredRows.length / _rowsPerPage).ceil());
    _page = _page.clamp(0, totalPages - 1).toInt();
    final start = _page * _rowsPerPage;
    final end = math.min(start + _rowsPerPage, filteredRows.length);
    final currentRows =
        filteredRows.isEmpty ? <T>[] : filteredRows.sublist(start, end);

    return EnterprisePanel(
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${filteredRows.length} rows',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AetherColors.muted),
          ),
          OutlinedButton.icon(
            onPressed: filteredRows.isEmpty
                ? null
                : () => _exportCsv(context, filteredRows),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export CSV'),
          ),
        ],
      ),
      child: Column(
        children: [
          _toolbar(context),
          const SizedBox(height: 12),
          if (currentRows.isEmpty)
            EmptyStateCard(
              title: widget.emptyTitle,
              message: widget.emptyMessage,
              icon: Icons.inbox_outlined,
              actionLabel: widget.emptyActionLabel,
              onAction: widget.onEmptyAction,
            )
          else
            _tableContent(context, currentRows),
          const SizedBox(height: 8),
          _pagination(context, filteredRows.length, totalPages),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _page = 0),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _page = 0);
                        },
                      ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ),
        if (widget.filters.isNotEmpty) ...[
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _filterIndex,
            borderRadius: BorderRadius.circular(AetherRadii.md),
            dropdownColor: AetherColors.bgElevated,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _filterIndex = value;
                _page = 0;
              });
            },
            items: [
              const DropdownMenuItem<int>(value: 0, child: Text('All')),
              for (var i = 0; i < widget.filters.length; i++)
                DropdownMenuItem<int>(
                  value: i + 1,
                  child: Text(widget.filters[i].label),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tableContent(BuildContext context, List<T> currentRows) {
    final tableWidth = widget.columns.fold<double>(
            widget.expandedBuilder == null ? 0 : 38,
            (sum, column) => sum + column.width) +
        (widget.actionsBuilder == null ? 0 : 156);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AetherRadii.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AetherColors.border),
          borderRadius: BorderRadius.circular(AetherRadii.md),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _headerRow(context),
                for (final row in currentRows) ...[
                  _dataRow(context, row),
                  if (_expandedRowId == widget.rowId(row) &&
                      widget.expandedBuilder != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AetherColors.bg,
                        border: Border(
                          top: BorderSide(color: AetherColors.border),
                          bottom: BorderSide(color: AetherColors.border),
                        ),
                      ),
                      child: widget.expandedBuilder!(row),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AetherColors.bgPanel,
        border: Border(bottom: BorderSide(color: AetherColors.border)),
      ),
      child: Row(
        children: [
          if (widget.expandedBuilder != null)
            const SizedBox(width: 38, child: Icon(Icons.unfold_more, size: 16)),
          for (var i = 0; i < widget.columns.length; i++)
            _headerCell(context, widget.columns[i], i),
          if (widget.actionsBuilder != null)
            SizedBox(
              width: 156,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Actions',
                  textAlign: TextAlign.right,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AetherColors.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(
      BuildContext context, EnterpriseTableColumn<T> column, int index) {
    final sorted = _sortIndex == index;
    final arrowIcon = _ascending ? Icons.arrow_upward : Icons.arrow_downward;

    return SizedBox(
      width: column.width,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortIndex == index) {
              _ascending = !_ascending;
            } else {
              _sortIndex = index;
              _ascending = true;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: column.numeric
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  column.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AetherColors.muted),
                ),
              ),
              if (sorted) ...[
                const SizedBox(width: 4),
                Icon(arrowIcon, size: 12, color: AetherColors.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataRow(BuildContext context, T row) {
    final rowId = widget.rowId(row);
    final expanded = _expandedRowId == rowId;
    return InkWell(
      onTap: widget.expandedBuilder == null
          ? null
          : () {
              setState(() {
                _expandedRowId = expanded ? null : rowId;
              });
            },
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AetherColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.expandedBuilder != null)
              SizedBox(
                width: 38,
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: AetherColors.muted,
                ),
              ),
            for (final column in widget.columns)
              SizedBox(
                width: column.width,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    column.cell(row),
                    textAlign:
                        column.numeric ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (widget.actionsBuilder != null)
              SizedBox(
                width: 156,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    children: widget.actionsBuilder!(row),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pagination(BuildContext context, int rows, int totalPages) {
    return Row(
      children: [
        DropdownButton<int>(
          value: _rowsPerPage,
          borderRadius: BorderRadius.circular(AetherRadii.md),
          dropdownColor: AetherColors.bgElevated,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _rowsPerPage = value;
              _page = 0;
            });
          },
          items: [
            for (final option in widget.rowsPerPageOptions)
              DropdownMenuItem<int>(
                value: option,
                child: Text('$option / page'),
              ),
          ],
        ),
        const Spacer(),
        Text(
          rows == 0
              ? '0-0 of 0'
              : '${_page * _rowsPerPage + 1}-${math.min((_page + 1) * _rowsPerPage, rows)} of $rows',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AetherColors.muted),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Previous page',
          onPressed: _page == 0
              ? null
              : () => setState(() {
                    _page -= 1;
                  }),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: _page >= totalPages - 1
              ? null
              : () => setState(() {
                    _page += 1;
                  }),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  List<T> _processedRows() {
    final rawQuery = _searchController.text.trim().toLowerCase();
    var items = List<T>.from(widget.rows);

    if (_filterIndex > 0) {
      final predicate = widget.filters[_filterIndex - 1].predicate;
      items = items.where(predicate).toList();
    }

    if (rawQuery.isNotEmpty) {
      items = items.where((row) {
        final source = widget.searchText?.call(row) ??
            widget.columns.map((column) => column.cell(row)).join(' ');
        return source.toLowerCase().contains(rawQuery);
      }).toList();
    }

    if (_sortIndex >= 0 && _sortIndex < widget.columns.length) {
      final column = widget.columns[_sortIndex];
      final extractor = column.sortValue;
      items.sort((a, b) {
        final aValue = extractor?.call(a) ?? column.cell(a);
        final bValue = extractor?.call(b) ?? column.cell(b);
        final compare = aValue.compareTo(bValue);
        return _ascending ? compare : -compare;
      });
    }

    return items;
  }

  Future<void> _exportCsv(BuildContext context, List<T> rows) async {
    final buffer = StringBuffer();
    final header = [
      ...widget.columns.map((column) => column.label),
    ];
    buffer.writeln(header.map(_escapeCsv).join(','));

    for (final row in rows) {
      final values =
          widget.columns.map((column) => _escapeCsv(column.cell(row)));
      buffer.writeln(values.join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

String formatUsd(double value, {int fractionDigits = 0}) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  final whole = absolute.truncate();
  final wholeWithCommas = whole
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  if (fractionDigits <= 0) {
    return '$sign\$$wholeWithCommas';
  }
  final decimals = absolute.toStringAsFixed(fractionDigits).split('.').last;
  return '$sign\$$wholeWithCommas.$decimals';
}

String formatPercent(double value, {int fractionDigits = 2}) {
  return '${(value * 100).toStringAsFixed(fractionDigits)}%';
}
