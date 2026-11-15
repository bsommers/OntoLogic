# Security Policy

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub private vulnerability reporting:
open the repository's **Security** tab and choose **Report a vulnerability**
(<https://github.com/bsommers/OntoLogic/security/advisories/new>).
Do not open a public issue for a security problem.

Include the OntoLogic version (`ontologic --version`), the `.logic` input or command line that
triggers the problem, and what you expected to happen. You can expect an acknowledgement within
a week. Fixes are released as patch versions and credited in the advisory unless you ask otherwise.

## Scope

In scope: the `ontologic` compiler, the `ontologic-lsp` language server, the REPL, the files in
`ontologic-lib/`, and the build and release scripts in this repository. Examples of interest:
reading files outside the intended import roots, running unintended commands, and a hostile
`.logic` file exhausting resources.

Not in scope: a solver reporting a wrong answer for a valid ontology (file a normal bug report),
and vulnerabilities in third-party tools OntoLogic calls (Z3, cvc5, Vampire, d2, mmdc); report
those upstream.

## Supported versions

Only the latest release receives security fixes.
