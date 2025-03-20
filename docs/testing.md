<!--
SPDX-FileCopyrightText: 2025 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Testing</h1>

<!-- TOC -->
* [Overview](#overview)
* [Test concept](#test-concept)
  * [Rely on upstream applications QA](#rely-on-upstream-applications-qa)
  * [Run minimal functional QA (end-to-end tests)](#run-minimal-functional-qa-end-to-end-tests)
  * [Run extensive load and performance tests](#run-extensive-load-and-performance-tests)
    * [Base performance testing](#base-performance-testing)
    * [Load testing to saturation point](#load-testing-to-saturation-point)
    * [Load testing up to a defined user count](#load-testing-up-to-a-defined-user-count)
    * [Overload/recovery tests](#overloadrecovery-tests)
* [Reporting and test results](#reporting-and-test-results)
  * [Allure TestOps](#allure-testops)
<!-- TOC -->

# Overview

The following section provides an overview of the testing approach adopted to ensure the quality and reliability of openDesk. This concept balances leveraging existing quality assurance (QA) processes with targeted testing efforts tailored to the specific needs of openDesk. The outlined strategy focuses on three key areas:

1. Relying on application QA: Utilizing the existing QA processes of the applications to ensure baseline functionality and quality standards.
2. Minimal functional QA: Executing end-to-end tests to validate critical workflows and ensure that key functionalities operate as expected.
3. Extensive load and performance testing: Conducting comprehensive load and performance tests to assess openDesk's scalability and responsiveness under varying usage conditions.

These efforts are designed to complement each other, minimizing redundancy while ensuring robust testing coverage.

# Test concept

## Rely on upstream applications QA

openDesk contains applications from different suppliers. As a general approach, we rely on the testing
conducted by these suppliers for their respective applications.

We review the supplier's QA measures on a regular basis, to ensure a reliable and sufficient QA of the underlying applications.

We receive the release notes early before a new application release is integrated into openDesk, so
we are able to check for the existence of a sufficient set of test cases.
The suppliers create a set of test cases for each new function.

## Run minimal functional QA (end-to-end tests)

To ensure the function of all applications, we run a minimal set of testcases to check the
basic functionality of openDesk along with the integrated applications.

Furthermore, we analyze all features and use cases which are implemented by a set of more than one
application.
Not all of these features are testable by the suppliers, so we develop testcases
for such features.

The openDesk application owners prioritize this list of end-to-end-testcases, and we
implement these testcases in the [test automation framework](https://gitlab.opencode.de/bmi/opendesk/deployment/e2e-tests).

## Run extensive load and performance tests

Our goal is to deliver openDesk as application-grade software with the ability to serve large user bases.

We create and perform extensive load and performance tests for each release of openDesk.

Our approach consists of different layers of load testing.

### Base performance testing

For these tests we define a set of "normal", uncomplicated user-interactions with openDesk.

For each testcase in this set, we measure the duration of the whole testcase (and individual steps within the
testcase) on a given, unloaded environment, prepared with a predefined setup and openDesk release installed.

As a result, we receive the total runtime of one iteration of the given testcase, the runtime of each
step inside the testcase, the error rate and min/max/median runtimes.

Most importantly, the environment should not be used by other users or have running background tasks, so it should
be an environment in a mostly idle state.

The results can be compared with the results of the previous release, so we can see if changes
in software components improve or decrease the performance of a testcase.

### Load testing to saturation point

These tests are performed to ensure the correct processing and user interaction, even under
high-load scenarios.

We use the same test cases as in the base performance tests.

Now we measure the duration on a well-defined environment while the system is being used
by a predefined number of test users in parallel. The number of users is incrementally scaled up.

Our goal is to see constant runtimes of each testcase iteration, despite the increased overall throughput due to the increasing number of parallel users.

At a certain point, increasing the number of users does not lead to higher overall throughput, but instead leads to an increase in the runtime of each testcase iteration.

This point, the saturation point, is the load limit of the environment. Up to this point, the
environment and the installed software packages can handle the load. Beyond this point, response times increase and error rates rise.

### Load testing up to a defined user count

For partners interested in large scale openDesk deployments,
we offer a tailored workshop in which we define scenarios and perform load testing analysis.

This way, we can help you decide on the appropriate sizing for the planned openDesk deployment.

### Overload/recovery tests

If necessary, we perform overload tests, which will saturate the system with multiple
test cases until no further increase in throughput is visible. Then we add even more load
until the first HTTP requests run into timeouts or errors.
After a few minutes, we reduce the load below the saturation point.
Then we check if the system is able to recover from the overload status.

# Reporting and test results

We perform test runs every night, on all of our environments.

For each environment, we define so-called profiles, these contain the features enabled
per environment.

For example: Testing the email features in an environment without deployment of Open-Xchange makes no sense at all.

Also, we test the whole system via a browser with `language=DE` and another browser with `language=EN`.

The test results are saved in an [Allure TestOps](https://qameta.io/) server, so interested persons
are able to view the test results later in detail.

## Allure TestOps

The Allure TestOps [server](https://testops.opendesk.run/) is currently only accessible to project members.

The relevant project is called *opendesk*.

To get an overview, click in the left symbol list onto the symbol "Rocket" to
check all relevant launches.

Now you can see the launch #xxxx, and directly check for the success
of this launch.
