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

    RESET          reset test for mode 2

    SLEEP          sleep time for modes 1 and 2

    MODE           run mode

    WAIT           wait command for modes 1 and 2

    OUT            output directory

    PRE            pre-run code identifier

    PST            post-run code identifier

    RSV            name reservation flag

    SRC            runner directory

    VER            framework version

    WKD            work directory

    WRK            command line plug-in</code></pre>
