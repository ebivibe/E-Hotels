import os, sys
import argparse



def find_all_files(file_queue, subdir, exclude):
    directories = []
    for item in os.scandir(subdir):
        if item.name in exclude:
            continue
        if item.is_dir():
            directories.append(item.path)
        else:
            file_queue.append(item.path)
    
    for directory in directories:
        find_all_files(file_queue, directory, exclude)

def find_dir_files(file_queue, exclude):
    for item in os.scandir():
        if item.name in exclude:
            continue
        if item.is_file():
            file_queue.append(item.path)

def apply_replace(path, old, new):
    data = ""
    with open(path, "r") as f:
        data = f.read()

    data.replace(old, new)

    with open(path, "w") as file:
        file.write(data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Runs operations on all files of a directory. Lists all file paths in directory if no flags given")
    parser.add_argument('-r', '--recursive', help='Runs operation on all files of all subdirectories', action="store_true")
    parser.add_argument('-c', '--change', help="Replace first argument with second argument", nargs=2, action="store")
    parser.add_argument('-e', '--exclude', help="Files and directories to exclude from the search", nargs=argparse.REMAINDER)
    parser.add_argument('-ef', '--exclude-file', help="Accesses a file for all excluded items", nargs=1, action="store")

    ## Always exclude this file from any operations
    exclude = set()
    exclude.add(sys.argv[0])

    args = parser.parse_args()

    items = []
    if args.exclude != None:
        for ex in args.exclude:
            exclude.add(ex)
    
    if args.exclude_file != None:
        with open(args.exclude_file, "r") as f:
            for line in f:
                exclude.add(line)

    if args.recursive:
        find_all_files(items, ".", exclude)
    else:
        find_dir_files(items, exclude)
    
    for item in items:
        if args.change == None:
            print(item)
        else:
            apply_replace(item, args.change[0], args.change[1])
    

