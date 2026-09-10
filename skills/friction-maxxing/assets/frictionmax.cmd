@echo off
rem friction-maxxing hook shim. Runtime and assets live in the frictionmax subdir beside this file.
node "%~dp0frictionmax/frictionmax.mjs" %*
