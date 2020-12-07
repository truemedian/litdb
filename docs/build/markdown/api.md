# API Reference

The API documentation is where you find how to do basically anything.

# Typed

A module to aid in allowing for typed code

Typed gives clean errors that look like errors from misused standard functions

`\`
bad argument #1 to 'tostring' (string | function expected, got nil)
\``

## Quick example



```
``
```



```
`
```

lua
local typed = require ‘typed’

local function hi(msg)
typed.func(_, ‘string’)(msg)

print(msg)
end

hi(‘hello’) – No errors
hi(1) – bad argument #1 to ‘hi’ (string expected, got number)


```
``
```



```
`
```


Typed can automatically figure out the name of the function, however,
if you want to replace it, you pass the first argument.

## Tables and arrays

Typed also supports arrays and tables in its definitions.

An array is type followed by [] while a table is table<keyType, valueType>.

By default, an empty table {} would be unknown[]. This is as it can’t be inferred what it is.

## Logical statements

Currently typed only supports the or logical operator.



```
``
```



```
`
```

lua
local typed = require ‘typed’

local function hi(msg)
typed.func(_, ‘string | number’)(msg)

print(msg)
end

hi(‘hello’) – No errors
hi(1) – No errors


```
``
```



```
`
```


Here is the first example using the or operator represented with |.

It does exactly what you would think it does, it will accept strings **or** numbers.


###  typed.isArray(tbl)
Is this an array?


* **Parameters**

    **tbl** (*dict[any, any]*) – 



* **Return type**

    boolean



###  typed.whatIs(this)
What is this specific item?

Note: This can be overridden with __name field.

Arrays are represented with type[] and tables with table<keyType, valueType>.


* **Parameters**

    **this** (*any*) – 



* **Return type**

    str



###  typed.resolve(validator, pos, name)
Create a new function to validate types

This is commonly piped into assert and should be used in environments without debug.


* **Parameters**

    
    * **validator** (*str*) – The validation string like string | number


    * **pos** (*number or nil*) – The position of where this is argument is (defaults to 1)


    * **name** (*str or nil*) – The name of the function (defaults to ?)



* **Return type**

    fun(any):boolean or nil or str



###  typed.func(name, ...)
Create a new typed function.

**This function uses the debug library**

You can override the inferred name by passing a first argument.

The rest of the arguments are validation strings.

This returns a function which would take those arguments defined in the validation string.


* **Parameters**

    
    * **name** (*str*) – 


    * **vararg** (*str*) – 



* **Returns**

    (…):void



* **Return type**

    function



### class typed.mt()

####  \__newindex(k, v)

* **Parameters**

    
    * **k** (*any*) – 


    * **v** (*any*) – 



### class typed.Array()

####  initialize(starting)

* **Parameters**

    **starting** (*any*) – 



####  \__pairs()
Loop over the array

> Warning: This requires lua5.2 compat, use :forEach or :pairs instead if you don’t have 5.2 compat


####  len()
Get the length of the array without metamethods


* **Return type**

    number



####  pairs()
Loop over the array without metamethods


####  get(k)
Get an item at a specific index


* **Parameters**

    **k** (*number*) – The key to get the value of



* **Return type**

    any



####  set(k, v)
Set an item at a specific index


* **Parameters**

    
    * **k** (*number*) – 


    * **v** (*any*) – 



####  iter()
Iterate over an array


####  unpack()
Unpack the array


####  push(item)
Add an item to the end of an array


* **Parameters**

    **item** (*any*) – The item to add



####  concat(sep)
Concat an array


* **Parameters**

    **sep** (*str*) – 



####  pop(pos)
Pop the item from the end of the array and return it


* **Parameters**

    **pos** (*number*) – The position to pop



####  forEach(fn)
Loop over the array and call the function each time


* **Parameters**

    **fn** (*fun(any, number):void*) – 



####  filter(fn)
Loop through each item and each item that satisfies the function gets added to an array and gets returned


* **Parameters**

    **fn** (*fun(any):void*) – 



* **Return type**

    Array



####  find(fn)
Return the first value which satisfies the function


* **Parameters**

    **fn** (*fun(any):boolean*) – 



* **Return type**

    any or number or nil



####  search(fn)
Similar to array:find except returns what the function returns as long as its truthy


* **Parameters**

    **fn** (*fun(any):any*) – 



* **Return type**

    any or number or nil



####  map(fn)
Create a new array based on the results of the passed function


* **Parameters**

    **fn** (*fun(any):any*) – 



* **Return type**

    Array



####  slice(start, stop, step)
Slice an array using start, stop, and step


* **Parameters**

    
    * **start** (*number*) – The point to start the slice


    * **stop** (*number*) – The point to stop the slice


    * **step** (*number*) – The amount to step by



* **Return type**

    Array



####  copy()
Copy an array into a new array


* **Return type**

    Array



####  reverse()
Reverse an array, does not affect original array


* **Return type**

    Array



### class typed.TypedArray(: Array)

####  initialize(arrType, starting)

* **Parameters**

    
    * **arrType** (*any*) – 


    * **starting** (*any*) – 



####  push(item)
A typed version of the push method


* **Parameters**

    **item** (*any*) – The type of the item should be the specified type



### class typed.Schema()

####  initialize(name)
Create a new schema


* **Parameters**

    **name** (*str*) – 



####  field(name, value, default)
Create a new field within the schema


* **Parameters**

    
    * **name** (*str*) – 


    * **value** (*str or Schema*) – 


    * **default** (*any*) – 



* **Return type**

    Schema



####  validate(tbl)
Validate a table to see if it matches the schema


* **Parameters**

    **tbl** (*dict[any, any]*) – 



* **Return type**

    boolean or str or nil
