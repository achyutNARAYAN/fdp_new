import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:fdp/features/support/models/support_ticket_model.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class RaiseTicketScreen extends ConsumerStatefulWidget {
  final String? initialOrderId;

  const RaiseTicketScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends ConsumerState<RaiseTicketScreen> {
  late TextEditingController _orderIdController;
  final TextEditingController _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.meltedOrSpoiled;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(
      text: widget.initialOrderId ?? '',
    );
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Please provide details describing the issue.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support ticket API is unavailable.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Related Order', style: AppTypography.itemName),
            const SizedBox(height: 8),
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.receipt_long, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusInput,
                  ),
                  borderSide: const BorderSide(color: AppColors.neutralBorder),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text('Issue Category', style: AppTypography.itemName),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TicketCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryTint20,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.neutralBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text('Describe the Problem', style: AppTypography.itemName),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Please share details (e.g. package was unsealed, gelato melted, missing ladoo box)...',
                hintStyle: AppTypography.bodySmall,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusInput,
                  ),
                  borderSide: const BorderSide(color: AppColors.neutralBorder),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Photo upload is unavailable.',
              style: AppTypography.caption,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            AppPrimaryButton(
              label: 'Submit Support Ticket',
              onPressed: _submitTicket,
            ),
          ],
        ),
      ),
    );
  }
}
