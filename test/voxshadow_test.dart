import 'package:test/test.dart';
import 'package:voxshadow/voxshadow.dart';

void main() {
  test('ShadowCascadeSplitter blends uniform & log splits monotonically with lambda', () {
    final splits = ShadowCascadeSplitter.computeSplits(
      nearPlane: 0.1,
      farPlane: 100.0,
      cascadeCount: 4,
      lambda: 0.65,
    );

    expect(splits.length, 4);
    expect(splits.first.nearPlane, closeTo(0.1, 1e-6));
    expect(splits.last.farPlane, closeTo(100.0, 1e-5));
    expect(splits.last.normalizedSplitDepth, closeTo(1.0, 1e-6));
    for (var i = 0; i < splits.length - 1; i++) {
      expect(splits[i].farPlane, closeTo(splits[i + 1].nearPlane, 1e-6));
      expect(splits[i].farPlane, greaterThan(splits[i].nearPlane));
    }

    // Pure log splits concentrate much tighter near the camera than uniform splits.
    final uniformSplits = ShadowCascadeSplitter.computeSplits(
      nearPlane: 0.1,
      farPlane: 100.0,
      cascadeCount: 4,
      lambda: 0.0,
    );
    final logSplits = ShadowCascadeSplitter.computeSplits(
      nearPlane: 0.1,
      farPlane: 100.0,
      cascadeCount: 4,
      lambda: 1.0,
    );
    expect(logSplits.first.farPlane, lessThan(uniformSplits.first.farPlane));
  });

  test('LightOrthoFitter snaps orthographic bounds to discrete shadow texels under sub-texel shift', () {
    final lightDir = const ShadowVec3(0.4, -0.85, -0.34).normalized();
    final orthoA = LightOrthoFitter.fitCascade(
      cameraPosition: const ShadowVec3(10.0, 2.0, 10.0),
      cameraForward: const ShadowVec3(0.0, 0.0, -1.0),
      cameraUp: const ShadowVec3(0.0, 1.0, 0.0),
      fovYRadians: 1.0,
      aspectRatio: 16.0 / 9.0,
      splitNear: 0.5,
      splitFar: 25.0,
      lightForward: lightDir,
      shadowMapResolution: 512,
      snapToTexels: true,
    );

    // Move camera slightly by less than half a shadow texel.
    final tinyOffset = orthoA.texelWorldSize * 0.15;
    final orthoB = LightOrthoFitter.fitCascade(
      cameraPosition: ShadowVec3(10.0 + tinyOffset, 2.0, 10.0),
      cameraForward: const ShadowVec3(0.0, 0.0, -1.0),
      cameraUp: const ShadowVec3(0.0, 1.0, 0.0),
      fovYRadians: 1.0,
      aspectRatio: 16.0 / 9.0,
      splitNear: 0.5,
      splitFar: 25.0,
      lightForward: lightDir,
      shadowMapResolution: 512,
      snapToTexels: true,
    );

    expect(orthoA.width, closeTo(orthoA.sphereRadius * 2.0, 1e-6));
    expect(orthoB.minX, closeTo(orthoA.minX, 1e-6));
    expect(orthoB.minY, closeTo(orthoA.minY, 1e-6));
    expect(orthoA.farZ, greaterThan(orthoA.nearZ));
  });

  test('PcssKernelTable normalizes Vogel disk weights and scales penumbra width by blocker depth', () {
    final kernel = PcssKernelTable.vogelDisk(sampleCount: 16);
    expect(kernel.taps.length, 16);
    final totalW = kernel.taps.fold<double>(0.0, (acc, t) => acc + t.weight);
    expect(totalW, closeTo(1.0, 1e-6));
    for (final t in kernel.taps) {
      expect(t.u * t.u + t.v * t.v, lessThanOrEqualTo(1.0 + 1e-6));
    }

    final nearShadow = PcssKernelTable.estimatePenumbraWidth(
      receiverDepth: 11.0,
      averageBlockerDepth: 10.0,
      lightWorldRadius: 1.0,
    );
    final farShadow = PcssKernelTable.estimatePenumbraWidth(
      receiverDepth: 18.0,
      averageBlockerDepth: 10.0,
      lightWorldRadius: 1.0,
    );
    expect(nearShadow, closeTo(0.1, 1e-6));
    expect(farShadow, greaterThan(nearShadow));
  });
}
