import 'dart:math' as math;

/// 2D Poisson / Vogel disk kernel sample with radial weight for blocker search & soft PCF filtering.
final class PoissonTapOffset {
  final double u;
  final double v;
  final double weight;

  const PoissonTapOffset({
    required this.u,
    required this.v,
    required this.weight,
  });
}

/// Deterministic Vogel-spiral Poisson sample table & PCSS penumbra radius estimator.
final class PcssKernelTable {
  final List<PoissonTapOffset> taps;

  const PcssKernelTable._(this.taps);

  /// Generates [sampleCount] unit-disk Poisson taps distributed via golden-angle Vogel spiral.
  factory PcssKernelTable.vogelDisk({
    int sampleCount = 16,
    double angleOffsetRadians = 0.0,
  }) {
    final count = sampleCount.clamp(1, 128);
    const goldenAngle = 2.399963229728653; // pi * (3 - sqrt(5))
    final raw = <PoissonTapOffset>[];
    var weightSum = 0.0;

    for (var i = 0; i < count; i++) {
      final r = math.sqrt((i + 0.5) / count);
      final theta = i * goldenAngle + angleOffsetRadians;
      final u = r * math.cos(theta);
      final v = r * math.sin(theta);
      // Smooth Gaussian-like radial falloff weight.
      final w = math.exp(-1.5 * r * r);
      weightSum += w;
      raw.add(PoissonTapOffset(u: u, v: v, weight: w));
    }

    final normalized = raw
        .map(
          (t) => PoissonTapOffset(
            u: t.u,
            v: t.v,
            weight: weightSum <= 1e-12 ? (1.0 / count) : t.weight / weightSum,
          ),
        )
        .toList(growable: false);
    return PcssKernelTable._(normalized);
  }

  /// Estimates world/UV penumbra width using parallel-plane PCSS formula:
  /// `(receiverDepth - avgBlockerDepth) * lightWorldRadius / avgBlockerDepth`.
  static double estimatePenumbraWidth({
    required double receiverDepth,
    required double averageBlockerDepth,
    double lightWorldRadius = 0.5,
    double minPenumbra = 0.0,
    double maxPenumbra = 8.0,
  }) {
    if (averageBlockerDepth <= 1e-5 || receiverDepth <= averageBlockerDepth) {
      return minPenumbra;
    }
    final penumbra =
        (receiverDepth - averageBlockerDepth) * math.max(0.0, lightWorldRadius) / averageBlockerDepth;
    return penumbra.clamp(minPenumbra, maxPenumbra).toDouble();
  }
}
