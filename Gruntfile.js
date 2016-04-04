module.exports = function(grunt) {
  grunt.initConfig({
    pkg : grunt.file.readJSON('package.json'),
    browserify: {
      options: {
        watch: (function() {
          if (process.env.DEBUG === 'true') {
            return true;
          } else {
            return false;
          }
        }()),
        keepAlive: (function() {
          if (process.env.DEBUG === 'true') {
            return true;
          } else {
            return false;
          }
        }()),
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
    uglify: {
      options: {
        compress: {
          drop_console: true
        },
        sourceMap: true
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
  grunt.loadNpmTasks('grunt-preprocess');

  grunt.registerTask('default', 'default task', function() {
    console.log('Please set NODE_ENV to production to uglify.');
    console.log('Please set DEBUG to true to watchify.');
    console.log('e.g.');
    console.log('% grunt                      # to build a development version');
    console.log('% DEBUG=true grunt           # to watch modified files');
    console.log('% NODE_ENV=production grunt  # to build a production version');

    grunt.task.run('preprocess');
    grunt.task.run('browserify');
    if (process.env.NODE_ENV === 'production') grunt.task.run('uglify');
  });
}

