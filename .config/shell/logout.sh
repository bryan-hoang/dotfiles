#!/usr/bin/env sh
# -*- coding: utf-8 -*-

# ~/.logout: executed by shell when login shell exits.

# Clear cached credentials.
command -v sudo >/dev/null && sudo -k 2>/dev/null

# When leaving the console clear the screen to increase privacy.
clear
