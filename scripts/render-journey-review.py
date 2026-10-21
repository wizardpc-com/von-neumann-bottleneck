#!/usr/bin/env python3
"""Render production map geometry as an explicitly labelled review SVG/PNG."""
import argparse,html,json
from pathlib import Path

def render(data,region=None):
    nodes=[n for n in data['nodes'] if region is None or n['region']==region]
    regions=[r for r in data['regions'] if region is None or r['region']==region]
    if region is None: origin=[0,0];size=data['size']
    else: origin=[regions[0]['position'][0]-30,regions[0]['position'][1]-60];size=[regions[0]['size'][0]+60,regions[0]['size'][1]+100]
    x0,y0=origin;w,h=size;colors={r['region']:r['color'] for r in regions}
    chunks=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x0} {y0} {w} {h}">',f'<rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="#091521"/>']
    def text(x,y,t,size=16):return f'<text x="{x}" y="{y}" fill="#dce9f2" font-family="sans-serif" font-size="{size}">{html.escape(t)}</text>'
    chunks.append(text(x0+15,y0+24,'PRODUCTION GEOMETRY REVIEW — NOT A GAME SCREENSHOT',14))
    for r in regions:
        x,y=r['position'];rw,rh=r['size']
        chunks.append(f'<rect x="{x}" y="{y}" width="{rw}" height="{rh}" rx="18" fill="#0c1925" stroke="{r["color"]}" stroke-opacity=".3"/>')
        chunks.append(text(x+20,y+30,f'Region {r["region"]}',22))
    visible={n['key'] for n in nodes}
    for edge in data['edges']:
        if edge['from'] not in visible or edge['to'] not in visible or not edge['points']:continue
        path='M'+' L'.join(f'{x},{y}' for x,y in edge['points'])
        dash=' stroke-dasharray="10 7"' if edge['recommended'] else ''
        color='#799b8c' if edge['recommended'] else '#839bb7'
        chunks.append(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="2"{dash}/>')
        if not edge['recommended']:
            x,y=edge['points'][-1];chunks.append(f'<path d="M{x},{y} L{x-9},{y-6} L{x-9},{y+6} Z" fill="{color}"/>')
    for n in nodes:
        x,y=n['position'];nw,nh=n['size'];color=colors[n['region']]
        chunks.append(f'<rect x="{x}" y="{y}" width="{nw}" height="{nh}" rx="10" fill="#1b3443" stroke="{color}"/>')
        # Exact key remains below the title so review cannot confuse similar labels.
        title=n['title'];short=title if len(title)<27 else title[:25]+'…'
        chunks.append(text(x+10,y+29,short,16));chunks.append(text(x+10,y+52,n['key'].split('/')[-1],12))
        chunks.append(text(x+10,y+75,('Optional · ' if n['optional'] else '')+('Available' if n['unlocked'] else 'Locked'),12))
    chunks.append('</svg>');return ''.join(chunks)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('manifest',type=Path);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
    data=json.loads(args.manifest.read_text())['locales']['en'];args.output.mkdir(parents=True,exist_ok=True)
    import fitz
    for region in [None]+[r['region'] for r in data['regions']]:
        p=args.output/('whole.svg' if region is None else f'region-{region}.svg');p.write_text(render(data,region))
        with fitz.open(p) as d:
            scale=min(1.5,3000/max(d[0].rect.width,d[0].rect.height))
            d[0].get_pixmap(matrix=fitz.Matrix(scale,scale)).save(str(p.with_suffix('.png')))
    print('Review assets generated. These are not game screenshots.')
if __name__=='__main__':main()
