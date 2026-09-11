import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('সিস্টেম সিকিউরিটি ও সেটিংস', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // সিস্টেম লক ও সিকিউরিটি কার্ড
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('নিরাপত্তা অপশন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(),
                const SizedBox(height: 5),
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('অ্যাডমিন পিন/পাসওয়ার্ড পরিবর্তন'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আয়/ব্যয়ের খাত ব্যবস্থাপনা', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(),
                const Text('নতুন ক্যাটাগরি ও সাবক্যাটাগরি যোগ করুন, যেগুলো আয়/ব্যয় এন্ট্রির সময় ব্যবহার করতে পারবেন।'),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('ক্যাটাগরি ম্যানেজমেন্ট'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        body: const CategoryManagementScreen(),
                      )),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('ক্যাটাগরি ম্যানেজ করুন'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false)) return;

            setState(() {
              isSubmitting = true;
              errorMessage = null;
            });

            final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);
            final result = await authProvider.changePassword(
              currentPassword: currentPasswordController.text,
              newPassword: newPasswordController.text,
            );

            if (!dialogContext.mounted) return;

            if (result['success'] == true) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              setState(() {
                isSubmitting = false;
                errorMessage = result['message'] ?? 'পাসওয়ার্ড পরিবর্তন করা যায়নি।';
              });
            }
          }

          return AlertDialog(
            title: const Text('পাসওয়ার্ড পরিবর্তন করুন'),
            content: SizedBox(
              width: 350,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null) ...[
                      Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'বর্তমান পাসওয়ার্ড'),
                      validator: (val) => (val == null || val.isEmpty) ? 'বর্তমান পাসওয়ার্ড দিন' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'নতুন পাসওয়ার্ড দিন';
                        if (val.length < 6) return 'কমপক্ষে ৬ ক্যারেক্টার দিন';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড নিশ্চিত করুন'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'পাসওয়ার্ড আবার লিখুন';
                        if (val != newPasswordController.text) return 'পাসওয়ার্ড মিলছে না';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('আপডেট'),
              ),
            ],
          );
        },
      ),
    );
  }
}