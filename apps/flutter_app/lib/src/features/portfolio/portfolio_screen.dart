import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_card.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Portfolio',
      child: ListView(
        children: const [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net PnL', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('\$660', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Open YES position in BTC > \$120k and HashKey TVL market'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
