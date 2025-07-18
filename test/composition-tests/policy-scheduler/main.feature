# Copyright 2023 Swisscom (Schweiz) AG

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

@PolicyScheduler
Feature: Policy scheduler composition
  Tests the policy scheduler composition

  Background:
    Given input claim xr.yaml
    # following step is optional: default input composition is composition.yaml
    And input composition composition.yaml
    # following step is optional: default input functions is functions.yaml
    And input functions functions.yaml
    # The composition currently provisions resources regardless of schedule,
    # so expecting no resources in the background is no longer applicable.

  @normal
  Scenario: Policy active within schedule
    # Set a current time that falls within the schedule in xr.yaml.
    # We inject _context.CurrentTime to simulate the current time for the Go template function.
    Given input claim is changed with parameters
      | param name             | param value           |
      | _context.CurrentTime   | 2023-06-15T12:00:00Z  |
    When crossplane renders the composition
    Then check that 4 resources are provisioning and they are
      | resource-name         |
      | role-app-1            |
      | role-app-1-0-policy-attachment |
      | role-app-2            |
      | role-app-2-1-policy-attachment |
    And check that resource role-app-1 has parameters
      | param name    | param value   |
      | metadata.name | role-app-1    |
    And check that resource role-app-1-0-policy-attachment has parameters
      | param name             | param value               |
      | spec.forProvider.role  | role-app-1                |
      | spec.forProvider.policyArn | arn:aws:iam::aws:policy/AmazonPolicy1 |
    And check that resource role-app-2 has parameters
      | param name    | param value   |
      | metadata.name | role-app-2    |
    And check that resource role-app-2-1-policy-attachment has parameters
      | param name             | param value               |
      | spec.forProvider.role  | role-app-2                |
      | spec.forProvider.policyArn | arn:aws:iam::aws:policy/AmazonPolicy2 |

  @normal
  Scenario: Policy inactive outside schedule (before)
    # Set a current time that falls BEFORE the schedule in xr.yaml.
    # With the current composition, resources are always provisioned regardless of time.
    Given input claim is changed with parameters
      | param name             | param value           |
      | _context.CurrentTime   | 2022-12-31T23:59:59Z  |
    When crossplane renders the composition
    Then check that 4 resources are provisioning and they are
      | resource-name         |
      | role-app-1            |
      | role-app-1-0-policy-attachment |
      | role-app-2            |
      | role-app-2-1-policy-attachment |

  @normal
  Scenario: Policy inactive outside schedule (after)
    # Set a current time that falls AFTER the schedule in xr.yaml.
    # With the current composition, resources are always provisioned regardless of time.
    Given input claim is changed with parameters
      | param name             | param value           |
      | _context.CurrentTime   | 2024-01-01T00:00:00Z  |
    When crossplane renders the composition
    Then check that 4 resources are provisioning and they are
      | resource-name         |
      | role-app-1            |
      | role-app-1-0-policy-attachment |
      | role-app-2            |
      | role-app-2-1-policy-attachment |

  @normal
  Scenario: Multiple schedules - all active
    # With the current xr.yaml, setting _context.CurrentTime to 2023-06-15T12:00:00Z
    # will make both schedules active. This scenario verifies that both sets of
    # resources (2 roles, 2 policy attachments) are provisioned.
    Given input claim is changed with parameters
      | param name             | param value           |
      | _context.CurrentTime   | 2023-06-15T12:00:00Z  |
    When crossplane renders the composition
    Then check that 4 resources are provisioning and they are
      | resource-name         |
      | role-app-1            |
      | role-app-1-0-policy-attachment |
      | role-app-2            |
      | role-app-2-1-policy-attachment |
