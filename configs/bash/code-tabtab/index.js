#!/usr/bin/env node
const debug = require('tabtab/lib/debug')('code');
const tab = require('tabtab')({ name: 'code', ttl: 1000 * 60 * 1 });

const { lstatSync, readdirSync } = require('fs')
const { join, basename } = require('path')

const isDirectory = source => lstatSync(source).isDirectory()
const getDirectories = source => (
  readdirSync(source)
    .map(name => join(source, name))
    .filter(isDirectory)
    .map(path => basename(path))
);

tab.on('code', (data, done) => {
    const codeDirectories = getDirectories(process.env.CODE_PATH);
    done(null, codeDirectories);
});

tab.start();
