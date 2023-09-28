## [0.5.2](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.5.1...v0.5.2) (2023-09-28)


### Bug Fixes

* **ci:** Add Gitlab-CI sledgehammer deployment removal ([6fd655a](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6fd655a0b1afd40303ac11130692202146bab215))

## [0.5.1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.5.0...v0.5.1) (2023-09-28)


### Bug Fixes

* **docs:** Add 'Helm Chart Trust Chain' section ([b6b4972](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/b6b4972a5dd426bcc8fa00137d7e7b60056376c8))
* **docs:** Highlight that Helmfile >= 0.157.0 is required ([d86f516](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/d86f516747323d117f620658c4368408926c507a))
* **element:** Use OCI registry and verify chart signatures ([a41b9a6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a41b9a699c79bf90163bbb3c233c805b8d0a999e))
* **helmfile:** Add cleanup flag for job resources ([0f01b94](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0f01b94aa19b40b4774ba11d9886fe6f12090e73))
* **helmfile:** Create directory for gpg pubkeys ([4c5731e](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4c5731e6bb057cb272f660b4df0369b67709c203))
* **intercom-service:** Use OCI registry and verify chart signatures ([74b3d41](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/74b3d41381474efd2fbc5a9f3a0f1c0713811106))
* **jitsi:** Verify chart signatures ([1dd6582](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1dd6582ec7d742250ba08f69eba9a4679984b1ae))
* **keycloak-bootstrap:** Use OCI registry and verify chart signatures ([ca5d5f8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ca5d5f82800ea6d7ecfa38eb2b5d8b85e709bb9f))
* **keycloak:** Use OCI registry and verify chart signatures ([095059c](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/095059c7e53bbe8a874773f574cc6794ef8af6e4))
* **nextcloud:** Use OCI registry and verify chart signatures ([41dfdc0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/41dfdc0c8f83e3d79fa5a763ac449f6edfc76676))
* **open-xchange:** Use OCI registry and verify chart signatures ([2d5d370](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2d5d3708f7f45600961c22ce11e750561de1fd27))
* **open-xchange:** Use renamed istio gateway ([65d2642](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/65d2642d34c1c21a00a29278f7e1143f7fabb2aa))
* **openproject:** Use OCI registry and verify chart signatures ([5343840](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/5343840bed01992b3132eace362f91588c705a98))
* **services:** Add wildcard certifcate request support ([15ad8ca](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/15ad8ca7ab34b079252f7b69219ede81ad43aa1c))
* **services:** Bump opendesk-certificates to 2.1.0 ([4372f06](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4372f063e0a27d5156da963d44d3ed4e72490fc4))
* **services:** Only create istio gateway with webmail domain ([6a39011](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6a390112dab11afaca06118a0ca7a18afe633a30))
* **services:** Use OCI registry for all services and add gpg verify mechanism ([892920b](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/892920b0487b41a35b5a96596c61101827e8dd6d))
* **univention-corporate-container:** Use OCI registry and verify chart signatures ([424317e](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/424317ed585f7bd5036259d7e3d77d081d2aec1b))

# [0.5.0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.9...v0.5.0) (2023-09-27)


### Bug Fixes

* **element:** Move the static configuration into the values.yaml ([f22619b](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/f22619bd8ef11cb43147ef19dcff2c02d9fe0503))
* **element:** Specify resources for the guest module init container ([275798c](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/275798c1d6aa47ef33fbb0da3bb03a86d3e4b0ee))


### Features

* **element:** Activate the guest module ([5ad25ac](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/5ad25acafd54d19dd2ed330b19f7860aff5d49f4))

## [0.4.9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.8...v0.4.9) (2023-09-27)


### Bug Fixes

* **nextcloud:** Bump Helm chart to add app "groupfolders" ([62b767e](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/62b767ef38c8eae2874b20a9aa51e85d2a3fe5a3))

## [0.4.8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.7...v0.4.8) (2023-09-26)


### Bug Fixes

* **openproject:** Digest rollback ([9acce08](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/9acce081397c06426820b61f39c9aa0dcc1234a5))

## [0.4.7](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.6...v0.4.7) (2023-09-26)


### Bug Fixes

* **helmfile:** Add timeout for database services ([98ec02f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/98ec02f230f1691eb8c17d8d3552fceda329bf7c))
* **openproject:** Image digest ([b340373](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/b340373133ad973cfd6a3632adc9a74a23419cc7))

## [0.4.6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.5...v0.4.6) (2023-09-26)


### Bug Fixes

* **openproject:** Use renamed registry open_desk ([a37faf3](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a37faf3b5769aea9944ffa7626096c16296dcc85))

## [0.4.5](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.4...v0.4.5) (2023-09-26)


### Bug Fixes

* **helmfile:** Streamline timeouts ([2703615](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2703615dffb2ba5c70704a4f08bb0485629218f3))

## [0.4.4](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.3...v0.4.4) (2023-09-25)


### Bug Fixes

* **open-xchange:** Updates for mail templates and mail export ([ae3d0da](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ae3d0daa117d3d0ff307f379590394914a757546))

## [0.4.3](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.2...v0.4.3) (2023-09-25)


### Bug Fixes

* **nextcloud:** Update image to 27.1.1 ([ce7e5f6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ce7e5f670a4dbc980eb8be73e5f7d15b27e8b1de))

## [0.4.2](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.1...v0.4.2) (2023-09-21)


### Bug Fixes

* **nextcloud:** Add Nextcloud app for OpenProject integration; Bump Collabora Image ([f46c8a9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/f46c8a9a5f4f9778cb171d65e9a0280e4ce61c16))

## [0.4.1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.4.0...v0.4.1) (2023-09-19)


### Bug Fixes

* **univention-management-stack:** Remove doublette triple dashes in helmfile.yaml ([41b9afb](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/41b9afb3648a0e1fddc5aa4337cc1501756b370c))

# [0.4.0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.3.2...v0.4.0) (2023-09-18)


### Features

* **ci:** Optionally trigger E2E tests of the SouvAP Dev team ([a99c088](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a99c088361b95b2bb7ee2b161e3a254f02bcd9ae))

## [0.3.2](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.3.1...v0.3.2) (2023-09-14)


### Bug Fixes

* **helmfile:** Fix linter issues ([1514678](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1514678db00d32c1463d8fc496c0e6d1c2a2df96))
* **univention-management-stack:** Add "commonLabels" into helmfile ([16c08f8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/16c08f82c9b4934567bb3b9c7fccab754bfad494))
* **univention-management-stack:** Add Helm charts ([a74d662](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a74d66240423fd5ba87854cc2b71132f11271ec7))
* **univention-management-stack:** Add switch "univentionManagementStack.enabled" ([471a2fa](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/471a2fa26205b8ca3afb5eeeb4524897a57f5c20))
* **univention-management-stack:** Adjust Ingress configuration for portal-server ([13bcd78](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/13bcd785e8f7db22d20903020e0cdd28094309a9))
* **univention-management-stack:** Adjust Ingress configuration for umc ([320da3b](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/320da3bec3a49d974765e567878d5c2f2b4e93ef))
* **univention-management-stack:** Adjust Ingress configuration of notifications-api ([5e1a7b1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/5e1a7b19e278147d010c48dac2da111f828dd115))
* **univention-management-stack:** Adjust ingress configuration of the portal-frontend ([c54bab1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/c54bab165bf81854471d790200781b4181eba22a))
* **univention-management-stack:** Adjust Ingress configuration of udm-rest-api ([c61b1b8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/c61b1b828150caa8d2fe1a5b9f0a862b2fbef4f1))
* **univention-management-stack:** Adjust Ingress conifguration of store-dav ([96097e4](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/96097e470483a5251acd81eb772da70ad7f55137))
* **univention-management-stack:** Configure cookie banner data ([12c931f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/12c931fcff5536116af11df1c9c0468429949fe2))
* **univention-management-stack:** Define resource requests and limits ([2f8a298](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2f8a2989250ea0f3b50dd3417f214a8864fe62d0))
* **univention-management-stack:** Disable istio for the stack ([4835a2b](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4835a2beec408ec6267177f82257edd9ccb0d937))
* **univention-management-stack:** Prepare persistence configuration ([7ab1cb5](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/7ab1cb5c7e7bca85394eae2ed17141e513dd5a42))
* **univention-management-stack:** Process bases before releases ([ec3f1d9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ec3f1d96ac17cf1fb9d34ab692240460d5bd4ba1))
* **univention-management-stack:** Set externalDomainName for bootstrapping the stack ([0ba71f2](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0ba71f2749eaf51b09429a5f3c705bd0075c1efa))
* **univention-management-stack:** Split templated from static values ([09079a1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/09079a13031be7894a34bf92945bd25a040c2290))
* **univention-management-stack:** Split values into templated and static ([d3c4390](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/d3c439038a2551ec90324ab8659d24b65b223d4f))
* **univention-management-stack:** Update portal-listener to leverage dependency waiting ([c840608](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/c84060811229bb131bcd473a9e4668dfa73f97d7))
* **univention-management-stack:** Use global secrets to fill initialPasswordAdministrator ([a4bab40](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a4bab4068dc298056ed864e60a244d49a2934c8b))
* **univention-management-stack:** Use global secrets to populate ldap related secrets ([9409ad8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/9409ad829a725c84ebc3de5d1c4d42fe735e9d0c))
* **univention-management-stack:** Use global secrets to set store-dav related passwords ([90019e3](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/90019e3ef6de5e4ed1742ee9ddc3bbb256cd3dec))
* **univention-management-stack:** Use ldap base DN "dc=swp-ldap,dc=internal" ([77e362f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/77e362f6bc053c5d456bf65649f15130ce53547c))
* **univention-management-stack:** Use postgresql service for notifications-api ([fe0e0cd](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/fe0e0cdce4622352afbf74875adcae8324d769a3))
* **univention-management-stack:** Use the prefix "ums-" for all releases ([edb25bd](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/edb25bd7655beeefa73a62fb9a8c85e076c4cc2f))
* **univention-management-stack:** Use the value "global.imagePullPolicy" ([15db5dc](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/15db5dcbba33c39f752499f2d73c77cac32d1e8c))

## [0.3.1](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.3.0...v0.3.1) (2023-09-14)


### Bug Fixes

* **collabora:** Update Ingress annotations and set securityContext ([b5583ca](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/b5583caec10c24e3bfb312edcb2800e6a60a9b10))
* **element:** Improve default container security settings ([882f1fb](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/882f1fbc93ceb4ac33683d445e100e445798b202))
* **element:** Update opendesk element version to 2.0.1 ([d725b93](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/d725b937989987ffacf87d7a9ee05803dcdd4c93))
* **helmfile:** Remove default SMTP credentials and create docs for SMTP/TURN ([e120f5f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/e120f5fb9a91b80ba71ce78eace99852b4da5fda))
* **helmfile:** Update images and use a tag and digest together ([c7fc187](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/c7fc187f14b78cdcc698abbbaec1ba0bbfc718a1))
* **services:** Explicitly set securityContexts ([a799db0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a799db03c4115ba69303be1c265f7aefef95d659))
* **services:** Update Postfix to 2.0.2 fixing security gaining ([e1070ee](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/e1070eeb0602523c240a91dae1b0869a7cc42a78))

# [0.3.0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.10...v0.3.0) (2023-09-12)


### Features

* **ci:** Selective tests ([d2e7ac9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/d2e7ac93481249e9eb7e5e1a41a6c6e333abe2dc))

## [0.2.10](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.9...v0.2.10) (2023-09-06)


### Bug Fixes

* **helmfile:** Add imagePullPolicy default env variable ([f988644](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/f9886448b60bbbd917b5ba04d188401275293eec))
* **helmfile:** Update images and add jitsi, keycloak to security section in docs ([0eceb85](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0eceb85e7df7455fa61cb17a854807069fbcf51a))
* **jitsi:** Update chart to 1.4.2 with improved security and fixed change on each deployment ([1349181](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1349181d802ccb80d9e48cf50fe39f1505116c8e))
* **jitsi:** Update jitsi to 1.5.1 and fix prosody image ([ed7e5e4](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ed7e5e428e5d9213a92f97dc03d72fa3e04334c2))
* **keycloak:** Improve default security settings ([3b90533](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/3b90533063c151a9f3cdc9861a115481f6dc440a))
* **nextcloud:** Fix yamllint disable comment ([4380e78](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4380e789814ec2b0458fb2c341c8160ab2743afc))
* **services:** Disable https redirect in istio to fix cert-manager issues ([1ef4a86](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1ef4a861acc955e2e85715c62f715a6629ada940))
* **services:** Fix capabilities of postifix ([a6fa846](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a6fa846afc9744f2b399c37cc754f878b6b9e90b))
* **services:** Fix OCI registry address of postgresql, mariadb ([be82243](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/be822439661f766c4db6044fd3581db0cce214bb))

## [0.2.10](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.9...v0.2.10) (2023-09-06)


### Bug Fixes

* **helmfile:** Add imagePullPolicy default env variable ([f988644](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/f9886448b60bbbd917b5ba04d188401275293eec))
* **helmfile:** Update images and add jitsi, keycloak to security section in docs ([0eceb85](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0eceb85e7df7455fa61cb17a854807069fbcf51a))
* **jitsi:** Update chart to 1.4.2 with improved security and fixed change on each deployment ([1349181](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1349181d802ccb80d9e48cf50fe39f1505116c8e))
* **keycloak:** Improve default security settings ([3b90533](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/3b90533063c151a9f3cdc9861a115481f6dc440a))
* **nextcloud:** Fix yamllint disable comment ([4380e78](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4380e789814ec2b0458fb2c341c8160ab2743afc))
* **services:** Disable https redirect in istio to fix cert-manager issues ([1ef4a86](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/1ef4a861acc955e2e85715c62f715a6629ada940))
* **services:** Fix capabilities of postifix ([a6fa846](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/a6fa846afc9744f2b399c37cc754f878b6b9e90b))
* **services:** Fix OCI registry address of postgresql, mariadb ([be82243](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/be822439661f766c4db6044fd3581db0cce214bb))

## [0.2.9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.8...v0.2.9) (2023-09-05)


### Bug Fixes

* **collabora:** Add websocket support for NGINX Inc. Ingress ([6e5ef63](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6e5ef639c22aad93fd2d0eb75f7a1ffc00d6cc9a))
* **docs:** Add security part in README ([ff462ab](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/ff462ab0dc2252cc7b517874f5337427b8d19053))
* **docs:** Update scaling docs ([63a1e25](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/63a1e2568e8c5ff62081c6e6594d2019c1aa4b74))
* **helmfile:** Reduce icap resources in default enviroment ([c5ab1b8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/c5ab1b81fecbce46788c50b282ed6d1770124fa5))
* **helmfile:** Update clamav and nextcloud images in default environment ([4f2a8ae](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/4f2a8aeee4ee6c3d27b1c8a99bad14f603486be5))
* **nextcloud:** Add support for up to 4G large upload for Ingress NGINX and NGINX Inc. Ingress ([6e68f7f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6e68f7f28c937319d93f8afe1dbb302012f77233))
* **nextcloud:** Rename sovereign-workplace-nextcloud-bootstrap to opendesk-nextcloud-bootstrap and use OCI ([cef11ac](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/cef11acbae28510809f9bfa13224dc3a6996207f))
* **nextcloud:** Use clamav-icap when clamavDistributed is activated ([41d40c9](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/41d40c9b731b866da2666fa4ffa8cb6493737112))
* **services:** Enable security context and use default increased security settings ([9a6d240](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/9a6d2409a697f7e9811a0f4f8d31bb18bac1b926))
* **services:** Fix image registry templates for postfix ([6321ff5](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6321ff50a00203abbfb7f5822e67a3c0e00d4b01))
* **services:** Replace image digest by tag ([f758293](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/f7582932412f13b1a087d40459e97cf633b1a97e))
* **services:** Set readOnlyRootFilesystem to true on master ([5fbf86b](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/5fbf86b6bc7b63c81b3ac07c5e0fa8cd464fdad1))
* **services:** Update clamav to 4.0.0, redis to 18.0.0, postgresql to 2.0.2, mariadb to 2.0.2 and use OCI registries ([9d78664](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/9d7866480cee889fd3b3003b2eea313a6ed73344))

## [0.2.8](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.7...v0.2.8) (2023-08-31)


### Bug Fixes

* **open-xchange:** Update images and Helm chart ([39565c7](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/39565c7cfd89a8d1c2e645e3ecea28fba703ccc1))

## [0.2.7](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.6...v0.2.7) (2023-08-30)


### Bug Fixes

* **jitsi:** Update Jitsi Helm chart to set the user's display name as default ([387bd87](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/387bd8715c5a1cf54733c6642cf57c6ef9a44316))

## [0.2.6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.5...v0.2.6) (2023-08-30)


### Bug Fixes

* **ci:** Change path of asset_generator ([6ab4fa0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6ab4fa078b0bb3939c54f46d6475770fa9901936))
* **ci:** Include deployment environments ([0f59736](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0f59736c5dcff905400ae2e1bbf7ae496ffb9b2c))
* **ci:** Release artefacts ([2a61b5f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2a61b5f2a66bf1dc1ad06f7111ef7ecaf9247b39))

## [0.2.6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.5...v0.2.6) (2023-08-30)


### Bug Fixes

* **ci:** Change path of asset_generator ([6ab4fa0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6ab4fa078b0bb3939c54f46d6475770fa9901936))
* **ci:** Include deployment environments ([0f59736](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/0f59736c5dcff905400ae2e1bbf7ae496ffb9b2c))
* **ci:** Release artefacts ([2a61b5f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2a61b5f2a66bf1dc1ad06f7111ef7ecaf9247b39))

## [0.2.6](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/compare/v0.2.5...v0.2.6) (2023-08-30)


### Bug Fixes

* **ci:** Change path of asset_generator ([6ab4fa0](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/6ab4fa078b0bb3939c54f46d6475770fa9901936))
* **ci:** Release artefacts ([2a61b5f](https://gitlab.opencode.de/bmi/souveraener_arbeitsplatz/deployment/sovereign-workplace/commit/2a61b5f2a66bf1dc1ad06f7111ef7ecaf9247b39))

## [0.2.5](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.2.4...v0.2.5) (2023-08-30)


### Bug Fixes

* **xwiki:** Theming and language of central navigation ([3d4d45f](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/3d4d45f7114e6e3bc353b8d6c5fdbcac4cb2460f))

## [0.2.4](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.2.3...v0.2.4) (2023-08-29)


### Bug Fixes

* **element:** Apply the global theme to Element ([7f7eae8](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/7f7eae8f99a6d8ad8085ad99c63af27b858ff9b7))

## [0.2.3](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.2.2...v0.2.3) (2023-08-29)


### Bug Fixes

* **ci:** Add central branding information ([a14c42f](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/a14c42f6ed2e3d8e12af5d04cae1a4bb1336fb3d))

## [0.2.2](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.2.1...v0.2.2) (2023-08-16)


### Bug Fixes

* **jitsi:** Allow configuration of LoadBalancer status field for patchJVB job ([7491582](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/7491582c28c21e83a0bc6349fb68045472146aad))
* **open-xchange:** Explicitly disable core-ui-middleware ingress ([06dc7a1](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/06dc7a115d36841f1109f9e75aac844d934c2f4c))

## [0.2.1](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.2.0...v0.2.1) (2023-08-16)


### Bug Fixes

* **keycloak:** Increase proxy-buffer-size for ingress-nginx ([d8adcc4](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/d8adcc463adc8bec5a793a97977dddd89d7363cc))

# [0.2.0](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.1.2...v0.2.0) (2023-08-15)


### Bug Fixes

* **helmfile:** Replace bitnami repositories with OCI ([4c21fd2](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/4c21fd228654520bb71d56dc1bda96332334002b))


### Features

* **helmfile:** Implement private image/chart registry variables ([5788323](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/57883236219811d2a5fc422649b4f9b042a0ac22))

## [0.1.2](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.1.1...v0.1.2) (2023-08-15)


### Bug Fixes

* **jitsi:** Update support for NodePort setups with different ingress/egress ips ([de25789](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/de257893d4ff2b3e8ea1d6988c6bdde5ed1eae9a))

## [0.1.1](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.1.0...v0.1.1) (2023-08-14)


### Bug Fixes

* **open-xchange:** Bump dovecot and sovereign-workplace-open-xchange-bootstrap to 1.3.0 with image digest support ([53796da](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/53796dae660463207a460b387b6f3dd23ce20cd0))
* **open-xchange:** Bump sovereign-workplace-open-xchange-bootstrap to 1.3.1 ([390f2de](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/390f2dee5226b83855a6cca8bf1c0d0f5647ee34))

# [0.1.0](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.6...v0.1.0) (2023-08-14)


### Bug Fixes

* **docs:** Typo ([ee684a7](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/ee684a78910ce721ea834e9ec2f4222ed37572c6))


### Features

* **element:** Add element component ([5f0ca92](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/5f0ca92a058e51a27aa56e35ebcf2048bad88671))

## [0.0.6](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.5...v0.0.6) (2023-08-14)


### Bug Fixes

* **open-xchange:** Functional mailboxes auth settings update in AppSuite and Dovecot ([53948ea](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/53948eae7648cc9785d2b8a813fc7e40b36aa3aa))

## [0.0.5](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.4...v0.0.5) (2023-08-11)


### Bug Fixes

* **keycloak:** Improve digest image pinning ([b8a8932](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/b8a8932221ae4d6632c7d1f4a85f46fea01a92e7))

## [0.0.4](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.3...v0.0.4) (2023-08-11)


### Bug Fixes

* **jitsi:** Fix identifiers in resources ([3a0b246](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/3a0b246f83dc6a3ff19973959b3cf3c243c39025))

## [0.0.3](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.2...v0.0.3) (2023-08-10)


### Bug Fixes

* **keycloak:** Keycloak extensions sha256 image pinning, includes fix for failing keycloak extension handler on unavailable SMTP relay. ([27ce715](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/27ce71554d5f495731d90632a56e134762b95a25))

## [0.0.2](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/compare/v0.0.1...v0.0.2) (2023-08-10)


### Bug Fixes

* **services:** Remove fqdn from dovecot in postfix ([2033c76](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/2033c76d81e39c625112b312934668d3b3eb43fe))

## 0.0.1 (2023-08-10)


### Bug Fixes

* **ci:** Add 'qa' cluster ([43e94f8](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/43e94f8018e8fa9a98c57c9dc53709c25c643af3))
* **ci:** Deploy provisioning in separate/later stage ([ef1cb75](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/ef1cb75d45c323bc7ef43fed1a8c42aa17cdf088))
* **collabora:** Bump to 23.05.2.2.1 and add capabilites to non containerd k8s clusters ([2652b26](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/2652b2645d93106b9d6a3e50e35c9e2bd07bee12))
* **collabora:** Image version bump from 23.05.1.2.1 to 23.05.1.2.2 ([3bf7dae](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/3bf7daeeaa9a7aafe16e649dd1df0c2a537acb4a))
* **collabora:** Remove MKNOD capabilities ([2f18734](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/2f1873454c97b3e28670aca0996cdca1940515bb))
* **docs:** Cleanup and enhance README.md and CONTRIBUTING.md ([cc5f88c](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/cc5f88cbafd9147c21f4bca67f7df01c2a4c28f2))
* **helmfile:** Allow selection of environments when installing from root helmfile ([8ce01df](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/8ce01df681a5a3347e5b8e2277fc3acaf043b21e))
* **helmfile:** Comment out Open-Xchange Appsuite 8 Deployment until is publicly available ([cb65baa](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/cb65baa8afc305c8faf3484704f578e1c62f8033))
* **jitsi:** Fix wrong parameter for jitsiPatchJVB tag ([fb3fca2](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/fb3fca2e7ee8dbb22a0622f86953fcfdb9934864))
* **nextcloud:** Add Istio domain on integration for read/write contacts with Open-Xchange ([b235685](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/b2356855d5b481359a2b29e43517bbc1f9025b5c))
* **provisioning:** OX-Connector inits contexts and accessprofiles first, profile pictures are now provisioned ([94552a3](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/94552a361456b6688070cb01f80fa8a91ef086fb))
* **provisioning:** Update OX-Connector image ([3cc7ba9](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/3cc7ba911502d69e780a274e93dd9ef693fe6049))
* **services:** Bump postgresql chart to 2.0.0 ([e609bf3](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/e609bf36fc1bdb4f9b8c2b9318baf0477a20ebf9))
* **services:** Specify dovecot with fqdn ([59d64de](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/59d64de44e545904198b77528687382ddd511fc8))
* **services:** Update mariadb Chart to 2.0.0 ([f39811c](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/f39811ce44c0a6cbebb48d91c3d5f6724f8cf3e6))
* **univention-corporate-server:** Update image to improve pod restarting behaviour ([57dea1e](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/57dea1e1ddc7af7298a2b90a7b999f0a80cd0858))
* **xwiki:** Remove init job as XWiki now does the required bootstrapping internally; Restartability works now as expected ([8425c10](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/8425c10b1893c812060298d15471371bfa2c1151))
* **xwiki:** Use external-registry for image download ([841bfb6](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/841bfb62fe067d2ec73c198c46bd9a97538e20f5))


### Features

* **ci:** Add release-automation and linting ([82bf038](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/82bf0387e0057f2ef64d392341fe8c34490310e4))
* **ci:** Support for MASTER_PASSWORD to be set on Gitlab Settings > CI/CD > Variables ([e7d68ea](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/e7d68ea78e5e9f393f92d12acbf67ebe5176ccad))
* **ci:** Triggered tests ([23fc3c4](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/23fc3c4a1b77fbfa0202a283e74d14d6f8dbaec7))
* **docs:** Update various chapters and structure ([42232db](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/42232db5dbc0056e3169115546afd288e4a1d796))
* **helmfile:** Add capabilities for a RWO deployment ([d5190cd](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/d5190cd40ceb8b16252c7bd57ca7e43359634320))
* **helmfile:** Remove environment specific values to use cluster defaults ([4fb86b5](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/4fb86b5addd92f04b3315c0c722b69e6f7e7182b))
* **helmfile:** Remove environments and replace with generic one ([ef7d75f](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/ef7d75ff1f9ac7f2ce02fced3db1549639fbd0fd))
* **nextcloud:** Rename to sovereign-workplace-nextcloud-bootstrap and bump to 2.2.0 ([84de627](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/84de627e209dfd38390ec5a2ff126c75b5e71cc6))
* **open-xchange:** Add service type for dovecot ([c9a763f](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/c9a763f368f6b23a7760f90b2b4ab79245bf27ea))
* **open-xchange:** OX AppSuite 8 within SWP is now publicly available ([6dc470f](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/6dc470fd67edbb9711e406acb067569ca357b989))
* **services:** Add clamav-simple deployment ([505f25c](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/505f25c5493ebb9e0181233ed5b7d8018e3a315d))
* **sovereign-workplace:** Initial commit ([533c504](https://gitlab.souvap-univention.de/souvap/devops/sovereign-workplace/commit/533c5040faebd91f4012b604d0f4779ea1510424))
