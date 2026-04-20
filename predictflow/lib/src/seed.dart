import 'models.dart';

List<Market> seedMarkets() {
  final now = DateTime.now().toUtc();
  return [
    Market(
      id: 'fed-cut-june',
      address: '0xPF001',
      title: 'Will the Fed cut rates in June?',
      description: 'Binary macro market for the next FOMC decision.',
      category: 'Macro',
      resolutionSource: 'Fed statement',
      closesAt: now.add(const Duration(days: 18)),
      liquidityUsd: 125000,
      volume24h: 46000,
      yesPrice: 0.54,
      noPrice: 0.46,
      spread: 0.01,
      spreadTier: 'HIGH',
      ammYesReserve: 62000,
      ammNoReserve: 58000,
      rebateBps: 10,
      feeBps: 35,
      topProviders: [
        LiquidityProviderPosition(
          wallet: '0xmaker1',
          collateral: 42000,
          sharePct: 0.34,
        ),
        LiquidityProviderPosition(
          wallet: '0xmaker2',
          collateral: 31000,
          sharePct: 0.25,
        ),
      ],
    ),
    Market(
      id: 'btc-120k-2026',
      address: '0xPF002',
      title: 'Will BTC hit 120k before year-end?',
      description: 'Crypto milestone probability market.',
      category: 'Crypto',
      resolutionSource: 'Reference exchange index',
      closesAt: now.add(const Duration(days: 70)),
      liquidityUsd: 72000,
      volume24h: 28000,
      yesPrice: 0.41,
      noPrice: 0.59,
      spread: 0.02,
      spreadTier: 'MEDIUM',
      ammYesReserve: 29500,
      ammNoReserve: 42500,
      rebateBps: 10,
      feeBps: 40,
      topProviders: [
        LiquidityProviderPosition(
          wallet: '0xmaker3',
          collateral: 22000,
          sharePct: 0.31,
        ),
      ],
    ),
  ];
}

List<Portfolio> seedPortfolios() {
  return [
    Portfolio(
      wallet: 'demo-wallet',
      collateralBalance: 5000,
      realizedPnl: 180,
      positions: [
        PortfolioPosition(
          marketId: 'fed-cut-june',
          title: 'Will the Fed cut rates in June?',
          outcome: Outcome.yes,
          shares: 120,
          avgEntry: 0.49,
          markPrice: 0.54,
          unrealizedPnl: 6,
        ),
      ],
    ),
  ];
}
