#!/usr/bin/env python3
"""Refresh the self-contained results page's game catalog titles and CSP hashes."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re


DEPLOY = Path(__file__).resolve().parent
ROOT = DEPLOY.parents[1]


def translations(path):
    entries = re.finditer(r'^msgid (".*")\nmsgstr (".*")((?:\n".*")*)', path.read_text(encoding="utf-8"), re.M)
    return {json.loads(key): json.loads(value) + "".join(json.loads(line) for line in rest.splitlines() if line)
            for key, value, rest in (entry.groups() for entry in entries)}


def catalog_list(source, name):
    match = re.search(r"^const " + name + r"\b[^=\n]*=\s*(\[.*?\])", source, re.M | re.S)
    return json.loads(match[1])


def paired_titles(domain, ids, english, chinese):
    if len(ids) != len(english) or len(ids) != len(chinese):
        raise ValueError("misaligned localized task catalog for " + domain)
    return {f"{domain}/{level}": [en, zh] for level, en, zh in zip(ids, english, chinese)}


def catalog_titles(root):
    catalog = json.loads((root / "server/community_rules.json").read_text(encoding="utf-8"))
    tasks = {key for manifest in catalog["content_manifests"].values() for key in manifest["tasks"]}
    locales = [translations(root / "localization" / f"game.{locale}.po") for locale in ("en", "zh_CN")]
    prologue = {}
    for path in (root / "src/content/prologue").glob("*_content_pack.gd"):
        pattern = r'LevelType\.new\(\s*&"([^"]+)"\s*,\s*&"[^"]+"\s*,\s*\d+\s*,\s*&"([^"]+)"'
        prologue.update(re.findall(pattern, path.read_text(encoding="utf-8")))
    prefixes = {"chapter_1": "system.level", "chapter_2": "chapter2.level", "chapter_3": "overlap"}
    titles = {}
    for task in sorted(tasks):
        domain, level = task.split("/", 1)
        key = prologue.get(level) if domain == "hardware_foundations" else (
            f"{prefixes[domain]}.{level}.title" if domain in prefixes else None)
        if key:
            titles[task] = [locale.get(key, "") for locale in locales]

    for domain, file, en, zh in (
        ("chapter_4", "src/layout_chapter/layout_catalog.gd", "EN_TITLES", "TITLES"),
        ("creation", "experiments/creation/catalog.gd", "TITLES_EN", "TITLES_ZH"),
    ):
        source = (root / file).read_text(encoding="utf-8")
        titles.update(paired_titles(domain, catalog_list(source, "IDS"), catalog_list(source, en), catalog_list(source, zh)))

    second_act = (root / "src/campaign/second_act_tasks.gd").read_text(encoding="utf-8")
    ids = json.loads(re.search(r"^const IDS := (\{.*\})$", second_act, re.M)[1])
    rep = (root / "experiments/representation_region/catalog.gd").read_text(encoding="utf-8")
    for domain, pattern, source in (
        ("representation", r"^static func title\(.*\n\s*return \((\[.*?\]) if en else (\[.*?\])", rep),
        ("service", r"var service_titles: Array = (\[.*?\]) if english else (\[.*?\])", second_act),
        ("prediction", r"var prediction_titles: Array = (\[.*?\]) if english else (\[.*?\])", second_act),
    ):
        english, chinese = map(json.loads, re.search(pattern, source, re.M).groups())
        titles.update(paired_titles(domain, ids[domain], english, chinese))
    return {key: value for key, value in sorted(titles.items()) if key in tasks and any(value)}


def rendered_page(source, titles):
    data = ",\n".join(f"    {json.dumps(key)}: {json.dumps(value, ensure_ascii=False)}"
                      for key, value in titles.items()).replace("<", "\\u003c")
    block = "  // BEGIN GENERATED TASK TITLES\n  const taskTitles = {\n" + data + "\n  };\n  // END GENERATED TASK TITLES"
    result, count = re.subn(r"  // BEGIN GENERATED TASK TITLES\n.*?\n  // END GENERATED TASK TITLES",
                            lambda _: block, source, flags=re.S)
    if count != 1:
        raise ValueError("expected one task title block")
    return result


def with_csp(source, page):
    for tag in ("script", "style"):
        body, = re.findall(fr"<{tag}>(.*?)</{tag}>", page, re.S)
        digest = base64.b64encode(hashlib.sha256(body.encode("utf-8")).digest()).decode("ascii")
        source, count = re.subn(fr"{tag}-src 'sha256-[^']+'", f"{tag}-src 'sha256-{digest}'", source)
        if count != 1:
            raise ValueError("expected one CSP hash for " + tag)
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    site = DEPLOY / "my-results.html"
    caddy = DEPLOY / "vnb-feedback-public.caddy"
    original_page, original_config = (path.read_text(encoding="utf-8") for path in (site, caddy))
    page = rendered_page(original_page, catalog_titles(ROOT))
    config = with_csp(original_config, page)
    if args.check:
        if (page, config) != (original_page, original_config):
            parser.exit(1, "Results page titles or CSP are stale. Regenerate them.\n")
        return
    site.write_text(page, encoding="utf-8")
    caddy.write_text(config, encoding="utf-8")


if __name__ == "__main__":
    main()
