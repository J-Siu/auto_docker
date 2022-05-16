# Auto Docker [![Paypal donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate/?business=HZF49NM9D35SJ&no_recurring=0&currency_code=CAD)

Bash script for mass updating Docker project base on Alpine Linux packages.

### Table Of Content
<!-- TOC -->

- [Purpose](#purpose)
- [Features](#features)
- [Usage](#usage)
- [Workflow](#workflow)
  - [Generate DB](#generate-db)
  - [Staging](#staging)
  - [Save](#save)
  - [Commit](#commit)
  - [Tag](#tag)
- [What Is Being Updated](#what-is-being-updated)
  - [Dockerfile](#dockerfile)
  - [README.md](#readmemd)
  - [License](#license)
- [Limitation](#limitation)
- [Distro and DB](#distro-and-db)
  - [db.sh ${auto_db_script}](#dbsh-auto_db_script)
  - [distro.conf](#distroconf)
  - [db.data ${auto_db_data}](#dbdata-auto_db_data)
- [Repository](#repository)
- [Contributors](#contributors)
- [Change Log](#change-log)
- [License](#license)

<!-- /TOC -->

### Purpose

As more and more packages are made into docker images, keeping them up to date become a tedious task.

Some images just pull package without specifying version and update means rebuilding them blindly. And there is no version info from image tag.

Auto_Docker intend to ease this burden, at least for simple docker images that depends on single package. It can update Dockerfile, README.md, apply git commit and tag according to new version.

### Features

- [x] Update project
  - [x] Dockerfile
  - [x] README.md
  - [x] LICENSE
- [x] Dry run
- [x] Try build
- [x] Update DB
  - [x] Alpine
- [x] Auto git commit
- [x] Auto git tag

A framework for automatically updating simple docker project.

### Usage

```sh
git clone https://github.com/J-Siu/auto_docker.git
cd auto_docker
```

```txt
./auto_docker
Usage:
  ./auto_docker [flags]
Flags:
  -commit                  Apply git commit. Only work with -save
  -tag                     Apply git tag. Only work with -commit
  -debug                   Show debug log
  -h, -help                Show help
  -nobuild                 Do not perform docker build
  -noskip                  Do not skip project
  -pref, -prefix string    Path prefix for project
  -proj, -project string   Path of project
  -save                    Write back to project folder
  -updatedb                Update package database
```

Example directory tree:

```sh
.
├── auto_docker
├── docker_amule
├── docker_compose
├── docker_dnsmasq
├── docker_hostapd
├── docker_hugo
├── docker_mldonkey
├── docker_mpd
├── docker_mpd_lite
├── docker_postfix
├── docker_testing
├── docker_tor
├── docker_transmission
└── docker_unbound
```

Update db:

```sh
cd auto_docker
./auto_docker -debug -updatedb
```

Process 1 docker project `docker_amule`:

Test run only ...

```sh
cd auto_docker
./auto_docker -debug -project ../docker_amule
```

Save ...

```sh
cd auto_docker
./auto_docker -debug -project ../docker_amule -save
```

Git commit too ...

```sh
cd auto_docker
./auto_docker -debug -project ../docker_amule -save -commit
```

Process all docker projects `docker_`, use `-prefix`:

Test run only ...

```sh
cd auto_docker
./auto_docker -debug -prefix ../docker_
```

Use `-project` to specify single project

Use `prefix` to specify projects with common path prefix

Multiple `-project` and `-prefix` can be used together.

### Workflow

#### Generate DB

```sh
cd auto_docker
./auto_docker -debug -updatedb
```

When `-updatedb` is used. All `${auto_distro_root}/<distro>/${auto_db_script}` will be executed. Each will generate a `${auto_data_root}/db/<distro>/${auto_db_data}`.

With default configuration, related file structure as follow:

```sh
./ (${auto_root})
├── data/ (${auto_data})
│   └── db/
│       ├── alpine/ (<distro>)
│       │   ├── edge/ (download dir used by db.sh)
│       │   ├── latest-stable/ (download dir used by db.sh)
│       │   └── db.data (${auto_db_data})
│       └── debian/ (<distro>)
│           └── db.data (${auto_db_data})
├── distro/ (${auto_distro_root})
│   ├── alpine/ (<distro>)
│   │    ├── db.sh (${auto_db_script})
│   │    └── distro.conf (${auto_db_conf})
│   └── debian/ (<distro>)
│       ├── db.sh (${auto_db_script})
│       └── distro.conf (${auto_db_conf})
├── auto.common.sh
├── auto.conf
└── auto_docker
```

> Distro `debian` script is not available now.

#### Staging

A docker project is being copied under staging area ${auto_stg_root} before being process. All changes will be applied there.

```sh
cd auto_docker
./auto_docker -debug -prefix ../docker_
```

Projects are copied into `${auto_stg_root}`:

```sh
data/ (${auto_data})
└── stg/ (${auto_stg_root})
    ├── docker_amule
    │   ├── docker-compose.yml
    │   ├── Dockerfile
    │   ├── env
    │   ├── LICENSE
    │   ├── README.md
    │   └── start.sh
    ├── docker_dnsmasq
    │   ├── docker-compose.yml
    │   ├── Dockerfile
    │   ├── env
    │   ├── LICENSE
    │   └── README.md
    ├── docker_hostapd
    │   ├── docker-compose.yml
    │   ├── Dockerfile
    │   ├── env
    │   ├── LICENSE
    │   └── README.md
    └── docker_hugo
        ├── Dockerfile
        ├── LICENSE
        ├── README.md
        └── start.sh
```

If new package version is found, `Dockerfile` will be updated and a testing `docker build` will be performed.

`docker build` test can be skipped with `-nobuild`.

> As long as `-save` is not used, nothing will change in the original project folder. It is advice to inspect the staging files before using the `-save` option.

#### Save

`-save` option will copy `Dockerfile`, `LICENSE` and `README.md` back to original project folder.

#### Commit

`-commit` will commit with new package version. Only has effect with `-save`.

```sh
git commit -a -m ${dockerfile["version"]}
```

#### Tag

`-tag` will tag with new package version. Only has effect with `-commit`.

```sh
git tag -a ${dockerfile["version"]} -m ${dockerfile["version"]}
```

### What Is Being Updated

#### Dockerfile

Take following `Dockerfile` as example:

```sh
FROM alpine:edge

LABEL version="0.73.0-r0"
LABEL maintainers="[John Sing Dao Siu](https://github.com/J-Siu)"
LABEL name="hugo"
LABEL usage="https://github.com/J-Siu/docker_hugo/blob/master/README.md"

RUN apk --no-cache add git hugo=0.73.0-r0

...
```

Package name is taken from `name` label.

Package version is taken from `version` label.

They are then compare with distro db. If new version is found, the version will be update accordingly, including version line 8.

`maintainer` and `usage` will also be updated if they are available.

#### README.md

Take following `README.md` as example:

```md
- 0.73.0-r0
  - something ...
<!--CHANGE-LOG-END-->
```

If version is updated to `0.74.0`, new lines will be automatically added before `<!--CHANGE-LOG-END-->` as follow:

```md
- 0.73.0-r0
  - something ...
- 0.74.0
  - Auto update to 0.74.0
<!--CHANGE-LOG-END-->
```

If there copyright line as follow:

```txt
Copyright (c) xxxx
```

It will be updated with current year:

```txt
Copyright (c) 2020
```

#### License

`LICENSE` file, if there copyright line as follow:

```txt
Copyright (c) xxxx
```

It will be updated with current year:

```txt
Copyright (c) 2020
```

### Limitation

- Distro
  - Only alpine:latest and alpine:edge are supported now.
- Dockerfile
  - `name` label must be same as package name.
  - `version` label must be same as package version.

### Distro and DB

The `${auto_distro_root}/<distro>` directory provide a way to extend support for more distro.

#### db.sh ${auto_db_script}

`db.sh` of each distro should start with following:

```sh
#!/bin/bash

# --- db.sh common start ---

COMMON="auto.common.sh"
source ${COMMON}
common_option ${@}

_my_path=${BASH_SOURCE[0]}
_my_name=$(basename ${_my_path})
_my_dir=${_my_path/%\/${_my_name}/}

source ${_my_dir}/${auto_db_conf}

_db_path=${auto_db_root}/${my_distro_name}/${auto_db_data}

# --- db.sh common end ---
```

`db.sh` only task is to produce `db.data` at `${_db_path}`.

#### distro.conf

```sh
# --- distro.conf common start ---

tags="latest edge" # latest / edge

# --- distro.conf common start ---
```

#### db.data ${auto_db_data}

`db.sh` create `db.data` in following format:

```sh
<repo>::<package>
<version>
<repo>::<package>
<version>
<repo>::<package>
<version>
...
```

Example:

```sh
latest::geoclue-dev
2.5.6-r1
latest::vdr
2.4.1-r0
latest::krfb-lang
20.04.2-r0
```

### Repository

- [docker_compose](https://github.com/J-Siu/auto_docker)

### Contributors

- [John Sing Dao Siu](https://github.com/J-Siu)

### Change Log

- 0.9
  - Base features completed
  - README.md completed
- 1.0
  - Add auto clear stage
  - Add option nobuild
  - Clean up
  - Fix commit and tag version
  - Fix sed inline for MacOS
  - Rename auto.sh -> auto_docker
  - Update to use #!/usr/bin/env bash
  - Update usage

### License

The MIT License

Copyright (c) 2020

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
