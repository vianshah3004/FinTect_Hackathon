import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/scheme.dart';
import '../../models/user.dart';
import '../../services/scheme_matcher_service.dart';
import '../../providers/user_provider.dart';
import '../../services/tts_service.dart';

class EligibilityFormScreen extends StatefulWidget {
  const EligibilityFormScreen({super.key});

  @override
  State<EligibilityFormScreen> createState() => _EligibilityFormScreenState();
}

class _EligibilityFormScreenState extends State<EligibilityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Data
  int? age;
  String gender = "male";
  String occupation = "farmer";
  int? income;
  bool ownsLand = false;

  bool _isLoading = false;
  List<Scheme> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from UserProvider if available
    final user = context.read<UserProvider>().user;
    if (user != null) {
      age = user.age;
      // Map occupation if matches
      if ([
        'farmer',
        'student',
        'worker',
        'business',
      ].contains(user.occupation)) {
        occupation = user.occupation;
      }
    }
  }

  void _findSchemes() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _hasSearched = true;
        _results = [];
      });

      // Simulate network/processing delay for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      // Prepare user profile and additional data
      final userProvider = context.read<UserProvider>();
      final currentUser =
          userProvider.user ??
          UserProfile(
            id: 'temp',
            name: 'Guest',
            language: userProvider.language,
            occupation: occupation,
            incomeRange: income.toString(),
            createdAt: DateTime.now(),
          );

      final matches = SchemeMatcherService.match(
        currentUser,
        additionalData: {
          'age': age,
          'occupation': occupation,
          'gender': gender,
          'income': income ?? 0,
          'owns_land': ownsLand,
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = matches;
        });

        // Voice Feedback
        final tts = context.read<TtsService>();
        String msg = userProvider.language == 'hi'
            ? "हमें ${_results.length} योजनाएं मिली हैं"
            : "We found ${_results.length} schemes for you";

        if (_results.isEmpty) {
          msg = userProvider.language == 'hi'
              ? "माफ़ कीजिये, अभी कोई योजना उपलब्ध नहीं है"
              : "Sorry, no schemes found matching your profile";
        }

        tts.speak(msg, language: userProvider.language);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isHindi = userProvider.language == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? 'पात्रता जांचें' : 'Check Eligibility'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_hasSearched) _buildForm(isHindi),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            if (_hasSearched && !_isLoading) _buildResults(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isHindi) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            title: isHindi ? 'बुनियाਦੀ जानकारी' : 'Basic Details',
            children: [
              _buildDropdown(
                label: isHindi ? 'व्यवसाय' : 'Occupation',
                value: occupation,
                items: [
                  DropdownMenuItem(
                    value: 'farmer',
                    child: Text(isHindi ? 'किसान' : 'Farmer'),
                  ),
                  DropdownMenuItem(
                    value: 'student',
                    child: Text(isHindi ? 'छात्र' : 'Student'),
                  ),
                  DropdownMenuItem(
                    value: 'worker',
                    child: Text(isHindi ? 'मज़दूर' : 'Worker'),
                  ),
                  DropdownMenuItem(
                    value: 'business',
                    child: Text(isHindi ? 'व्यापारी' : 'Business'),
                  ),
                  DropdownMenuItem(
                    value: 'shopkeeper',
                    child: Text(isHindi ? 'दुकानदार' : 'Shopkeeper'),
                  ),
                  DropdownMenuItem(
                    value: 'homemaker',
                    child: Text(isHindi ? 'गृहिणी' : 'Homemaker'),
                  ),
                ],
                onChanged: (val) => setState(() => occupation = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: isHindi ? 'उम्र' : 'Age',
                      initialValue: age?.toString(),
                      inputType: TextInputType.number,
                      onSaved: (val) => age = int.tryParse(val ?? ''),
                      validator: (val) =>
                          (val == null || val.isEmpty) ? '*' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: isHindi ? 'लिंग' : 'Gender',
                      value: gender,
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(isHindi ? 'पुरुष' : 'Male'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(isHindi ? 'महिला' : 'Female'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(isHindi ? 'अन्य' : 'Other'),
                        ),
                      ],
                      onChanged: (val) => setState(() => gender = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: isHindi ? 'आर्थिक विवरण' : 'Economic Details',
            children: [
              _buildTextField(
                label: isHindi ? 'वार्षिक आय (₹)' : 'Annual Income (₹)',
                initialValue: income?.toString(),
                inputType: TextInputType.number,
                onSaved: (val) => income = int.tryParse(val ?? ''),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  isHindi ? 'क्या आपके पास जमीन है?' : 'Do you own land?',
                ),
                value: ownsLand,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => ownsLand = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _findSchemes,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isHindi ? 'खोजें' : 'Find Schemes',
              style: AppTypography.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isHindi) {
    if (_results.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कोई योजना नहीं मिली' : 'No schemes found',
            style: AppTypography.titleMedium,
          ),
          TextButton(
            onPressed: () => setState(() => _hasSearched = false),
            child: Text(isHindi ? 'फिर से प्रयास करें' : 'Try Again'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isHindi
                  ? 'आपके लिए ${_results.length} परिणाम'
                  : 'Found ${_results.length} schemes',
              style: AppTypography.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _hasSearched = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._results.map((scheme) => _buildSchemeCard(scheme, isHindi)).toList(),
      ],
    );
  }

  Widget _buildSchemeCard(Scheme scheme, bool isHindi) {
    final benefits = isHindi ? scheme.benefitsHi : scheme.benefits;
    final eligibility = isHindi ? scheme.eligibilityHi : scheme.eligibility;
    final documents = isHindi ? scheme.documentsHi : scheme.documents;
    final howToApply = isHindi ? scheme.howToApplyHi : scheme.howToApply;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(scheme.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          isHindi ? scheme.nameHi : scheme.name,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isHindi ? scheme.descriptionHi : scheme.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall,
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Description
          Text(
            isHindi ? scheme.descriptionHi : scheme.description,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Benefits Section
          _buildInfoSection(
            title: isHindi ? '✅ लाभ' : '✅ Benefits',
            items: benefits,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),

          // Eligibility Section
          _buildInfoSection(
            title: isHindi ? '📋 पात्रता' : '📋 Eligibility',
            items: eligibility,
            color: AppColors.info,
          ),
          const SizedBox(height: 12),

          // Documents Section
          _buildInfoSection(
            title: isHindi ? '📄 आवश्यक दस्तावेज' : '📄 Documents Required',
            items: documents,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),

          // How to Apply Section
          _buildInfoSection(
            title: isHindi ? '📝 आवेदन कैसे करें' : '📝 How to Apply',
            items: howToApply,
            color: AppColors.primary,
            numbered: true,
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final desc = isHindi
                        ? scheme.descriptionHi
                        : scheme.description;
                    final name = isHindi ? scheme.nameHi : scheme.name;
                    context.read<TtsService>().speak(
                      "$name. $desc",
                      language: isHindi ? 'hi' : 'en',
                    );
                  },
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: Text(isHindi ? 'सुनें' : 'Listen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (scheme.websiteUrl != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open website
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(isHindi ? 'वेबसाइट' : 'Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<String> items,
    required Color color,
    bool numbered = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleSmall.copyWith(color: color)),
        const SizedBox(height: 8),
        ...items.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numbered ? '${entry.key + 1}. ' : '• ',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(entry.value, style: AppTypography.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
          ),
          const Divider(),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    required TextInputType inputType,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
