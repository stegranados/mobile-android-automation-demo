package org.wikipedia.testsuites

import org.junit.runner.RunWith
import org.junit.runners.Suite
import org.junit.runners.Suite.SuiteClasses
import org.wikipedia.tests.settings.ChangingLanguageTest
import org.wikipedia.tests.settings.FontSizeTest

@RunWith(Suite::class)
@SuiteClasses(
    ChangingLanguageTest::class,
    FontSizeTest::class
)
class AndroidMobileTestSuite

