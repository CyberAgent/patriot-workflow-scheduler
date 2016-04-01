module.exports = function(grunt) {
  grunt.initConfig({
    pkg : grunt.file.readJSON('package.json'),
    browserify: {
      options: {
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
    env : {
      development : {
        NODE_ENV : 'development'
      },
      build : {
        NODE_ENV : 'production'
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
    },
    esteWatch: {
      options: {
        dirs: ['src/main/jsx/**/'],
        livereload: {
          enabled: false
        }
      },
      '*': function(filepath) { return 'browserify' }
    }
  });
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-env');
  grunt.loadNpmTasks('grunt-este-watch');
  grunt.loadNpmTasks('grunt-preprocess');
  grunt.registerTask('default', ['env:development', 'browserify', 'preprocess']);
  grunt.registerTask('build', ['env:build', 'browserify', 'uglify', 'preprocess']);
}
