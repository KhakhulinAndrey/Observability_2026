#!/bin/bash
case "$1" in
    "discovery")
        echo '{
            "data": [
                {"{#METRIC}": "metric1"},
                {"{#METRIC}": "metric2"},
                {"{#METRIC}": "metric3"}
            ]
        }'
        ;;
    "metric1"|"metric2"|"metric3")
        echo $((RANDOM % 101))
        ;;
esac