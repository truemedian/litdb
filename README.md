
# fswatch

A wrapper around luv's fs_event bindings that make it much easier to deal with.
fswatch's only function's documentation is provided below. Issues and PRs are
welcome, if you see something that could be done better, help fix it!

# Functions

## watch(filepath[, recursive], callback)

| Parameter | Type     | Optional |
| --------- | -------- |:--------:|
| filepath  | string   |          |
| recursive | boolean  |     ✔    |
| callback  | function |          |

Attaches a watcher to either a file or directory to watch for changes. If
`recursive` is true, changes in directories will be reported (note that
`directory_changed` events will still be emitted for directories in the watched 
directory regardless of this value). The callback's parameters and a 
description of all events are included below.

### callback(err, event, filepath, stat)

| Parameter | Type        |
| --------- | ----------- |
| err       | nil, string |
| event     | string, nil |
| filepath  | string, nil |
| stat      | table, nil  |

In case of an error thrown by the event watcher or fs_stat, `err` will be set 
to the respective error string and all other arguments will be nil. If `err` 
is `nil` the event is processable. `filepath` will be a path the the relevant 
file or directory **relative to the watcher's directory**. `stat` will be the 
output of calling `fs_stat` on the file or directory, this may be nil or stale. 
The event string may be any of the events listed below:

#### created

A file was created

#### removed

A file was removed.  
note: `stat` will be stale or nil

#### file_changed

The content of the file changed, multiple of these events may be emitted for 
one edit if the file is cleared first.

#### directory_changed

Any attribute of the directory changed, or a file in the directory was changed 
or renamed.  
This is useful for monitoring when any file in a subdirectory has changed.