doc
# fixinsert

Parse a text file that contains insert into statements

and generate a list of the maximum observed field lengths.

# Overview

This script takes a text file that contains insert into statements
and generates a list of the maximum observed field lengths.
This is useful when you want to paste values into a database
but get Data too long for column errors.

# Usage

Call the script with the -h as argument to get the help function:

```bash
$ fixinsert.py --help
```

# Example

If you want to just have the length of one column, you can call it like this:

```bash
$ fixinsert.py parse -f my_column my_file.txt
```

To generate a whole table, you can do it like this:

```bash
$ fixinsert.py parse my_file.txt
```
