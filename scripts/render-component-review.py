#!/usr/bin/env python3
"""Render editable SVG review sheets from the Godot-exported contract manifest.
These are labelled design previews, NOT game screenshots or graphical acceptance.
Uses Python stdlib for SVG; optional installed PyMuPDF rasterizes review PNGs.
"""
import argparse, html, json
from pathlib import Path

LABELS = {'half_adder':'HA','full_adder':'FA','mux4':'MUX 4:1','mux2_word':'MUX 2:1','alu1':'ALU1','alu4':'ALU4','sr_latch':'SR','register1':'REG1','register4':'REG4','ram2x4':'RAM 2×4','decoder1_to_2':'DEC 1→2','control':'CTRL','tiny_computer':'CPU + RAM'}
def text(x,y,value,size=14,color='#d7e9f6',anchor='middle'):
    return f'<text x="{x:g}" y="{y:g}" font-family="DejaVu Sans,sans-serif" font-size="{size}" fill="{color}" text-anchor="{anchor}">{html.escape(str(value))}</text>'
def line(x1,y1,x2,y2,color,width=2):
    return f'<path d="M{x1:g},{y1:g} L{x2:g},{y2:g}" stroke="{color}" stroke-width="{width}" fill="none"/>'
def polygon(points,fill,stroke,width=2):
    path='M'+' L'.join(f'{x:g},{y:g}' for x,y in points)+' Z'
    return f'<path d="{path}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"/>'

def boundary_x(points, py, side):
    intersections=[]
    for (ax,ay),(bx,by) in zip(points,points[1:]+points[:1]):
        if min(ay,by) <= py <= max(ay,by) and ay != by:
            intersections.append(ax+(bx-ax)*(py-ay)/(by-ay))
    return (min(intersections) if side==0 else max(intersections)) if intersections else (74 if side==0 else 326)

def component(item, selected=False):
    kind=item['kind'];accent=item['accent'];edge='#f0f5ff' if selected else accent
    inputs=item['inputs'];outputs=item['outputs'];count=max(1,len(inputs),len(outputs))
    h=max(130,70+count*27); w=400; x=74;y=38;bw=252;bh=h-52
    chunks=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h+32}" viewBox="0 0 {w} {h+32}">']
    body=[(x+px/240*bw,y+py/160*bh) for px,py in item['shell']]
    if kind in ('and','or','xor','nor','not'):
        # IEEE-inspired semantic silhouettes, including XOR's extra arc and inversion bubble.
        gx=x+58;gy=y+10;gw=136;gh=bh-20
        if kind=='and': path=f'M{gx},{gy} L{gx+gw/2},{gy} C{gx+gw*1.18},{gy} {gx+gw*1.18},{gy+gh} {gx+gw/2},{gy+gh} L{gx},{gy+gh} Z'
        elif kind=='not': path=f'M{gx},{gy} L{gx+gw-12},{gy+gh/2} L{gx},{gy+gh} Z'
        else: path=f'M{gx},{gy} Q{gx+gw*.68},{gy-8} {gx+gw},{gy+gh/2} Q{gx+gw*.68},{gy+gh+8} {gx},{gy+gh} Q{gx+30},{gy+gh/2} {gx},{gy} Z'
        chunks.append(f'<path d="{path}" fill="#192b40" stroke="{edge}" stroke-width="{3 if selected else 2}"/>')
        if kind=='xor':chunks.append(f'<path d="M{gx-9},{gy} Q{gx+21},{gy+gh/2} {gx-9},{gy+gh}" fill="none" stroke="{edge}" stroke-width="2"/>')
        if kind in ('not','nor'):chunks.append(f'<circle cx="{gx+gw-6 if kind=="not" else gx+gw+6}" cy="{gy+gh/2}" r="5" fill="#192b40" stroke="{edge}" stroke-width="2"/>')
    elif kind=='lamp':chunks.append(f'<circle cx="200" cy="{y+bh/2}" r="26" fill="#192b40" stroke="{edge}" stroke-width="2"/>')
    elif kind=='junction':chunks.append(f'<circle cx="200" cy="{y+bh/2}" r="7" fill="{accent}"/>')
    else: chunks.append(polygon(body,'#192b40',edge,3 if selected else 2))
    title=LABELS.get(kind,kind.upper())
    chunks.append(text(200,23,title,16,accent))
    if kind not in ('and','or','xor','nor','not','lamp','junction'):
        chunks.append(text(200,y+bh/2+5,title,20))
    elif kind in ('and','or','xor','nor'):
        chunks.append(text(204,y+bh/2+5,kind.upper(),14))
    for side,(ports,widths) in enumerate(((inputs,item['input_widths']),(outputs,item['output_widths']))):
        for i,(port,bits) in enumerate(zip(ports,widths)):
            py=y+bh*(i+1)/(len(ports)+1); outer=18 if side==0 else 382; inner=boundary_x(body,py,side)
            if kind in ('and','or','xor','nor','not'):
                if side:
                    inner=gx+gw+(12 if kind=='nor' else -1 if kind=='not' else 0)
                elif kind in ('or','xor','nor'):
                    t=max(0,min(1,(py-gy)/gh));inner=gx+60*t*(1-t)
                else:inner=gx
            elif kind=='lamp':inner=200-26 if side==0 else 226
            elif kind=='junction':inner=193 if side==0 else 207
            color='#f4bf75' if bits==1 else '#c0a2ff' if bits==2 else '#72ceff'
            chunks.append(line(outer,py,inner,py,color,2 if bits==1 else 3))
            if bits==1:chunks.append(f'<circle cx="{outer}" cy="{py:g}" r="4" fill="#192b40" stroke="{color}" stroke-width="2"/>')
            else:chunks.append(f'<rect x="{outer-4}" y="{py-4:g}" width="8" height="8" fill="#192b40" stroke="{color}" stroke-width="2"/>')
            label_x=(outer+12 if side==0 else outer-12) if kind=='junction' else inner+(8 if side==0 else -8)
            chunks.append(text(label_x,py-5,f'{port}:{bits}',11,color,'start' if side==0 else 'end'))
    caption='System device · host owns interfaces' if item['system_device'] else 'Selected' if selected else 'Contract-derived review preview'
    chunks.append(text(200,h+20,caption,11,'#8fa3b8'))
    chunks.append('</svg>');return ''.join(chunks)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('manifest',type=Path);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--png',action='store_true');args=ap.parse_args()
    data=json.loads(args.manifest.read_text());args.output.mkdir(parents=True,exist_ok=True)
    generated=[]
    for item in data['entries']:
        for state in ('default','selected'):
            p=args.output/f'{item["kind"]}-{state}.svg';p.write_text(component(item,state=='selected'))
            generated.append(p)
    for sample in data['layout_fixtures']:
        body=polygon([(x+30,y+45) for x,y in sample['outline']],'#192b40','#7fcbd6')
        svg='<svg xmlns="http://www.w3.org/2000/svg" width="300" height="250">'+text(150,24,sample['name'],16)+body+text(150,230,'GEOMETRIC FIXTURE · NOT EARNED WORK',10)+'</svg>'
        p=args.output/f'layout-{sample["name"]}.svg';p.write_text(svg);generated.append(p)
    if args.png:
        try:
            import fitz
        except ImportError:
            raise SystemExit('PNG unavailable: PyMuPDF is not installed. All SVGs retained.')
        for p in generated:
            with fitz.open(p) as document:
                document[0].get_pixmap(matrix=fitz.Matrix(2,2),alpha=True).save(str(p.with_suffix('.png')))
    print(f'Created {len(data["entries"])*2+len(data["layout_fixtures"])} editable review SVGs; these are not game screenshots.')
if __name__=='__main__':main()
