
import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Recova'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 20),

          _buildSectionTitle('Recova Features'),

          _buildFeatureCard(
            icon: Icons.restore,
            title: 'Recently Deleted Recovery',
            description:
                'Finds media that Android still exposes through '
                'Trash or Recently Deleted locations and helps '
                'restore those files using Android-supported recovery '
                'mechanisms.',
          ),

          _buildFeatureCard(
            icon: Icons.photo_library_outlined,
            title: 'Accessible Media Recovery',
            description:
                'Finds photos, videos and supported documents that '
                'are still accessible on your device and allows you '
                'to save them into the Recova recovery folder.',
          ),

          _buildFeatureCard(
            icon: Icons.folder_off_outlined,
            title: 'Hidden Media Finder',
            description:
                'Searches accessible storage locations for media '
                'that may not appear in your normal Gallery or file '
                'browser views.',
          ),

          _buildFeatureCard(
            icon: Icons.history,
            title: 'Recovery History',
            description:
                'Keeps track of successfully processed recovery '
                'operations and displays your total Recovered count.',
          ),

          _buildFeatureCard(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            description:
                'Provides backup and restore functionality for '
                'supported Recova data and recovery information.',
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('Where Recovered Files Are Saved'),

          _buildPathCard(),

          const SizedBox(height: 20),

          _buildSectionTitle('How Recova Works'),

          _buildHowItWorks(),

          const SizedBox(height: 20),

          _buildSectionTitle('Important Recovery Information'),

          _buildImportantCard(),

          const SizedBox(height: 20),

          _buildSectionTitle('Supported Recovery'),

          _buildSupportedCard(),

          const SizedBox(height: 20),

          _buildSectionTitle('What Recova Cannot Guarantee'),

          _buildLimitationsCard(),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Recova\nSmart Media Recovery & File Rescue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF185ABC),
            Color(0xFF2E75B6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.restore,
            color: Colors.white,
            size: 60,
          ),
          SizedBox(height: 12),
          Text(
            'Recova',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Smart Media Recovery & File Rescue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF185ABC)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF185ABC),
                size: 27,
              ),
            ),
           const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.folder,
                  color: Color(0xFF185ABC),
                ),
                SizedBox(width: 10),
                Text(
                  'Recovery Folder',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '/Recova/Recovered/',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Recovered photos, videos and supported documents '
              'are organized inside the Recova recovery folder.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            _step(
              number: '1',
              icon: Icons.search,
              title: 'Scan',
              description:
                  'Recova scans supported and accessible media '
                  'locations.',
            ),
            _line(),
            _step(
              number: '2',
              icon: Icons.folder_open,
              title: 'Find',
              description:
                  'Recova identifies accessible media and '
                  'Android-exposed Recently Deleted items.',
            ),
            _line(),
            _step(
              number: '3',
              icon: Icons.check_circle_outline,
              title: 'Select',
              description:
                  'Choose the files you want to recover.',
            ),
            _line(),
            _step(
              number: '4',
              icon: Icons.restore,
              title: 'Recover',
              description:
                  'Recova processes the selected files using '
                  'the appropriate recovery method.',
            ),
            _line(),
            _step(
              number: '5',
              icon: Icons.folder_special,
              title: 'Save',
              description:
                  'Successfully recovered accessible files are '
                  'saved in the Recova recovery folder.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF185ABC),
            borderRadius: BorderRadius.circular(21),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF185ABC),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
Widget _line() {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 6,
        bottom: 6,
      ),
      height: 18,
      width: 2,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildImportantCard() {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.orange.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade800,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recova cannot guarantee recovery of permanently '
                'deleted files. Android normally prevents ordinary '
                'apps from accessing storage data that has been '
                'permanently deleted or overwritten.\n\n'
                'Recova focuses on files that Android still exposes '
                'through Recently Deleted / Trash or files that '
                'remain accessible on the device.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            _BulletItem(
              icon: Icons.check_circle,
              text:
                  'Android Trash / Recently Deleted media '
                  'that is still exposed to the app',
            ),
            _BulletItem(
              icon: Icons.check_circle,
              text:
                  'Accessible photos and images',
            ),
            _BulletItem(
              icon: Icons.check_circle,
              text:
                  'Accessible videos',
            ),
            _BulletItem(
              icon: Icons.check_circle,
              text:
                  'Supported accessible documents',
            ),
            _BulletItem(
              icon: Icons.check_circle,
              text:
                  'Hidden or unusual folders that remain '
                  'accessible to the app',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationsCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.red.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            _limitation(
              'Permanently erased files',
            ),
            _limitation(
              'Storage sectors that have been overwritten',
            ),
            _limitation(
              'Forensic recovery requiring root or '
              'specialized hardware',
            ),
            _limitation(
              'Files that Android no longer exposes '
              'to ordinary applications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _limitation(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.cancel,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

