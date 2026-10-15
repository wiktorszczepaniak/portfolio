"""Static source + packed-asset integrity checks for the GitHub branch."""
from pathlib import Path
import base64, io, re, zipfile
root = Path(__file__).resolve().parent / 'project'
script = (root / 'scripts/boss_rush.gd').read_text()
patterns = (root / 'scripts/bullet_patterns.gd').read_text()
scene = (root / 'scenes/main.tscn').read_text()
assert 'res://scripts/boss_rush.gd' in scene
assert 'res://scenes/main.tscn' in (root / 'project.godot').read_text()
for p in re.findall(r'"(res://[^"%]+\.(?:gd|tscn))"', script + scene):
    assert (root / p[6:]).exists(), p
for keyword in ('run_logic_qa','QA_LOGIC_PASS','QA_SMOKE_PASS','transform_stage += 1',
                'clone_shot_cd = 0.50','phase_shift(2)','phase_shift(3)',
                'load_progress','save_progress','boss_attack'):
    assert keyword in script, keyword
assert 'shot_cd <= 0.03' not in script, 'Clone frame-rate flood regression'
for key in ('ring','fan','aimed','spiral','wave'):
    assert 'static func ' + key in patterns, key
with zipfile.ZipFile(io.BytesIO(base64.b64decode((root / 'assets/packed_sprites.b64').read_text()))) as z:
    assert z.testzip() is None, 'Sprite ZIP corruption'
    names = z.namelist()
    for form in ('base','kyuubi','sage','kcm'):
        assert sum(x.startswith('assets/characters/naruto/' + form + '_') for x in names) >= 6, form
    assert sum(x.startswith('assets/characters/zabuza/z_') for x in names) >= 20, 'Zabuza frames'
with zipfile.ZipFile(io.BytesIO(base64.b64decode((root / 'assets/packed_audio.b64').read_text()))) as z:
    assert z.testzip() is None, 'Audio ZIP corruption'
    assert len([x for x in z.namelist() if x.endswith('.ogg')]) >= 10, 'Audio clips'
print('QA_STATIC_GITHUB_PASS: source, sprites, sound, gameplay invariants')
