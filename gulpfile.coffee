gulp = require "gulp"
coffee = require "gulp-coffee"
del = require "del"
mocha = require "gulp-mocha"
sourcemaps = require "gulp-sourcemaps"
require('source-map-support').install()

gulp.task "default", [ "dev" ]

gulp.task "dev", [ "test" ], ->
  return gulp.watch("src/**/*", [ "test" ])

gulp.task "clean", ->
  return del("dist/**")

gulp.task "compile", [ "clean" ], ->
  return gulp.src("src/**/*.coffee")
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write()
    .pipe gulp.dest("dist")

gulp.task "test", [ "compile" ], ->
  return gulp.src("dist/**/*-test.js")
    .pipe mocha()
