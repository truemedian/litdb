---@class sqlite3
local sqlite3 = {}

--- Opens a connection to the database specified by filename and returns a `conn` representing a connection to it.
--- If filename is "" then a temporary database is created in memory which is destroyed once conn is closed (or collected).
--- The optional argument mode can be one the following:
--- * "ro": read only mode;
--- * "rw": read and write mode;
--- * "rwc": (default) read and write mode, creates the database if it does not exist.
---@overload fun(filename: string):Connection
---@param filename string
---@param mode string | "'ro'" | "'rw'" | "'rwc'"
---@return Connection
function sqlite3.open(filename, mode) end

--- Creates a luablob from its argument which must be of string type.
--- It's only used in binding methods to distinguish between a string which represents text and one which represents binary data.
--- The luablob wrapper makes sure that `str` is classified as an SQLite BLOB when passed to binding methods.
--- A luablob object does not have any method associated with it and any operation on it (indexing, ...) is undefined. Example:
---
--- ```lua
--- local conn = sql.open("")
--- conn:exec("CREATE TABLE t(x)")
--- local stmt = conn:prepare("INSERT INTO t VALUES(?)")
--- stmt:reset():bind("atext"):step()
--- stmt:reset():bind(sql.blob("ablob")):step()
--- conn "SELECT x, typeof(x) FROM t"
--- --> x       typeof(x)
--- --> atext   text
--- --> ablob   blob
--- ```
---@param str string
---@return string
function sqlite3.blob(str) end

--- Represents a connection to an sqlite database
---@class Connection
local Connection = {}

--- Closes all the database connections associated with `conn`, closes all the `stmt`s associated with `conn` and un-registers all the scalar and aggregate custom functions associated with `conn`.
--- It is an error to close `conn` more than once or to attempt any operation on a closed `conn` (the same holds for stmts).
--- Any `conn` is automatically closed if necessary when garbage collected.
function Connection:close() end

--- Executes SQLite commands separated by the ';' character (a trailing ';' is fine and is ignored).
--- For all the commands except the last one the method ignore any resulting record.
--- If the last command results in an empty result set, i.e. it is not a SELECT query or it is a SELECT query which produces 0 records, then `nil`, `0` is returned.
--- Otherwise `nrow` is the number of records and `resultset` is a table whose structure depends on the value of the parameter `get`:
---
--- ```lua
--- --[[
--- Suppose that the query returns data with the following layout:
--- |    colname[   1]   |   ...  |   colname[ncol]
--- ------------------------------------------------------
---      1 | record[   1][   1] |   ...  | record[   1][ncol]
---      2 | record[   2][   1] |   ...  | record[   2][ncol]
---    ... |        ...         |   ...  |        ...
---   nrow | record[nrow][   1] |   ...  | record[nrow][ncol]
--- ]]
--- --> Then if get contains the character "h":
--- resultset[   0] = { colname[   1], ..., colname[ncol] }
--- --> If get contains the character "i":
--- resultset[   1] = { record[   1][   1], ..., record[ncol][   1] }
--- ...
--- resultset[nrow] = { record[   1][nrow], ..., record[ncol][nrow] }
--- --> If get contains the character "k":
--- resultset[colname[   1]] = resultset[   1]
--- ...
--- resultset[colname[ncol]] = resultset[ncol]
--- ```
---
--- That is, the records are returned **by column** and are indexable using both the column numerical index and the column name.
--- The method returns `nrow` as well because in case of NULL elements (which correspond to Lua nils) it would not be possible to determine the number of records resulting from the query.
--- Examples of use:
---
--- ```lua
--- local conn = sql.open("")
--- --> Returns nil:
--- conn:exec[[
--- CREATE TABLE t(id TEXT, num REAL);
--- INSERT INTO t VALUES('myid1', 200);
--- ]]
--- --> Returns the resultset:
--- local t = conn:exec("SELECT * FROM t")
--- print(unpack(t[0]))      --> id    num
--- print(t.id[1], t.num[1]) --> myid1 200
--- print(t[1][1], t[2][1])  --> myid1 200
--- --> Probably a user mistake, returns nil:
--- local t = conn:exec[[
--- SELECT * FROM t;
--- INSERT INTO t VALUES('myid2', 400);
--- ]]
--- assert(t == nil)
--- ```
---@overload fun(commands: string): table<any, any> | nil, number
---@param commands string
---@param get string | "'hik'"
---@return table<any, any> | nil, number
function Connection:exec(commands, get) end

--- Executes a single command which must return at most one record.
--- If the query results in no records `nil` is returned.
--- Otherwise ncol values are returned which corresponds to the columns of the single record. Example:
---
--- ```lua
--- local conn = sql.open("")
--- conn:exec[[
--- CREATE TABLE t(id TEXT, num REAL);
--- INSERT INTO t VALUES('myid1', 200);
--- ]]
--- local id, num = conn:rowexec("SELECT * FROM t WHERE id=='myid1'")
--- print(id, num) --> myid1 200
--- ```
---@param command string
---@return ...
function Connection:rowexec(command) end

--- Executes SQLite commands separated by the ';' character (a trailing ';' is fine and is ignored) and passes all the records returned by all the commands preceded by the corresponding column names as strings to `out` (thus multiple parameters are passed to `out()` for each call).
--- As `out` defaults to `print` this method mimics the Command Line Shell by default. Example:
---
--- ```lua
--- local conn = sql.open("")
--- conn [[
--- CREATE TABLE t(id TEXT, num REAL);
--- INSERT INTO t VALUES('myid1', 200);
--- INSERT INTO t VALUES('myid2', 400);
--- SELECT * FROM t WHERE id=='myid1';
--- SELECT * FROM t WHERE id=='myid2';
--- ]]
--- --> id    num
--- --> myid1 200
--- --> id    num
--- --> myid2 400
--- ```
---@param commands string
---@param out function
function Connection:__call(commands, out) end

--- These methods register scalar and aggregate functions to a specific connection only with the specified name.
--- It is **not** an error to register both a scalar and an aggregate with the same name.
--- The argument name should be a string and the remaining arguments callable entities (functions or tables/cdatas with the `__call()` metamethod defined) with the following signatures:
---
--- ```lua
--- --> Called for each record where ... = record column elements:
--- scalar    = function(...)        --> return mapping-allowed result
--- --> Called to initialise the aggregate computation:
--- initstate = function()           --> return state
--- --> Called for each record where ... = record column elements;
--- --> state is the persistent state of the computation:
--- step      = function(state, ...) --> return nothing
--- --> Called after all records has been passed to step;
--- --> sate is the persistent state of the computation:
--- final     = function(state)      --> return mapping-allowed result
--- ```
---
--- By mapping-allowed we mean that the return type must be one of the Lua types listed in the input column of table Lua types > SQLite types.
--- For the aggregate case the state can be any Lua object, it's created by calling `initstate()` and is passed back for each record as first argument to `step()` and after that as the unique argument to `final()` which returns the result of the computation.
--- There is no state for scalar functions as it is not needed. To clear a registered function (and free the callback resource) simply call the methods `conn:setscalar()` and `conn:setaggregate()` passing name as the only argument.
--- Example:
---
--- ```lua
--- local conn = sql.open("")
--- conn:exec "CREATE TABLE t(num REAL);"
--- local stmt = conn:prepare("INSERT INTO t VALUES(?)")
--- for i=1,4 do stmt:reset():bind(i):step() end
--- conn:setscalar("MYSQRT", math.sqrt)
--- conn "SELECT MYSQRT(num) FROM t"
--- --> MYSQRT(num)
--- --> 1
--- --> 1.4142135623731
--- --> 1.7320508075689
--- --> 2
--- conn:setscalar("MYSQRT") -- Free callback.
--- conn:setaggregate("MYSUM",
---   function() return { sum = 0 } end,
---   function(self, x) self.sum = self.sum + x end,
---   function(self) return self.sum end
--- )
--- conn "SELECT MYSUM(num) FROM t"
--- --> MYSUM(num)
--- --> 10
--- conn:setaggregate("MYSUM") -- Free callback.
--- ```
---@param name string
---@param scalar function
function Connection:setscalar(name, scalar) end

---@see Connection:setscalar
---@param name string
---@param initstate function
---@param step function
---@param final function
function Connection:setaggregate(name, initstate, step, final) end

--- Creates a `stmt` associated to `conn` from a single SQLite command.
---@param command string
---@return Stmt
function Connection:prepare(command) end

--- Represents a stmt associated to a connection
---@class Stmt
local Stmt = {}

--- Closes (finalizes) a `stmt`. It is an error to close a `stmt` more than once or to attempt any operation on a closed `stmt`.
--- Any `stmt` is closed automatically if necessary when garbage collected.
function Stmt:close() end

--- Resets a `stmt` to its initial state (i.e. just after `conn:prepare()`) so that it's ready to be used again.
--- Resetting a `stmt` that is already in its initial state is allowed and has no effect.
--- Returns the `stmt` itself allowing chaining, see example in next definition below.
---@return Stmt
function Stmt:reset() end

--- If `stmt` is in its initial state (i.e. just returned from `conn:prepare()` or `stmt:reset()` has just been called) the command from which `stmt` has been prepared gets executed.
--- The argument `row` defaults to an empty table.
--- If no record results from the executed command nil is returned.
--- Otherwise `row` is used to store the record elements indexed by their numeric index and returned as first return value.
--- Moreover if `colnames` is not nil then `colnames` is used to store the column names indexed by their numeric index and it is returned as second return value (otherwise only one value is returned).
--- Further calls to `step` will return all the records in the order they are returned by the SQLite command according to the rules defined in the previous paragraph.
--- When there are no records left step will return `nil` and so will do further calls to step:
---
--- ```lua
--- local conn = sql.open("")
--- conn:exec[[
--- CREATE TABLE t(id TEXT, num REAL);
--- INSERT INTO t VALUES('myid1', 200);
--- INSERT INTO t VALUES('myid2', 400);
--- ]]
--- local stmt = conn:prepare("SELECT * FROM t")
--- local row, names = stmt:step({}, {})
--- print(unpack(names))
--- print(unpack(row))
--- while stmt:step(row) do
---     print(unpack(row))
--- end
--- --> id    num
--- --> myid1 200
--- --> myid2 400
--- ```
---@overload fun(): table<number, any>, table<number, string>
---@param row table<number, any> | "{}"
---@param colnames table<number, any>  | "nil"
---@return table<number, any>, table<number, string>
function Stmt:step(row, colnames) end

--- This method behaves like `conn:exec()`:
--- it returns the remaining records resulting from the command from which `stmt` has been prepared according to the same rules of `conn:exec()` up to a maximum of `maxrecords` if `maxrecords` is not nil (otherwise all the remaining records are returned).
--- Remark: for both `stmt:step()` and `stmt:resultset()` methods it may be useful to think of `stmt` as a file descriptor:
--- we traverse the records (lines) from the first to the last:
---
--- ```lua
--- local stmt = conn:prepare("SELECT * FROM some_table")
--- while true do
---     --> Retrieve the records in chunks of maximum 1000 records.
---     local partial, nr = stmt:resultset(1000)
---     --> Do something with them ...
---     if not partial then break end -- Stop when no records left.
--- end
--- ```
---@param get string | "'hik'"
---@param maxrecords number | "nil"
---@return table<any, any> | nil, number
function Stmt:resultset(get, maxrecords) end

--- This method has to be used with statements which have been prepared for later binding according to SQLite parameters syntax.
--- Please notice that **only** parameters indexed by a numerical value are supported. `stmt:bind1()` binds a single mapping-allowed Lua value (i.e. in the input column of table Lua types > SQLite types) to the i-th parameter of the query.
--- It is an error for `i` to be out of the allowed bounds.
--- Any parameter which has not been binded is set to NULL.
--- Binded parameters persist among multiple calls to `stmt:reset()` and `stmt:step()`: `stmt:clearbind()` must be used to set all the parameters back to NULL).
--- Example:
---
--- ```lua
--- local conn = sql.open("")
--- conn:exec "CREATE TABLE t(r REAL, i INTEGER, s TEXT, b BLOB);"
--- local stmt = conn:prepare "INSERT INTO t VALUES(?, ?, ?, ?)"
--- stmt:reset():bind(1, 1, "astr", "astr"):step()
--- stmt:reset():bind(2, 2, "bstr", sql.blob("bblob")):step()
--- stmt:reset():step()
--- stmt:reset():bind1(2, 4LL):step()
--- stmt:reset():clearbind():bind1(2, 5LL):step()
--- conn "SELECT * FROM t"
--- --> r       i       s       b
--- --> 1       1LL     astr    astr
--- --> 2       2LL     bstr    bblob
--- --> 2       2LL     bstr    bblob
--- --> 2       4LL     bstr    bblob
--- -->         5LL
--- ```
---@param i number
---@param value any
---@return Stmt
function Stmt:bind1(i, value) end

--- This method is equivalent to calling `stmt:bind1(i, v)` once for every passed argument where `i` is the position of the argument and `v` the argument itself.
--- See example in `stmt:bind1()`.
---@vararg any
---@return Stmt
function Stmt:bind(...) end

--- Sets back all the parameters to NULL. See example in `stmt:bind1()`.
---@return Stmt
function Stmt:clearbind() end