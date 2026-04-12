import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../registration_cubit.dart';
import '../models/membership_type.dart';

class MembershipSelectionScreen extends StatelessWidget {
  const MembershipSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final regCubit = context.read<RegistrationCubit>();
    final state = regCubit.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Membership Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your Membership Type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The system will automatically determine eligibility based on your information.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Indigent Option
            _buildMembershipCard(
              context: context,
              title: 'Indigent (Free / Subsidized)',
              subtitle: 'For eligible low-income households',
              description: '• Automatic eligibility check\n'
                  '• No premium payment required\n'
                  '• Coverage activated immediately if approved',
              icon: Icons.volunteer_activism,
              color: Colors.green,
              isRecommended: true, // You can make this dynamic later
              onSelect: () {
                regCubit.submitMembership(
                  MembershipSelection(type: MembershipType.indigent),
                );
              },
            ),

            const SizedBox(height: 20),

            // Paying Option
            _buildMembershipCard(
              context: context,
              title: 'Paying Member',
              subtitle: 'Standard CBHI Membership',
              description: '• Pay annual premium\n'
                  '• Full coverage benefits\n'
                  '• Premium: ETB 500 / household (example)',
              icon: Icons.payment,
              color: Colors.blue,
              isRecommended: false,
              onSelect: () {
                regCubit.submitMembership(
                  MembershipSelection(
                    type: MembershipType.paying,
                    premiumAmount: 500.0, // You can make this dynamic from backend
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.errorMessage != null)
              Text(
                'Error: ${state.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool isRecommended,
    required VoidCallback onSelect,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: color, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Select This Option'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}