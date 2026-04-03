import 'models.dart';

const markets = <Market>[
  Market(
    id: 'btc-120k',
    title: 'Will BTC exceed \$120k before Dec 31 2026?',
    category: 'Crypto',
    yesProbability: 0.74,
    aiConfidence: 0.91,
    volume: 842300,
    liquidity: 320000,
    points: [0.65, 0.68, 0.71, 0.74],
  ),
  Market(
    id: 'hashkey-tvl',
    title: 'Will HashKey Chain TVL exceed \$50M by Q3?',
    category: 'Ecosystem',
    yesProbability: 0.58,
    aiConfidence: 0.79,
    volume: 265800,
    liquidity: 180000,
    points: [0.49, 0.52, 0.55, 0.58],
  ),
  Market(
    id: 'eth-etf',
    title: 'Will ETH ETF volume double by year end?',
    category: 'Macro',
    yesProbability: 0.63,
    aiConfidence: 0.84,
    volume: 410500,
    liquidity: 245000,
    points: [0.55, 0.59, 0.61, 0.63],
  ),
];

const agents = <AgentCardModel>[
  AgentCardModel(
    name: 'Liquidity Agent',
    status: 'Intervening',
    summary: 'Injecting depth into BTC macro markets before volatility windows.',
    pnl: 18420,
  ),
  AgentCardModel(
    name: 'Arbitrage Agent',
    status: 'Active',
    summary: 'Capturing spread dislocations between venue clusters.',
    pnl: 9260,
  ),
  AgentCardModel(
    name: 'Sentinel Agent',
    status: 'Watching',
    summary: 'Monitoring whale wallet clusters and abnormal coordination.',
    pnl: 0,
  ),
];
