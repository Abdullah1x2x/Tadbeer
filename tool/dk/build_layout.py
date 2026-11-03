"""Builds assets/quran/dk_layout.json.gz and assets/fonts/DigitalKhattV2.otf.

Usage: python3 tool/dk/build_layout.py WORK_DIR

Downloads into WORK_DIR (once) the DigitalKhatt Madina Mushaf text (MIT,
github.com/DigitalKhatt/digitalkhatt-js) and the Digital Khatt V2 font (SIL
OFL-1.1, Tarteel QUL), then writes the line layout in the format of
qcf_v1_layout.json.gz: a list of 604 pages, each a list of lines. A line is
["h", surah] (surah header), ["b", surah] (basmala), or a list of words
[surah, ayah, text] with a fourth element 1 on ayah-number markers.

The source is TypeScript; it is read as data (nested arrays of quoted
strings), never run.
"""
import gzip, json, os, re, shutil, sys, unicodedata, urllib.request

TEXT = ('https://raw.githubusercontent.com/DigitalKhatt/digitalkhatt-js/HEAD/'
        'apps/site-angular/src/app/services/quran_text_madina.ts')
FONT = 'https://static-cdn.tarteel.ai/qul/fonts/dk/DigitalKhattV2.otf'
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BASMALA = unicodedata.normalize('NFC', 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ')
HEADER = 'سُورَةُ'
MARKER = '۝'
DIGITS = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')


def fetch(url, path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        # The font CDN refuses Python's default user agent.
        req = urllib.request.Request(url, headers={'User-Agent': 'tadbeer-build'})
        with urllib.request.urlopen(req, timeout=60) as r, open(path, 'wb') as f:
            f.write(r.read())


def read_pages(path):
    """The nested string arrays of the .ts file, without running it."""
    src = open(path, encoding='utf-8').read()
    body = src[src.index('['):src.rindex(']') + 1]
    pages, page, depth = [], None, 0
    for m in re.finditer(r"\[|\]|'((?:[^'\\]|\\.)*)'", body):
        token = m.group(0)
        if token == '[':
            depth += 1
            if depth == 2:
                page = []
        elif token == ']':
            if depth == 2:
                pages.append(page)
            depth -= 1
        else:
            assert depth == 2, token
            page.append(m.group(1).replace("\\'", "'"))
    return pages


def build(pages, ayah_counts):
    """Lines with each word's surah and ayah, walking the Mushaf in order."""
    surah, ayah = 0, 1
    layout = []
    for p, lines in enumerate(pages, 1):
        out = []
        for line in lines:
            if line.startswith(HEADER):
                surah, ayah = surah + 1, 1
                out.append(['h', surah])
            # The source orders some marks differently (shadda before fatha).
            elif unicodedata.normalize('NFC', line) == BASMALA and surah != 1:
                out.append(['b', surah])
            else:
                words = []
                for token in line.split(' '):
                    if token.startswith(MARKER):
                        number = int(token[1:].translate(DIGITS))
                        assert number == ayah, (p, surah, number, ayah)
                        words.append([surah, ayah, token, 1])
                        ayah += 1
                    else:
                        words.append([surah, ayah, token])
                out.append(words)
        layout.append(out)
    # Every surah ends on its last ayah.
    ends = {}
    for page in layout:
        for line in page:
            for w in line if isinstance(line[0], list) else []:
                if len(w) > 3:
                    ends[w[0]] = w[1]
    assert ends == ayah_counts, 'ayah counts differ'
    return layout


def page_mismatches(layout, app_pages):
    """Pages whose ayahs differ from the app's page data."""
    out = []
    for p, (page, app) in enumerate(zip(layout, app_pages), 1):
        ours = {(w[0], w[1]) for line in page if isinstance(line[0], list)
                for w in line}
        theirs = {(a['surahNumber'], a['ayahNumber']) for a in app['ayahs']}
        if ours != theirs:
            out.append(p)
    return out


def main(work):
    os.makedirs(work, exist_ok=True)
    fetch(TEXT, f'{work}/quran_text_madina.ts')
    fetch(FONT, f'{work}/DigitalKhattV2.otf')
    data = json.load(open(f'{ROOT}/assets/quran/quran_data.json'))
    counts = {s['number']: s['ayahCount'] for s in data['surahs']}
    pages = read_pages(f'{work}/quran_text_madina.ts')
    assert len(pages) == 604, len(pages)
    layout = build(pages, counts)
    basmalas = sum(1 for page in layout for line in page if line[0] == 'b')
    assert basmalas == 112, basmalas  # all but al-Fatihah and at-Tawbah
    mismatched = page_mismatches(layout, data['pages'])
    print('pages whose ayahs differ from the app data:', mismatched)
    raw = json.dumps(layout, ensure_ascii=False, separators=(',', ':')).encode()
    with open(f'{ROOT}/assets/quran/dk_layout.json.gz', 'wb') as f:
        f.write(gzip.compress(raw, 9, mtime=0))  # mtime=0: reproducible
    shutil.copyfile(f'{work}/DigitalKhattV2.otf',
                    f'{ROOT}/assets/fonts/DigitalKhattV2.otf')
    print('done')


if __name__ == '__main__':
    main(sys.argv[1])
