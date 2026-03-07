class InterstitialAdDecision {
  const InterstitialAdDecision({
    required this.updatedOpportunityCount,
    required this.shouldShowInterstitial,
  });

  final int updatedOpportunityCount;
  final bool shouldShowInterstitial;
}

InterstitialAdDecision evaluateInterstitialAdOpportunity({
  required int currentOpportunityCount,
  required DateTime now,
  required DateTime? lastInterstitialAt,
  required int everyOpportunities,
  required Duration cooldown,
}) {
  final updatedCount = currentOpportunityCount + 1;
  final hitsOpportunity = updatedCount % everyOpportunities == 0;
  if (!hitsOpportunity) {
    return InterstitialAdDecision(
      updatedOpportunityCount: updatedCount,
      shouldShowInterstitial: false,
    );
  }

  final stillCoolingDown =
      lastInterstitialAt != null && now.difference(lastInterstitialAt) < cooldown;
  if (stillCoolingDown) {
    return InterstitialAdDecision(
      updatedOpportunityCount: updatedCount,
      shouldShowInterstitial: false,
    );
  }

  return InterstitialAdDecision(
    updatedOpportunityCount: updatedCount,
    shouldShowInterstitial: true,
  );
}