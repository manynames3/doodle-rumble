"""Run source tests sequentially with isolated preferences and compact evidence."""
from pathlib import Path
import argparse,json,re,subprocess
p=argparse.ArgumentParser()
p.add_argument('--godot',required=True)
p.add_argument('--logs',default='test-logs')
a=p.parse_args()
game=Path(__file__).resolve().parents[1]
logs=Path(a.logs).resolve();logs.mkdir(parents=True,exist_ok=True)
results=[]
for suite in sorted((game/'tests').glob('test_*.gd')):
    path=logs/(suite.stem+'.log')
    try:
        with path.open('w') as stream:
            timing=[] if suite.stem=='test_boot_audio' else ['--fixed-fps','60']
            result=subprocess.run([a.godot,'--headless',*timing,'--path',str(game),'--script','res://tests/'+suite.name,'--','--isolated-qa','--silent-qa'],stdout=stream,stderr=subprocess.STDOUT,timeout=120)
        txt=path.read_text()
        summary=[line for line in txt.splitlines() if re.search(r'checks|failures',line,re.I)]
        ok=result.returncode==0 and not re.search(r'(SCRIPT ERROR:|^ERROR:|^WARNING:)',txt,re.M) and bool(summary)
        results.append({'suite':suite.stem,'passed':ok,'summary':summary[-2:]})
    except subprocess.TimeoutExpired:
        results.append({'suite':suite.stem,'passed':False,'summary':['TIMEOUT']})
    print(json.dumps(results[-1]),flush=True)
(logs/'results.json').write_text(json.dumps(results,indent=2))
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
