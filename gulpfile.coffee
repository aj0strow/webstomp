gulp = require "gulp"
coffee = require "gulp-coffee"
del = require "del"
mocha = require "gulp-mocha"

gulp.task "default", [ "dev" ]

gulp.task "dev", [ "clean" ], ->
  gulp.watch("src/**/*", [ "test" ])

gulp.task "clean", ->
  return del("dist")

gulp.task "compile", ->
  return gulp.src("src/**/*.coffee")
    .pipe gulp.dest("dist")

gulp.task "test", [ "compile" ], ->
  return gulp.src("dist/**/*-test.js")
    .pipe mocha()
