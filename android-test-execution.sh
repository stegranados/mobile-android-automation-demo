#!/bin/bash
set -e

echo "=== Setting JDK 21 ==="
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH

echo "=== Launching emulator ==="
emulator -avd mp-36 -no-window -no-audio -memory 4096 -cores 4 -gpu swiftshader_indirect &
EMULATOR_PID=$!

echo "Waiting for emulator to connect..."
WAIT_TIMEOUT=300
ELAPSED=0
while ! adb devices | grep -q "device$"; do
  if [ $ELAPSED -ge $WAIT_TIMEOUT ]; then
    echo "ERROR: Emulator failed to connect"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

echo "Waiting for boot to complete..."
BOOT_TIMEOUT=180
ELAPSED=0
until [[ -n $(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') ]]; do
  if [ $ELAPSED -ge $BOOT_TIMEOUT ]; then
    echo "ERROR: Boot timeout"
    adb emu kill
    exit 1
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

echo "Emulator ready! Waiting 10 seconds for stability..."
sleep 10

echo "Unlocking screen..."
adb shell input keyevent 82

echo "Device status:"
adb devices

echo "=== Running tests ==="
./gradlew connectedBetaDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=org.wikipedia.testsuites.AndroidMobileTestSuite \
  --stacktrace

echo "=== Shutting down emulator ==="
adb emu kill

echo "=== Tests complete! ==="
