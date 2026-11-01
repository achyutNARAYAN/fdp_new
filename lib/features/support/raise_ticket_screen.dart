import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/support_ticket_model.dart';
import '../../shared/providers/support_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class RaiseTicketScreen extends ConsumerStatefulWidget {
  final String? initialOrderId;

  const RaiseTicketScreen({
    super.key,
    this.initialOrderId,
  });

  @override
  ConsumerState<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends ConsumerState<RaiseTicketScreen> {
  late TextEditingController _orderIdController;
  final TextEditingController _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.meltedOrSpoiled;
  bool _photoAttached = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(text: widget.initialOrderId ?? 'FD10245');
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

    if (_selectedCategory.requiresPhoto && !_photoAttached) {
      setState(() => _error = 'A photo is required for ${_selectedCategory.label} verification.');
      return;
    }

    final ticketId = ref.read(supportTicketsProvider.notifier).createTicket(
          orderId: _orderIdController.text.trim(),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          attachments: _photoAttached ? ['https://images.unsplash.com/photo-1563805042-7684c019e1cb'] : [],
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ticket #$ticketId opened successfully.')),
    );

    context.pushReplacement('/ticket-details/$ticketId');
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
                  borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
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
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.neutralBorder),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                hintText: 'Please share details (e.g. package was unsealed, gelato melted, missing ladoo box)...',
                hintStyle: AppTypography.bodySmall,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                  borderSide: const BorderSide(color: AppColors.neutralBorder),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),

            const SizedBox(height: 20),

            // Photo Upload Requirement (Mandatory for quality/melted/damaged)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attach Photo Proof', style: AppTypography.itemName),
                if (_selectedCategory.requiresPhoto)
                  const Text('Mandatory for this issue', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () {
                setState(() => _photoAttached = !_photoAttached);
              },
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: _photoAttached ? AppColors.primaryTint20 : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _photoAttached ? AppColors.primary : AppColors.neutralBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _photoAttached ? Icons.check_circle : Icons.camera_alt_outlined,
                      color: _photoAttached ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _photoAttached ? '1 Photo Attached (Tap to remove)' : 'Tap to upload picture from camera or gallery',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _photoAttached ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.textPrimary))),
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

