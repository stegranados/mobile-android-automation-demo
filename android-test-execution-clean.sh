#!/bin/bash
set -e

echo "=== Using JDK 21 for compatibility ==="
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH=$JAVA_HOME/bin:$PATH

echo "Java version:"
java -version

echo "=== Killing all processes ==="
./gradlew --stop
sleep 2
pkill -9 -f KotlinCompileDaemon || true
pkill -9 -f GradleDaemon || true
sleep 2

echo "=== Nuclear cache cleanup ==="
rm -rf ~/.gradle/caches/
rm -rf ~/.gradle/daemon/
rm -rf ~/.gradle/wrapper/dists/
rm -rf .gradle/
rm -rf ~/.kotlin/
rm -rf app/build/
rm -rf build/
rm -rf */build/

echo "=== Verify Gradle version ==="
./gradlew -version

echo "=== Sync dependencies ==="
./gradlew --refresh-dependencies --no-daemon --no-build-cache

echo "=== Test compilation ==="
./gradlew :app:assembleBetaDebug \
  --no-daemon \
  --no-build-cache \
  -Dkotlin.compiler.execution.strategy=in-process \
  --stacktrace

echo "=== Compilation successful! Launching emulator ==="
emulator -avd mp-36 -no-window -no-audio -memory 4096 -cores 4 -gpu swiftshader_indirect &
EMULATOR_PID=$!

echo "Waiting for emulator..."
WAIT_TIMEOUT=300
ELAPSED=0
while ! adb devices | grep -q "device$"; do
  if [ $ELAPSED -ge $WAIT_TIMEOUT ]; then
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

BOOT_TIMEOUT=180
ELAPSED=0
until [[ -n $(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') ]]; do
  if [ $ELAPSED -ge $BOOT_TIMEOUT ]; then
    adb emu kill
    exit 1
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

sleep 10
adb shell input keyevent 82

echo "=== Running tests ==="
./gradlew connectedBetaDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=org.wikipedia.testsuites.AndroidMobileTestSuite \
  --no-daemon \
  --no-build-cache \
  --max-workers=2 \
  -Dkotlin.compiler.execution.strategy=in-process \
  --stacktrace

adb emu kill
echo "=== Complete! ==="
