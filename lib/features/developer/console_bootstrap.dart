/// JavaScript injected into every previewed page.
///
/// Hooks `console.log/warn/error/info/debug`, `window.onerror` and
/// `unhandledrejection`, forwarding entries to the native `Console`
/// JavaScriptChannel as compact JSON.
const String consoleBootstrapJs = '''
(function() {
  if (window.__hvConsoleHooked) return;
  window.__hvConsoleHooked = true;

  function fmt(a) {
    if (a instanceof Error) {
      return a.name + ': ' + a.message +
        (a.stack ? '\\n' + a.stack : '');
    }
    if (typeof a === 'object' && a !== null) {
      try { return JSON.stringify(a); } catch (e) { return String(a); }
    }
    return String(a);
  }

  function send(level, args) {
    try {
      var text = Array.prototype.map.call(args, fmt).join(' ');
      var json = '{"level":"' + level + '","text":' + quote(text) + '}';
      Console.postMessage(json);
    } catch (e) { /* never break the page */ }
  }

  function quote(s) {
    return '"' + String(s)
      .replace(/\\\\/g, '\\\\\\\\')
      .replace(/"/g, '\\\\"')
      .replace(/\\n/g, '\\\\n')
      .replace(/\\r/g, '') + '"';
  }

  var levels = { log: 'log', info: 'log', debug: 'log',
                 warn: 'warning', warning: 'warning', error: 'error' };
  Object.keys(levels).forEach(function(name) {
    var orig = console[name];
    console[name] = function() {
      send(levels[name], arguments);
      if (orig) { try { orig.apply(console, arguments); } catch (e) {} }
    };
  });

  window.addEventListener('error', function(e) {
    var where = '';
    if (e.filename) {
      var file = e.filename.split('/').pop() || e.filename;
      where = ' (' + file + ':' + e.lineno + ')';
    }
    send('error', [e.message || 'Script error' + where]);
  });

  window.addEventListener('unhandledrejection', function(e) {
    var r = e.reason;
    var msg = r instanceof Error ? r.name + ': ' + r.message : String(r);
    send('error', ['Unhandled promise rejection: ' + msg]);
  });
})();
''';
