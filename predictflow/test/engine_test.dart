import 'package:predictflow/predictflow.dart';
import 'package:test/test.dart';

void main() {
  test('engine exposes seeded markets', () {
    final engine = PredictFlowEngine();
    expect(engine.listMarkets(), isNotEmpty);
  });

  test('buy order updates portfolio and market snapshot', () {
    final engine = PredictFlowEngine();
    final result = engine.placeOrder(
      marketId: 'fed-cut-june',
      wallet: 'demo-wallet',
      outcome: Outcome.yes,
      side: Side.buy,
      type: OrderType.market,
      shares: 10,
    );

    expect(result.fills, isNotEmpty);
    expect(engine.getPortfolio('demo-wallet').positions, isNotEmpty);
  });
}
