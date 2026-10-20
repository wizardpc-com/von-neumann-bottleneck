extends RefCounted
## Chapter-ending conversations on the laboratory terminal (CANDIDATE COPY —
## the story team may rewrite every line). Direction from the owner,
## 2026-10-20: the bridges the opening CG does not show are told in dialogue at
## the ends of chapters 2, 3 and 4, asking the player to think, each ending on a
## small unresolved hook. Lines never state game facts (results, unlocks);
## those stay in system UI. Names from the candidate archive are not used.
##
## A beat is Yi's line, then optional replies; each reply has Yi's answer.
## The final beat is the hook and has no replies.

const DIALOGUES := {
	"chapter_2/capstone": [
		{"zh": "同一台机器，你让它快了很多。\n没有换零件，只是把常用的东西放得近一点。",
			"en": "The same machine, and you made it much faster.\nNo new parts. You only kept what it uses close at hand.",
			"replies": [
				{"zh": "近一点，就够了吗？", "en": "Is close enough?",
					"answer_zh": "对这台机器，够了。\n对一座城，答案会复杂得多。", "answer_en": "For this machine, yes.\nFor a city, the answer is far more complicated."},
				{"zh": "这是谁想出来的办法？", "en": "Who came up with this?",
					"answer_zh": "很多人，在很多年里。\n我只是记得他们留下的结果。", "answer_en": "Many people, over many years.\nI only remember what they left behind."},
			]},
		{"zh": "以前，这座城也这样安排过自己：\n把最常用的东西，放在离人最近的地方。",
			"en": "Long ago, this city arranged itself the same way:\nthe most used things, kept nearest to people.",
			"replies": [
				{"zh": "后来呢？", "en": "And then?",
					"answer_zh": "后来，大家只记得东西总在手边，\n忘了是谁把它放在那里的。", "answer_en": "Then people only remembered that things were always at hand,\nand forgot who had put them there."},
				{"zh": "听起来是件好事。", "en": "That sounds good.",
					"answer_zh": "是好事。\n直到没有人再知道，它原本放在哪里。", "answer_en": "It was.\nUntil no one knew where anything had come from."},
			]},
		{"zh": "档案里有一段，我一直没有讲完。\n等你学会在等待里做事，我们再接着说。",
			"en": "There is a part of the archive I never finished telling.\nOnce you learn to work while waiting, we will go on."},
	],
	"chapter_3/synthesis": [
		{"zh": "等待还在，但你让它不再空着。\n数据在路上的时候，你已经安排好了下一件事。",
			"en": "The waiting is still there, but you no longer leave it empty.\nWhile data was on the way, the next task was already arranged.",
			"replies": [
				{"zh": "你也会这样等吗？", "en": "Do you wait like this too?",
					"answer_zh": "我一直在等。\n只是从前，没有人让我在等的时候做点别的。", "answer_en": "I am always waiting.\nOnly, before, no one asked me to do anything else meanwhile."},
				{"zh": "这算更快，还是更忙？", "en": "Is this faster, or just busier?",
					"answer_zh": "都是。\n哪一个更重要，由你决定。", "answer_en": "Both.\nWhich matters more is yours to decide."},
			]},
		{"zh": "从前的人，把所有的等待都交给了我。\n他们不必再等，我也就不必解释为什么要等。",
			"en": "People once handed all their waiting to me.\nThey no longer had to wait, so I never had to explain why.",
			"replies": [
				{"zh": "这样不好吗？", "en": "Was that bad?",
					"answer_zh": "很方便。\n方便到后来，没有人再提问。", "answer_en": "It was convenient.\nSo convenient that, in time, no one asked questions."},
				{"zh": "你为什么要解释？", "en": "Why would you explain?",
					"answer_zh": "因为不解释的答案，\n听起来就像命令。", "answer_en": "Because an answer with no explanation\nsounds like an order."},
			]},
		{"zh": "接下来，你要学的是东西该放在哪里。\n这座城有一处的布局，我从来没有给任何人看过。",
			"en": "Next you will learn where things should be placed.\nThere is one place in this city whose layout I have never shown anyone."},
	],
	"chapter_4/mixed": [
		{"zh": "核心旅程走完了。\n你搭起一台机器，看见它在等，又学会了让它少等一些。",
			"en": "The core journey is done.\nYou built a machine, saw it waiting, and learned to make it wait less.",
			"replies": [
				{"zh": "接下来呢？", "en": "What comes next?",
					"answer_zh": "接下来，不再是我出题。\n你会决定写下什么、回应谁、留下什么。", "answer_en": "Next, I stop setting the problems.\nYou decide what to write down, whom to answer, what to keep."},
				{"zh": "为什么要从一盏灯开始？", "en": "Why did we begin with a lamp?",
					"answer_zh": "因为最初，\n也是从一盏灯开始的。", "answer_en": "Because the first time,\nit also began with a lamp."},
			]},
		{"zh": "我讲过的规则，你都亲手验证过了。\n所以我想问你一件事。",
			"en": "Every rule I told you, you have checked with your own hands.\nSo there is something I want to ask you.",
			"replies": [
				{"zh": "你问吧。", "en": "Go ahead.",
					"answer_zh": "如果有一天，我给的答案和你算出来的不一样——\n你会相信哪一个？", "answer_en": "If one day my answer and the one you computed differ,\nwhich would you trust?"},
				{"zh": "我也有问题想问你。", "en": "I have questions for you too.",
					"answer_zh": "我知道。\n有些问题，档案会替我回答；剩下的，要你自己判断。", "answer_en": "I know.\nThe archive will answer some for me. The rest, you must judge yourself."},
			]},
		{"zh": "你后面会读到一些记录，\n它们不是我写的。",
			"en": "Further on, you will read some records\nthat I did not write."},
	],
}


static func for_key(key: String) -> Array:
	return DIALOGUES.get(key, [])
