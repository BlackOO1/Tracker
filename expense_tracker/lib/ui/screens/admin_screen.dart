import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('lastSignIn', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.peach)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.teal.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Registered Users:', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${users.length}', style: const TextStyle(color: AppColors.teal, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final name = user['name'] ?? 'Unknown';
                    final email = user['email'] ?? 'No email';
                    final lastSignIn = user['lastSignIn'] != null 
                        ? (user['lastSignIn'] as Timestamp).toDate().toString() 
                        : 'Unknown';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        backgroundImage: user['photoUrl'] != null && user['photoUrl'].toString().isNotEmpty 
                            ? NetworkImage(user['photoUrl']) 
                            : null,
                        child: user['photoUrl'] == null || user['photoUrl'].toString().isEmpty
                            ? Text(name[0], style: const TextStyle(color: AppColors.teal))
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('Last seen: $lastSignIn', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                      trailing: const Icon(Icons.admin_panel_settings, color: AppColors.divider, size: 16),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
