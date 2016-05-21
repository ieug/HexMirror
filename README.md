# HexMirror

This project is intended to facilitate syncronization of packages between private and public hex_web instances. It will communicate with public hex_web to synchronize newly added public packages, and will download and push the packages to the private hex_web database. It is currentlly work in progress.

# Getting started

Edit the @hexmirror_home Macro on Line 4 of /lib/hex_mirror/diffHandler.ex file. This Macro tells HexMirror where registry archive should be downloaded during runtime.

Compile the project
```
iex -S mix
```
Run it via command 

```
HexMirror.Order.request(Order)
```
This will download the latest registry from public hex_web server, compute missing packeges, and lists them down if there are any. For example, if Cowboy version 1.0.0 is missing, the following is the expected result:

```
iex(1)> HexMirror.Order.request(Order)
:ok
iex(2)> Downloading Registry
Starting diffing
Extracting...
The following packages are not syched:
[{"cowboy", "1.0.0"}]

```

