#!/usr/bin/python3

import sys
import os
import argparse
from math import floor


def main():

    parser = argparse.ArgumentParser(
        description="Exports .fnt or .udg data to Z80 assembler.")

    parser.add_argument("infile", type=argparse.FileType('rb'),
                        default=sys.stdin)
    parser.add_argument("-o", "--outfile", type=argparse.FileType('w'),
                        default=sys.stdout, dest='out')
    parser.add_argument("-a", "--append-file", type=argparse.FileType('a'),
                        default=sys.stdout, dest='out')
    parser.add_argument(
        "-W", "--width", help="Width in bytes of all sprites.", type=int, default=2)
    parser.add_argument(
        "-H", "--height", help="Height in octets of all sprites.", type=int,   default=2)
    parser.add_argument(
        "-i", "--indent", help="Number of spaces to indent.", type=int, default=2)
    parser.add_argument(
        "-f", "--frames",
        help="Number of frames in the sprite, or characters in a font.",
        type=int, default=None
    )
    parser.add_argument(
        "-s", "--start-frame",
        help="Number of the first frame.",
        type=int, default=1
    )
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-l', '--label', type=ascii)

    args = parser.parse_args()

    # Argparse curiously - and undocumentedly - adds singe quotes *inside* the string.
    label = args.label.replace("'", "") if args.label else os.path.splitext(
        os.path.basename(args.infile.name))[0].capitalize()

    n_frames = args.frames if args.frames else floor(os.path.getsize(args.infile.name) /
                                                     (args.width * 8 * args.height))

    if args.verbose:
        print("label s " + label + ".")
        print("Making " + str(n_frames) + " frame(s).")

    for frameno in range(args.start_frame, args.start_frame + n_frames):
        print(label + "_" + str(frameno) + ":", file=args.out)
        for chunkno in range(args.height):
            chunk = args.infile.read(8 * args.width)
            if len(chunk) < 8 * args.width:
                print("Warning: file ends in the middle of a sprite",
                      file=sys.stderr)
                exit(0)
            for i in range(0, 8):
                print(" " * args.indent + "DB " +
                      " ", file=args.out, end='')
                print(", ".join(["%" + bin(chunk[byte * 8 + i])[2:].rjust(8,
                      '0') for byte in range(args.width)]), file=args.out)
        print(file=args.out)
        frameno += 1


if __name__ == "__main__":
    main()
