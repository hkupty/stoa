# Stoa

Stoa is my custom shell façade.

Think of [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh), but:
- written in zig;
- written for my own use-case, instead of something generic;

## Why?

- Because I wanted to get my hands dirty with zig;
- Because I wanted to customize my shell experience;
- Because I didn't want to rely on third-party software;
- Because I wanted to learn more about shells;
- Because I love performance and this is at least two orders of magnitude faster (benchmark below):
    - No, being that fast is not relevant at all. It just makes me happy.
    - Anything below 250ms is already fast enough, but I wanted to make this anyway.


## Architecture

There are a few binaries that work together to make this happen:

- `stoa-prompt`: The main one, draws the prompt
- `stoa-rprompt`: Draws the rprompt on the side
- `stoa-status`: Captures the status of previously run commands
- `stoa-transient`: Ensures a clean transient shell
- `stoa-session`: Starts a new session

All the binaries are minimal and follow a few rules:
- No errors should leak out: Make the output ugly, but never bubble out an error.
- Internal communication happen through the session file
- Each app "owns" writes for their own fields, everyone else can read them

## Benchmark

```

Benchmark 1 (367 runs): oh-my-posh print primary -c ~/.config/oh-my-posh/config.yaml
  measurement          mean ± σ            min … max           outliers         delta
  wall_time          13.5ms ± 6.52ms    7.56ms … 45.3ms          2 ( 1%)        0%
  peak_rss           23.6MB ± 1.17MB    21.2MB … 24.9MB          0 ( 0%)        0%
  cpu_cycles         17.8M  ± 1.84M     13.2M  … 26.0M          33 ( 9%)        0%
  instructions       30.8M  ± 2.24M     24.8M  … 33.8M          54 (15%)        0%
  cache_references    917K  ± 70.2K      727K  … 1.03M          54 (15%)        0%
  cache_misses        226K  ± 22.4K      166K  …  272K          52 (14%)        0%
  branch_misses       164K  ± 11.8K      131K  …  178K          52 (14%)        0%
Benchmark 2 (10000 runs): stoa-prompt
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           374us ±  158us     188us … 2.99ms        111 ( 1%)        ⚡- 97.2% ±  1.0%
  peak_rss            802KB ± 9.71KB     647KB …  803KB         42 ( 0%)        ⚡- 96.6% ±  0.1%
  cpu_cycles         12.9K  ±  796      11.2K  … 25.0K         355 ( 4%)        ⚡- 99.9% ±  0.2%
  instructions       4.23K  ± 0.43      4.23K  … 4.23K        2242 (22%)        ⚡-100.0% ±  0.1%
  cache_references   1.87K  ±  123      1.63K  … 2.92K         401 ( 4%)        ⚡- 99.8% ±  0.1%
  cache_misses        230   ± 43.4        92   …  628          140 ( 1%)        ⚡- 99.9% ±  0.2%
  branch_misses       137   ± 22.2        78   …  232          540 ( 5%)        ⚡- 99.9% ±  0.1%
```
