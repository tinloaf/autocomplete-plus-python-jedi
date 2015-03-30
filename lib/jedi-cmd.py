import sys
import json
import time

try:
	JEDI_IMPORT_FAILED=False
	import jedi
except ImportError:
	JEDI_IMPORT_FAILED=True

class JediCmdline(object):
	def __init__(self, istream, ostream):
		self.istream = istream
		self.ostream =  ostream

	def _process_line(self, line):
		data =  json.loads(line)
		script = jedi.api.Script(data['source'], data['line'] + 1, data['column'])
		completions = script.completions()

		retData = []
		for completion in completions:
			retData.append({
				'name': completion.name,
				'complete': completion.complete,
				'description': completion.description,
				'type': completion.type
			})

		self._write_response(retData, data)

	def _write_response(self, retData, data):
		reqId = data['reqId']
		ret = {'reqId': reqId,
				'prefix': data['prefix'],
				'suggestions': retData}
		self.ostream.write(json.dumps(ret) + "\n")
		self.ostream.flush()

	def _write_msg(self, code):
		ret = {'reqId': 'msg',
				'msg': code,
				'halt': True}
		self.ostream.write(json.dumps(ret) + "\n")
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
	project_path = sys.argv[1]
	sys.path.append(project_path)

	cmdline = JediCmdline(sys.stdin, sys.stdout)
	cmdline.run()
