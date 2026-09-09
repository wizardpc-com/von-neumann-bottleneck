import importlib.util
from pathlib import Path
import unittest
spec = importlib.util.spec_from_file_location('report', Path(__file__).parents[1]/'scripts/report-playtests.py')
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)

class ReportTest(unittest.TestCase):
    def event(self, sequence, name, **payload):
        return dict(schema_version=2, session_id='agent', sequence=sequence, source='agent_native', visit_id='v1' if name != 'map_action' else '', event=name, payload=dict(chapter_id='chapter_3',level_id='arrival',**payload))
    def test_deduplicate_unfinished_and_sources(self):
        events = [self.event(1,'map_action',action='eligible',task_key='chapter_3/arrival'),self.event(2,'map_action',action='viewport_exposure',task_key='chapter_3/arrival'),self.event(3,'level_start'),self.event(4,'visit_time',kind='foreground',duration_ms=1000),self.event(5,'visit_time',kind='background',duration_ms=9000),self.event(6,'official_run',run_id='r1',passed=False,result_class='correct_but_slow',correct=True),self.event(7,'case_outcome',run_id='r1',passed=True,metrics={'total_cycles':30}),self.event(8,'moment',kind='stuck',note='<script>evil()</script>')]
        old = dict(schema_version=1, session_id='legacy',sequence=1,event='level_start',payload={'chapter_id':'chapter_3','level_id':'arrival'})
        result = report.summarize([{'events':events},{'events':events+[old]}])
        self.assertEqual(result['duplicate_events_ignored'],8)
        self.assertEqual(result['input_sessions'],2)
        agent = next(t for t in result['tasks'] if t['source']=='agent_native')
        self.assertEqual(agent['completed_started'],{'n':0,'N':1})
        self.assertEqual(agent['foreground_seconds']['median'],1)
        self.assertEqual(agent['sessions']['correct_output'],1)
        visit = next(v for v in result['visits'] if v['visit_id']=='v1')
        self.assertIsNone(visit['exit'])
        self.assertEqual(visit['runs'][0]['cases'][0]['metrics']['total_cycles'],30)
        self.assertEqual(next(v for v in result['visits'] if v['source']=='unknown')['timing'],'unknown')
        self.assertNotIn('<script>evil()',report.render(result))
        self.assertIn('&lt;script&gt;',report.render(result))
    def test_map_counts_do_not_infer_attention_or_people(self):
        events = [self.event(1,'map_action',action='viewport_exposure',task_key='chapter_3/arrival')]
        result = report.summarize([{'events':events}])
        self.assertEqual(result['tasks'][0]['exposed_eligible'],{'n':0,'N':0})
        self.assertEqual(result['tasks'][0]['started_exposed'],{'n':0,'N':1})

if __name__ == '__main__': unittest.main()
