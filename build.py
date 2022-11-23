#!/usr/bin/python3
import os


name = 'a.out'
libs = []
files = ['salka', 'test/config']
config = 'test/config.sk'

out = ''
compiler = 'dmd'

run = True
print_cmd = True

if print_cmd:
    print("COMPILATION ========================")


def comp(f: str):
    global out
    cmd = f'{compiler} -c {f}.d'
    if print_cmd:
        print(cmd)
    os.system(cmd)
    out += f'{f.split("/")[-1]}.o '


def link():
    global out
    for lib in libs:
        out += '-l' + lib + ' '
    cmd = f'{compiler} -of={name} {out}'
    if print_cmd:
        print(cmd)
    os.system(cmd)


for f in files:
    comp(f)
link()

cmd = 'rm -rf *.o'
if print_cmd:
    print(cmd)
os.system(cmd)

if run:
    cmd = f'./{name} {config}'
    if print_cmd:
        print(cmd)
    print("RESULT =============================")
    os.system(cmd)
