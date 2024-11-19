#signal init .cmd routes cmdline to tests that run after create_session_ is successfully called inside session_ function and a new signal process is started
#use OUT instead of WKD
#local WKD="$OUT"

#change break strategy to session-controlled
#add intercept logic for sub-process communication
#define fg_ and bg_ functions

#use BKZ as temporary in order to navigate successful case to a new break instance
#BKX=...
eval "$BKZ"'[1]='"$BKZ"\;"$BKZ"'=-100'
