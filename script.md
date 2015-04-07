---
layout: default
---
## Patriot script

```
% ./bin/patriot
Commands:
  patriot execute [options] <yyyy-mm-dd[,yyyy-mm-dd]> <files/paths>+       # execute patriot jobs directly
  patriot help [COMMAND]                                                   # Describe available commands or one specific command
  patriot job [delete|show_dependency] job_id [job_id ..]                  # manage job(s) in job store
  patriot plugin [options] install <path to plugin>                        # manage plugins
  patriot register [OPTIONS] yyyy-mm-dd[,yyyy-mm-dd] path [path file ...]  # register jobs
  patriot validate [OPTIONS] path [path file ...]                          # validate pbc files
  patriot worker [options] [start|stop]                                    # controll worker
  patriot worker_admin [options] [start|stop|restart|sleep|wake|status]    # controll remote workers

Options:
  -c, [--config=CONFIG]  # path to configuration file
```

### execute

execute patriot jobs directly

```
./bin/patriot help execute
Usage:
  patriot execute [options] <yyyy-mm-dd[,yyyy-mm-dd]> <files/paths>+

Options:
  -f, [--filter=FILTER]          # regular expression for job_id
  -d, [--debug], [--no-debug]    # run in debug mode
  -t, [--test], [--no-test]      # run in test mode
      [--strict], [--no-strict]  # run in strict mode (according to dependency)
  -c, [--config=CONFIG]          # path to configuration file
```

### register

register jobs to jobstore

```
% ./bin/patriot help register
Usage:
  patriot register [OPTIONS] yyyy-mm-dd[,yyyy-mm-dd] path [path file ...]

Options:
  -f, [--filter=FILTER]                  # regular expression for Ruby
  -d, [--debug], [--no-debug]            # debug mode flag
  -p, [--priority=N]                     # job priority
                                         # Default: 1
  -s, [--state=N]                        # register as specified state
      [--keep-state], [--no-keep-state]  # don't change current state of jobs (only change definition)
      [--retry-dep], [--no-retry-dep]    # set states of dependent jobs to WAIT
      [--update-id=UPDATE_ID]            # default value is current unixtime
                                         # Default: Time.now.to_i
  -c, [--config=CONFIG]                  # path to configuration file
```


### validate

validate pbc files

```
% ./bin/patriot help validate
Usage:
  patriot validate [OPTIONS] path [path file ...]

Options:
  -s, [--stop-on-detection], [--no-stop-on-detection]  # stop immediately when invalid config detected
      [--date=DATE]                                    # date passed to parser
  -c, [--config=CONFIG]                                # path to configuration file
```
### worker

controll local worker

```
Usage:
  patriot worker [options] [start|stop]

Options:
      [--foreground], [--no-foreground]  # run as a foreground job
  -c, [--config=CONFIG]                  # path to configuration file

controll worker
```

### worker_admin
  
controll remote workers

```
Usage:
  patriot worker_admin [options] [start|stop|restart|sleep|wake|status]

Options:
  -a, [--all], [--no-all]  # target all worker hosts
  -h, [--host=HOST]        # target host
  -c, [--config=CONFIG]    # path to configuration file
```

### job

manage job(s) in job store

```
% ./bin/patriot help job
Usage:
  patriot job [delete|show_dependency] job_id [job_id ..]

Options:
  -c, [--config=CONFIG]  # path to configuration file

```

###  plugin

manage plugins

```
% ./bin/patriot help plugin
Usage:
  patriot plugin [options] install <path to plugin>

Options:
  -f, [--force]                  # force operation
      [--unpack], [--no-unpack]  # unpack gem into plugin dir
  -c, [--config=CONFIG]          # path to configuration file
```

