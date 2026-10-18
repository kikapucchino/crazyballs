import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('build_place', ROOT / 'tools/build_place.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class PlaceTests(unittest.TestCase):
    def test_scripts_are_embedded_exactly_once_in_correct_services(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / 'CloudpopCommons.rbxlx'
            builder.build(destination)
            root = ET.parse(destination).getroot()
            sources = {source.read_text(): source for source in (ROOT / 'src').rglob('*.luau')}
            embedded = root.findall('.//ProtectedString[@name="Source"]')
            self.assertEqual(len(embedded), len(sources))
            self.assertEqual({node.text for node in embedded}, set(sources))
            scripts = root.findall('./Item[@class="ServerScriptService"]//Item[@class="Script"]')
            clients = root.findall('./Item[@class="StarterPlayer"]//Item[@class="LocalScript"]')
            self.assertEqual(len(scripts), 1)
            self.assertEqual(len(clients), 1)
            self.assertEqual(len(root.findall('./Item[@class="ReplicatedStorage"]//Item[@class="ModuleScript"]')), 3)
            self.assertEqual(root.attrib['version'], '4')

    def test_place_is_reproducible_and_checksum_matches(self):
        with tempfile.TemporaryDirectory() as directory:
            first, second = Path(directory) / 'a.rbxlx', Path(directory) / 'b.rbxlx'
            builder.build(first)
            builder.build(second)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            expected = hashlib.sha256(first.read_bytes()).hexdigest()
            self.assertEqual(first.with_suffix('.rbxlx.sha256').read_text().split()[0], expected)


if __name__ == '__main__':
    unittest.main()
