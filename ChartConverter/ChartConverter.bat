@echo off
title ChartConverter
haxe ChartConverter.hx --run ChartConverter %*
timeout /t 3 /nobreak > NUL