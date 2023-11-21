## Asynchronous Bash Script Runner

  - `./run anything` in terminal to be executed after signal process is started and before stopping at the prompt. If no arguments are passed, `.cmd` file is sourced from the current directory if it exists.

  - If `SIG` is set equal to `0` prior to starting the runner, signal process will not be started. Otherwise, set it equal to a signal string (default: `SIGUSR1`) to be used by the new signal process to interrupt the command line process.

  - Every time a signal process is started, `.head` and `.update` files are first deleted in the current directory.

  - Signal process initially, and every time after it sources `.head` file, or every `SLEEP` seconds after that file is not found, will interrupt the command line process using `SIG` unless this process is terminated or `SIG` is empty.

  - **[Command-line process]** Every time the command line process is interrupted, it immediately looks for `.update` file inside the current directory and sources it. If the file does not exist, `refresh_()` is called. The process then continues from where it was interrupted. Console update tasks must be performed in this process. `BKPID` contains the command-line process number.

  - **[Signal process]** After each interruption, the signal process looks for `.head` file inside the current directory, then sources and deletes it only on success, after making an incremental copy of it inside *.th/pid/date* sub-directory of the work directory unless `TRACE` is equal to `0`. If the file does not exist, the process sleeps for `SLEEP` seconds (default: `1`). This logic is repeated by evaluating `SIGWRK` that sources the *task* script or exits with code 2 if it is not found in the work or the source directory. Asynchronous tasks are performed in this process. `SIGPID` contains the signal process number, `SIGTS` contains the process date, and `HEAD` holds the latest sourced task number.

  - Optionally before starting the runner, set `SLEEP` equal to a file path in order to have its content be used as sleep amount at every iteration of the signal process when `.head` file is not found.

  - Before stopping at the prompt or reading a new byte from keyboard, `PSTWRK` is evaluated. After reading a new byte from keyboard, `WRK` is evaluated. Then, that byte is processed for a key press event if `BKZ` is equal to `0`. Both variables are cleared before running the terminal command and stopping at the prompt. `BKP` is also cleared in order to safely start the command line prompt with the correct keybinding path. Therefore, these variables must be set either in the terminal command or `.cmd` file.

  - Evaluate `break` to stop command line and signal process.

  - Press `F8` to evaluate the command line.

  - Press `F7` to insert a new line character in command line.

  - Press `F6` to insert a tab character in command line.

  - Press `F5` to refresh the screen.

  - **Reserved variables:** `BKPID`, `COLOR`, `HEAD`, `LN`, `PSTKB164`, `PSTKB167`, `PSTLN`, `PSTWRK`, `REF`, `SIG`, `SIGPID`, `SIGTS`, `SIGUSR`, `SIGWRK`, `STATUS`, `THREAD`, `TRACE`

  - **Reserved functions:** `refresh_`, `update_`, `subpid_`, `ipclock_`

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
