"""Builds assets/quran/qcf_v1_layout.json.gz and assets/fonts/qcf/.

Usage: python3 tool/qcf/build_layout.py WORK_DIR

Downloads into WORK_DIR (once) each page's words from the Quran.com API v4
(glyph code_v1 and line number) and the King Fahd Complex QCF v1 page fonts,
then writes the line layout and copies the fonts into the app's assets.

Layout format: a list of 604 pages, each a list of lines. A line is
["h", surah] (surah header), ["b", surah] (basmala), or a list of words
[surah, ayah, glyph] with a fourth element 1 on ayah-number markers.
"""
import gzip, json, os, shutil, sys, urllib.request

API = ('https://api.quran.com/api/v4/verses/by_page/{p}'
       '?words=true&word_fields=code_v1,line_number,page_number&per_page=50')
FONT = 'https://static.qurancdn.com/fonts/quran/hafs/v1/ttf/p{p}.ttf'
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def fetch(url, path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        with urllib.request.urlopen(url, timeout=60) as r, open(path, 'wb') as f:
            f.write(r.read())


def page_layout(data, p, report):
    lines = {}
    for v in data['verses']:
        s, a = map(int, v['verse_key'].split(':'))
        for w in v['words']:
            entry = [s, a, w['code_v1']]
            if w['char_type_name'] == 'end':
                entry.append(1)
            lines.setdefault(w['line_number'], []).append(entry)
    out, run = [], []  # run: empty lines waiting for the surah they open
    for n in range(1, (8 if p <= 2 else 15) + 1):
        words = lines.get(n)
        if not words:
            run.append(n)
            continue
        if run:
            s, a = words[0][0], words[0][1]
            if a != 1:
                report.append(f'page {p}: empty lines before {s}:{a}')
            kinds = [['h', s]] if s in (1, 9) else [['h', s], ['b', s]]
            if len(run) > len(kinds):
                report.append(f'page {p}: {len(run)} empty lines before {s}')
            # A header printed at the foot of the previous page leaves only
            # the basmala here.
            out.extend(kinds[-len(run):])
            run = []
        out.append(words)
    if run:
        # The next surah's header (and basmala) at the foot of the page.
        nxt = out[-1][-1][0] + 1
        kinds = [['h', nxt]] if nxt == 9 else [['h', nxt], ['b', nxt]]
        if len(run) > len(kinds):
            report.append(f'page {p}: trailing empty lines {run}')
        out.extend(kinds[:len(run)])
    return out


def main(work):
    os.makedirs(f'{work}/pages', exist_ok=True)
    os.makedirs(f'{work}/fonts', exist_ok=True)
    layout, report = [], []
    for p in range(1, 605):
        fetch(API.format(p=p), f'{work}/pages/{p}.json')
        fetch(FONT.format(p=p), f'{work}/fonts/p{p}.ttf')
        layout.append(page_layout(json.load(open(f'{work}/pages/{p}.json')), p, report))
    assert not report, report
    ends = sum(1 for page in layout for line in page
               if line and isinstance(line[0], list) for w in line if len(w) > 3)
    assert ends == 6236, ends
    raw = json.dumps(layout, ensure_ascii=False, separators=(',', ':')).encode()
    with open(f'{ROOT}/assets/quran/qcf_v1_layout.json.gz', 'wb') as f:
        f.write(gzip.compress(raw, 9, mtime=0))  # mtime=0: reproducible
    os.makedirs(f'{ROOT}/assets/fonts/qcf', exist_ok=True)
    for p in range(1, 605):
        shutil.copyfile(f'{work}/fonts/p{p}.ttf', f'{ROOT}/assets/fonts/qcf/p{p}.ttf')
    print('done')


if __name__ == '__main__':
    main(sys.argv[1])
