#!/bin/bash
/usr/local/bin/occ globalsiteselector:users:update
/usr/local/bin/occ federation:sync-addressbooks
