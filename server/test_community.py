import copy
import json
from urllib.parse import urlencode
from test_receiver import ReceiverTests
from community import RULES

class CommunityTests(ReceiverTests):
    def test_creation_content_versions(self):
        manifests=RULES['content_manifests']
        old=manifests['tasks-20261010-journey-v1']
        new=manifests['tasks-20261012-journey-v1']
        current=manifests['tasks-20261013-journey-v1']
        old_hash='8fa772927fd31c80940fdb479201cffc4a3e9a3e5c698cfbd2bd56af3920408d'
        new_hash='6fb3476b76e1a37d75da712f409aa57a6e0cdda00a50a5d8b9cd507143363f35'
        current_hash='83b39f9c5a58f48ae5002b975c40ac02c8c9d09f26cf82358213fba9974fe3da'
        self.assertEqual(old['tasks'],new['tasks'])
        self.assertEqual(old['tasks'],current['tasks'])
        creation=[key for key in old['identities'] if key.startswith('creation/')]
        self.assertEqual(len(creation),9)
        for key,identity in old['identities'].items():
            expected=new_hash if key in creation else identity['case_set_version']
            self.assertEqual(new['identities'][key]['case_set_version'],expected)
            self.assertEqual(new['identities'][key]['model_version'],identity['model_version'])
            self.assertEqual(current['identities'][key]['case_set_version'],current_hash if key in creation else identity['case_set_version'])
            self.assertEqual(current['identities'][key]['model_version'],identity['model_version'])
            if key in creation: self.assertEqual(identity['case_set_version'],old_hash)
        for index,(version,digest,accepted) in enumerate([
            ('tasks-20261010-journey-v1',old_hash,True),
            ('tasks-20261012-journey-v1',new_hash,True),
            ('tasks-20261010-journey-v1',new_hash,False),
            ('tasks-20261012-journey-v1',old_hash,False),
            ('tasks-20261013-journey-v1',current_hash,True),
            ('tasks-20261013-journey-v1',old_hash,False),
            ('tasks-20261013-journey-v1',new_hash,False),
            ('tasks-20261010-journey-v1',current_hash,False),
            ('tasks-20261012-journey-v1',current_hash,False),
        ]):
            payload={'source':'automated','mode':'game','task_version':version,'chapter_id':'creation',
                     'level_id':'G2_intent','model_version':'creation-continuous-v1',
                     'case_set_version':digest,'note':'synthetic content identity check'}
            status,response=self.request('POST','/v1/events',{'client_id':'creation-version-client-'+str(index),
                'deletion_token':'c'*64,'records':[{'event_id':'creation-version-event-'+str(index),
                'kind':'feedback','payload':payload}]})
            self.assertEqual(status,200 if accepted else 400)
            if not accepted: self.assertEqual(response['reason'],'case_set_version')

    def test_summary_and_board(self):
        base={'source':'automated','mode':'test','task_version':RULES['task_version'], 'chapter_id':'chapter_4','level_id':'mixed',
              'event':'visit_summary','visit_id':'synthetic-visit-1','foreground_ms':1234,'background_ms':456,'feedback_ms':0,
              'completed':True,'completed_on_entry':False,'completed_during_visit':True,'post_completion':False,'max_hint_stage':2,'strategy':'batch'}
        def upload(index,p,kind='event',eid=None):
            return self.request('POST','/v1/events',{'client_id':'community-client-'+str(index),'deletion_token':'c'*64,
                'records':[{'event_id':eid or 'community-event-'+str(index),'kind':kind,'payload':p}]})
        self.assertEqual(upload(0,base)[0],200)
        route='/v1/community/tasks?source=automated&mode=test'
        first=self.request('GET',route)[1]['tasks']['chapter_4/mixed']
        self.assertTrue(first['small_sample']); self.assertIsNone(first['completion_percent'])
        for i in range(1,5): self.assertEqual(upload(i,base)[0],200)
        view=self.request('GET',route)[1]['tasks']['chapter_4/mixed']
        self.assertEqual(view['starts'],5); self.assertEqual(view['median_foreground_ms'],1234)
        self.assertEqual(view['completion_percent'],100)
        self.assertEqual(self.request('GET','/v1/community/tasks')[1]['tasks'],{},'Synthetic sources do not enter player stats')
        rule=RULES['boards']['chapter_4/mixed']
        score={**base,**{k:rule[k] for k in ['ruleset_version','model_version','case_set_version']},'build_version':'synthetic-build',
               'event':'score','passed':True,'passed_cases':2,'case_count':2,'total_cycles':2495,
               'sharing_mode':'score','privacy_notice_version':'2026-09-11','consent_version':'sharing-2',
               'consent_timestamp':'2026-09-11T00:00:00Z','source_batch':'synthetic','background_cohort':'unspecified'}
        for prefix,total in [('a',1364),('b',1131)]:
            score.update({prefix+'_total_cycles':total,prefix+'_prepare_cycles':100,prefix+'_query_cycles':total-109,
                prefix+'_output_cycles':9,prefix+'_ram_read_bytes':352,prefix+'_ram_write_bytes':68,prefix+'_peak_extra_bytes':32})
        self.assertEqual(upload(0,score,'score','synthetic-score-01')[0],200)
        self.assertEqual(upload(0,score,'score','synthetic-score-01')[0],200)
        current=copy.deepcopy(score); current['privacy_notice_version']='2026-10-17'
        self.assertEqual(upload(0,current,'score','synthetic-score-current')[0],200)
        future=copy.deepcopy(score); future['privacy_notice_version']='2099-01-01'
        self.assertEqual(upload(0,future,'score','synthetic-score-future')[0],400)
        query=urlencode({'level_id':'chapter_4/mixed',**{k:rule[k] for k in ['ruleset_version','model_version','case_set_version']},'source':'automated','mode':'test'})
        board=self.request('GET','/v1/leaderboards?'+query)[1]
        self.assertFalse(board['verified']); self.assertEqual(len(board['rows']),1)
        self.assertNotIn('client_id',board['rows'][0]); self.assertEqual(board['rows'][0]['total_cycles'],2495)
        for field,value in [('passed_cases',1),('a_total_cycles',0),('a_ram_read_bytes',17),('case_set_version','wrong'),('a_query_cycles',1),('total_cycles',float('inf'))]:
            bad=copy.deepcopy(score);bad[field]=value
            self.assertEqual(upload(0,bad,'score','synthetic-bad-'+field)[0],400,field)
        self.assertEqual(self.request('DELETE','/v1/data',{'client_id':'community-client-0','deletion_token':'c'*64})[0],200)
        self.assertEqual(upload(0,base)[0],410)
        self.assertEqual(self.request('GET','/v1/leaderboards?'+query)[1]['rows'],[])
        self.assertTrue(self.request('GET',route)[1]['tasks']['chapter_4/mixed']['small_sample'])
if __name__=='__main__': __import__('unittest').main(verbosity=2)
