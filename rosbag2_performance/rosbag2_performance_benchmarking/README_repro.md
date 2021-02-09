# About
Compare rolling and foxy ros2bag record performance (possibly other versions may be OK).

In transport mode, `benchmark_launch.py` calls `ros2 bag record` by ExecuteProcess.
To call different ros2 version bag2 record, this branch calls `ros2 bag record` via `bag2record.sh`.

# Configuration

1. Build rolling

```
$ cd ros2_rolling  # get codes and so on
$ colcon build --symlink-install --cmake-args -DBUILD_ROSBAG2_BENCHMARKS=1
```

2. Build foxy

```
$ cd ros2_foxy  # get codes and so on
$ colcon build --symlink-install
```

3. Set rolling and foxy paths to `launch/bag2record.sh`

```
FOXY_PATH=/home/rosuser/src/ros2_foxy
ROLLING_PATH=/home/rosuser/src/ros2_rolling
```

4. Edit `repro.yaml` and set test parameters

5. Run test

```
$ cd ros2_rolling
$ . install/local_setup.bash
$ DIR=`ros2 pkg prefix rosbag2_performance_benchmarking`
$ ros2 launch rosbag2_performance_benchmarking benchmark_launch.py \
    benchmark:=${DIR}/share/rosbag2_performance_benchmarking/config/benchmarks/test_transport.yaml \
	producers:=${DIR}/share/rosbag2_performance_benchmarking/config/producers/repro.yaml

$ ./src/ros2/rosbag2/rosbag2_performance/rosbag2_performance_benchmarking/scripts/report_gen.py \
    -i rosbag2_performance_test_results/test_transport_repro_transport_<YYYY_MM_DD_HH_MM_SS>
```

# Test Results

## Condition:

| Condition         |      value |
|-------------------|-----------:|
| `msg_size_bytes`  |      10000 |
| `msg_count_each`  |        500 |
| `rate_hz`         |        100 |
| `qos_reliability` | `reliable` |

We disable the following options of `ros2 bag record` because foxy ros2bag does not support them.

- `--storage_config_file`
- `--compression-mode`
- `--compression_queue_size`

## Tests patterns

We tested the following patterns.

(P1) original code with some modification:
  - call `ros2 bag record` directly in `benchmark_launch.py`.
  - omit options above
(P2) call rolling `ros2 bag record` via `bag2record.sh`
  - similar results to (1) is expected
(P3) call foxy `ros2 bag record` via `bag2record.sh`

We change the number of publishers(`publishers_count`) and `qos_depth`.
We run up to 100 publishers because `benchmark_: create_thread: benchmark_publi: no free slot` error occurs on `transport` mode.

To change test pattern, comment out `## Foxy` or `## Rolling` in `bag2record.sh`.
To change test parameters, edit `repro.yaml`.

## Test metrics

We record the `recoreded %` of `report_gen.py` output.

```
$ report_gen.py -i ...
(snip)
Results: 
        Repetitions: 2
        Max bagfile size: 0
        Compression: <default>
        Compression threads: 0
        Compression queue size: 1
        Recorded messages for different caches and storage config:
                storage config: default:
                        cache [bytes]: 10,000,000: 100.24% recorded     # here
                        cache [bytes]: 100,000,000: 100.24% recorded    # here
```


## Results

**Result of P1**: call rolling `ros2 bag` directly

| No | `publishers_count` | `qos_depth` | record(10MB) | record(100MB) |
|----|-------------------:|------------:|-------------:|--------------:|
| 1  |                 10 |           5 |      100.06% |       100.06% |
| 2  |                100 |           5 |       94.71% |        98.61% |
| 3  |                100 |       10000 |       99.86% |        99.78% |

In (3), as `qos_reliability` is `reliable` and `msg_count_each` is 500, this setup is similar to `KeepAll`.
But the drop happened.

**Result of P2**: call rolling `ros2 bag` via `bag2record.sh`

| No | `publishers_count` | `qos.depth` | record(10MB) | record(100MB) |
|---:|-------------------:|------------:|-------------:|--------------:|
|  1 |                 10 |           5 |      100.32% |       100.21% |
|  2 |                100 |           5 |       99.48% |        94.03% |
|  3 |                100 |         500 |       99.61% |       100.04% |

It looks similar to the P1 result.

**Result of P3**: call foxy `ros2 bag record` via `bag2record.sh`
We used rosbag2 bc1e53eb60b2f603f02c65c43d6eae74bd644aa7.

| No | version | publishers_count | qos.depth | record(10MB) | record(100MB) |
|---:|---------|-----------------:|----------:|-------------:|--------------:|
|  1 | foxy    |               10 |         5 |      100.24% |       100.24% |
|  2 | foxy    |              100 |         5 |       78.85% |        76.62% |
|  3 | foxy    |              100 |       500 |       89.42% |        91.88% |
|  4 | foxy    |              100 |      5000 |       91.22% |        91.79% |

(2) shows the drop rate is higher than rolling.
(3), (4) shows even if we prepared enough QoS depth, the drop still occured.

