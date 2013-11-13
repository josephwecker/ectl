

why?
----

because I've done this over and over again:

  - rake wrapper I did for jtv-web project (probably prettiest)
  - imb- earlier metacon-like, then current dispatcher (most complete)
  - quick command wrapper I did for fxsig
  - metacon- bash version and start of C version
  - some Proj stuff in shorthand
  - lots of custom vim stuff that started to be a lot more project-aware
  - I believe I might have even done one for zerl back in the day...
  - not by me: rake, make, git, rebar, rvm, reltools output ctl script, most init.d type scripts...



meta-exctl
---------
 - initiate project
 - set up initial directory structure
   - eventually different depending on various templates (e.g., erlang-apps, ruby gem, etc.)
 - local version of exctl files
 - create shell wrapper that has project-specific invocation name etc.
 - command for dumping information about the project - including known tasks etc.


commands
--------

- command
  - description
  - synopsis
  - arguments
    - name
    - flag
    - description
    - value *
    - default *
    - validation-format *
    - transform-format *



files
-----

    PROJ-ROOT/<BIN-NAME>       (required)
             /.exctl/*         (required)
             /.commands        (not required, but default one on init)
             /scripts/<CMDS>/* (ones with manifests after hashbang are included)


eventually more seamless
------------------------

- Rakefile
- Gemfile
- Makefile
- rebar.config
- .rvmrc
- ...


aggregate features
------------------

- (convention over configuration)
- quickly add and document external commands, scripts, code...
- wrap around and delegate to rake, rebar, mix, custom code, and/or standalone scripts/shell-commands
- dev/build tools integrated with / blended into server name
- families of (high-level) commands (ala git)
- families of commands (hierarchies- deps.get, db:create, ...)
- execute sequential commands
- default command (possibly contextual)
- commands with automatically triggered precondition commands
- semantic- explains itself, including most common / necessary commands (possibly contextual- i.e., build commands if it hasn't been built yet, run commands if it has, etc.)
- automatic manpage generation from same definitions?
- bash/zsh completion (automatically refreshed as necessary)
- very fast
- colored output
- default help, man, version (semantic & w/ git) commands
- allows for older style commandline args- at least expected gnu standards like -h, --help, -v, --version, etc.
- correctly manipulates environment variables before delegating
- @<env> environment shorthand
- always show environment except for possibly --version etc...
- default values
- post-format entered values
- allow for a configuration / environment / commandline-option option hierarchy
- multiple instances / servers / daemons running simultaneously and potentially aware of each other
- for compiled languages- make sure each environment has an isolated build target directory (including rel nodes for erlang, etc.)
- usually a fallback build method that is going to be expected by a maintainer

- tasks done "in the background" as much as possible- e.g., simply try to run the program and it will realize it needs
  to compile the dev version first.

(and some new features)

- default 'status' command (long and short [for ps1 integration or something]) possibly plugin-able - git-state, build-state, coverage-state, running-instances, ...
- automatic environment detection- e.g., via hostname, cwd, whoami, etc.
- certain commands only allowed in certain environments
- good synchronity between git version / tags and erlang (etc.) releases


task families
--------------
 interact with the project (bump, package, conformance-test, ...)
 interact with the system / environment (deploy, start, stat, stop, ...)
 interact with an instance of the application (upgrade, attach, test, ...  environment-sensitive)

(
 - local control (run, stop, attach, upgrade, downgrade, etc.-  up/downgrade prefered to reload/restart)
 - local testing, profiling, benchmarking, analyzing
 - releasing, including integration, deployment, packaging, and release management
 - project management (dependencies and submodules, ...)
)

(older misc notes)
-------------------



- Ability to have some kind of mock historical files for downloading during most tests
- test, dev, and prod all running on same machine without interfering with each other
- 

- app-ctl tasks:
  - init.d compatible:
    - start
    - stop
    - restart
    - try-restart (only restart if already running)
    - reload
    - force-reload
    - status       information on currently running app - maybe list showing available versions as well

  - node controller:

  - custom:
    - help
    - queued
    - 

