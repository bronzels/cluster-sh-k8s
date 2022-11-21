# -*- coding: utf-8 -*-
import sys

def replaceit(orig_file, replace_file, start_line, end_line):
    print('orig_file:', orig_file)
    print('replace_file:', replace_file)
    print('start_line:', start_line)
    print('end_line:', end_line)
    with open(orig_file, 'r') as orig_handle:
        orig_content = orig_handle.read()
    with open(replace_file, 'r') as replace_handle:
        replace_content = replace_handle.read()
    lines = orig_content.splitlines()
    before_lines = []
    after_lines = []
    started = False
    ended = False
    for line in lines:
        #print(line)
        if not started:
            before_lines.append(line)
        if start_line in line:
            print("---------------started---------------")
            started = True
            continue
        if started and end_line in line:
            print("---------------ended---------------")
            ended = True
        if ended:
            after_lines.append(line)
    delimiter = '\n'
    if started and ended:
        print("matched and replaced")
        result = delimiter.join(before_lines) + '\n' + replace_content + '\n' + delimiter.join(after_lines)
    else:
        print("not matched and no change")
        result = orig_content
    with open(orig_file, 'w') as new_handle:
        new_handle.write(result)

if __name__ == "__main__" :
    n_argv = len(sys.argv)
    print('参数个数为:', n_argv, '个参数。')
    if n_argv != 5:
        print("wrong input, example: replace-between-2lines.py orig_file, replace_file, start_line, end_line")
        exit(1)
    print('参数列表:', str(sys.argv))
    orig_file = sys.argv[1]
    replace_file = sys.argv[2]
    start_line = sys.argv[3]
    end_line = sys.argv[4]
    replaceit(orig_file, replace_file, start_line, end_line)
