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

def read_swc_node_dict(file_path: str) -> dict[int, NeuronNode]:
    r"""
    Read the swc file at `file_path` and return a dictionary mapping sample numbers \
    to their associated nodes.

    :param file_path: A full path to an \*.swc file. \
    The only validation performed on the file's contents is to ensure that each line has \
    at least seven whitespace-separated strings.

    :return: A dictionary whose keys are sample numbers taken from \
    the first column of an SWC file and whose values are NeuronNodes.
    """
    nodes: dict[int, NeuronNode] = {}
    with open(file_path, "r") as file:
        for n, line in enumerate(file):
            if line[0] == "#" or len(line.strip()) < 2:
                continue
            row = line.strip().split()[0:7]
            if len(row) < 7:
                raise TypeError(
                    "Row "
                    + str(n)
                    + " in file "
                    + file_path
                    + " has fewer than seven whitespace-separated strings."
                )
            nodes[int(row[0])] = NeuronNode(
                sample_number=int(row[0]),
                structure_id=int(row[1]),
                coord_triple=(float(row[2]), float(row[3]), float(row[4])),
                radius=float(row[5]),
                parent_sample_number=int(row[6]),
            )
    return nodes

def main():
    parser = argparse.ArgumentParser(
        prog='Py1',
        description='What the program does',
        epilog='Text at the bottom of help')

    parser.add_argument('filename')           # positional argument
    parser.add_argument('-w', '--warmup', default=0)
    parser.add_argument('-c', '--count', default=1)
    parser.add_argument('-d', '--dump')
    parser.add_argument('-v', '--verbose',
                        action='store_true')  # on/off flag

    args = parser.parse_args()
    filename = args.filename
    verbose = args.verbose
    warmup = int(args.warmup)
    count = int(args.count)
    print("filename=%s, verbose=%s, warmup=%s,  count=%s\n" % (filename, verbose, count, warmup))

    for i in range(warmup):
        d = read_swc_node_dict(args.filename)

    d = read_swc_node_dict(args.filename)
    print("# entries: ", len(d))
    dump = args.dump
    if dump is not None:
        print("Dump: %s" % (d[int(dump)]))
    elapsed = timeit.timeit(lambda: read_swc_node_dict(args.filename), number=count)
    print("elapsed: %s"% (elapsed,))

if __name__ == '__main__':
    main()
