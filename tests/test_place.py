import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile
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
            embedded = root.findall('.//Properties/*[@name="Source"]')
            self.assertEqual(len(embedded), len(sources))
            self.assertEqual({node.text for node in embedded}, set(sources))
            scripts = root.findall('./Item[@class="ServerScriptService"]//Item[@class="Script"]')
            clients = root.findall('./Item[@class="StarterGui"]/Item[@class="ScreenGui"]/Item[@class="LocalScript"]')
            self.assertEqual(len(scripts), 1)
            self.assertEqual(len(clients), 1)
            self.assertEqual(len(root.findall('./Item[@class="ReplicatedStorage"]//Item[@class="ModuleScript"]')), 7)
            self.assertEqual(root.attrib['version'], '4')
            workspace = root.find('./Item[@class="Workspace"]/Properties')
            height = workspace.find('./*[@name="FallenPartsDestroyHeight"]')
            self.assertIsNotNone(height, 'The restricted height property must be saved in the place')
            self.assertEqual(float(height.text), -100)

    def test_binary_place_has_the_roblox_binary_header(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / 'CloudpopCommons.rbxl'
            builder.build(destination)
            data = destination.read_bytes()
            self.assertTrue(data.startswith(b'<roblox!\x89\xff\r\n\x1a\n'))
            self.assertGreater(len(data), 1000)
            expected = hashlib.sha256(data).hexdigest()
            self.assertEqual(destination.with_suffix('.rbxl.sha256').read_text().split()[0], expected)

    def test_startup_interface_is_packaged_without_running_any_script(self):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / 'CloudpopCommons.rbxlx'
            builder.build(destination)
            root = ET.parse(destination).getroot()
            gui = root.find('./Item[@class="StarterGui"]/Item[@class="ScreenGui"]')
            self.assertIsNotNone(gui)
            self.assertEqual(gui.findtext('./Properties/bool[@name="ResetOnSpawn"]'), 'false')
            status = gui.find('./Item[@class="TextLabel"]/Properties')
            self.assertEqual(status.findtext('./string[@name="Name"]'), 'StartupStatus')
            self.assertIn('CLOUDPOP COMMONS', status.findtext('./string[@name="Text"]'))
            self.assertEqual(status.findtext('./UDim2[@name="Size"]/XS'), '0')
            self.assertEqual(status.findtext('./UDim2[@name="Size"]/YS'), '0')

    def test_download_zip_contains_exact_binary_place(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'CloudpopCommons.rbxl'
            builder.build(source)
            builder.package_zip(source)
            archive_path = source.parent / 'CloudpopCommons-Studio.zip'
            with zipfile.ZipFile(archive_path) as archive:
                self.assertEqual(archive.namelist(), ['CloudpopCommons.rbxl'])
                self.assertIsNone(archive.testzip())
                self.assertEqual(archive.read('CloudpopCommons.rbxl'), source.read_bytes())

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
