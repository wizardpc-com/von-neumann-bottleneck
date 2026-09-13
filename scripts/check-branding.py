#!/usr/bin/env python3
"""Check the single branding contract without changing product/save identity."""
import configparser, json, struct
from pathlib import Path

def read_brand(root):
    cfg=configparser.ConfigParser();cfg.read(root/'assets/branding/brand.cfg')
    values={key:json.loads(value) for key,value in cfg['brand'].items()}
    for key,path in values.items():
        if key=='revision' or not path:continue
        if not path.startswith('res://assets/branding/'):raise ValueError('Brand asset must remain local: '+key)
        file=(root/path[6:]).resolve()
        if not file.is_relative_to((root/'assets/branding').resolve()) or not file.is_file():raise ValueError('Missing brand asset: '+key)
        if key=='native_icon_windows':
            data=file.read_bytes(); reserved,kind,count=struct.unpack_from('<HHH',data)
            if reserved or kind!=1 or count<1:raise ValueError('Invalid ICO header')
            sizes={(data[6+16*i] or 256,data[7+16*i] or 256) for i in range(count)}
            if not {(x,x) for x in (16,32,48,64,128,256)} <=sizes:raise ValueError('ICO needs 16/32/48/64/128/256 sizes')
        if key=='native_icon_macos' and file.read_bytes()[:4]!=b'icns':raise ValueError('Expected ICNS')
    if not values.get('app_icon'):raise ValueError('App icon is required')
    return values
if __name__=='__main__':
    read_brand(Path(__file__).resolve().parents[1]);print('PASS: local branding assets and native icon contracts')
