r"""
Definition of a NeuronNode, NeuronTree and SWCForest class for representing the internal contents \
of an \*.swc file. Basic functions for manipulating, examining, validating and \
filtering \*.swc files. A function for reading \*.swc files from memory.
"""
from __future__ import annotations

import argparse
import timeit
import os
import sys
from dataclasses import dataclass
from typing import Callable, Iterator, Literal, Container, Optional

@dataclass
class NeuronNode:
    r"""
    A NeuronNode represents the contents of a single line in an \*.swc file.
    """
    sample_number: int
    structure_id: int
    coord_triple: tuple[float, float, float]
    radius: float
    parent_sample_number: int

    def is_soma_node(self) -> bool:
        return self.structure_id == 1

def read1(line: str, file_path: str, linenum: int) -> NeuronNode:
    row = line.strip().split()[0:7]
    if len(row) < 7:
        raise TypeError(
            "Row "
            + str(linenum)
            + " in file "
            + file_path
            + " has fewer than seven whitespace-separated strings."
        )
    nn = NeuronNode(
        sample_number=int(row[0]),
        structure_id=int(row[1]),
        coord_triple=(float(row[2]), float(row[3]), float(row[4])),
        radius=float(row[5]),
        parent_sample_number=int(row[6]),
    )
    return nn

def main():
    parser = argparse.ArgumentParser(
        prog='Py2',
        description='What the program does',
        epilog='Text at the bottom of help')

    parser.add_argument('-w', '--warmup', default=0)
    parser.add_argument('-c', '--count', default=1)
    parser.add_argument('-d', '--dump',
                        action='store_true')  # on/off flag
    parser.add_argument('-v', '--verbose',
                        action='store_true')  # on/off flag

    args = parser.parse_args()
    verbose = args.verbose
    warmup = int(args.warmup)
    count = int(args.count)
    print("verbose=%s, warmup=%s,  count=%s\n" % (verbose, count, warmup))

    line = "201 3 594.5597 444.0379 80.8959 0.1373 200"
    for i in range(warmup):
        nn = read1(line, "<string>", 1)

    nn = read1(line, "<string>", 1)
    dump = args.dump
    if dump:
        print("Dump: %s" % (nn,))
    elapsed = timeit.timeit(lambda: read1(line, "<string>", 1), number=count)
    print("elapsed: %s"% (elapsed,))

if __name__ == '__main__':
    main()
