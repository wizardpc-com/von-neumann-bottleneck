#!/usr/bin/env python3
"""Check the single branding contract without changing product/save identity."""
import configparser, json, struct
import xml.etree.ElementTree as ET
from pathlib import Path

def png_size(data):
    if data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise ValueError('Native icon entry must contain PNG pixels')
    return struct.unpack_from('>II', data, 16)

def check_native_icon(file, kind):
    data=file.read_bytes()
    sizes=set()
    if kind=='native_icon_windows':
        reserved,icon_type,count=struct.unpack_from('<HHH',data)
        if reserved or icon_type!=1 or count<1:raise ValueError('Invalid ICO header')
        for index in range(count):
            width,height,_,_,planes,depth,length,offset=struct.unpack_from('<BBBBHHII',data,6+16*index)
            size=(width or 256,height or 256)
            if planes!=1 or depth!=32 or offset<6+16*count or offset+length>len(data):raise ValueError('Invalid ICO entry')
            if png_size(data[offset:offset+length])!=size:raise ValueError('ICO pixel size differs from directory')
            sizes.add(size)
        required=(16,32,48,64,128,256)
    else:
        if data[:4]!=b'icns' or struct.unpack_from('>I',data,4)[0]!=len(data):raise ValueError('Invalid ICNS header')
        offset=8
        while offset<len(data):
            tag=data[offset:offset+4]
            length=struct.unpack_from('>I',data,offset+4)[0]
            if length<8 or offset+length>len(data):raise ValueError('Invalid ICNS entry')
            expected={b'icp4':16,b'icp5':32,b'icp6':64,b'ic07':128,b'ic08':256,b'ic09':512,b'ic10':1024}.get(tag)
            if expected is not None:
                size=png_size(data[offset+8:offset+length])
                if size!=(expected,expected):raise ValueError('ICNS pixel size differs from type')
                sizes.add(size)
            offset+=length
        required=(16,32,64,128,256,512,1024)
    if not {(x,x) for x in required}<=sizes:raise ValueError('Native icon missing required sizes: '+kind)

def read_brand(root):
    cfg=configparser.ConfigParser();cfg.read(root/'assets/branding/brand.cfg')
    values={key:json.loads(value) for key,value in cfg['brand'].items()}
    for key,path in values.items():
        if key=='revision' or not path:continue
        if not path.startswith('res://assets/branding/'):raise ValueError('Brand asset must remain local: '+key)
        file=(root/path[6:]).resolve()
        if not file.is_relative_to((root/'assets/branding').resolve()) or not file.is_file():raise ValueError('Missing brand asset: '+key)
        if key in ('native_icon_windows','native_icon_macos'):check_native_icon(file,key)
        if file.suffix=='.svg':
            svg=ET.fromstring(file.read_text(encoding='utf-8'))
            bounds=[float(value) for value in svg.attrib.get('viewBox','').split()]
            if len(bounds)!=4 or min(bounds[2:])<=0:raise ValueError('Invalid SVG bounds: '+key)
            for element in svg.iter():
                if element.tag.rsplit('}',1)[-1] in ('text','script','image','foreignObject'):
                    raise ValueError('Brand SVG must use self-contained vector outlines: '+key)
    if not values.get('app_icon'):raise ValueError('App icon is required')
    return values
if __name__=='__main__':
    read_brand(Path(__file__).resolve().parents[1]);print('PASS: local branding assets and native icon contracts')
