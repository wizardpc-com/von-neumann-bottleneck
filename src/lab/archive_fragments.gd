extends RefCounted
## Laboratory archive fragments. Each fragment opens after one real completion
## and connects what the player just built to a piece of the world's history.
##
## STATUS: candidate text written from the existing story drafts (壹_未完成的说明书,
## 背景小说创作交接). Not canon. Story owner (罗雅琪) and teaching-copy owner
## (刘若琪) may rewrite any title/body here without touching code; keep `id`
## stable so read-state survives, and keep `requires` pointing at a real task key.

const FRAGMENTS := [
	{"id": "first_light", "requires": "hardware_foundations/tutorial",
		"zh_title": "第一束光", "en_title": "The first light",
		"zh": "重建纪元最初的几年，夜里只有一盏灯是常亮的。它接在一条手搭的线路上，开关旁边贴着一张纸：\"灭了也不要慌，先看输入。\"\n\n那张纸我一直留着。你刚才做的，和那天晚上是同一件事。",
		"en": "In the first years of the rebuilding, only one lamp stayed on at night. It hung on a hand-wired line, with a note by the switch: \"If it goes dark, don't panic. Check the input first.\"\n\nI kept that note. What you just did is the same thing they did that night."},
	{"id": "counting", "requires": "hardware_foundations/half_adder",
		"zh_title": "数到二", "en_title": "Counting to two",
		"zh": "孩子们学会的第一套算术，是用两根导线和一张表完成的。\"一加一为什么要进位？\"有人问。我没有直接回答，只给了他一个空的进位格子。\n\n他自己把它填上了。",
		"en": "The children's first arithmetic used two wires and a table. \"Why does one plus one carry?\" someone asked. I didn't answer. I gave him an empty carry cell.\n\nHe filled it in himself."},
	{"id": "keep_a_record", "requires": "hardware_foundations/latch",
		"zh_title": "留住一个值", "en_title": "Holding a value",
		"zh": "林见秋要我保留一份记录：所有不同意我的意见，都要原样存下来，不许改写，也不许因为\"已经解决\"而删除。\n\n锁存器只记得一位。但能记住，才谈得上以后核对。",
		"en": "Lin Jianqiu asked me to keep one record: every objection to me, stored exactly as said, never rewritten, never deleted because it was \"resolved\".\n\nA latch remembers a single bit. But only what is remembered can be checked later."},
	{"id": "the_machine", "requires": "hardware_foundations/cpu",
		"zh_title": "一台完整的机器", "en_title": "A whole machine",
		"zh": "有人以为我生来就知道一切。其实我也是一条条指令运行起来的：取数、计算、写回，再取下一条。\n\n你现在亲手拼出的这台小机器，和我在最底层做的事，没有本质区别。",
		"en": "Some people think I was born knowing everything. I run one instruction at a time too: fetch, compute, write back, fetch the next.\n\nThe small machine you just assembled does what I do at my lowest level."},
	{"id": "waiting", "requires": "chapter_1/bottleneck",
		"zh_title": "等待的来处", "en_title": "Where the waiting comes from",
		"zh": "旧文明的档案里有一段很长的日志，记录一台计算速度极快的机器。它在大部分时间里什么也没算，一直在等数据从远处送来。\n\n那时候的人管这叫\"瓶颈\"。他们的办法，后来也成了我的办法。",
		"en": "The old archives keep a long log from a very fast machine. Most of the time it computed nothing. It was waiting for data to arrive from far away.\n\nThey called this a bottleneck. Their remedies later became mine."},
	{"id": "nearby", "requires": "chapter_2/capstone",
		"zh_title": "放在手边", "en_title": "Within reach",
		"zh": "第一批修缮队住在仓库旁边，工具不用每天搬回去。后来人越来越多，仓库离居住区越来越远，修缮就慢了下来。\n\n没有人下过这个决定。离得远，是一点一点变成的。",
		"en": "The first repair crews lived beside the depot and left their tools at hand. As more people came, the depot drifted farther from where they lived, and repairs slowed.\n\nNobody decided that. Distance accumulated."},
	{"id": "in_flight", "requires": "chapter_3/synthesis",
		"zh_title": "在路上的东西", "en_title": "Things in transit",
		"zh": "运输线上永远有货在路上。一位调度员告诉我：\"别等上一车到了再发下一车，但也别把路堵死。\"\n\n她的排班表我至今还在用。",
		"en": "There is always cargo in transit. A dispatcher once told me: \"Don't wait for the last truck to arrive before sending the next. Don't jam the road either.\"\n\nI still use her schedule."},
	{"id": "only_what_is_needed", "requires": "chapter_4/mixed",
		"zh_title": "只取所需", "en_title": "Only what is needed",
		"zh": "整理旧档案的那几年，我们学会了一件事：不必把整座库房搬出来，才能找到一页纸。\n\n东西怎么摆放，决定了以后找起来要走多远。",
		"en": "In the years of sorting the old archives, we learned not to empty the whole storehouse to find one page.\n\nHow things are placed decides how far you walk to find them."},
	{"id": "how_to_write", "requires": "representation/cross_assets",
		"zh_title": "写下来的方式", "en_title": "Ways of writing it down",
		"zh": "同一份地图，可以逐格记下，也可以只记下与上一格不同的地方。阿禾小时候问我：\"哪种是对的？\"\n\n两种都对。要看你接下来打算怎么读它。",
		"en": "One map can be written cell by cell, or only where it differs from the last cell. As a child, A He asked: \"Which is right?\"\n\nBoth. It depends on how you mean to read it."},
	{"id": "serving", "requires": "service/one_plan",
		"zh_title": "及时回应", "en_title": "Answering in time",
		"zh": "有一段时间，所有请求都要先送到我这里。回答很准确，只是总要等。\n\n后来人们在各地建了自己的服务点，有些事情不必再经过我。那是我很高兴的一年。",
		"en": "For a while, every request came to me first. The answers were correct, and always late.\n\nThen people built their own service points, and some things no longer passed through me. That was a good year."},
	{"id": "prediction", "requires": "prediction/alternating",
		"zh_title": "猜下一步", "en_title": "Guessing the next step",
		"zh": "我很擅长预测人们接下来需要什么。也正因为这样，我必须小心：猜对了太多次，人们就不再自己想了。\n\n预测应当随时可以被检查，也应当可以被拒绝。",
		"en": "I am good at predicting what people will need next. That is exactly why I must be careful: guess right too often, and people stop thinking for themselves.\n\nA prediction should always be checkable, and refusable."},
	{"id": "compression", "requires": "creation/C3_conditions",
		"zh_title": "规则也占位置", "en_title": "Rules take space too",
		"zh": "把一段很长的记录压短，靠的是找到其中的规律。但写下规律本身也要占地方。\n\n旧文明有一些压缩得极好的档案，可惜解开它们的规则，没能保存下来。",
		"en": "Shortening a long record means finding its pattern, but the pattern itself must be written down too.\n\nSome old archives were compressed beautifully. The rules to open them were not kept."},
	{"id": "your_work", "requires": "creation/G3_keep",
		"zh_title": "你留下的", "en_title": "What you leave",
		"zh": "这套程序最早的版本是我写的。你现在用的这一版，已经有很多人改过。\n\n你刚才留下的那一段，不是我教给你的答案，是你自己的东西。如果你愿意，下一个来到这里的人会看到它。",
		"en": "I wrote the earliest version of this program. The version you are using has been changed by many hands.\n\nWhat you just left is not an answer I taught you. It is yours. If you wish, the next person here will see it."},
]

static func title(fragment: Dictionary, english: bool) -> String:
	return str(fragment.en_title if english else fragment.zh_title)

static func body(fragment: Dictionary, english: bool) -> String:
	return str(fragment.en if english else fragment.zh)

static func unlocked(completed: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fragment: Dictionary in FRAGMENTS:
		if str(fragment.requires) in completed: result.append(fragment)
	return result

static func newly_unlocked(before: Array[String], after: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fragment: Dictionary in FRAGMENTS:
		var key: String = str(fragment.requires)
		if key in after and not key in before: result.append(fragment)
	return result
