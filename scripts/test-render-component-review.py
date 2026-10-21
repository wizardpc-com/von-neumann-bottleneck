#!/usr/bin/env python3
"""Review-asset contract checks, not graphical-game acceptance."""
import importlib.util
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
spec=importlib.util.spec_from_file_location("review",Path(__file__).with_name("render-component-review.py"))
review=importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)

class ReviewTests(unittest.TestCase):
    def fixture(self,kind="alu4"):
        return {"kind":kind,"accent":"#7fcbd6","inputs":["A","B"],"outputs":["RESULT"],"input_widths":[4,4],"output_widths":[4],"shell":[[0,0],[230,0],[240,80],[230,160],[0,160],[10,80]],"system_device":False}
    def test_valid_svg_and_real_port_labels(self):
        node=ET.fromstring(review.component(self.fixture()))
        text=" ".join(node.itertext())
        self.assertIn("A:4",text);self.assertIn("RESULT:4",text)
        self.assertNotIn("CARRY",text)
    def test_notch_intersections(self):
        points=[(0,0),(230,0),(240,80),(230,160),(0,160),(10,80)]
        self.assertEqual(review.boundary_x(points,80,0),10)
        self.assertEqual(review.boundary_x(points,80,1),240)
        self.assertEqual(review.boundary_x(points,40,0),5)
    def test_closed_shell(self):
        self.assertIn(' Z"',review.polygon([(0,0),(20,0),(20,20)],"#000","#fff"))
    def test_selection_is_distinct(self):
        self.assertIn('#f0f5ff',review.component(self.fixture(),True))
        self.assertNotIn('#f0f5ff',review.component(self.fixture(),False))
    def test_no_fake_system_ports(self):
        item=self.fixture('cpu');item.update(inputs=[],outputs=[],input_widths=[],output_widths=[],system_device=True)
        node=ET.fromstring(review.component(item))
        self.assertEqual(len(node.findall('{http://www.w3.org/2000/svg}circle')),0)
        self.assertIn('host owns interfaces',' '.join(node.itertext()))

if __name__=='__main__':unittest.main()
