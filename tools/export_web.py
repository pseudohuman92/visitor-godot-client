#!/usr/bin/env python3
"""Export the real Godot client for an HTTPS static host and a WSS rules engine."""
import argparse,json,os,subprocess
from pathlib import Path
from urllib.parse import urlsplit,urlunsplit

parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,default=Path('../visitor-client-web'))
parser.add_argument('--server-url',required=True,help='WSS rules-engine base URL, including an optional proxy path')
parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
args=parser.parse_args()
url=urlsplit(args.server_url)
protocol={'https':'wss','http':'ws'}.get(url.scheme,url.scheme)
if protocol not in ('ws','wss') or not url.netloc or url.query or url.fragment:
 parser.error('Use an HTTP(S) or WS(S) base URL without a query or fragment.')
server=urlunsplit((protocol,url.netloc,url.path.rstrip('/'),'',''))
root=Path(__file__).resolve().parents[1]
output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
subprocess.run([args.godot,'--headless','--path',str(root),'--export-release','Web',str(output/'index.html')],check=True)
(output/'visitor-config.js').write_text('window.VISITOR_SERVER_URL = '+json.dumps(server)+';\n')
print('Web client exported to',output)
