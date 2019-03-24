import os, sys
import argparse

exclude = (".git", sys.argv[0], "git", ".gitignore")

def find_all_files(file_queue, subdir):
    directories = []
    for item in os.scandir(subdir):
        if item.name in exclude:
            continue
        if item.is_dir():
            directories.append(item.path)
        else:
            file_queue.append(item.path)
    
    for directory in directories:
        find_all_files(file_queue, directory)

def find_dir_files(file_queue):
    for item in os.scandir():
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
    parser = argparse.ArgumentParser(description="Runs operations on all files of a directory")
    parser.add_argument('-r', '--recursive', help='Runs operation on all files of all subdirectories', action="store_true")
    parser.add_argument('-l', '--list', help="List files with path", action="store_true")
    parser.add_argument('-c', '--change', help="Replace first argument with second argument", nargs=2, action="store")
    parser.add_argument('-e', '--exclude', help="Files and directories to exclude from the search", narg=argparse.REMAINDER)


    queue = []
    find_all_files(queue, os.getcwd())
    
    print("Replaced " + sys.argv[1] + " with " + sys.argv[2] + " on " + str(len(queue)) + " files")


