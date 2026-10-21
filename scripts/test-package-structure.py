#!/usr/bin/env python3
"""Synthetic PE/PCK parsing fixtures; these do not represent playable builds."""
import importlib.util,struct,tempfile,unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location("pack",Path(__file__).with_name("package-verified-playtest.py"))
pack=importlib.util.module_from_spec(spec);spec.loader.exec_module(pack)
class PackageTests(unittest.TestCase):
    def data(self):
        data=bytearray(256);data[:2]=b'MZ';data[0x3c:0x40]=struct.pack('<I',0x40)
        data[0x40:0x46]=b'PE\0\0'+struct.pack('<H',0x8664)
        payload=b'GDPC'+b'fixture-only'
        return data+payload+struct.pack('<Q',len(payload))+b'GDPC'
    def inspect(self,data):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'fixture.exe';p.write_bytes(data);return pack.inspect_executable(p)
    def test_structure(self):
        result=self.inspect(self.data());self.assertEqual(result['pe_architecture'],'x86_64');self.assertEqual(result['embedded_pack_bytes'],16)
    def test_truncated(self):
        with self.assertRaises(ValueError):self.inspect(b'MZ')
    def test_architecture(self):
        data=self.data();data[0x44:0x46]=struct.pack('<H',0x14c)
        with self.assertRaises(ValueError):self.inspect(data)
    def test_footer(self):
        data=self.data();data[-4:]=b'NOPE'
        with self.assertRaises(ValueError):self.inspect(data)
if __name__=='__main__':unittest.main()
