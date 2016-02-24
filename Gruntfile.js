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
         'skel/public/js/patriot-workflow-scheduler-<%= pkg.version %>.js'  : ["src/main/jsx/**/*.jsx"]
        }
      }
    },
    esteWatch: {
      options: {
        dirs: ["src/main/jsx/**/"],
        livereload: {
          enabled: false
        }
      },
      '*': function(filepath) { return 'browserify' }
    }
  });
  grunt.loadNpmTasks("grunt-browserify");
  grunt.loadNpmTasks("grunt-este-watch");
  grunt.registerTask('default', ['browserify']);
}
