## Asynchronous Bash Script Runner

  - `./run anything` in terminal to be executed after signal process is started and before stopping at the command prompt. If no arguments are passed, `.cmd` file is sourced from the **current** directory if it exists.

  - If `SIG` is set equal to `0` prior to starting the runner, signal process will not be started. Otherwise, set it equal to a signal string (default: `SIGUSR1`) to be used by the new signal process to interrupt the command-line process.

  - Signal process initially, and every time after it sources `.head` file inside the **work** directory, or every `SLEEP` seconds after that file is not found, will interrupt the command-line process using `SIG` unless this process is terminated or `SIG` is empty.

  - **[Command-line process]** Every time the command-line process is interrupted, it immediately looks for `.update` file inside the **current** directory and sources it. If the file does not exist, `refresh_()` is called. Variables `SIG` and `SIGTS` are passed as arguments in both calls so that multiple signal processes may be detected. The process then continues from where it was interrupted. Console update tasks must be performed in this process. `BKPID` contains the command-line process number.

  - **[Signal process]** After each interruption, the signal process looks for `.head` file inside the **work** directory, then sources and deletes it only on success, after making an incremental copy of it inside *.th/pid/date* sub-directory of the **work** directory unless `TRACE` is equal to `0`. If the file does not exist, the process sources `.setup` file in the **current** directory then sleeps for `SLEEP` seconds (default: `1`). This logic is repeated by evaluating `SIGWRK` that sources the *task* script or exits with code 2 if it is not found in the **work** or the **source** directory. Asynchronous tasks are performed in this process. `SIGPID` contains the signal process number, `SIGTS` holds the process date, and `HEAD` holds the latest saved task number.

  - Optionally before starting the runner or inside `.setup` file, set `SLEEP` equal to a file path in order to have its content be used as sleep amount at every iteration of the signal process when `.head` file is not found.

  - Every time the *signal* script is sourced from the command-line, it takes the previous `SIGPID` values and attempts to terminate any process that was issued by a matching command string. In order to start a new signal process without terminating any of the previous ones clear or unset `SIGPID` and optionally set `SIG` equal to an unused signal string prior to sourcing the script again.

    Every time a signal process is started, `.head` and `.update` files are first deleted in the **current** directory. This will be avoided if the work directory is **not** the same as the current directory. It is generally good practice to start a new signal process inside its own work directory and leave the current directory for the command-line and setup processes.

    ```bash
    # first signal process
    WKD=./task1 \       # optional
    ./run

    # second signal process
    WKD=./task2 \       # safe practice
    SIG=SIGUSR2 \
    SIGPID= \
    ./run

    # use console if you only need the command-line
    ./console
    ```

    **WARNING:** A common mistake would be to start the second signal process using a local `SIGPID` in a single-line command such as `SIGPID= . signal` and evaluating it inside the command-line. This will lead to issues at termination time because the value of `SIGPID` will not persist once the script is sourced. Instead, this variable must be cleared in the current enclosure.

  - Before stopping at the prompt or reading a new byte from keyboard, `PSTWRK` is evaluated. After reading a new byte from keyboard, `WRK` is evaluated. Then, that byte is processed for a key press event if `BKZ` is equal to `0`. Both variables are cleared before running the terminal command and stopping at the prompt. `BKP` is also cleared in order to safely start the command prompt with the correct keybinding path. Therefore, these variables must be set either in the terminal command or `.cmd` file.

  - Evaluate `break` to stop command line and all signal processes.

    **WARNING:** Occasionally when multiple signal processes are started, `kill` command will skip a signal sub-process when breaking out of the command prompt. The bug may be caused by the order that this command issues the termination signal to each sub-process or it may have other reasons. The best way around the problem is to always check for any orphaned process after exiting the command-line process and to terminate each one.

    ```bash
    # look for any hanging signal process
    ps

    # try to terminate all signal processes
    SIG=0 SIGPID=0 ./run exit

    # try to terminate specific signal processes
    NKL="list of processes to keep alive" \
    SIG=0 SIGPID=0 ./run exit

    # same as above only inside command line
    NKL="list of processes to keep alive" \
    kill_signal_ [ list of processes to kill ]
    ```

  - Press `F8` to evaluate the command line.

  - Press `F7` to insert a new line character in command line.

  - Press `F6` to insert a tab character in command line.

  - Press `F5` to refresh the screen.

  - **Reserved variables:** `BKPID`, `COLOR`, `HEAD`, `LN`, `NKL`, `PRE`, `PST`, `PSTKB164`, `PSTKB167`, `PSTLN`, `PSTWRK`, `REF`, `SIG`, `SIGPID`, `SIGTS`, `SIGUSR`, `SIGWRK`, `SLEEP`, `STATUS`, `STLN`, `STREF`, `THREAD`, `TRACE`

  - **Reserved functions:** `kill_signal_`, `reset_sigpid_`, `subpid_`, `update_`, `refresh_`, `refresh_status_`, `ipclock_`, `timestamp_`

### Example:

Evaluating this command in terminal prints `HEAD` in console __asynchronously__ until it is greater than `9` and stops:

```bash
./run eval "echo 'echo \$HEAD; [[ HEAD -gt 9 ]]' > .head"
Starting new signal process
1
2
3
4
5
6
7
8
9
10
```
