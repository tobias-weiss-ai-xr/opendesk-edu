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
  * [Run extensive load- and performance tests](#run-extensive-load--and-performance-tests)
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
3. Extensive load and performance testing: Conducting comprehensive load and performance tests to assess openDesk's scalability and response under varying usage conditions.

These efforts are designed to complement each other, minimizing redundancy while ensuring robust testing coverage.

# Test concept

## Rely on upstream applications QA

openDesk contains applications from different suppliers, as a general approach, we rely on the testing
conducted by these suppliers for their respective applications.

We review the supplier's QA measures on a regular basis, to ensure a reliable and sufficient QA of the underlying applications.

We receive the release notes early before a new application release is integrated into openDesk, so
we are able to check the existence of a sufficient set of test scases.
The suppliers create a set of test cases for each new functionality.

## Run minimal functional QA (end-to-end tests)

To ensure the functioning of all applications, we run a minimal set of testcases to check the
basic functionality of openDesk and all integrated applications.

Furthermore, we analyze all features/usecases which are implemented by a set of more than one
applications.
All these features are not testable naturally by the suppliers, so we develop testcases
for such features.

The openDesk application owners prioritize then this list of end-to-end-testcases, and we
implement these testcases in the [test automation framework](https://gitlab.opencode.de/bmi/opendesk/deployment/e2e-tests).

## Run extensive load- and performance tests

We want to deliver openDesk as an application-grade software with the ability to serve a large user base.

We create and perform extensive load- and performance tests for every release of openDesk.

Our approach consists of different layers of load testing.

### Base performance testing

For these tests we define a set of "normal", not too complicated user-interactions with openDesk.

For each testcase in this set, we measure the duration of the whole testcase (and steps inside the
testcase) on a given, unloaded environment, installed with a predefined setup and openDesk release.

As a result, we receive the total runtime of one iteration of the given testcase, the runtime of each
step inside the testcase, the error rate and min/max/median runtimes.

Most importantly, the environment should not be used by other users or background tasks, so it should
be an environment being mostly in idle state.

The results can be compared with the results of the previous release, so we can see if changes
in software components improve or decrease the performance of a testcase.

### Load testing to saturation point

These tests are performed to ensure the correct processing and user interactions even in
high-load scenarios.

We use the same test cases as in the base performance tests.

Now we measure the duration on a well-defined environment while the system is being used
by a predefined number of test users in parallel. This number will be scaled up.

Our goal is to see constant runtimes of each testcase iteration, while the total throughput
of requests increases consistently with the number of users in parallel usage of the system.

At a distinct point, a further increase of the number of users leads to no more increase of the
total throughput, but instead leads to an increase in the runtime of each testcase iteration.

This point, the saturation point, is the load limit of the environment. Up to this point the
environment and the installed software packages can handle the load. More load over this point
leads to increased response times and increased error rates.

### Load testing up to a defined user count

For interested partners, that are looking into large scale openDesk deployments,
we offer a load testing analysis based on defined scenarios to be discussed together with the partner in a workshop.

This way, we can help to decide on the appropriate sizing for the planned openDesk usage scenario.

### Overload/recovery tests

If necessary, we perform overload tests, which will saturate the system with multiple
test cases until no further increase in throughput is visible. Then we add even more load
until the first HTTP requests run into timeouts or errors.
After a few minutes, we reduce the load below the saturation point.
Now we can check if the system is able to recover from the overload status.

# Reporting and test results

We perform testruns every night on every of our environments.

For each environment, we define so called profiles, these contains the features enabled
per environment.

For example: Testing the email features in an environment without deployment of Open-Xchange makes no sense at all.

Also we test the whole system via a browser with `language=DE` and another browser with `language=EN`.

The test results will be saved in an [Allure TestOps](https://qameta.io/) server, so interested persons
are able to view the test results in detail.

## Allure TestOps

The Allure TestOps [server](https://testops.opendesk.run/) is currently only accessible to project members.

The relevant project is called *opendesk*.

To get an overview, click in the left symbol list onto the symbol "Rocket" to
check all relevant launches.

Now you can, e.g., see the launch #1733, and directly check for the success
of this launch.
