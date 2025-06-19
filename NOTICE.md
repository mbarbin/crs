# License

crs is released under the terms of the `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception` license.

This notice file contains more details, as well as document the organization of files and headers that relate to licenses.

## License, copyright & notices

- **COPYING.HEADER** contains the copyright and license notices. It is added as a header to every file in the project.

- **COPYING** contains a copy of the full [GPL-3.0 license](https://www.gnu.org/licenses/gpl-3.0.txt)

- **COPYING.LESSER** contains a copy the full [LGPL-3.0 license](https://www.gnu.org/licenses/lgpl-3.0.txt)

- **COPYING.LINKING** contains a copy of the [LGPL-3.0-linking-exception](https://spdx.org/licenses/LGPL-3.0-linking-exception.html) notice.

- **NOTICE.md** (this file) documents the project licensing.

## A note about Iron

In 2016-2017, Jane Street released on GitHub an internal code review system named [Iron](https://github.com/janestreet/iron).

Iron was released under the terms of the [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0) License.

We've included a copy of Iron's `Apache-2.0` License in the repository [here](./third-party-license/LICENSE-iron-apache-2.0.txt)

We're referring to the Iron source code as of `v0.9.114.44+47`, revision `dfb106cb82abf5d16e548d4ee4f419d0994d3644`.

`Iron` includes functionality for interacting with `Mercurial` repositories, and parsing code review comments embedded in source code.

To build this project, we've used a format for code review comments almost identical to the syntax used by Iron. Moreover, we have used as a starting point the code from Iron responsible for modeling and parsing the comments.

#### Notices

The files in question carry prominent notices stating that their contents was derived from files from the `Iron` project. We include the path of said files relative to the root of the `Iron` project repository, as well as a description of the changes made.

For example, in addition to the crs project header, such files carry the following extra header:

```ocaml
(* This module is derived from Iron (v0.9.114.44+47), file
 * [./path/to/file], which is released under Apache 2.0:
 *
 * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at:
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 * See the file `NOTICE.md` at the root of this repository for more details.
 *
 * Changes: ...
 *)
```

#### List of modules

The exact list of modules that are derived from `Iron` is as follows:

- lib/cr_comment/src/cr_comment
- lib/crs_parser/src/crs_parser
- lib/crs_parser/src/file_parser
- lib/crs_parser/src/header_parser

## Printbox

This project has a dependency to the opam packages [printbox](https://opam.ocaml.org/packages/printbox/), released under `BSD-2-Clause`.

A copy of the license file for the printbox project is located under `third-party-licenses/`.
