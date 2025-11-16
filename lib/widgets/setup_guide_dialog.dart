import 'package:flutter/material.dart';

/// 노션 설정 가이드 다이얼로그
class SetupGuideDialog extends StatelessWidget {
  const SetupGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📘 Setup Guide'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              title: '1️⃣ Create Notion Integration',
              steps: [
                'Go to https://www.notion.so/my-integrations',
                'Click "New integration"',
                'Name it (e.g., "My Widget")',
                'Select workspace',
                'Click "Submit"',
                'Copy the "Internal Integration Token"',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '2️⃣ Create or Open Database',
              steps: [
                'Open any Notion page',
                'Type "/database" and create a new database',
                'Or use an existing database',
                'Add some pages to the database',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '3️⃣ Connect Integration to Database',
              steps: [
                'Open your database page',
                'Click "..." (top right)',
                'Click "Connections"',
                'Select your integration',
                'Click "Confirm"',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '4️⃣ Get Database ID',
              steps: [
                'Copy the database URL',
                'Paste the full URL in the app',
                'Or extract the ID manually:',
                '  - URL format: notion.so/xxxxx?v=yyyyy',
                '  - ID is the "xxxxx" part (32 characters)',
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Pro Tips:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Use Notion\'s template gallery for pre-made databases',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• Integration token starts with "secret_"',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• You can paste the full database URL',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '• Database must have pages to display',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<String> steps}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
