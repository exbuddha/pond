## Production Bash Script Runner

**NOTE:** DO NOT run this script yet. Implementation on this branch is in progress.

The requirement is to be able to have a secure session for new signal processes and to be able to reconnect to past sessions and control the activity in scripts with good console UI work.

This branch covers program interrupts (interceptions) and exceptions (error handling) by re-routing code execution through and back into the command-line again.

In order to implement the new features a set of variables and functions are added. The proposed changes are described as follows.

The `interrupt_` function is called whenever SIGINT is emitted. There will be an `intercept_` function as well that is called for user signals that are emitted from sub-processes. Exceptions are also routed to a function very similar to the `interrupt_` function.

Instead of issuing a `break` whenever one of these functions is called a tracing logic is added to control the execution flow. Two questions require to be answered at runtime: 1. where is the code currently blocking; and, 2. what is the correct course of action that must be taken to route the execution flow unto a designated origin in the code.

For example, if the code is currently running inside a function or a script, the right course of action would be to issue a `return`. If the code is in a repeating loop, whether to retry or count, then the right course of action would be to issue a `break`. This decision, in turn, adds more complexity to the code by demanding the program to follow a specific pattern. Every time the logic in code calls a function or a script and every time it enters a loop there needs to be a call made to an internal infrastructure that handles interruptions.

```bash
# inside functions
appoint_interrupt_function_
while ...; do
    ...
done
eval "$(resource_ run_/process/navigate_interrupt)"
```

```bash
# inside sourced scripts
appoint_interrupt_source_
while ...; do
    ...
done
eval "$(resource_ run_/process/navigate_interrupt)"
```

There are additional versions of these functions for retry loop.

The underlying logic needs to be aware where within the exposed `FUNCNAME` array the interrupt handler is being called. Based on the record saved in `INTTAIL` and `INTTRACE` variables, it will then be able to correctly navigate the execution flow to its designated origination point. By using loop functionality everywhere the `interrupt_` function can break the loop in order to begin the navigation process; however, this implies that a new function called `bypass_interrupt` needs to explicitly handle breaking out of retry and timeout loops cooperatively and the program must become aware of this strategy as it defers from the mentioned returning strategy. Based on the order in `FUNCNAME` array and the records, the logic can decide how to correctly navigate to the origination point, which is where the outer-most loop containing the command-line call was made, inside the `run_` function.

There also needs to be a way to save the state of execution, with all local variables that were defined, after a command-line was started, in order to be able to resurrect these variables or functions when the time comes to retry them. If a retry is not intended, these saved states will be simply dropped once the origination point is reached. This, in turn, implies that code must be written with the awareness that it may be called in two different states: first pass, or retry passes.

In order to allow the code to be aware of the pass it is executing on, a set of new variables and functions are introduced to facilitate the decision making. The variables `INR` and `INRHIST` save the states of execution while the code is written with these variables involved during a pass.

For example, a variable declaration has to be aware of the state of retries, therefore it needs to be declared as such:

```bash
eval "$(resource_ run_/process/appoint_interrupt_cooperative)"
for((;;))do
if [[ RETRY -eq 0 ]]; then
    # perform normal assignment
    # appoint_interrupt_ function should have already been called and WRD is optionally registered for the current pass
    eval "${WRD}varname='value'"
    inr_ varname
    eval "$(resource_ run_/process/bypass_interrupt)"
else
    # the old value of WRD is used instead of the current one if retry requires it
    eval "$(resource_ run_/process/assign_interrupt_variable varname "$WRD")"
    eval "$(resource_ run_/process/assign_interrupt_value varname 'value')"
fi
break
done
eval "$(resource_ run_/process/remove_interrupt_cooperative)"
```

The two new resources handle saved states based on where in the interrupt infrastructure the code is passing.

Finally, once the origination point is reached `BKZ` and `BKX` coordinate the interrupt (break signal or exception) and intercept (sub-process signal) flow of execution by their respective stacks.

After a session is successfully acquired, the program logic can choose to rely more heavily on disk records instead of in-memory states, that paves the way to having session reconnect capabilities.
