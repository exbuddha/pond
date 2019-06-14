## Extensible Bash Script Runner

<pre><code>usage:

    run [options] [cmd]   # press F8 to evaluate command line

options:

    -m|--mode m    run mode

                     [0]    starts immediately

                       1    periodically evaluates WAIT,
                            if empty sleeps for SLEEP amount

                       2    periodically evaluates RESET,
                            on success repeats mode 1 once,
                            if empty creates OUT directory,
                            on failure repeats mode 1 once

    -o|--out dir   output directory

    --pre code     pre-run code

    --post code    post-run code

    MODE           run mode

    WAIT           wait command for modes 1 and 2

    SLEEP          sleep time for modes 1 and 2

    RESET          reset test for mode 2

    OUT            output directory

    PRE            pre-run code identifier

    PST            post-run code identifier

    RSV            name reservation flag

    SRC            runner directory

    WKD            work directory

    WRK            command line plug-in code

    BKP            command line keybinding path

    BKW            command line stack counter

    VER            runner version</code></pre>

#### Name Reservation:

Reservation is required for correctness and specifically in the case of recursive functions. By default, name reservation is disabled. In order to enable it, set `RSV` equal to a positive integer forcing the runner to reserve all environment variables before evaluating the command. After that point, anywhere in the code where name reservation becomes a requirement again, set `RSV` equal to an array with the first element being a positive integer and the rest being the names that must be reserved going forward, then evaluate resource `run_/preset`. Once these names are reserved, `WRD` will hold the smallest string that, prepended to any variable name, will guarantee that there will be no naming collisions. For convenience, by calling this resource `WRD` is added to the list of local arguments, as `$1`. Source code can then be generated and evaluated securely:

```bash
local -a VARNAMES=(list of reserved variable names)
local -a RSV=(1 "${VARNAMES[@]}")
eval "$(resource_ run_/preset)"
eval "shift; local ${1}protected_name; ..."

# or, avoid changing local arguments and reserve names directly

eval "$(recall_ run_/reserve)" "${VARNAMES[@]}"
eval "local ${WRD}protected_name; ..."
```

These names are reserved by the runner:

  - Single underscore starting character in all variable and function names is reserved.
  - Variable names `BKR`, `BKX`, `BKZ`, `ext`, `EXT`, `EXX`, `RCT`, `RCX`, `LDD`, `LDX`, `UDD`, `UDX`, `CAP`, `WRD`, `CHS`, `OFS`, and `SAN` are reserved in addition to the variables named above.
  - Function names `main_`, `recall_`, `resource_`, `run_`, and `return_` are all reserved.
  - Variable `_64run_95_47mkdir_95_out` is a special variable evaluated by the runner after parsing the options. The runner allows the variable to be overridden by environment before it is loaded from disk.

#### Code Extension:

Code extension, similar to `source` and `eval` commands, allows for code to be reloaded from disk or memory on-demand. It is a hashing strategy for variable and function names. All extended (cached) variables and functions are prepended with a single underscore character in order to avoid naming collisions with user variables or functions.

  - Source directory, work directory, and resourcing:

    The runner recognizes and uses two directory names `SRC` and `WKD` in order to locate extended resources on disk. Source directory is set to the location of the *run* script and work directory is set to the current directory; however, both variables can be overridden by the environment as well. Every time a resource is called, the runner looks for a directory named *.rc* inside the work directory first and then the source directory. By design, the extension resource (located at *run_/@/ext*) is used to find the path for other resources on disk. As a minimum requirement, this resource must exist in either of the two directories when the runner is started.

  - Default startup resources:

    In addition to the extension resource mentioned above, three other resources are used by the runner but they are not all required. The two required resources are called `run_/parse_opts` and `run_/mkdir_out`. The optional resource is called `run_/prep`. As a minimum requirement, after these resources are evaluated successfully, the runner expects functions `run_` and `return_` to be declared or exits with code 2.

    Two special resources are used by the reservation mechanism and are both essential parts of the runner. These resources are named `run_/reserve` and `run_/preset`. They are required only when name reservation is used.

    **IMPORTANT:** Required resources `run_/parse_opts` and `run_/mkdir_out` are both evaluated **twice**; first by the runner and then again by the `run_` function. They must contain code that safely accommodates one or more repetitions. In some cases when the runner is started in mode 1 or 2, the reserved variables `WAIT` or `RESET` must either change `MODE` or their own value based on runtime criteria when they are evaluated.

  - `recall_` and `resource_` functions:

    These functions comprise the backbone of the runner and carry out the code extension logic. Variables `ext`, `EXT`, `EXX`, `RCT`, and `RCX` are reserved by these two functions.

    Every time an extension is resourced, the extension lookup logic uses `EXT` to find that resource and set `ext` equal to its location if it is found; otherwise, `EXX` is evaluated. By convention, the code contained in `EXX` must make the extended resource available on disk and then set `ext` equal to its path. Variables `RCX` and `RCT` are then used to resolve errors during and after loading the resource file. `RCX` is evaluated if `cat` command is unable to access the file. `RCT` is evaluated as a test command prior to calling the resource.

    ```bash
    EXT=run_/load \
    EXX='download $EXT' \
    RCX='return_ 3' \
    RCT='return_' \
    eval "$(recall_)" func args ...

    if [[ $? -eq 3 ]]; then
    
        # failed to load run_/load resource
    
    fi
    ```

  - Function loading:

    Function loading is a secondary method of code extension that the runner performs in order to declare functions with names that are readable. By default, the optional `run_/prep` resource is called to prepare dependencies and this internally is done by calling `run_/load` and `run_/unload` resources. Variables `LDD`, `LDX`, `EXX`, `UDD`, and `UDX` are reserved for this process. The `run_/unload` resource allows `MODE` and `VER` variables to be reused prior to loading, and also transfers `UDD` and `UDX` to `LDD` and `LDX`.

    The reserved variable `EXX` serves a similar role as in `recall_` and `resource_` functions except that it also allows to return with an error code. Variables `LDX` and `UDX` work similarly to `RCX` mentioned above.

    ```bash
    EXX='return 4' \
    LDX='return 5' \
    eval "$(EXX= RCX='return_ 3' RCT='return_' recall_ run_/load)" func args ...

    case $? in
    3)
        # failed to load run_/load resource
        ;;
    4)
        # function resource was not found
        ;;
    5)
        # failed to load function resource
        ;;
    esac
    ```

    **NOTE:** `EXX` has overlapping usages in both resource extension and function loading procedures and must be set appropriately.

    **IMPORTANT:** The first `/` character is trimmed from `EXT` before it is processed for lookup.
      * Use `internal/file` for internal resources located inside *.rc* directory (enabled in resource extension only)
      * Use `/relative/path/file` for resources with relative paths (enabled in function loading only)
        ```bash
        # LDD is an alias for EXT
        PATH=/relpath/to/file \
        LDD=PATH \
        eval "$(recall_ run_/load)" name args ...
        ```
      * Use `//root/path/file` for resources with full paths
      * Network paths are not supported

#### Command-line:

The command-line (resourced at `run_/break`) is a code that reads from the keyboard and processes each key according to the resource which is bound to that key at the moment. The reserved variable `BKP` determines this resource path located inside the */run_/@/binding* directory.

The command-line loops endlessly through steps 2-5 until interrupted or broken:
   1. evaluate `WRK`
   2. read one byte from the keyboard
   3. evaluate `WRK` again (for every byte)
   4. continue if `BKZ` is **not** equal to `0`
   5. process the key press if recognized, or process as unconventional keystroke

The command-line stack counter `BKW` increments every time a new command-line is started by calling the `run_` function with no arguments. After breaking out of the command-line, if `BKZ` contains an identifier that is **less** than `0` at the time `BKX` will be evaluated. If this command continues the loop, a new command-line is resourced. `BKR` contains the identifier holding the latest return code of the command-line.

#### System Requirements:

  - POSIX-standard Bash interpreter
  - `awk`, `sed`, and `realpath` system functions
