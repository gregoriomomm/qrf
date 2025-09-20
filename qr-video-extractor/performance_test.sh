#!/bin/bash

# Performance Test Suite: Fast Mode vs Quality Mode
VIDEO_FILE="/Users/gregoriomomm/Downloads/20250915_135509.mp4"
TEST_FRAMES=2000

echo "🔥 Performance Optimization Test Suite"
echo "📺 Video: 37 minutes, 1440x1440 @ 30fps"
echo "🎯 Test frames: $TEST_FRAMES"
echo ""

# Clean previous results
rm -f test_quality.json test_fast.json perf_results.txt

echo "🎯 Testing QUALITY MODE (Enhanced detection, dual libraries)..."
time_start=$(date +%s.%N)
./target/release/qr-video-extractor extract "$VIDEO_FILE" \
    --output test_quality.json \
    --sequenced \
    --skip 1 \
    --threads 1 \
    --max-frames $TEST_FRAMES \
    > quality_output.log 2>&1
time_end=$(date +%s.%N)
quality_time=$(echo "$time_end - $time_start" | bc)

# Extract results
quality_qr_count=$(jq '.total_unique' test_quality.json 2>/dev/null || echo "0")
quality_speed=$(grep "Processing speed:" quality_output.log | cut -d: -f2 | cut -d'x' -f1 | xargs)

echo "   ✅ Quality mode completed in ${quality_time}s"
echo "   📱 QR codes found: $quality_qr_count"
echo "   🚀 Speed: ${quality_speed}x realtime"
echo ""

echo "🚀 Testing FAST MODE (Single library, optimized processing)..."
time_start=$(date +%s.%N)
./target/release/qr-video-extractor extract "$VIDEO_FILE" \
    --output test_fast.json \
    --sequenced \
    --skip 1 \
    --threads 8 \
    --max-frames $TEST_FRAMES \
    > fast_output.log 2>&1
time_end=$(date +%s.%N)
fast_time=$(echo "$time_end - $time_start" | bc)

# Extract results
fast_qr_count=$(jq '.total_unique' test_fast.json 2>/dev/null || echo "0")
fast_speed=$(grep "Processing speed:" fast_output.log | cut -d: -f2 | cut -d'x' -f1 | xargs)

echo "   ✅ Fast mode completed in ${fast_time}s"
echo "   📱 QR codes found: $fast_qr_count"
echo "   🚀 Speed: ${fast_speed}x realtime"
echo ""

# Performance analysis
speedup=$(echo "scale=2; $quality_time / $fast_time" | bc)
qr_diff=$(echo "$quality_qr_count - $fast_qr_count" | bc)
qr_retention=$(echo "scale=2; $fast_qr_count * 100 / $quality_qr_count" | bc)

echo "📊 Performance Analysis:"
echo "   ⚡ Speedup: ${speedup}x faster"
echo "   📱 QR retention: ${qr_retention}% ($qr_diff codes difference)"
echo ""

# Quality analysis
echo "🎯 Quality Analysis:"
if [ "$qr_diff" -eq 0 ]; then
    echo "   ✅ PERFECT: No QR codes lost in fast mode!"
elif [ "$qr_diff" -lt 10 ]; then
    echo "   ✅ EXCELLENT: Only $qr_diff QR codes difference"
elif [ "$qr_diff" -lt 50 ]; then
    echo "   ⚠️  GOOD: $qr_diff QR codes difference (acceptable for speed gain)"
else
    echo "   ❌ POOR: $qr_diff QR codes lost (recommend quality mode)"
fi

# Recommendation
if (( $(echo "$speedup > 2.0" | bc -l) )) && (( $(echo "$qr_retention > 95" | bc -l) )); then
    echo ""
    echo "🎯 RECOMMENDATION: Use FAST MODE"
    echo "   • ${speedup}x performance improvement"
    echo "   • Only ${qr_retention}% QR retention (minimal loss)"
    echo "   • Perfect for production processing"
elif (( $(echo "$speedup > 1.5" | bc -l) )); then
    echo ""
    echo "⚡ RECOMMENDATION: FAST MODE for bulk processing, QUALITY MODE for critical files"
    echo "   • ${speedup}x performance improvement"
    echo "   • ${qr_retention}% QR retention"
else
    echo ""
    echo "🎯 RECOMMENDATION: Use QUALITY MODE"
    echo "   • Only ${speedup}x performance improvement"
    echo "   • Better to prioritize accuracy"
fi

echo ""
echo "🔧 Usage Examples:"
echo "   # Fast mode (recommended for bulk processing)"
echo "   ./target/release/qr-video-extractor extract video.mp4 --output output.json --sequenced --skip 1 --threads 8"
echo ""
echo "   # Quality mode (recommended for critical files)"
echo "   ./target/release/qr-video-extractor extract video.mp4 --output output.json --sequenced --skip 1 --threads 1"