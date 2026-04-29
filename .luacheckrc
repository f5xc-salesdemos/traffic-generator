-- wrk benchmarking tool defines these globals
globals = {
    "wrk",
    "request",
    "response",
    "done",
    "init",
    "delay",
    "setup",
    "thread"
}

-- wrk thread:set/get variables are runtime-injected
read_globals = {
    "id"
}

-- wrk scripts are standalone; unused variable/argument warnings are noise
max_line_length = false
unused_args = false
