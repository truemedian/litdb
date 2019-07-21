-- vim: softtabstop=4:tabstop=4:shiftwidth=4:noexpandtab:smarttab
prometheus = require('prometheus').Prometheus

local Logger = {}
Logger.__index = Logger
function Logger.log(level, ...)
	if not Logger.logs then Logger.logs = {} end
	table.insert(Logger.logs, table.concat({...}, " "))
end

-- Finds index of a given object in a table
local function find_idx(table, element)
	element = element .. "\n"
	for idx, value in pairs(table) do
		if value == element then
			return idx
		end
	end
end

TestPrometheus = {}
TestPrometheus.__index = TestPrometheus
function TestPrometheus.new()
	return setmetatable({}, TestPrometheus)
end

function TestPrometheus:assertEqual(a, b)
	local comp = a ~= b
	if comp then
		local err = string.format("====================================\nshould be %s but %s found\n", a, b)
		err = err .. "values:\n"

		local str = self.p:collect()
		err = err .. str .. "\n"
		if Logger.logs then
			err = err .. "logs:\n"
			for _, v in pairs(Logger.logs) do
				err = err .. "\t" .. v .. "\n"
			end
		end
		err = err .. "\n===================================="
		self.errors[#self.errors+1] = err
	end
	return not comp
end

function TestPrometheus:reset()
	self.p = prometheus.init("", Logger)
	self.counter1 = self.p:counter("metric1", "Metric 1")
	self.counter2 = self.p:counter("metric2", "Metric 2", {"f2", "f1"})
	self.gauge1 = self.p:gauge("gauge1", "Gauge 1")
	self.gauge2 = self.p:gauge("gauge2", "Gauge 2", {"f2", "f1"})
	self.hist1 = self.p:histogram("l1", "Histogram 1")
	self.hist2 = self.p:histogram("l2", "Histogram 2", {"var", "site"})
	Logger.logs = nil
	self.errors = {}
end
function TestPrometheus:testInit()
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testErrorInvalidMetricName()
	local h = self.p:histogram("name with a space", "Histogram")
	local g = self.p:gauge("nonprintable\004characters", "Gauge")
	local c = self.p:counter("0startswithadigit", "Counter")

	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 3)
	self:assertEqual(#Logger.logs, 3)
end
function TestPrometheus:testErrorInvalidLabels()
	local h = self.p:histogram("hist1", "Histogram", {"le"})
	local g = self.p:gauge("count1", "Gauge", {"le"})
	local c = self.p:counter("count1", "Counter", {"foo\002"})

	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 3)
	self:assertEqual(#Logger.logs, 3)
end
function TestPrometheus:testErrorDuplicateMetrics()
	self.p:counter("metric1", "Another metric 1")
	self.p:counter("l1_count", "Conflicts with Histogram 1")
	self.p:counter("l2_sum", "Conflicts with Histogram 2")
	self.p:counter("l2_bucket", "Conflicts with Histogram 2")
	self.p:gauge("metric1", "Conflicts with Metric 1")
	self.p:histogram("l1", "Conflicts with Histogram 1")
	self.p:histogram("metric2", "Conflicts with Metric 2")

	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 7)
	self:assertEqual(#Logger.logs, 7)
end
function TestPrometheus:testErrorNegativeValue()
	self.counter1:inc(-5)

	self:assertEqual(self.p.dict:get("metric1"), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 1)
	self:assertEqual(#Logger.logs, 1)
end
function TestPrometheus:testErrorIncorrectLabels()
	self.counter1:inc(1, {"should-be-no-labels"})
	self.counter2:inc(1, {"too-few-labels"})
	self.counter2:inc(1)
	self.gauge1:set(1, {"should-be-no-labels"})
	self.gauge2:set(1, {"too-few-labels"})
	self.gauge2:set(1)
	self.hist2:observe(1, {"too", "many", "labels"})
	self.hist2:observe(1, {nil, "label"})
	self.hist2:observe(1, {"label", nil})

	self:assertEqual(self.p.dict:get("metric1"), nil)
	self:assertEqual(self.p.dict:get("l1_count"), nil)
	self:assertEqual(self.p.dict:get("gauge1"), nil)
	self:assertEqual(self.p.dict:get("gauge2"), nil)
	self:assertEqual(self.p.dict:get("l1_count"), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 9)
	self:assertEqual(#Logger.logs, 9)
end
function TestPrometheus:testNumericLabelValues()
	self.counter2:inc(1, {0, 15.5})
	self.gauge2:set(1, {0, 15.5})
	self.hist2:observe(1, {-3, 90000})

	self:assertEqual(self.p.dict:get('metric2{f2="0",f1="15.5"}'), 1)
	self:assertEqual(self.p.dict:get('gauge2{f2="0",f1="15.5"}'), 1)
	self:assertEqual(self.p.dict:get('l2_sum{var="-3",site="90000"}'), 1)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testNonPrintableLabelValues()
	self.counter2:inc(1, {"foo", "baz\189\166qux"})
	self.gauge2:set(1, {"z\001", "\002"})
	self.hist2:observe(1, {"\166omg", "fooшbar"})

	self:assertEqual(self.p.dict:get('metric2{f2="foo",f1="bazqux"}'), 1)
	self:assertEqual(self.p.dict:get('gauge2{f2="z",f1=""}'), 1)
	self:assertEqual(self.p.dict:get('l2_sum{var="omg",site="foobar"}'), 1)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testNoValues()
	self.counter1:inc()  -- defaults to 1
	self.gauge1:set()  -- should produce an error
	self.hist1:observe()  -- should produce an error

	self:assertEqual(self.p.dict:get("metric1"), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 2)
	self:assertEqual(#Logger.logs, 2)
end
function TestPrometheus:testCounters()
	self.counter1:inc()
	self.counter1:inc(4)
	self.counter2:inc(1, {"v2", "v1"})
	self.counter2:inc(3, {"v2", "v1"})

	self:assertEqual(self.p.dict:get("metric1"), 5)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v1"}'), 4)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testGaugeIncDec()
	self.gauge1:inc(-1)
	self:assertEqual(self.p.dict:get("gauge1"), -1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:inc(3)
	self:assertEqual(self.p.dict:get("gauge1"), 2)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:inc()
	self:assertEqual(self.p.dict:get("gauge1"), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(1, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(5, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 6)
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="othervalue"}'), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(-2, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 4)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(-5, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), -1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:inc(1, {"should-be-no-labels"})
	self.gauge2:inc(1, {"too-few-labels"})
	self:assertEqual(self.p.dict:get("gauge1"), 3)
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), -1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 2)
end
function TestPrometheus:testGaugeDel()
	self.gauge1:inc(1)
	self:assertEqual(self.p.dict:get("gauge1"), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:del()
	self:assertEqual(self.p.dict:get("gauge1"), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(1, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:del({"f2value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 1)

	self.gauge2:del({"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 1)
end
function TestPrometheus:testCounterDel()
	self.counter1:inc(1)
	self:assertEqual(self.p.dict:get("metric1"), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter1:del()
	self:assertEqual(self.p.dict:get("metric1"), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter2:inc(1, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('metric2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter2:del()
	self:assertEqual(self.p.dict:get('metric2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 1)

	self.counter2:del({"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('metric2{f2="f2value",f1="f1value"}'), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 1)
end
function TestPrometheus:testReset()
	self.gauge1:inc(1)
	self:assertEqual(self.p.dict:get("gauge1"), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:reset()
	self:assertEqual(self.p.dict:get("gauge1"), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge1:inc(3)
	self:assertEqual(self.p.dict:get("gauge1"), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(1, {"f2value", "f1value"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), 1)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:inc(4, {"f2value", "f1value2"})
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value2"}'), 4)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.gauge2:reset()
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), nil)
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value2"}'), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)
	self:assertEqual(self.p.dict:get("gauge1"), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter1:inc()
	self.counter1:inc(4)
	self.counter2:inc(1, {"v2", "v1"})
	self.counter2:inc(3, {"v2", "v2"})

	self:assertEqual(self.p.dict:get("metric1"), 5)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v1"}'), 1)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v2"}'), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter1:reset()
	self:assertEqual(self.p.dict:get("metric1"), nil)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v1"}'), 1)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v2"}'), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)

	self.counter1:inc(4)
	self.counter2:reset()
	self:assertEqual(self.p.dict:get("metric1"), 4)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v1"}'), nil)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="v2"}'), nil)
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value"}'), nil)
	self:assertEqual(self.p.dict:get('gauge2{f2="f2value",f1="f1value2"}'), nil)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)
	self:assertEqual(self.p.dict:get("gauge1"), 3)
	self:assertEqual(self.p.dict:get("prometheus_metric_errors_total"), 0)
end
function TestPrometheus:testLatencyHistogram()
	self.hist1:observe(0.35)
	self.hist1:observe(0.4)
	self.hist2:observe(0.001, {"ok", "site1"})
	self.hist2:observe(0.15, {"ok", "site1"})

	self:assertEqual(self.p.dict:get('l1_bucket{le="00.300"}'), nil)
	self:assertEqual(self.p.dict:get('l1_bucket{le="00.400"}'), 2)
	self:assertEqual(self.p.dict:get('l1_bucket{le="00.500"}'), 2)
	self:assertEqual(self.p.dict:get('l1_bucket{le="Inf"}'), 2)
	self:assertEqual(self.p.dict:get('l1_count'), 2)
	self:assertEqual(self.p.dict:get('l1_sum'), 0.75)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site1",le="00.005"}'), 1)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site1",le="00.100"}'), 1)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site1",le="00.200"}'), 2)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site1",le="Inf"}'), 2)
	self:assertEqual(self.p.dict:get('l2_count{var="ok",site="site1"}'), 2)
	self:assertEqual(self.p.dict:get('l2_sum{var="ok",site="site1"}'), 0.151)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testLabelEscaping()
	self.counter2:inc(1, {"v2", "\""})
	self.counter2:inc(5, {"v2", "\\"})
	self.gauge2:set(1, {"v2", "\""})
	self.gauge2:set(5, {"v2", "\\"})
	self.hist2:observe(0.001, {"ok", "site\"1"})
	self.hist2:observe(0.15, {"ok", "site\"1"})

	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="\\""}'), 1)
	self:assertEqual(self.p.dict:get('metric2{f2="v2",f1="\\\\"}'), 5)
	self:assertEqual(self.p.dict:get('gauge2{f2="v2",f1="\\""}'), 1)
	self:assertEqual(self.p.dict:get('gauge2{f2="v2",f1="\\\\"}'), 5)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site\\"1",le="00.005"}'), 1)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site\\"1",le="00.100"}'), 1)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site\\"1",le="00.200"}'), 2)
	self:assertEqual(self.p.dict:get('l2_bucket{var="ok",site="site\\"1",le="Inf"}'), 2)
	self:assertEqual(self.p.dict:get('l2_count{var="ok",site="site\\"1"}'), 2)
	self:assertEqual(self.p.dict:get('l2_sum{var="ok",site="site\\"1"}'), 0.151)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testCustomBucketer1()
	local hist3 = self.p:histogram("l3", "Histogram 3", {"var"}, {1,2,3})
	self.hist1:observe(0.35)
	hist3:observe(2, {"ok"})
	hist3:observe(0.151, {"ok"})

	self:assertEqual(self.p.dict:get('l1_bucket{le="00.300"}'), nil)
	self:assertEqual(self.p.dict:get('l1_bucket{le="00.400"}'), 1)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="1.0"}'), 1)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="2.0"}'), 2)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="3.0"}'), 2)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="Inf"}'), 2)
	self:assertEqual(self.p.dict:get('l3_count{var="ok"}'), 2)
	self:assertEqual(self.p.dict:get('l3_sum{var="ok"}'), 2.151)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testCustomBucketer2()
	local hist3 = self.p:histogram("l3", "Histogram 3", {"var"},
	{0.000005,5,50000})
	hist3:observe(0.000001, {"ok"})
	hist3:observe(3, {"ok"})
	hist3:observe(7, {"ok"})
	hist3:observe(70000, {"ok"})

	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="00000.000005"}'), 1)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="00005.000000"}'), 2)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="50000.000000"}'), 3)
	self:assertEqual(self.p.dict:get('l3_bucket{var="ok",le="Inf"}'), 4)
	self:assertEqual(self.p.dict:get('l3_count{var="ok"}'), 4)
	self:assertEqual(self.p.dict:get('l3_sum{var="ok"}'), 70010.000001)
	self:assertEqual(Logger.logs, nil)
end
function TestPrometheus:testCollect()
	local hist3 = self.p:histogram("b1", "Bytes", {"var"}, {100, 2000})
	self.counter1:inc(5)
	self.counter2:inc(2, {"v2", "v1"})
	self.counter2:inc(2, {"v2", "v1"})
	self.gauge1:set(3)
	self.gauge2:set(2, {"v2", "v1"})
	self.gauge2:set(5, {"v2", "v1"})
	self.hist1:observe(0.000001)
	self.hist2:observe(0.000001, {"ok", "site2"})
	self.hist2:observe(3, {"ok", "site2"})
	self.hist2:observe(7, {"ok", "site2"})
	self.hist2:observe(70000, {"ok","site2"})
	hist3:observe(50, {"ok"})
	hist3:observe(50, {"ok"})
	hist3:observe(150, {"ok"})
	hist3:observe(5000, {"ok"})
	local data = self.p:metric_data()

	self:assertEqual(true, find_idx(data, "# HELP metric1 Metric 1") ~= nil)
	self:assertEqual(true, find_idx(data, "# TYPE metric1 counter") ~= nil)
	self:assertEqual(true, find_idx(data, "metric1 5") ~= nil)

	self:assertEqual(true, find_idx(data, "# TYPE metric2 counter") ~= nil)
	self:assertEqual(true, find_idx(data, 'metric2{f2="v2",f1="v1"} 4') ~= nil)

	self:assertEqual(true, find_idx(data, "# TYPE gauge1 gauge") ~= nil)
	self:assertEqual(true, find_idx(data, 'gauge1 3') ~= nil)

	self:assertEqual(true, find_idx(data, "# TYPE gauge2 gauge") ~= nil)
	self:assertEqual(true, find_idx(data, 'gauge2{f2="v2",f1="v1"} 5') ~= nil)

	self:assertEqual(true, find_idx(data, "# TYPE b1 histogram") ~= nil)
	self:assertEqual(true, find_idx(data, "# HELP b1 Bytes") ~= nil)
	self:assertEqual(true, find_idx(data, 'b1_bucket{var="ok",le="0100.0"} 2') ~= nil)
	self:assertEqual(true, find_idx(data, 'b1_sum{var="ok"} 5250') ~= nil)

	self:assertEqual(true, find_idx(data, 'l2_bucket{var="ok",site="site2",le="04.000"} 2') ~= nil)
	self:assertEqual(true, find_idx(data, 'l2_bucket{var="ok",site="site2",le="+Inf"} 4') ~= nil)

	-- check that type comment exists and is before any samples for the metric.
	local type_idx = find_idx(data, '# TYPE l1 histogram')
	if self:assertEqual(true, type_idx ~= nil) then
		self:assertEqual(true, data[type_idx-1]:find("^l1") == nil)
		self:assertEqual(true, data[type_idx+1]:find("^l1") ~= nil)
	end
	self:assertEqual(Logger.logs, nil)
end

function TestPrometheus:testCollectWithPrefix()
	local p = prometheus.init("test_pref_", Logger)
	local counter1 = p:counter("metric1", "Metric 1")
	local gauge1 = p:gauge("gauge1", "Gauge 1")
	local hist1 = p:histogram("b1", "Bytes", {"var"}, {100, 2000})
	counter1:inc(5)
	gauge1:set(3)
	hist1:observe(50, {"ok"})
	hist1:observe(50, {"ok"})
	hist1:observe(150, {"ok"})
	hist1:observe(5000, {"ok"})
	local data = p:metric_data()

	self:assertEqual(true, find_idx(data, "# HELP test_pref_metric1 Metric 1") ~= nil)
	self:assertEqual(true, find_idx(data, "# TYPE test_pref_metric1 counter") ~= nil)
	self:assertEqual(true, find_idx(data, "test_pref_metric1 5") ~= nil)

	self:assertEqual(true, find_idx(data, "# HELP test_pref_gauge1 Gauge 1") ~= nil)
	self:assertEqual(true, find_idx(data, "# TYPE test_pref_gauge1 gauge") ~= nil)
	self:assertEqual(true, find_idx(data, "test_pref_gauge1 3") ~= nil)

	self:assertEqual(true, find_idx(data, "# TYPE test_pref_b1 histogram") ~= nil)
	self:assertEqual(true, find_idx(data, "# HELP test_pref_b1 Bytes") ~= nil)
	self:assertEqual(true, find_idx(data, 'test_pref_b1_bucket{var="ok",le="0100.0"} 2') ~= nil)
	self:assertEqual(true, find_idx(data, 'test_pref_b1_sum{var="ok"} 5250') ~= nil)
end

function TestPrometheus:testDuplicateMetricLogs()
	self.p:gauge("gauge", "MyGauge")
	local gauge1 = self.p:gauge("gauge", "MyGauge")
	self:assertEqual(nil, gauge1)
	if self:assertEqual(1, #Logger.logs) then
		self:assertEqual("Duplicate metric gauge", Logger.logs[1])
	end
end

local suite = TestPrometheus.new()
for key,value in pairs(getmetatable(suite)) do
	suite:reset()
	if key:sub(1, 4) == "test" then
		suite[key](suite)
		if #suite.errors ~= 0 then
			print(string.format("ERROR %s", key))
			for _, v in pairs(suite.errors) do
				print(v)
			end
		else
			print(string.format("OK %s", key))
		end
	end
end
