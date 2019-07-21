# luvit-prometheus

This is a Lua library that can be used with Luvit HTTP to keep track of metrics and
expose them on a separate web page to be pulled by [Prometheus](https://prometheus.io).

## Installation

`lit install logctl/luvit-prometheus`

## API reference

### init()

**syntax:** require("prometheus").init(*dict_name*, [*prefix*])

Initializes the module.

### prometheus:counter()

**syntax:** prometheus:counter(*name*, *description*, *label_names*)

Registers a counter.

* `name` is the name of the metric.
* `description` is the text description that will be presented to Prometheus
  along with the metric. Optional (pass `nil` if you still need to define
  label names).
* `label_names` is an array of label names for the metric. Optional.

[Naming section](https://prometheus.io/docs/practices/naming/) of Prometheus
documentation provides good guidelines on choosing metric and label names.

Returns a `counter` object that can later be incremented.

Example:
```
  prometheus = require("prometheus").init("prometheus_metrics")
  metric_bytes = prometheus:counter(
    "http_request_size_bytes", "Total size of incoming requests")
  metric_requests = prometheus:counter(
    "http_requests_total", "Number of HTTP requests", {"host", "status"})
```

### prometheus:gauge()

**syntax:** prometheus:gauge(*name*, *description*, *label_names*)

Registers a gauge. 

* `name` is the name of the metric.
* `description` is the text description that will be presented to Prometheus
  along with the metric. Optional (pass `nil` if you still need to define
  label names).
* `label_names` is an array of label names for the metric. Optional.

Returns a `gauge` object that can later be set.

Example:
```
  prometheus = require("prometheus").init("prometheus_metrics")
  metric_connections = prometheus:gauge(
    "http_connections", "Number of HTTP connections", {"state"})
```

### prometheus:histogram()

**syntax:** prometheus:histogram(*name*, *description*, *label_names*,
  *buckets*)

Registers a histogram. 

* `name` is the name of the metric.
* `description` is the text description. Optional.
* `label_names` is an array of label names for the metric. Optional.
* `buckets` is an array of numbers defining bucket boundaries. Optional,
  defaults to 20 latency buckets covering a range from 5ms to 10s (in seconds).

Returns a `histogram` object that can later be used to record samples.

Example:
```
  prometheus = require("prometheus").init("prometheus_metrics")
  metric_latency = prometheus:histogram(
    "http_request_duration_seconds", "HTTP request latency", {"host"})
  metric_response_sizes = prometheus:histogram(
    "http_response_size_bytes", "Size of HTTP responses", nil,
    {10,100,1000,10000,100000,1000000})
```

### prometheus:collect()

**syntax:** prometheus:collect()

Presents all metrics in a text format compatible with Prometheus. This can be supplied
as a response to a HTTP request.

### prometheus:metric_data()

**syntax:** prometheus:metric_data()

Returns metric data as an array of strings.

### counter:inc()

**syntax:** counter:inc(*value*, *label_values*)

Increments a previously registered counter.

* `value` is a value that should be added to the counter. Defaults to 1.
* `label_values` is an array of label values.

The number of label values should match the number of label names defined when
the counter was registered using `prometheus:counter()`. No label values should
be provided for counters with no labels. Non-printable characters will be
stripped from label values.

Example:
```
  metric_bytes:inc(tonumber(var.request_length))
  metric_requests:inc(1, {var.server_name, var.status})
```

### counter:del()

**syntax:** counter:del(*label_values*)

Delete a previously registered counter. This is usually called when you don't 
need to observe such counter (or a metric with specific label values in this 
counter) any more. If this counter has labels, you have to pass `label_values` 
to delete the specific metric of this counter. If you want to delete all the 
metrics of a counter with labels, you should call `Counter:reset()`.

* `label_values` is an array of label values.

The number of label values should match the number of label names defined when
the counter was registered using `prometheus:counter()`. No label values should
be provided for counters with no labels. Non-printable characters will be
stripped from label values.

### counter:reset()

**syntax:** counter:reset()

Delete all metrics for a previously registered counter. If this counter have no 
labels, it is just the same as `Counter:del()` function. If this counter have labels, 
it will delete all the metrics with different label values.

### gauge:set()

**syntax:** gauge:set(*value*, *label_values*)

Sets the current value of a previously registered gauge.

* `value` is a value that the gauge should be set to. Required.
* `label_values` is an array of label values.

### gauge:inc()

**syntax:** gauge:inc(*value*, *label_values*)

Increments or decrements a previously registered gauge. This is usually called 
when you want to observe the real-time value of a metric that can both be 
increased and decreased.

* `value` is a value that should be added to the gauge. It could be a negative 
value when you need to decrease the value of the gauge. Defaults to 1.
* `label_values` is an array of label values.

The number of label values should match the number of label names defined when
the gauge was registered using `prometheus:gauge()`. No label values should
be provided for gauges with no labels. Non-printable characters will be
stripped from label values.

### gauge:del()

**syntax:** gauge:del(*label_values*)

Delete a previously registered gauge. This is usually called when you don't 
need to observe such gauge (or a metric with specific label values in this 
gauge) any more. If this gauge has labels, you have to pass `label_values` 
to delete the specific metric of this gauge. If you want to delete all the 
metrics of a gauge with labels, you should call `Gauge:reset()`.

* `label_values` is an array of label values.

The number of label values should match the number of label names defined when
the gauge was registered using `prometheus:gauge()`. No label values should
be provided for gauges with no labels. Non-printable characters will be
stripped from label values.

### gauge:reset()

**syntax:** gauge:reset()

Delete all metrics for a previously registered gauge. If this gauge have no 
labels, it is just the same as `Gauge:del()` function. If this gauge have labels, 
it will delete all the metrics with different label values.

### histogram:observe()

**syntax:** histogram:observe(*value*, *label_values*)

Records a value in a previously registered histogram.

* `value` is a value that should be recorded. Required.
* `label_values` is an array of label values.

Example:
```
  metric_latency:observe(tonumber(var.request_time), {var.server_name})
  metric_response_sizes:observe(tonumber(var.bytes_sent))
```

### Built-in metrics

The module increments the `prometheus_metric_errors_total` metric if it encounters
an error (for example, when `lua_shared_dict` becomes full). You might want
to configure an alert on that metric.

Also, a deubbing Logger can be passed when initializing the module via `Prometheus.init(<prefix>, <logger>)`.
Logger must implement `log(head, table-values)` method.

# Credits
This is a port of [knyar/nginx-lua-prometheus](https://github.com/knyar/nginx-lua-prometheus).
