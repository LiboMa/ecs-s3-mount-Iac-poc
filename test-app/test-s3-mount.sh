#!/bin/bash

# S3 Mount Test Script
echo "=========================================="
echo "ECS S3 Mount Test Application"
echo "=========================================="
echo "Start time: $(date)"
echo ""

# Test 1: Check if S3 mount point exists
echo "Test 1: Checking S3 mount point..."
if [ -d "/app/s3-data" ]; then
    echo "✓ S3 mount point exists: /app/s3-data"
else
    echo "✗ S3 mount point not found: /app/s3-data"
    exit 1
fi
echo ""

# Test 2: List S3 mount contents
echo "Test 2: Listing S3 mount contents..."
echo "Contents of /app/s3-data:"
ls -la /app/s3-data/
echo ""

# Test 3: Check test-data directory
echo "Test 3: Checking test-data directory..."
if [ -d "/app/s3-data/test-data" ]; then
    echo "✓ test-data directory found"
    echo "Contents of test-data directory:"
    ls -la /app/s3-data/test-data/
else
    echo "✗ test-data directory not found"
fi
echo ""

# Test 4: Read sample.txt file
echo "Test 4: Reading sample.txt file..."
if [ -f "/app/s3-data/test-data/sample.txt" ]; then
    echo "✓ sample.txt found, contents:"
    cat /app/s3-data/test-data/sample.txt
else
    echo "✗ sample.txt not found"
fi
echo ""

# Test 5: Read config.json file
echo "Test 5: Reading config.json file..."
if [ -f "/app/s3-data/test-data/config.json" ]; then
    echo "✓ config.json found, contents:"
    cat /app/s3-data/test-data/config.json | jq .
else
    echo "✗ config.json not found"
fi
echo ""

# Test 6: Write test (if writable)
echo "Test 6: Testing write capability..."
TEST_FILE="/app/s3-data/test-write-$(date +%s).txt"
if echo "Test write at $(date)" > "$TEST_FILE" 2>/dev/null; then
    echo "✓ Write test successful: $TEST_FILE"
    echo "File contents:"
    cat "$TEST_FILE"
    rm -f "$TEST_FILE" 2>/dev/null
else
    echo "ℹ Write test failed (may be read-only mount)"
fi
echo ""

# Test 7: Performance test
echo "Test 7: Basic performance test..."
echo "Counting files in S3 mount..."
FILE_COUNT=$(find /app/s3-data -type f 2>/dev/null | wc -l)
echo "✓ Found $FILE_COUNT files in S3 mount"
echo ""

echo "=========================================="
echo "S3 Mount Test Completed Successfully!"
echo "End time: $(date)"
echo "=========================================="

# Keep container running for inspection
echo "Container will continue running for monitoring..."
tail -f /dev/null