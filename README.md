## Asynchronous Bash Script Runner

  - `./run anything` in terminal to be executed after signal process is started and before stopping at the command prompt. If no arguments are passed, `.cmd` file is sourced from the current directory if it exists.

  - If `SIG` is set equal to `0` prior to starting the runner, signal process will not be started. Otherwise, set it equal to a signal string (default: `SIGUSR1`) to be used by the new signal process to interrupt the command-line process.

  - Every time a signal process is started, `.head` and `.update` files are first deleted in the current directory.

  - Signal process initially, and every time after it sources `.head` file, or every `SLEEP` seconds after that file is not found, will interrupt the command-line process using `SIG` unless this process is terminated or `SIG` is empty.

  - **[Command-line process]** Every time the command-line process is interrupted, it immediately looks for `.update` file inside the current directory and sources it. If the file does not exist, `refresh_()` is called. The value of `SIG` is passed as argument in both calls so that multiple signal processes may be detected. The process then continues from where it was interrupted. Console update tasks must be performed in this process. `BKPID` contains the command-line process number.

  - **[Signal process]** After each interruption, the signal process looks for `.head` file inside the current directory, then sources and deletes it only on success, after making an incremental copy of it inside *.th/pid/date* sub-directory of the work directory unless `TRACE` is equal to `0`. If the file does not exist, the process sleeps for `SLEEP` seconds (default: `1`). This logic is repeated by evaluating `SIGWRK` that sources the *task* script or exits with code 2 if it is not found in the work or the source directory. Asynchronous tasks are performed in this process. `subpid_` function outputs the signal process number, `SIGTS` contains the process date, and `HEAD` holds the latest sourced task number.

    **WARNING:** Even though `subpid_` outputs all of the signal process numbers correctly every time, `SIGPID` contains one additional number outside that list. This is due to an anomaly in the `subpid_` function caused by a race condition, where the piping mechanism causes additional sub-process numbers to also be included in the result due to having matching command strings in the output of `ps` command. There is a slight possibility that this flaw may cause security hazards by mismatching the extra number with a new sub-process number and terminating it by accident. There are solutions to the problem and they require keeping an up-to-date list of sub-processes as they are started in code. Work on this issue is under review.

  - Every time the *signal* script is sourced from the command-line, it takes the previous `SIGPID` values and attempts to terminate any process that was issued by a matching command string. In order to start a new signal process without terminating any of the previous ones clear or unset `SIGPID` and optionally set `SIG` equal to an unused signal string prior to sourcing the script again.

    **WARNING:** A common mistake would be to start a new signal process with a local `SIGPID` in a single-line command such as `SIGPID= . signal`. This will lead to issues at termination time because the value of `SIGPID` will not persist once the script is sourced. Instead, this variable must be cleared in the current enclosure.

  - Optionally before starting the runner, set `SLEEP` equal to a file path in order to have its content be used as sleep amount at every iteration of the signal process when `.head` file is not found.

  - Before stopping at the prompt or reading a new byte from keyboard, `PSTWRK` is evaluated. After reading a new byte from keyboard, `WRK` is evaluated. Then, that byte is processed for a key press event if `BKZ` is equal to `0`. Both variables are cleared before running the terminal command and stopping at the prompt. `BKP` is also cleared in order to safely start the command prompt with the correct keybinding path. Therefore, these variables must be set either in the terminal command or `.cmd` file.

  - Evaluate `break` to stop command line and all signal processes.

    **WARNING:** Occasionally when multiple signal processes are started, `kill` command will skip a signal sub-process when breaking out of the command prompt. The bug may be caused by the order that this command issues the termination signal to each sub-process or it may have other reasons. The best way around the problem is to always check for any orphaned process after exiting the command-line process and to terminate each one.

  - Press `F8` to evaluate the command line.

  - Press `F7` to insert a new line character in command line.

  - Press `F6` to insert a tab character in command line.

  - Press `F5` to refresh the screen.

  - **Reserved variables:** `PRE`, `PST`, `SLEEP`, `BKPID`, `COLOR`, `HEAD`, `LN`, `PSTKB164`, `PSTKB167`, `PSTLN`, `PSTWRK`, `REF`, `SIG`, `SIGPID`, `SIGTS`, `SIGUSR`, `SIGWRK`, `STATUS`, `STLN`, `STREF`, `THREAD`, `TRACE`

  - **Reserved functions:** `kill_signal_`, `subpid_`, `ps_subpids_`, `update_`, `refresh_`, `refresh_status_`, `ipclock_`

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
