---
layout: default
---

## Patriot Batch Config (PBC)

PBC is a ruby-based DSL to describe batch jobs with dependency.
The below is a 'Hello World' example.

```
% cat test.pbc
sh{
  name 'test'
  commands ["echo 'hello world' > /tmp/out.txt"]
}
```

```
% ./bin/patriot execute 2015-04-01 test.pbc
% cat /tmp/out.txt
hello world
```
The initial target of this scheduler is daily batch jobs and the script takes a date (or range of dates) as an argument.
The date given as the argument can be used via the global variable '$dt'.
For instance, 

```
% cat test.pbc
sh{
  name 'test'
  commands ["echo 'hello world (#{$dt})' > /tmp/out.txt"]
}
% ./bin/patriot execute 2015-04-01 test.pbc
% cat /tmp/out.txt
hello world (2015-04-01)
```





