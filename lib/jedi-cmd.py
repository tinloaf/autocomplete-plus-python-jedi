import sys
import json
import time
import os

JEDI_IMPORT_FAILED = False

try:
  import jedi
except ImportError:
  # Use the bundled jedi
  sys.path.append(os.path.join(os.path.dirname(__file__), 'python_packages'))
  try:
    import jedi
  except ImportError:
    JEDI_IMPORT_FAILED = True


class JediCmdline(object):
  def __init__(self, istream, ostream):
    self.istream = istream
    self.ostream = ostream

  def _get_params(self, completion):
    try:
      param_defs = completion.params
    except AttributeError:
      return []
    except:
      # TODO Propagate!
      return []

    params = []
    for param_def in param_defs:
      params.append({
        'name': param_def.name,
        'description': param_def.description
      })

    return params

  @classmethod
  def _get_top_level_module(cls, path):
    """Recursively walk through directories looking for top level module.
    """
    _path, _ = os.path.split(path)
    if os.path.isfile(os.path.join(_path, '__init__.py')):
      return cls._get_top_level_module(_path)
    return path

  def _process_line(self, line):
    """
    Jedi will use filepath to look for another modules at same path,
    but it will not be able to see modules **above**, so our goal
    is to find the higher python module available from filepath.
    """
    data = json.loads(line)

    path = self._get_top_level_module(data.get('path', ''))
    if path not in sys.path:
      sys.path.insert(0, path)
    script = jedi.api.Script(
      source=data['source'], line=data['line'] + 1, column=data['column'],
      path=data.get('path', ''))

    retData = []
    try:
      completions = script.completions()

      for completion in completions:
        params = self._get_params(completion)

        retData.append({
          'name': completion.name,
          'complete': completion.complete,
          'description': completion.description,
          'type': completion.type,
          'params': params,
          'docstring': completion.docstring(),
        })
    except:
      # TODO Error handling!
      pass

    self._write_response(retData, data)

  def _write_response(self, retData, data):
    reqId = data['reqId']
    ret = {'reqId': reqId, 'prefix': data['prefix'], 'suggestions': retData}
    self.ostream.write(json.dumps(ret) + "\n")
    self.ostream.flush()

  def _write_msg(self, code):
    ret = {'reqId': 'msg', 'msg': code, 'halt': True}
    self.ostream.write(json.dumps(ret) + '\n')
    self.ostream.flush()

  def _watch(self):
    # This seems to be the only sane way for python 2 and 3...
    while True:
      line = self.istream.readline()
      self._process_line(line)

  def run(self):
    if JEDI_IMPORT_FAILED:
      self._write_msg('jedi-missing')
      while True:
        time.sleep(10)

    self._watch()

if __name__ == '__main__':
  # TODO: jedi is not inderested in folders which are not python modules
  # (are not contains __init__.py file)
  for path in sys.argv[1:]:
    if path not in sys.path:
      sys.path.insert(0, path)

  cmdline = JediCmdline(sys.stdin, sys.stdout)
  cmdline.run()
