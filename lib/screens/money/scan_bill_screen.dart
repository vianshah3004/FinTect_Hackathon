import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../providers/user_provider.dart';
import '../../providers/money_provider.dart';

/// Scan Bill Screen - OCR-based expense entry
/// Uses image picker for now, OCR can be integrated later with google_mlkit_text_recognition
class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});

  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  XFile? _selectedImage;
  bool _isProcessing = false;
  bool _isScanned = false;

  // Detected values (mock values for now, real OCR to be integrated)
  String _detectedAmount = '';
  String _detectedMerchant = '';
  String? _selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isProcessing = true;
        });

        // Simulate OCR processing (in real app, use google_mlkit_text_recognition)
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Mock OCR result
        setState(() {
          _isProcessing = false;
          _isScanned = true;
          _detectedAmount = '${(100 + (DateTime.now().millisecond % 900)).toString()}';
          _detectedMerchant = 'Grocery Store';
          _amountController.text = _detectedAmount;
          _noteController.text = _detectedMerchant;
          _selectedCategory = 'food';
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final expense = Expense(
      id: const Uuid().v4(),
      category: _selectedCategory!,
      amount: amount,
      note: _noteController.text.isEmpty ? 'Scanned bill' : _noteController.text,
      date: DateTime.now(),
      isIncome: false,
    );

    context.read<MoneyProvider>().addExpense(expense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('₹$amount added to expenses!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';
    final categories = ExpenseCategory.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? '📷 बिल स्कैन करें' : '📷 Scan Bill'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🧾', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  isHindi
                      ? 'बिल या रसीद का फोटो लें'
                      : 'Take a photo of your bill',
                  style: AppTypography.titleLarge.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isHindi
                      ? 'हम राशि अपने आप पढ़ लेंगे!'
                      : 'We will auto-detect the amount!',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Camera/Gallery buttons
          if (!_isScanned) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    label: isHindi ? 'कैमरा' : 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library,
                    label: isHindi ? 'गैलरी' : 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      isHindi ? 'बिल पढ़ रहे हैं...' : 'Reading bill...',
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Scanned result
          if (_isScanned) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        isHindi ? '✓ बिल स्कैन हो गया!' : '✓ Bill scanned!',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount field
                  Text(
                    isHindi ? 'राशि' : 'Amount',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: '0',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category selection
                  Text(
                    isHindi ? 'श्रेणी' : 'Category',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(cat['color']).withOpacity(0.2) : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? Border.all(color: Color(cat['color']), width: 2) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['icon'], style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                isHindi ? cat['nameHi'] : cat['name'],
                                style: TextStyle(
                                  color: isSelected ? Color(cat['color']) : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Note field
                  Text(
                    isHindi ? 'नोट (वैकल्पिक)' : 'Note (optional)',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: isHindi ? 'विवरण लिखें...' : 'Add details...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isHindi ? 'खर्च में जोड़ें' : 'Add to Expenses',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan another
            TextButton.icon(
              onPressed: () => setState(() {
                _isScanned = false;
                _selectedImage = null;
                _amountController.clear();
                _noteController.clear();
                _selectedCategory = null;
              }),
              icon: const Icon(Icons.refresh),
              label: Text(isHindi ? 'दूसरा बिल स्कैन करें' : 'Scan another bill'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(label, style: AppTypography.titleMedium),
          ],
        ),
      ),
    );
  }
}