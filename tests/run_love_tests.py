"""Run the real game with an isolated save directory and scripted interactions."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
work = Path(tempfile.mkdtemp(prefix='miswander-love-test-'))
project = work / 'game'
project.mkdir()
for source in root.glob('*.lua'):
    shutil.copy2(source, project / source.name)
shutil.copytree(root / 'assets', project / 'assets')
with (project / 'main.lua').open('a') as output:
    output.write('\n' + (root / 'tests/runtime.lua').read_text())
env = dict(os.environ, XDG_DATA_HOME=str(work / 'data'))
env.pop('ISOMET_SMOKE', None)
subprocess.run(['love', str(project)], env=env, check=True, timeout=60)
print('Isolated test files:', work)
