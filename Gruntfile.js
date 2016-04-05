module.exports = function(grunt) {
  grunt.initConfig({
    pkg : grunt.file.readJSON('package.json'),
    browserify: {
      options: {
        watch: grunt.option('watch'),
        keepAlive: grunt.option('watch'),
        transform: ['babelify'],
        browserifyOptions: {
          extensions: ['.jsx','.js']
        }
      },
      dist: {
        files: {
          'skel/public/js/patriot-workflow-scheduler-<%= pkg.version %>.js'  : ['src/main/jsx/**/*.jsx']
        }
      }
    },
    env: {
      development: {
        NODE_ENV: 'development'
      },
      production: {
        NODE_ENV: 'production'
      }
    },
    uglify: {
      options: {
        compress: {
          drop_console: true
        }
      },
      build: {
        src: 'skel/public/js/patriot-workflow-scheduler-<%= pkg.version %>.js',
        dest: 'skel/public/js/patriot-workflow-scheduler-<%= pkg.version %>.min.js'
      }
    },
    preprocess: {
      html: {
        src: 'skel/public/views/index.tpl.erb',
        dest:'skel/public/views/index.erb'
      }
    }
  });
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-env');
  grunt.loadNpmTasks('grunt-preprocess');

  grunt.log.writeln('% grunt                      # to build a development version');
  grunt.log.writeln('% grunt --watch              # to watch modified files');
  grunt.log.writeln('% grunt build                # to build a production version');

  grunt.registerTask('default', ['env:development', 'preprocess', 'browserify']);
  grunt.registerTask('build', ['env:production', 'preprocess', 'browserify', 'uglify']);
}

