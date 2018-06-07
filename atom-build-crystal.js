const exec = require("child_process").spawn

module.exports = {
  cmd: 'crystal',
  args: ['build', 'src/ransac.cr'],
  name: 'Crystal Build',
  sh: false,
  cwd: '{PROJECT_PATH}',
  preBuild: function() {
    exec('crystal',  ['tool', 'format']).unref()
  },
  functionMatch: function (terminal_output) {
    const error = /^(.*) ?in ([^:]+):(\d+): (.+)$/;
    // this is the list of error matches that atom-build will process
    var matches = [];
    terminal_output = terminal_output.replace(/\u001b\[.*?m/g, "")
    const trace_output = terminal_output.split(/\n/).filter( str => str.trim().length > 0).map(function(str) { return { html_message: str.replace(/\s/g, "\u00A0") }})
    trace_output.unshift({
      html_message: "\u00A0"
    })

    // iterate over the output by lines
    terminal_output.split(/\n/).reverse().forEach(function (line, line_number, term) {
      if(this.length > 0) return
      const error_match = error.exec(line);
      if(error_match) this.push({
        file: error_match[2].replace(/\s/g, "\u00A0"),
        line: error_match[3].replace(/\s/g, "\u00A0"),
        html_message: (error_match[1].trim().length > 0 ? (error_match[1] + ": ") : "") + "<strong>" + error_match[4].replace(/\s/g, "\u00A0") + "</strong>",
        trace: trace_output,
        type: error_match[1]
      })
    }, matches)


    // TODO: detect crystal spec failures and highlight spec

    return matches
  },
  targets: {
    "Crystal Spec": {
      cmd: 'crystal',
      args: ['spec'],
      sh: false
    }
  }
};
