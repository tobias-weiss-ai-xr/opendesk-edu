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
