#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh; -*-

function unless_yes {
    echo -n "$@"
    read -p " [y/N] " ANSWER

    case $ANSWER in
        [yY]*)
            true
            ;;
        *)
            false
            ;;
    esac
}
