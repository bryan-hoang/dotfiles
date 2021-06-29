#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# [[ -f ~/.Xresources ]] && xrdb --merge -I"$HOME" ~/.Xresources

autocutsel -fork -selection CLIPBOARD
autocutsel -fork -selection PRIMARY
