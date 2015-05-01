import sys
import json
import time
import inspect
import os

JEDI_IMPORT_FAILED=False

try:
	import jedi
except ImportError:
	# Use the bundled jedi
	my_file = inspect.stack()[0][1]
	my_path = os.path.dirname(os.path.abspath(my_file))
	sys.path.append(my_path + '/python_packages')
	try:
		import jedi
	except ImportError:
		JEDI_IMPORT_FAILED=True

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

	def _process_command(self, data):
		if data['cmd'] == 'add_python_path':
			sys.path.append(data['path'])

	def _process_line(self, line):
		data =  json.loads(line)

		if 'cmd' in data:
			self._process_command(data)
			return

		script = jedi.api.Script(data['source'], data['line'] + 1, data['column'])

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
					'docstring': completion.docstring()
				})
		except:
			# TODO Error handling!
			pass

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
	cmdline = JediCmdline(sys.stdin, sys.stdout)
	cmdline.run()
