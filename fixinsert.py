#!/usr/bin/env python
# encoding: utf-8
r"""

Parse a text file that contains insert into statements
and generate a list of the maximum observed field lengths.

# Overview

This script takes a text file that contains insert into statements
and generates a list of the maximum observed field lengths.
This is useful when you want to paste values into a database
but get Data too long for column errors.

# Usage

Call the script with the -h as argument to get the help function:

$ fixinsert.py --help

# Example

If you want to just have the length of one column, you can call it like this:

$ fixinsert.py parse -f my_column my_file.txt

To generate a whole table, you can do it like this:

$ fixinsert.py parse my_file.txt


"""

import warnings
import re
import sys


#
# More Beautiful Tracebacks and Pretty Printing
#
from rich import print;
from rich import traceback;
from rich import pretty;
pretty.install()
traceback.install()

#
# Command Line Interface
#
from typing import List, Optional
import typer

app = typer.Typer(
    add_completion = False,
    rich_markup_mode = "rich",
    no_args_is_help=True,
    help="Parse a text file of insert into statements to get the max field lenghts",
    epilog="""
    To get help about the parser, call it with the --help option:
./fixinsert.py parse --help
    """
)

@app.command(
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True}
)

#
# Main
#
#@app.callback(invoke_without_command=True)
@app.command()
def parse (
    ctx:        typer.Context,
    field:      str  = typer.Option(None, "--field", "-f", help="The field to get the max length for"),
    files:      Optional[List[str]] = typer.Argument(None, help="The files to process"),
) -> None:
    """
    Parse CSV files to generate MySQL tables
    """
    if len(files) == 0: # len(ctx.args) == 0:
        print("Please specify a file name.")
        sys.exit(1)
    else:
        for file in files: #ctx.args:
            run(file, field)
    


def run(filename, field):
    """
    A function that takes a filename and a column name as input and outputs the maximum length of the values in the column.

    Parameters:
    filename (str): The name of the file to be read.
    pcol (str): The name of the column whose maximum length of values is to be calculated.

    Returns: None
    """    
    lengths = {} # Dictionary to store column names as keys and their maximum value length as values.
    with open(filename, 'r', encoding='utf-8') as file:
        for line in file:
            process_line(line, lengths)

    #
    # Finding the maximum length of the column names
    #
    max_column_length = max(len(col) for col in lengths.keys())

    #
    # Printing the column name and its maximum value length
    #
    for col in sorted(lengths.keys()):
        if field is not None and field != col:
            continue
        print(f"{col:<{max_column_length}} : {lengths[col]:>5}")


def process_line(line, lengths):
    match = re.search(r"^insert into (.*?) \((.*?)\) values \((.*?)\);$", line)
    if match:
        table, fields, values = match.groups()
        #
        # Replacing special characters with a delimiter to separate values
        #
        values = values.replace("','", '@a@')
        values = values.replace(",'", '@a@')
        values = values.replace("\@a\@'", '@a@')
        values = values.replace("^\'", '')
        values = values.replace("\'$", '')
        values = values.replace("\@a\@", "','")
        fields = fields.split(',')
        values = values.split('@a@')

        #
        # Iterating over the fields and values and updating the 'lengths' dictionary
        #
        for i, value in enumerate(values):
            if fields[i] in lengths:
                lengths[fields[i]] = max(lengths[fields[i]], len(value))
            else:
                lengths[fields[i]] = len(value)


#
# Command: Doc
#
@app.command()
def doc (
    ctx:        typer.Context,
    title:      str  = typer.Option(None,   help="The title of the document"),
    toc:        bool = typer.Option(False,  help="Whether to create a table of contents"),
) -> None:
    """
    Re-create the documentation and write it to the output file.
    """
    import importlib
    import importlib.util
    import sys
    import doc2md
    import os

    def import_path(path):
        module_name = os.path.basename(path).replace("-", "_")
        spec = importlib.util.spec_from_loader(
            module_name,
            importlib.machinery.SourceFileLoader(module_name, path),
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        sys.modules[module_name] = module
        return module

    mod_name = os.path.basename(__file__)
    if mod_name.endswith(".py"):
        mod_name = mod_name.rsplit(".py", 1)[0]
    atitle = title or mod_name.replace("_", "-")
    module = import_path(__file__)
    docstr = module.__doc__
    result = doc2md.doc2md(docstr, atitle, toc=toc, min_level=0)
    print(result)


#
# Entry Point
#
if __name__ == '__main__':
    try:
        app()
    except SystemExit as e:
        if e.code != 0:
            raise


